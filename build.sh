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

# Marka varlıkları (kurulan sisteme de kopyalanır).
BRAND_ICON="$ROOT/airootfs/usr/share/horos/branding/horos-icon.png"
BRAND_LOGO="$ROOT/airootfs/usr/share/horos/branding/logo.png"
WALLPAPER_DIR="$ROOT/airootfs/usr/share/backgrounds/horos"
PLYMOUTH_THEME_DIR="$ROOT/airootfs/usr/share/plymouth/themes/horos"
if [[ ! -f "$BRAND_ICON" ]]; then
  echo "HATA: Marka dosyası eksik: $BRAND_ICON" >&2
  echo "      Dosyayı airootfs/usr/share/horos/branding/ altına koy." >&2
  exit 1
fi
if [[ ! -f "$BRAND_LOGO" ]]; then
  echo "HATA: Transparan logo eksik: $BRAND_LOGO" >&2
  exit 1
fi
if [[ ! -f "$PLYMOUTH_THEME_DIR/horos.plymouth" ]]; then
  echo "HATA: Plymouth teması eksik: $PLYMOUTH_THEME_DIR/horos.plymouth" >&2
  exit 1
fi
shopt -s nullglob
wallpapers=("$WALLPAPER_DIR"/horos-wallpaper-*.jpg)
if (( ${#wallpapers[@]} != 20 )); then
  echo "HATA: 20 duvar kağıdı bekleniyor, ${#wallpapers[@]} bulundu: $WALLPAPER_DIR" >&2
  exit 1
fi
frames=("$PLYMOUTH_THEME_DIR"/animation-*.png)
if (( ${#frames[@]} != 36 )); then
  echo "HATA: 36 Plymouth spinner karesi bekleniyor, ${#frames[@]} bulundu: $PLYMOUTH_THEME_DIR" >&2
  exit 1
fi

# Plymouth watermark'ı her build'de transparan logodan yenile.
cp -f "$BRAND_LOGO" "$PLYMOUTH_THEME_DIR/watermark.png"

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
iso="$(find "${isos[@]}" -printf '%T@ %p\n' | sort -rn | head -n1 | cut -d' ' -f2-)"

echo
echo "Tamamlandı: $iso"
