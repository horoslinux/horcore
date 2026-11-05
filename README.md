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

The ISO is for installation only. On tty1, root is logged in automatically and the `horos` menu opens.
The system is already running live at that point, so there is no "live" entry. The menu lists:

1. Install to disk, one entry per profile (Server, Workstation)
2. Network settings (`nmtui`, for Wi-Fi)
3. Reboot
4. Power off

- For a recovery shell, type `shell` at the menu prompt (it is not shown), or log in with `HOROS_NO_MENU=1`.
- The Live ISO is not persistent storage; changes are lost after reboot.

## Installation to Disk

Choosing a profile in the menu starts `archinstall` with HorOS presets. You choose the disk, users and network
interactively inside `archinstall`. Select the target disk carefully; the wrong disk can cause data loss.
`archinstall` is the upstream tool, so its screens are not written by HorOS and the installed system's `os-release` currently appears as Arch.

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

The answers are written to a partial `archinstall` JSON config (`hostname`, `packages`, `custom_commands`, `timezone`, `locale_config`) passed with `--config`.

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
