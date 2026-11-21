# HorOS Linux

An AI-native, terminal-focused Live ISO and terminal installation wizard based on Arch Linux. The [limon](https://github.com/horoslinux/limon) AI assistant is installed with every system; you pick the provider during setup.

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
| 5 | AI assistant (limon) | installed for root **and** the created user; provider chosen during setup |
| 6 | Installation destination | **required**; the whole disk is erased, the live medium is hidden |
| 7 | Network and host name | `horos` |
| 8 | Root account | locked (or set a password) |
| 9 | Create user | **required** unless root has a password; admin (sudo) by default |
| 10 | Swap | **enabled**; swapfile sized from RAM (2× up to 2 GiB, =RAM up to 8 GiB, 8 GiB above) |

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

- **Disk layout:** whole disk, no encryption. UEFI (GPT): 512 MiB ESP at `/boot` + ext4 `/`. BIOS (MBR, which `archinstall` selects automatically): 1 GiB FAT32 `/boot` with the `boot` flag + ext4 `/`; GRUB uses the `i386-pc` target, so no `bios_grub` partition is needed.
- **Swap:** on by default. A `/swapfile` is created on the ext4 root and added to `/etc/fstab` (no extra partition, so the layout stays the same). It is deliberately *not* `swapon`-ed inside the install chroot: an active swapfile keeps the root partition busy and causes a misleading “kök bölüm bağlanamadı” warning after installation. Swap activates from `/etc/fstab` on first boot. Item 10 in the summary turns it off or sets a custom size (256–65536 MiB).
- **Bootloader:** always GRUB, set explicitly in the config (`bootloader` and `bootloader_config`, so old and new `archinstall` schemas both see it; `removable: true`).
  A fallback step in `custom_commands` runs `grub-install` if `archinstall` did not (UEFI: `--removable`, so the disk boots even when the VM does not keep NVRAM entries).
- **Verification:** after `archinstall` finishes, the installer disables any live swap, waits for udev, then mounts the root and `/boot` partitions read-only (with a short retry) and checks for the kernel, initramfs, `grub.cfg` and the EFI/BIOS boot files, and reports what is missing (log: `/var/log/archinstall/install.log`).
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

### Hardware drivers

The live medium probes the hardware before the installer opens (`lspci`/`lsusb` plus the DMI product name) and shows the result on the summary screen. Only packages from the official repositories are added, so the install does not depend on the AUR:

| Detected hardware | Packages added |
| --- | --- |
| NVIDIA GPU (`10de:`) | `nvidia`, `nvidia-utils`, `nvidia-settings`, `linux-headers` |
| AMD / Intel GPU | `mesa` |
| Broadcom Wi-Fi (`14e4:`) | `broadcom-wl` |
| Intel audio | `sof-firmware` |
| VirtualBox / VMware / QEMU guest | `virtualbox-guest-utils` / `open-vm-tools` / `qemu-guest-agent` + `spice-vdagent` |
| Bluetooth | `bluez`, `bluez-utils` |

`linux-firmware` is always installed. `pciutils` and `usbutils` ship in the ISO so detection works; if no extra driver is needed, nothing is added. Detection is a best-effort convenience — the normal Arch package set covers most hardware through `mesa` and the in-kernel drivers.

### Branding assets

- HorOS app icon: `airootfs/usr/share/horos/branding/horos-icon.png`. It is installed as `/usr/share/pixmaps/horos.png`, `/usr/share/icons/hicolor/512x512/apps/horos.png` and a `horos.desktop` launcher that opens `https://horoslinux.github.io` with `xdg-open`. `xdg-utils` is always installed and desktop profiles also get Firefox, so the shortcut actually works. The launcher is grouped under a Freedesktop menu category named **HorOS project** via `/usr/share/desktop-directories/horos-project.directory` and `/etc/xdg/menus/applications-merged/horos.menu`.
- Wallpapers: curated JPEGs in `airootfs/usr/share/backgrounds/horos/` (`horos-wallpaper-NN.jpg` plus any extra favourites). The old generated `horos-wallpaper.png` was removed; the first `horos-wallpaper-NN.jpg` is used as the default. GNOME gets a system-wide `gschema.override`; KDE Plasma users get the same default in `/etc/skel` and the newly created home.
- The icon is a committed PNG asset; wallpapers are curated JPEGs. There is no generator script.

### Other presets

- **Keyboard:** suggested from the public IP country and always confirmed by you; applied to the live console immediately so the password you type matches the installed system.
- **Time zone:** detected from the public IP; UTC if detection fails (a VPN can give a wrong zone; change it in the `archinstall` menu).
- **Language:** the installed system uses `en_US.UTF-8`. The live ISO uses `C.UTF-8` (as the official archiso does), because `en_US.UTF-8` is not generated in the live image and would make every shell print `setlocale` warnings.
- **AI assistant:** [limon](https://github.com/horoslinux/limon) is installed in **every** installation (AI-native default): for `root` and, when one is created in item 9, for that normal user as well. The `limon` command is therefore available in the user's `~/.local/bin` immediately after first login. Before installation begins you choose
  which provider SDK to add — Claude, OpenAI, Gemini, all, or base only (item 5 in the summary can change it; the provider/API key is set with `limon config`).
  For each account the installer clones the source to `<home>/.limon` and runs `install.sh` with an explicit `--extras=` value (empty means base only, since limon's own default is `all`). `HOME` is set to that account's home, so the venv, the `~/.local/bin/limon` shortcut and the PATH line in `~/.bashrc` land in the right place; files written by the chroot are chown'd to the user.
  Additional users can install it with `curl -fsSL https://horoslinux.github.io/limon/install.sh | bash -s -- --extras=` (add `claude`, `openai`, `gemini` or `all` after `--extras=`).
  `limon daemon install` sets up the background agent after first login.
- **Package database:** before `archinstall` starts, the installer waits for the keyring and mirror services, syncs the clock, runs `pacman -Sy`,
  and on failure retries after refreshing the keyring or switching to a fixed mirror. If it still fails it prints the real error instead of starting `archinstall`.

The answers are written to an `archinstall` JSON config (`hostname`, `packages`, `custom_commands`, `timezone`, `locale_config`, `disk_config`) passed with `--config --silent`.

## Boot screen

- The loading screen uses **Arch's default Plymouth theme**. The profile no longer ships `/etc/plymouth/plymouthd.conf`, so Plymouth reads `/usr/share/plymouth/plymouthd.defaults` from the `plymouth` package (`Theme=bgrt` on Arch). No custom spinner or logo is selected at boot.
- `quiet splash` remains on the kernel command line, so Plymouth is actually shown during boot.
- The old custom theme files in `airootfs/usr/share/plymouth/themes/horos/` are kept only as branding sources for the icon generator (`logo.png`); they are not activated.
- `systemd.firstboot=off` is set on the kernel command line, and `locale.conf`, `vconsole.conf` and a UTC `localtime` are shipped, so systemd's "Initial Setup" prompts never appear.

### About "Loading Linux linux" / "Loading initial ramdisk"

Those two lines are printed by **GRUB on the installed system**, not by the live ISO (which uses Syslinux/systemd-boot) and not by the kernel. Arch's `/etc/grub.d/10_linux` generates:

```sh
echo 'Loading Linux linux ...'
linux   /vmlinuz-linux ...
echo 'Loading initial ramdisk ...'
initrd  /initramfs-linux.img
```

The message template is `Loading Linux %s ...`; `%s` is the kernel *name* derived from the filename `vmlinuz-linux` by stripping the `vmlinuz-` prefix. Arch keeps that filename stable across kernel upgrades, so `%s` is always `linux`. In other words, the first "Linux" is part of the message and the second "linux" is the kernel flavour — it is **not** a second kernel being loaded and not an error. The `quiet` kernel parameter does not hide it because the line is a GRUB `echo`, not a kernel log message.

HorOS branding disables it cleanly: the `message=` line in `/etc/grub.d/10_linux` is emptied (so future `grub-mkconfig` runs stay quiet too) and the generated `grub.cfg` echo lines are removed.

## Customization

- Packages: `packages.x86_64`
- ISO identity: `profiledef.sh`
- Profiles (Server, Workstation, ...): `airootfs/usr/share/horos/profiles/`
- Menu and installer commands: `airootfs/usr/local/bin/`
- Shell greeting: `airootfs/etc/motd`, `airootfs/etc/issue`, `airootfs/etc/os-release`
- Installer autostart on tty1: `airootfs/etc/systemd/system/getty@tty1.service.d/10-horos.conf`
- Boot menu: `syslinux/` (BIOS), `efiboot/` (UEFI)
- Default Arch Plymouth boot screen: `plymouth` in `packages.x86_64`, `quiet splash` in `syslinux/archiso_sys-linux.cfg`; custom theme files under `airootfs/usr/share/plymouth/themes/horos/` are unused branding sources
- Icon asset: `airootfs/usr/share/horos/branding/horos-icon.png`. Wallpapers are curated JPEGs in `airootfs/usr/share/backgrounds/horos/`; the generated `horos-wallpaper.png` was removed.
- The installer copies **every image** in `/usr/share/backgrounds/horos/` into the installed system, registers them with GNOME (`/usr/share/gnome-background-properties/horos.xml`) and KDE Plasma (`/usr/share/wallpapers/horos…/` KPackage folders containing symlinks to the canonical files), and uses the first `horos-wallpaper-NN.jpg` as the default. Files are named `horos-wallpaper-NN.jpg`; extra favourites are accepted under any name.
- Hardware driver rules and swapfile: `airootfs/usr/local/bin/horos-installer`
