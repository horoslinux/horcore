# HorOS Plymouth teması

`two-step` modülünü kullanan açılış ekranı. Spinner, HorOS marka rengiyle
(`#FDC41D`) üretilmiş özgün 36 karelik bir animasyondur; upstream spinner
varlıkları kullanılmaz.

## Görsel tasarım

- Arka plan: saf siyah (`0x000000`).
- Logo: `branding/logo.png` dosyasının şeffaf alanları kırpılıp 384 px genişliğe
  ölçeklenmiş hâli (`watermark.png`), ekranın ~%28’inde yatayda ortada.
- Spinner: 72×72 px, 36 kare (`throbber-0001.png` … `throbber-0036.png`),
  ekranın ~%62’sinde logonun altında.
- Firmware (ACPI BGRT) logosu çizilmez: tüm modlarda `UseFirmwareBackground=false`.

## Dosyalar

```text
horos.plymouth           tema tanımı
watermark.png            transparan HorOS logosu
throbber-0001.png …      açılış spinner kareleri (36 adet)
lock.png                 two-step için zorunlu şifre simgesi (şeffaf)
box.png                  two-step için opsiyonel giriş kutusu (şeffaf)
```

`lock.png` olmadan `two-step` eklentisi temayı yükleyemez ve Plymouth text
fallback’e (`...`) düşer; dosya bu yüzden şeffaf da olsa mutlaka bulunmalıdır.
`animation-*.png` adları kapanış animasyonu içindir; açılış spinner’ı
`throbber-*.png` dosyalarından okunur.

## Etkinleştirme

Tema şu ayarlarla etkindir:

- `packages.x86_64`: `plymouth`
- `airootfs/etc/plymouth/plymouthd.conf`: `[Daemon] Theme=horos`
- `airootfs/etc/mkinitcpio.conf.d/archiso.conf`: `plymouth` hook’u `udev`’den
  sonra, `kms`’ten önce; `MODULES=(bochs vmwgfx vboxvideo)` QEMU, VMware ve
  VirtualBox sanal grafik kartları için.
- BIOS/UEFI/PXE komut satırları: `quiet splash vt.global_cursor_default=0`.
  `splash` temayı açar, `quiet` systemd durum yazılarını gizler. Ayrıntılar için
  açılış sırasında `Esc` tuşuna basılabilir.

`base plymouth udev` sırası yanlıştır: Plymouth, udev’in DRM/fb düğümlerini
işaretlemesinden sonra gelmelidir.

## Doğrulama

Temiz derlemeden sonra initramfs içeriği kontrol edilebilir:

```bash
lsinitcpio work/x86_64/boot/initramfs-linux.img \
  | grep -E 'plymouthd\.conf|two-step\.so|themes/horos/(horos\.plymouth|watermark\.png|lock\.png|throbber-0001\.png)'
```

Tema görünmüyorsa `plymouth.debug` parametresi ve
`/var/log/plymouth-debug.log` kullanılabilir.
