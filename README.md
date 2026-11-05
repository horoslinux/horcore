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

The ISO boots straight into the installer, like Fedora/Ubuntu: on tty1 root is logged in automatically and `horos` starts the install flow with no menu.

1. Network check (opens `nmtui` only if there is no connection)
2. Keyboard layout is confirmed first (a wrong layout would break the password you type)
3. A Fedora-style **Installation Summary** screen shows every setting with its current value; pick a number to change it:

| # | Item | Default |
| --- | --- | --- |
| 1 | Keyboard | suggested from the public IP country |
| 2 | Time zone | detected from the IP, UTC if it fails |
| 3 | Installation profile | Server / Workstation |
| 4 | Desktop environment (Workstation only) | not installed; asks KDE Plasma or GNOME when Workstation is selected |
| 5 | AI assistant (limon) | not installed |
| 6 | Installation destination | **required**; the whole disk is erased, the live medium is hidden |
| 7 | Network and host name | `horos` |
| 8 | Root account | locked (or set a password) |
| 9 | Create user | **required** unless root has a password; admin (sudo) by default |

4. `b` starts the installation: type `INSTALL` to confirm, then `archinstall --silent` runs
5. When it ends: Enter reboots; `t` retry, `n` network, `k` power off, `s` shell

- For a recovery shell, press `s` at the end prompt, or log in with `HOROS_NO_MENU=1`.
- `HOROS_DRYRUN=1 horos-installer` writes the archinstall config and stops without touching any disk.
- The Live ISO is not persistent storage; changes are lost after reboot.

## Installation to Disk

HorOS has its own front end; `archinstall` is the backend. The installer builds one `archinstall` JSON config
(disk layout, hostname, packages, time zone, locale) and passes it with `--config --silent`.
Users, passwords, the firewall and services are set up through `custom_commands` on the installed system.
`archinstall` is the upstream tool and the installed system's `os-release` currently appears as Arch.

- **Disk layout:** whole disk. UEFI: GPT, 512 MiB ESP at `/boot` + ext4 `/`. BIOS: MBR, 1 GiB FAT32 `/boot` + ext4 `/`. No swap, no encryption.
- **Bootloader:** left to the `archinstall` default (systemd-boot on UEFI, GRUB on BIOS).
- **Network:** NetworkManager is installed and enabled; connections made in the live session (including Wi-Fi) are copied over.
- **Time:** `systemd-timesyncd` is enabled.

### Profiles

Profiles live in `airootfs/usr/share/horos/profiles/`. Every folder except `common` is a profile and appears in the menu automatically.

| Profile | SSH | Inbound traffic |
| --- | --- | --- |
| `server` | `sshd` enabled, port 22 open, `PermitRootLogin no` | everything else closed |
| `workstation` | `sshd` not enabled | everything closed, SSH included |

A profile folder contains:

- `title`: the text shown in the menu
- `packages`: extra packages (one per line)
- `services`: units enabled with `systemctl enable`
- `files/`: copied to the same path on the installed system (`files/etc/foo.conf` becomes `/etc/foo.conf`)

`common/` applies to every profile: packages `nano`, `nftables`, `openssh` and the firewall.
To add a profile, create a new folder with these files; no installer code needs to change.

### Desktop environment

When the **Workstation** profile is selected, the installer asks whether to also install a desktop:

| Choice | Packages | Enabled display manager |
| --- | --- | --- |
| No desktop | terminal only | — |
| KDE Plasma | `plasma-meta`, `plasma-login-manager`, `mesa`, `noto-fonts` | `plasmalogin` |
| GNOME | `gnome`, `gnome-tweaks`, `gdm`, `mesa`, `noto-fonts` | `gdm` |

Both choices also install PipeWire (`pipewire`, `pipewire-pulse`, `wireplumber`) for audio.
The choice can be changed later from item 4 in the summary (it only applies to Workstation; Server ignores it).

### Firewall

All profiles get `nftables` with inbound traffic denied by default (loopback, established connections, ICMP and DHCP replies are allowed).
Profiles open ports by adding a file under `/etc/nftables.d/`, for example `add element inet horos tcp_in { 443 }`, then `systemctl restart nftables`.
No forward chain is defined, so Docker or libvirt manage their own forwarding rules; VM/container networks that need host services may need extra input rules.
During installation the rules are syntax-checked with `nft -c`, and a warning is printed if the check fails.

### Other presets

- **Keyboard:** suggested from the public IP country and always confirmed by you; applied to the live console immediately so the password you type matches the installed system.
- **Time zone:** detected from the public IP; UTC if detection fails (a VPN can give a wrong zone; change it in the `archinstall` menu).
- **Language:** always `en_US.UTF-8`.
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
- Automatic login: `airootfs/etc/systemd/system/getty@tty1.service.d/autologin.conf`
- Boot menu: `syslinux/` (BIOS), `efiboot/` (UEFI)
