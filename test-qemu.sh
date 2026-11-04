#!/usr/bin/env bash
# HorOS Linux — ISO'yu QEMU'da dene.   BIOS: ./test-qemu.sh   UEFI: UEFI=1 ./test-qemu.sh
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
shopt -s nullglob
isos=("$ROOT"/out/*.iso)
if ((${#isos[@]} == 0)); then
  echo "ISO bulunamadı. Önce sudo ./build.sh çalıştır." >&2
  exit 1
fi
iso="$(ls -1t "${isos[@]}" | head -n1)"

args=(-m 4096 -smp 2 -cdrom "$iso" -boot d -nic user,model=virtio-net-pci)

if [[ -w /dev/kvm ]]; then
  args+=(-enable-kvm -cpu host)
else
  echo "KVM yok, yavaş (TCG) modda çalışılıyor." >&2
fi

if [[ "${UEFI:-0}" == "1" ]]; then
  ovmf=""
  for f in /usr/share/edk2/x64/OVMF_CODE.4m.fd /usr/share/edk2/x64/OVMF_CODE.fd /usr/share/OVMF/OVMF_CODE.fd; do
    [[ -f "$f" ]] && { ovmf="$f"; break; }
  done
  [[ -n "$ovmf" ]] || { echo "OVMF bulunamadı (pacman -S edk2-ovmf)." >&2; exit 1; }
  args+=(-drive "if=pflash,format=raw,readonly=on,file=$ovmf")
fi

exec qemu-system-x86_64 "${args[@]}"
