#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
shopt -s nullglob
isos=("$ROOT"/out/*.iso)
if ((${#isos[@]} == 0)); then
  echo "ISO bulunamadı. Önce ./build.sh çalıştır." >&2
  exit 1
fi
exec qemu-system-x86_64 -m 4096 -enable-kvm -cdrom "${isos[0]}" -boot d
