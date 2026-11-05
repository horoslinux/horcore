#!/usr/bin/env bash
# shellcheck disable=SC2034
iso_name="horos"
iso_label="HOROS_$(date +%Y%m)"
iso_publisher="HorOS Linux"
iso_application="HorOS Linux Live/Install"
iso_version="$(date +%Y.%m.%d)"
install_dir="horos"
buildmodes=('iso')
bootmodes=('bios.syslinux' 'uefi.systemd-boot')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
bootstrap_tarball_compression=(zstd -c -T0 --long -19)
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/etc/sudoers.d"]="0:0:750"
  ["/etc/sudoers.d/10-wheel"]="0:0:440"
  ["/root"]="0:0:750"
  ["/usr/local/bin/horos"]="0:0:755"
  ["/usr/local/bin/horos-installer"]="0:0:755"
)
