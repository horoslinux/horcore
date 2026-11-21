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

for tool in mkarchiso bsdtar lsinitcpio; do
  if ! command -v "$tool" >/dev/null; then
    case "$tool" in
      mkarchiso) pkg=archiso ;;
      bsdtar)    pkg=libarchive ;;
      lsinitcpio) pkg=mkinitcpio ;;
    esac
    echo "$tool bulunamadı. Kur: pacman -S $pkg" >&2
    exit 1
  fi
done

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
for f in horos.plymouth horos.script logo.png horos-mark.png seg.png; do
  if [[ ! -f "$THEME_DIR/$f" ]]; then
    echo "HATA: Plymouth teması eksik: $THEME_DIR/$f" >&2
    exit 1
  fi
done

# Marka varlıkları (kurulan sisteme de kopyalanır).
BRAND_ICON="$ROOT/airootfs/usr/share/horos/branding/horos-icon.png"
WALLPAPER="$ROOT/airootfs/usr/share/backgrounds/horos/horos-wallpaper.png"
for f in "$BRAND_ICON" "$WALLPAPER"; do
  if [[ ! -f "$f" ]]; then
    echo "HATA: Marka dosyası eksik: $f" >&2
    echo "      Yeniden üret: python3 tools/generate-branding.py" >&2
    exit 1
  fi
done

# Simgeyi canlı sistemde de görünür yap (hicolor / pixmaps).
ICON_DIR="$ROOT/airootfs/usr/share/icons/hicolor/512x512/apps"
mkdir -p "$ICON_DIR" "$ROOT/airootfs/usr/share/pixmaps"
ln -sfn /usr/share/horos/branding/horos-icon.png "$ICON_DIR/horos.png"
ln -sfn /usr/share/horos/branding/horos-icon.png "$ROOT/airootfs/usr/share/pixmaps/horos.png"

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
