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

- On tty1, root is automatically logged in (no username/password prompt), and the `horos` menu opens.
- To exit the menu, select `Live terminal`; when you exit the shell, the menu opens again.
- To skip the menu, log in with `HOROS_NO_MENU=1`.
- The `horos-user` command creates a normal user in the live session.
- The Live ISO is not persistent storage; changes are lost after reboot.
- The `Live ISO` is not persistent storage; changes are lost on restart.

## Installation to Disk

Selecting `Install HorOS to disk` from the menu launches the `archinstall` tool.
`archinstall` guides you through disk partitioning and installation interactively.
During installation, select the target disk carefully. Choosing the wrong disk can cause data loss.

Because the installed system's `os-release` file comes from `archinstall`, it currently appears as Arch.
This first release is a HorOS-branded Archiso and a terminal-based installation experience. `archinstall` is the upstream tool; not all installation screens are written by HorOS.

## Customization

- Packages: `packages.x86_64`
- ISO identity: `profiledef.sh`
- Live services and commands: `airootfs/usr/local/bin/`
- Shell greeting: `airootfs/etc/motd`, `airootfs/etc/issue`, `airootfs/etc/os-release`
- Automatic login: `airootfs/etc/systemd/system/getty@tty1.service.d/autologin.conf`
- Boot menu: `syslinux/` (BIOS), `efiboot/` (UEFI)
