#!/usr/bin/env bash
# HorOS Linux — ISO build scripti
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

clean=1
for arg in "$@"; do
  case "$arg" in
    --clean) clean=1 ;;
    --keep)  clean=0 ;;
    -h|--help)
      echo "Kullanım: sudo ./build.sh [--keep|--clean]"
      echo "  --clean  work/ dizinini sil (varsayılan)"
      echo "  --keep   work/ dizinini koru (hızlı yeniden derleme)"
      exit 0
      ;;
    *)
      echo "Bilinmeyen seçenek: $arg" >&2
      exit 1
      ;;
  esac
done

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

# Plymouth teması initramfs'e gireceği için kaynakta eksiksiz olmalı.
THEME_DIR="$ROOT/airootfs/usr/share/plymouth/themes/horos"
for f in horos.plymouth horos.script logo.png seg.png track.png; do
  if [[ ! -f "$THEME_DIR/$f" ]]; then
    echo "HATA: Plymouth teması eksik: $THEME_DIR/$f" >&2
    exit 1
  fi
done

# mkarchiso work/ içindeki adımları önbelleğe alır ve profil değişikliklerini
# sessizce atlayabilir. Varsayılan olarak temiz başla; --keep ile koru.
if (( clean )); then
  echo "Eski build artıkları siliniyor: $ROOT/work"
  rm -rf "$ROOT/work"
else
  echo "work/ korunuyor (--keep); profil değişiklikleri atlanabilir."
fi

mkdir -p "$ROOT/out" "$ROOT/work"
mkarchiso -v -w "$ROOT/work" -o "$ROOT/out" "$ROOT"

shopt -s nullglob
isos=("$ROOT"/out/*.iso)
if (( ${#isos[@]} == 0 )); then
  echo "HATA: out/ içinde ISO bulunamadı." >&2
  exit 1
fi
iso="$(ls -1t "${isos[@]}" | sed -n '1p')"

# Markalamanın gerçekten ISO'ya girdiğini doğrula: tema initramfs içinde olmalı.
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
bsdtar -tf "$iso" > "$tmp/iso.list"
initramfs_rel="$(grep -m1 -E '/boot/[^/]+/initramfs-linux\.img$' "$tmp/iso.list" || true)"
if [[ -z "$initramfs_rel" ]]; then
  echo "HATA: ISO içinde initramfs-linux.img bulunamadı." >&2
  exit 1
fi
bsdtar -xf "$iso" -C "$tmp" "$initramfs_rel"
lsinitcpio "$tmp/$initramfs_rel" > "$tmp/initramfs.list"
if ! grep -q 'usr/share/plymouth/themes/horos/horos.plymouth' "$tmp/initramfs.list"; then
  echo "HATA: HorOS Plymouth teması initramfs içinde yok." >&2
  echo "      initramfs: $initramfs_rel" >&2
  echo "      Temanın /usr/share/plymouth/themes/horos altında olduğundan emin ol." >&2
  exit 1
fi
echo "Plymouth teması initramfs içinde doğrulandı."

echo
echo "Tamamlandı: $iso"
