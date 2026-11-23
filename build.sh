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

# Kurulum arayüzü dosyaları (getty drop-in'i bunları doğrudan çalıştırır).
BIN_DIR="$ROOT/airootfs/usr/local/bin"
for script in horos horos-installer-tui horos-installer-core horos-tui-theme; do
  if [[ ! -f "$BIN_DIR/$script" ]]; then
    echo "HATA: Eksik kurulum betiği: $BIN_DIR/$script" >&2
    exit 1
  fi
done
chmod +x "$BIN_DIR/horos" "$BIN_DIR/horos-installer-tui"

# BIOS menü arka planı (syslinux/archiso_head.cfg).
if [[ ! -f "$ROOT/syslinux/splash.png" ]]; then
  echo "HATA: Eksik BIOS menü arka planı: $ROOT/syslinux/splash.png" >&2
  exit 1
fi

# Marka varlıkları (kurulan sisteme de kopyalanır).
BRAND_ICON="$ROOT/airootfs/usr/share/horos/branding/horos-icon.png"
BRAND_LOGIN_LOGO="$ROOT/airootfs/usr/share/horos/branding/horos-login-logo.png"
WALLPAPER_DIR="$ROOT/airootfs/usr/share/backgrounds/horos"
for brand_file in "$BRAND_ICON" "$BRAND_LOGIN_LOGO"; do
  if [[ ! -f "$brand_file" ]]; then
    echo "HATA: Marka dosyası eksik: $brand_file" >&2
    echo "      Dosyayı airootfs/usr/share/horos/branding/ altına koy." >&2
    exit 1
  fi
done
shopt -s nullglob
wallpapers=("$WALLPAPER_DIR"/horos-wallpaper-*.jpg)
if (( ${#wallpapers[@]} == 0 )); then
  echo "HATA: Duvar kağıdı bulunamadı: $WALLPAPER_DIR" >&2
  exit 1
fi
for wallpaper in "${wallpapers[@]}"; do
  if [[ ! -s "$wallpaper" ]]; then
    echo "HATA: Boş duvar kağıdı: $wallpaper" >&2
    exit 1
  fi
done

# Açılış teması (plymouth hook'u initramfs'e kopyalar).
PLYMOUTH_CONF="$ROOT/airootfs/etc/plymouth/plymouthd.conf"
PLYMOUTH_THEME="$ROOT/airootfs/usr/share/plymouth/themes/horos"
# two-step eklentisi lock.png olmadan temayı yükleyemez ve text fallback'e
# ("...") düşer. box.png opsiyoneldir ama şifre girişi için tema ile gelir.
if [[ ! -f "$PLYMOUTH_CONF" || ! -f "$PLYMOUTH_THEME/horos.plymouth" \
   || ! -f "$PLYMOUTH_THEME/watermark.png" || ! -f "$PLYMOUTH_THEME/lock.png" \
   || ! -f "$PLYMOUTH_THEME/box.png" ]]; then
  echo "HATA: Plymouth yapılandırması veya tema dosyaları eksik." >&2
  exit 1
fi
throbbers=("$PLYMOUTH_THEME"/throbber-*.png)
if (( ${#throbbers[@]} != 36 )); then
  echo "HATA: 36 spinner karesi bekleniyor, ${#throbbers[@]} bulundu: $PLYMOUTH_THEME" >&2
  exit 1
fi
# Splash, TUI çizilene kadar açık kalır; bu override'lar olmadan Plymouth
# getty ile yarışır ve spinner ile kurulum ekranı arasında siyah boşluk oluşur.
for plymouth_dropin in \
  "$ROOT/airootfs/etc/systemd/system/plymouth-quit.service.d/10-horos.conf" \
  "$ROOT/airootfs/etc/systemd/system/plymouth-quit-wait.service.d/10-horos.conf"; do
  if [[ ! -f "$plymouth_dropin" ]]; then
    echo "HATA: Eksik Plymouth geçiş birimi: $plymouth_dropin" >&2
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
iso="$(find "${isos[@]}" -printf '%T@ %p\n' | sort -rn | head -n1 | cut -d' ' -f2-)"

# Tema dosyaları initramfs'e girmezse canlı ISO text fallback'e düşer.
initramfs="$(find "$ROOT/work" -name initramfs-linux.img -print -quit 2>/dev/null || true)"
if [[ -n "$initramfs" ]] && command -v lsinitcpio >/dev/null; then
  initramfs_files="$(lsinitcpio "$initramfs")"
  for required in \
    'etc/plymouth/plymouthd.conf' \
    'usr/lib/plymouth/two-step.so' \
    'usr/share/plymouth/themes/horos/horos.plymouth' \
    'usr/share/plymouth/themes/horos/watermark.png' \
    'usr/share/plymouth/themes/horos/lock.png' \
    'usr/share/plymouth/themes/horos/throbber-0001.png' \
    'usr/share/plymouth/themes/horos/throbber-0036.png'; do
    if ! grep -qF "$required" <<<"$initramfs_files"; then
      echo "HATA: Plymouth dosyası initramfs'te yok: $required" >&2
      exit 1
    fi
  done
fi

echo
echo "Tamamlandı: $iso"
