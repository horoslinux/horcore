# HorOS Linux

Arch Linux tabanlı, terminal odaklı Live ISO ve terminal kurulum sihirbazı.

## Gereksinimler

- x86_64 Arch Linux üzerinde build
- `archiso`, `git`, `base-devel`
- ISO test etmek için `qemu-desktop`

```bash
sudo pacman -Syu
sudo pacman -S archiso git base-devel qemu-desktop
```

## ISO oluşturma

```bash
cd horcore
sudo ./build.sh        # takılırsa: sudo ./build.sh --clean
```

ISO `out/` klasörüne yazılır. Build çalışma alanı `work/` klasöründedir.

## Test

```bash
./test-qemu.sh            # BIOS
UEFI=1 ./test-qemu.sh     # UEFI (edk2-ovmf gerekir)
```

## Live ISO

- tty1'de root otomatik giriş yapılır (kullanıcı adı/parola sorulmaz) ve `horos` menüsü açılır.
- Menüden çıkmak için `Live terminal` seç; shell'den çıkınca menü tekrar açılır.
- Menüyü atlamak için: `HOROS_NO_MENU=1` ile giriş yap.
- `horos-user` komutu Live oturumunda normal kullanıcı oluşturur.
- Live ISO kalıcı depolama değildir; yeniden başlatınca değişiklikler kaybolur.

## Diske kurulum

Menüden `HorOS'u diske kur` seçeneği, `archinstall` aracını başlatır.
`archinstall` disk bölümleme ve kurulum adımlarını etkileşimli olarak yürütür.
Kurulum sırasında hedef diski dikkatle seç. Yanlış disk seçimi veri kaybına neden olabilir.

Kurulu sistemin `os-release` dosyası archinstall'dan geldiği için şimdilik Arch olarak görünür.
Bu ilk sürüm, HorOS markalı bir Archiso ve terminal kurulum girişidir. `archinstall`
upstream aracıdır; kurulum ekranlarının tümü HorOS tarafından yazılmış değildir.

## Özelleştirme

- Paketler: `packages.x86_64`
- ISO kimliği: `profiledef.sh`
- Live servisleri ve komutları: `airootfs/usr/local/bin/`
- Shell karşılama: `airootfs/etc/motd`, `airootfs/etc/issue`, `airootfs/etc/os-release`
- Otomatik giriş: `airootfs/etc/systemd/system/getty@tty1.service.d/autologin.conf`
- Boot menüsü: `syslinux/` (BIOS), `efiboot/` (UEFI)
