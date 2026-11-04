# HorOS Linux

A terminal-focused Live ISO and terminal installation wizard based on Arch Linux.

## Requirements

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
sudo ./build.sh        # if needed: sudo ./build.sh --clean
```

The ISO is written to the `out/` directory. The build workspace is in `work/`.

## Test

```bash
./test-qemu.sh            # BIOS
UEFI=1 ./test-qemu.sh     # UEFI (requires edk2-ovmf)
```

## Live ISO

The ISO is for installation only. On tty1, root is logged in automatically and the `horos` menu opens:

1. Install HorOS to disk
2. Rescue terminal (set up networking, fix disk problems)
3. Reboot
4. Power off

- Exiting the rescue terminal opens the menu again.
- To skip the menu, log in with `HOROS_NO_MENU=1`.
- The Live ISO is not persistent storage; changes are lost after reboot.

## Installation to Disk

Selecting `Install HorOS to disk` from the menu launches the `archinstall` tool with server-oriented presets.
The system is installed as empty as possible: no desktop, only `nano` as an extra package, hostname `horos`.
You choose the disk, users, network and language interactively inside `archinstall`.
During installation, select the target disk carefully. Choosing the wrong disk can cause data loss.

Before `archinstall` starts, the installer asks for a keyboard layout (see below) and two more questions:

- **SSH:** install and enable `openssh` (default: yes). Password login will be on unless you configure it otherwise; prefer key-based login.
- **AI assistant:** install [limon](https://github.com/aardaakpinar/limon) with one provider SDK (Claude, OpenAI, Gemini) or all (default: no).
  limon is installed for the `root` account. Other users can install it with
  `curl -fsSL https://aardaakpinar.github.io/limon/install.sh | bash`.
  On Linux, `limon daemon install` sets up the background agent that monitors services, logs and disk usage.

The time zone is detected from the machine's public IP (it stays UTC if detection fails or you use a VPN; change it in the `archinstall` menu).
The keyboard layout is suggested from the detected country; the installer asks you to confirm or type another layout and applies it immediately, so passwords are typed with the layout you chose. The system language is preset to `en_US.UTF-8`; change it in the `archinstall` menu if needed.
The answers are written to a partial `archinstall` JSON config (`packages`, `custom_commands`, `hostname`, `timezone`, `locale_config`) that is passed with `--config`.

Because the installed system's `os-release` file comes from `archinstall`, it currently appears as Arch.
`archinstall` is the upstream tool; not all installation screens are written by HorOS.

## Customization

- Packages: `packages.x86_64`
- ISO identity: `profiledef.sh`
- Menu and installer commands: `airootfs/usr/local/bin/`
- Shell greeting: `airootfs/etc/motd`, `airootfs/etc/issue`, `airootfs/etc/os-release`
- Automatic login: `airootfs/etc/systemd/system/getty@tty1.service.d/autologin.conf`
- Boot menu: `syslinux/` (BIOS), `efiboot/` (UEFI)
