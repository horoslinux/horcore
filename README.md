# HorOS Linux

An AI-native, terminal-focused Live ISO and terminal installation wizard based on Arch Linux. The [limon](https://github.com/horoslinux/limon) AI assistant is installed with every system; you pick the provider during setup.

## Minimum system requirements

HorOS is 64-bit only (no 32-bit/x86 support).

| | Minimum | Recommended |
| --- | --- | --- |
| CPU | x86_64 with SSE2, 1 GHz | 2 cores, 2 GHz or faster |
| RAM (live installer) | 1 GB (Server), 2 GB (KDE/GNOME) | 4 GB |
| RAM (installed system) | 2 GB (Server), 4 GB (desktop) | 8 GB |
| Disk | 8 GB (tüm profiller) | 40 GB SSD |
| USB medium | 4 GB | 8 GB |
| Network | Internet connection **required** during installation | Wired connection |
| Firmware | BIOS (legacy/MBR) or 64-bit UEFI | UEFI |

Notes:

- The installer downloads every package, so there is no offline installation; without a working connection it stops and asks you to configure the network.
- tty1 opens the `whiptail` TUI wizard (Arch package: `libnewt`; network → IP-based locale → profile/desktop → accounts → disk → swap → final warning). The old numbered CLI menu and its script are removed; `horos-installer-core` is a backend library used only by the TUI.
- TUI colors come from `horos-tui-theme` (amber HorOS palette). Use `HOROS_THEME=classic` for whiptail defaults or `HOROS_NEWT_COLORS='...'` for a custom newt palette.
- Installed systems use `ufw` instead of nftables: incoming denied, outgoing allowed; the server profile opens SSH (22/tcp). Manage it with `sudo ufw status` and `sudo ufw allow <port>/tcp`.
- Wallpaper assets are only copied for desktop profiles; the server profile skips them.
- Installed systems keep the HorOS Plymouth theme (`quiet splash`, amber spinner) and the GDM login logo/background; the Arch default `bgrt` splash and logo are not left behind.
- The full-disk mode erases the selected disk; choose the partition-preserving mode at the installation destination step to install into free space. The live medium is hidden from the disk list. Back up your data first.
- The live ISO runs from RAM (archiso), so a desktop installation with only 2 GB is slow; 4 GB is safer for KDE Plasma or GNOME.
- An installed desktop feels comfortable with 4 GB or more, especially with a browser open. UEFI firmware must be 64-bit (32-bit UEFI is not supported).

## Build requirements

- Build on x86_64 Arch Linux
- `archiso`, `git`, `base-devel`
- `qemu-desktop` to test the ISO

```bash
sudo pacman -Syu
sudo pacman -S archiso git base-devel qemu-desktop
```

## Create ISO

```bash
cd horcore
sudo ./build.sh        # clean build (default)
sudo ./build.sh --keep # reuse work/ for a quick rebuild
```

The ISO is written to the `out/` directory. The build workspace is in `work/`.
Builds start clean by default because `mkarchiso` caches steps in `work/` and can silently skip profile changes.
Boot uses the bundled HorOS Plymouth theme with `quiet splash`; systemd status messages are hidden (`Esc` shows details). The initial ramdisk includes `bochs`, `vmwgfx` and `vboxvideo` so the theme renders under QEMU, VMware and VirtualBox; the build verifies the theme assets inside `initramfs-linux.img`.

## Test

```bash
./test-qemu.sh            # BIOS
UEFI=1 ./test-qemu.sh     # UEFI (requires edk2-ovmf)
```
