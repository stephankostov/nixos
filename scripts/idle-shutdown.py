#!/usr/bin/env python3
import argparse
import shutil
import subprocess
import time


def read_cpu_times():
    with open("/proc/stat", "r", encoding="utf-8") as f:
        line = f.readline()
    parts = line.split()
    if not parts or parts[0] != "cpu":
        raise RuntimeError("Unexpected /proc/stat format")
    vals = [int(x) for x in parts[1:]]
    total = sum(vals)
    idle = vals[3] + (vals[4] if len(vals) > 4 else 0)
    return total, idle


def cpu_usage_percent(sample_sec: float) -> float:
    t0, i0 = read_cpu_times()
    time.sleep(sample_sec)
    t1, i1 = read_cpu_times()
    dt = t1 - t0
    di = i1 - i0
    if dt <= 0:
        return 0.0
    return 100.0 * (dt - di) / dt


def loadavg_1min() -> float:
    with open("/proc/loadavg", "r", encoding="utf-8") as f:
        return float(f.readline().split()[0])


def find_nvidia_smi() -> str | None:
    for cand in ("/run/opengl-driver/bin/nvidia-smi",
                 "/run/current-system/sw/bin/nvidia-smi"):
        if shutil.which(cand):
            return cand
    return shutil.which("nvidia-smi")


def gpu_busy(util_threshold: float, mem_mb_threshold: int) -> tuple[bool, str]:
    smi = find_nvidia_smi()
    if not smi:
        return False, "no nvidia-smi"
    try:
        out = subprocess.run(
            [smi, "--query-gpu=utilization.gpu,memory.used",
             "--format=csv,noheader,nounits"],
            capture_output=True, text=True, timeout=10, check=True,
        ).stdout
    except (subprocess.SubprocessError, FileNotFoundError) as e:
        return False, f"nvidia-smi failed: {e}"
    for line in out.strip().splitlines():
        try:
            util_s, mem_s = [x.strip() for x in line.split(",")]
            util = float(util_s)
            mem = int(mem_s)
        except ValueError:
            continue
        if util >= util_threshold or mem >= mem_mb_threshold:
            return True, f"gpu util={util}% mem={mem}MiB"
    return False, "gpu idle"


def has_active_sessions() -> tuple[bool, str]:
    try:
        out = subprocess.run(
            ["loginctl", "list-sessions", "--no-legend"],
            capture_output=True, text=True, timeout=5, check=True,
        ).stdout.strip()
    except (subprocess.SubprocessError, FileNotFoundError):
        out = ""
    if out:
        return True, f"{len(out.splitlines())} login session(s)"
    try:
        who = subprocess.run(
            ["who"], capture_output=True, text=True, timeout=5, check=True,
        ).stdout.strip()
    except (subprocess.SubprocessError, FileNotFoundError):
        who = ""
    if who:
        return True, f"who: {len(who.splitlines())} user(s)"
    return False, "no sessions"


def read_net_bytes(ignored_prefixes: tuple[str, ...]) -> int:
    total = 0
    with open("/proc/net/dev", "r", encoding="utf-8") as f:
        lines = f.readlines()[2:]
    for line in lines:
        name, _, rest = line.partition(":")
        name = name.strip()
        if not name or name == "lo":
            continue
        if any(name.startswith(p) for p in ignored_prefixes):
            continue
        parts = rest.split()
        if len(parts) < 16:
            continue
        rx = int(parts[0])
        tx = int(parts[8])
        total += rx + tx
    return total


def net_busy(sample_sec: float, kbps_threshold: float) -> tuple[bool, str]:
    ignored = ("docker", "veth", "br-", "virbr", "tailscale", "wg")
    b0 = read_net_bytes(ignored)
    time.sleep(sample_sec)
    b1 = read_net_bytes(ignored)
    kbps = ((b1 - b0) * 8 / 1000.0) / max(sample_sec, 0.001)
    if kbps >= kbps_threshold:
        return True, f"net {kbps:.0f} kbps"
    return False, f"net {kbps:.0f} kbps"


def watched_process_running(patterns: list[str]) -> tuple[bool, str]:
    for pat in patterns:
        try:
            r = subprocess.run(
                ["pgrep", "-af", pat],
                capture_output=True, text=True, timeout=5,
            )
        except (subprocess.SubprocessError, FileNotFoundError):
            continue
        if r.returncode == 0 and r.stdout.strip():
            first = r.stdout.strip().splitlines()[0]
            return True, f"proc {pat!r}: {first[:80]}"
    return False, "no watched procs"


def check_busy(args) -> tuple[bool, str]:
    cpu = cpu_usage_percent(args.sample_sec)
    if cpu >= args.cpu_threshold:
        return True, f"cpu {cpu:.1f}%"

    la = loadavg_1min()
    if la >= args.load_threshold:
        return True, f"loadavg1 {la:.2f}"

    for fn in (
        lambda: gpu_busy(args.gpu_util_threshold, args.gpu_mem_mb_threshold),
        has_active_sessions,
        lambda: net_busy(args.sample_sec, args.net_kbps_threshold),
        lambda: watched_process_running(args.watch_proc),
    ):
        busy, msg = fn()
        if busy:
            return True, msg

    return False, f"idle (cpu {cpu:.1f}% la {la:.2f})"


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--cpu-threshold", type=float, default=10.0)
    p.add_argument("--load-threshold", type=float, default=1.0)
    p.add_argument("--gpu-util-threshold", type=float, default=5.0)
    p.add_argument("--gpu-mem-mb-threshold", type=int, default=500)
    p.add_argument("--net-kbps-threshold", type=float, default=200.0)
    p.add_argument("--sample-sec", type=float, default=2.0)
    p.add_argument("--checks", type=int, default=15,
                   help="consecutive idle checks required before shutdown")
    p.add_argument("--between-sec", type=float, default=120.0)
    p.add_argument("--watch-proc", action="append", default=[
        "python", "jupyter", "ipykernel", "torchrun", "torch.distributed",
        "wandb", "tensorboard", "rsync", "rclone",
    ])
    args = p.parse_args()

    for i in range(args.checks):
        busy, msg = check_busy(args)
        print(f"[{i+1}/{args.checks}] {msg}", flush=True)
        if busy:
            return 0
        if i < args.checks - 1:
            time.sleep(args.between_sec)

    print("System idle across all checks, shutting down...", flush=True)
    subprocess.run(["systemctl", "poweroff"], check=False)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
