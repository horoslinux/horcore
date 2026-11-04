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
cd HorOS-Linux
./build.sh
```

ISO `out/` klasörüne yazılır. Build çalışma alanı `work/` klasöründedir.

## Test

```bash
./test-qemu.sh
```

## Live ISO

- Root otomatik girişli Live ortamdır.
- İlk açılışta `horos` komutunu çalıştırarak terminal menüsünü aç.
- `horos-user` komutu Live oturumunda normal kullanıcı oluşturur.
- Live ISO kalıcı depolama değildir; yeniden başlatınca değişiklikler kaybolur.

## Diske kurulum

Menüden `Install HorOS` seçeneği, `archinstall` aracını başlatır.
`archinstall` disk bölümleme ve kurulum adımlarını etkileşimli olarak yürütür.
Kurulum sırasında hedef diski dikkatle seç. Yanlış disk seçimi veri kaybına neden olabilir.

Bu ilk sürüm, HorOS markalı bir Archiso ve terminal kurulum girişidir. `archinstall`
upstream aracıdır; kurulum ekranlarının tümü HorOS tarafından yazılmış değildir.

## Özelleştirme

- Paketler: `packages.x86_64`
- ISO kimliği: `profiledef.sh`
- Live servisleri ve komutları: `airootfs/usr/local/bin/`
- Shell karşılama: `airootfs/etc/motd`
