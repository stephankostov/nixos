#!/usr/bin/env bash
set -euo pipefail
cf="${1:?missing connection file}"

find_root() {
  local d="$PWD"
  while [[ "$d" != "/" ]]; do
    [[ -f "$d/flake.nix" || -f "$d/shell.nix" ]] && { echo "$d"; return 0; }
    d="$(dirname "$d")"
  done
  return 1
}

root="$(find_root)" || { echo "No nix project root found from $PWD" >&2; exit 2; }
cd "$root"
exec nix develop --command python -m ipykernel_launcher -f "$cf"