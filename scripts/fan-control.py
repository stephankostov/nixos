#!/usr/bin/env python3
import argparse
import json
import subprocess
import time


def read_max_temp_c(sensors_bin: str) -> float:
    out = subprocess.check_output([sensors_bin, "-j"], text=True)
    data = json.loads(out)

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
    if m is None:
        raise RuntimeError("No *_input temperature fields found in sensors -j output")
    return float(m)


def clamp(x: float, lo: float, hi: float) -> float:
    return lo if x < lo else hi if x > hi else x


def piecewise_linear(temp_c: float, points):
    points = sorted(points, key=lambda p: p[0])
    if temp_c <= points[0][0]:
        return points[0][1]
    if temp_c >= points[-1][0]:
        return points[-1][1]

    for (t0, s0), (t1, s1) in zip(points, points[1:]):
        if t0 <= temp_c <= t1:
            a = (temp_c - t0) / (t1 - t0) if t1 != t0 else 1.0
            return s0 + a * (s1 - s0)

    return points[-1][1]


def set_sync_speed(liquidctl_bin: str, duty: int):
    cmd = [liquidctl_bin]
    cmd += ["set", "sync", "speed", str(int(duty))]
    subprocess.run(cmd, check=True)


def main():
    
    p = argparse.ArgumentParser()
    p.add_argument("--sensors-bin", default="sensors")
    p.add_argument("--liquidctl-bin", default="liquidctl")
    p.add_argument("--interval", type=float, default=30.)

    p.add_argument("--curve", nargs="+", default=["30:30", "50:60", "80:100"],
                   help='Curve points as T:D, e.g. "30:30 50:60 80:100"')
    p.add_argument("--min-duty", type=int, default=20)
    p.add_argument("--max-duty", type=int, default=100)
    p.add_argument("--min-duty-change", type=int, default=2)
    p.add_argument("--min-temp-change", type=float, default=1.0)
    args = p.parse_args()

    points = [ (float(t), float(d)) for t, d in (td.split(":") for td in args.curve) ]

    last_duty = 0
    last_temp = 999.0

    while True:

        temp = read_max_temp_c(args.sensors_bin)
        raw = piecewise_linear(temp, points)
        duty = int(round(clamp(raw, args.min_duty, args.max_duty)))

        update = False
        if abs(temp - last_temp) >= args.min_temp_change:
            if abs(duty - last_duty) >= args.min_duty_change:
                update = True

        if update:
            set_sync_speed(args.liquidctl_bin, duty)
            last_duty = duty
            last_temp = temp
            print(f"Set fan speed to {duty}% for temp {temp:.1f}°C")

        time.sleep(args.interval)


if __name__ == "__main__":
    main()
