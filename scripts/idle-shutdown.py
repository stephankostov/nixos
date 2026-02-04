#!/usr/bin/env python3
import argparse
import time
import subprocess


def read_cpu_times():
    with open("/proc/stat", "r", encoding="utf-8") as f:
        line = f.readline()
    parts = line.split()
    if not parts or parts[0] != "cpu":
        raise RuntimeError("Unexpected /proc/stat format")
    vals = [int(x) for x in parts[1:]]
    total = sum(vals)
    idle = vals[3] + (vals[4] if len(vals) > 4 else 0)  # idle + iowait
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


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--threshold", type=float, default=10.0)
    p.add_argument("--sample-sec", type=float, default=1.0)
    p.add_argument("--checks", type=int, default=6)          
    p.add_argument("--between-sec", type=float, default=10.0)
    args = p.parse_args()

    for _ in range(args.checks):
        usage = cpu_usage_percent(args.sample_sec)
        if usage >= args.threshold:
            return 0
        time.sleep(args.between_sec)

    print("System idle, shutting down...", flush=True)
    subprocess.run(["systemctl", "poweroff"], check=False)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
