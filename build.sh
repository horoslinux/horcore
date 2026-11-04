#!/usr/bin/env bash
# HorOS Linux — ISO build scripti
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

if [[ $EUID -ne 0 ]]; then
  echo "Build için root yetkisi gerekiyor: sudo $0" >&2
  exit 1
fi

if ! command -v mkarchiso >/dev/null; then
  echo "mkarchiso bulunamadı. Kur: pacman -S archiso" >&2
  exit 1
fi

# Zip/Windows/git bazı sembolik linkleri 0 baytlık dosyaya çevirebilir.
# Servis linklerini her build'de yeniden, doğru şekilde oluştur.
WANTS="$ROOT/airootfs/etc/systemd/system/multi-user.target.wants"
mkdir -p "$WANTS"
link() { rm -f "$WANTS/$1"; ln -s "$2" "$WANTS/$1"; }
link NetworkManager.service /usr/lib/systemd/system/NetworkManager.service
link reflector.service      /usr/lib/systemd/system/reflector.service
link pacman-init.service    /etc/systemd/system/pacman-init.service

# Betikler çalıştırılabilir olsun
chmod +x "$ROOT"/airootfs/usr/local/bin/horos*

# Eski/yarım kalmış build artıkları sorun çıkarırsa: ./build.sh --clean
if [[ "${1:-}" == "--clean" ]]; then
  rm -rf "$ROOT/work"
fi

mkdir -p "$ROOT/out" "$ROOT/work"
mkarchiso -v -w "$ROOT/work" -o "$ROOT/out" "$ROOT"

echo
echo "Tamamlandı: $(ls -1t "$ROOT"/out/*.iso | head -n1)"
