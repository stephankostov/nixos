#!/usr/bin/env python3
import argparse
import json
import subprocess
import time
from pathlib import Path

STATE_DIR = Path("/run/thermal-shutdown")
STATE_FILE = STATE_DIR / "since_epoch"

def max_temp_c_from_sensors_json(data):
    m = None

    def walk(x):
        nonlocal m
        if isinstance(x, dict):
            for k, v in x.items():
                if k.endswith("_input") and isinstance(v, (int, float)):
                    m = v if m is None else max(m, v)
                else:
                    walk(v)
        elif isinstance(x, list):
            for v in x:
                walk(v)

    walk(data)
    return m


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--max-c", type=float, default=90.0)
    p.add_argument("--persist-sec", type=int, default=600)
    p.add_argument("--sensors-bin", default="sensors")
    args = p.parse_args()

    STATE_DIR.mkdir(parents=True, exist_ok=True)

    out = subprocess.check_output([args.sensors_bin, "-j"], text=True)
    data = json.loads(out)
    max_c = max_temp_c_from_sensors_json(data)
    if max_c is None:
        raise SystemExit("No *_input temperature fields found in sensors -j output")

    now = int(time.time())

    if max_c >= args.max_c:
        try:
            since = int(STATE_FILE.read_text().strip())
        except FileNotFoundError:
            since = now
            STATE_FILE.write_text(str(since))

        hot_for = now - since
        if hot_for >= args.persist_sec:
            subprocess.run(
                ["logger", "-t", "thermal-shutdown",
                 f"Temp {max_c:.1f}C >= {args.max_c:.1f}C for {hot_for}s; powering off"],
                check=False,
            )
            subprocess.run(["systemctl", "poweroff"], check=False)
    else:
        try:
            STATE_FILE.unlink()
        except FileNotFoundError:
            pass


if __name__ == "__main__":
    main()
