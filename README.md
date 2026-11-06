# HorOS Linux

A terminal-focused Live ISO and terminal installation wizard based on Arch Linux.

## Minimum system requirements

HorOS is 64-bit only (no 32-bit/x86 support).

| | Minimum | Recommended |
| --- | --- | --- |
| CPU | x86_64 with SSE2, 1 GHz | 2 cores, 2 GHz or faster |
| RAM (live installer) | 1 GB (Server), 2 GB (KDE/GNOME) | 4 GB |
| RAM (installed system) | 2 GB (Server), 4 GB (desktop) | 8 GB |
| Disk | 10 GB (Server), 20 GB (Workstation) | 40 GB SSD |
| USB medium | 4 GB | 8 GB |
| Network | Internet connection **required** during installation | Wired connection |
| Firmware | BIOS (legacy/MBR) or 64-bit UEFI | UEFI |

Notes:

- The installer downloads every package, so there is no offline installation; without a working connection it stops and points to item 7 (Network).
- The whole selected disk is erased; the live medium itself is hidden from the disk list. Back up your data first.
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
After the build, the script checks that the HorOS Plymouth theme is inside the initramfs.

## Test

```bash
./test-qemu.sh            # BIOS
UEFI=1 ./test-qemu.sh     # UEFI (requires edk2-ovmf)
```

## Live ISO

The ISO boots straight into the installer, like Fedora/Ubuntu. There is no login and no console text between the Plymouth splash and the installer:
`getty@tty1` is replaced by a systemd drop-in (`getty@tty1.service.d/10-horos.conf`) that runs `horos` directly on tty1, and the kernel command line
has `quiet splash loglevel=3 systemd.show_status=false`. The screen opens at once; network and location are checked in the background and the summary updates when the result arrives.

1. The summary screen opens immediately (no waiting for the network)
2. The keyboard layout is confirmed the first time you type a password (a wrong layout would break it); item 1 changes it any time
3. A Fedora-style **Installation Summary** screen shows every setting with its current value; pick a number to change it:

| # | Item | Default |
| --- | --- | --- |
| 1 | Keyboard | suggested from the public IP country |
| 2 | Time zone | detected from the IP, UTC if it fails |
| 3 | Installation profile | Server / Workstation |
| 4 | Desktop environment | not installed; asks KDE Plasma or GNOME when Workstation is selected (item 3) |
| 5 | AI assistant (limon) | not installed |
| 6 | Installation destination | **required**; the whole disk is erased, the live medium is hidden |
| 7 | Network and host name | `horos` |
| 8 | Root account | locked (or set a password) |
| 9 | Create user | **required** unless root has a password; admin (sudo) by default |

4. `b` starts the installation: type `INSTALL` to confirm, then `archinstall --silent` runs
5. When it ends: Enter reboots; `t` retry, `n` network, `k` power off, `s` shell

- For a recovery shell, press `s` at the end prompt, or switch to tty2 (Ctrl+Alt+F2) and log in.
- `HOROS_DRYRUN=1 horos-installer` writes the archinstall config and stops without touching any disk.
- The Live ISO is not persistent storage; changes are lost after reboot.

## Installation to Disk

HorOS has its own front end; `archinstall` is the backend. The installer builds one `archinstall` JSON config
(disk layout, hostname, packages, time zone, locale) and passes it with `--config --silent`.
Users, passwords, the firewall and services are set up through `custom_commands` on the installed system.
`archinstall` is the upstream tool; the branding step below rewrites the installed `os-release` and boot menu to HorOS.

- **Disk layout:** whole disk, no swap, no encryption. UEFI (GPT): 512 MiB ESP at `/boot` + ext4 `/`. BIOS (MBR, which `archinstall` selects automatically): 1 GiB FAT32 `/boot` with the `boot` flag + ext4 `/`; GRUB uses the `i386-pc` target, so no `bios_grub` partition is needed.
- **Bootloader:** always GRUB, set explicitly in the config (`bootloader` and `bootloader_config`, so old and new `archinstall` schemas both see it; `removable: true`).
  A fallback step in `custom_commands` runs `grub-install` if `archinstall` did not (UEFI: `--removable`, so the disk boots even when the VM does not keep NVRAM entries).
- **Verification:** after `archinstall` finishes, the installer mounts the root and `/boot` partitions read-only and checks for the kernel, initramfs, `grub.cfg` and the EFI/BIOS boot files, and reports what is missing (log: `/var/log/archinstall/install.log`).
- **Network:** NetworkManager is installed and enabled; connections made in the live session (including Wi-Fi) are copied over.
- **Time:** `systemd-timesyncd` is enabled.
- **Branding:** the installed system gets HorOS `/etc/os-release` and `/etc/issue`; the GRUB menu (`GRUB_DISTRIBUTOR="HorOS"`, menu regenerated) and systemd-boot entries say HorOS Linux. If you later run `grub-mkconfig` by hand, GRUB may print `HorOS GNU/Linux`.

### Profiles

Profiles live in `airootfs/usr/share/horos/profiles/`. Every folder except `common` is a profile and appears in the menu automatically.

| Profile | SSH | Inbound traffic |
| --- | --- | --- |
| `server` | `sshd` enabled, port 22 open, `PermitRootLogin no` | everything else closed |
| `workstation` | `sshd` not enabled | everything closed, SSH included |

### Desktop environments

The desktop question is asked only for the **Workstation** profile; the answer is stored on the summary screen as item 4 and can be changed there at any time.

| Choice | Packages | Display manager |
| --- | --- | --- |
| Not installed | — (terminal only) | — |
| KDE Plasma | `plasma-meta`, `plasma-login-manager`, PipeWire, Mesa, Noto fonts | `plasmalogin` |
| GNOME | `gnome`, `gnome-tweaks`, `gdm`, PipeWire, Mesa, Noto fonts | `gdm` |

Selecting a desktop also sets `graphical.target` as the default boot target. The file manager, terminal and browser come from the chosen meta packages.

A profile folder contains:

- `title`: the text shown in the menu
- `packages`: extra packages (one per line)
- `services`: units enabled with `systemctl enable`
- `files/`: copied to the same path on the installed system (`files/etc/foo.conf` becomes `/etc/foo.conf`)

`common/` applies to every profile: packages `nano`, `nftables`, `openssh` and the firewall.
To add a profile, create a new folder with these files; no installer code needs to change.

### Firewall

All profiles get `nftables` with inbound traffic denied by default (loopback, established connections, ICMP and DHCP replies are allowed).
Profiles open ports by adding a file under `/etc/nftables.d/`, for example `add element inet horos tcp_in { 443 }`, then `systemctl restart nftables`.
No forward chain is defined, so Docker or libvirt manage their own forwarding rules; VM/container networks that need host services may need extra input rules.
During installation the rules are syntax-checked with `nft -c`, and a warning is printed if the check fails.

### Other presets

- **Keyboard:** suggested from the public IP country and always confirmed by you; applied to the live console immediately so the password you type matches the installed system.
- **Time zone:** detected from the public IP; UTC if detection fails (a VPN can give a wrong zone; change it in the `archinstall` menu).
- **Language:** the installed system uses `en_US.UTF-8`. The live ISO uses `C.UTF-8` (as the official archiso does), because `en_US.UTF-8` is not generated in the live image and would make every shell print `setlocale` warnings.
- **AI assistant:** optional [limon](https://github.com/horoslinux/limon) with one provider SDK (Claude, OpenAI, Gemini) or all. It is installed for `root`;
  other users can run `curl -fsSL https://horoslinux.github.io/limon/install.sh | bash`. `limon daemon install` sets up the background agent after first login.
- **Package database:** before `archinstall` starts, the installer waits for the keyring and mirror services, syncs the clock, runs `pacman -Sy`,
  and on failure retries after refreshing the keyring or switching to a fixed mirror. If it still fails it prints the real error instead of starting `archinstall`.

The answers are written to an `archinstall` JSON config (`hostname`, `packages`, `custom_commands`, `timezone`, `locale_config`, `disk_config`) passed with `--config --silent`.

## Boot screen

- The loading screen is a Plymouth theme: `airootfs/usr/share/plymouth/themes/horos/` (logo, script, colours). It must live under `/usr/share/plymouth/themes`; Plymouth does not read themes from `/etc`.
- The theme is selected in `airootfs/etc/plymouth/plymouthd.conf`.
- `systemd.firstboot=off` is set on the kernel command line, and `locale.conf`, `vconsole.conf` and a UTC `localtime` are shipped, so systemd's "Initial Setup" prompts never appear.

## Customization

- Packages: `packages.x86_64`
- ISO identity: `profiledef.sh`
- Profiles (Server, Workstation, ...): `airootfs/usr/share/horos/profiles/`
- Menu and installer commands: `airootfs/usr/local/bin/`
- Shell greeting: `airootfs/etc/motd`, `airootfs/etc/issue`, `airootfs/etc/os-release`
- Installer autostart on tty1: `airootfs/etc/systemd/system/getty@tty1.service.d/10-horos.conf`
- Boot menu: `syslinux/` (BIOS), `efiboot/` (UEFI)
