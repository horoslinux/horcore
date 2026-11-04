#!/usr/bin/env bash
iso_name="horos"
iso_label="HOROS_$(date +%Y%m)"
iso_publisher="HorOS Linux"
iso_application="HorOS Linux Live/Install"
iso_version="$(date +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux' 'uefi.systemd-boot')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86')
bootstrap_tarball_compression=(zstd -c -T0 --long -19)
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/root/.automated_script.sh"]="0:0:755"
  ["/usr/local/bin/horos"]="0:0:755"
  ["/usr/local/bin/horos-user"]="0:0:755"
  ["/usr/local/bin/horos-installer"]="0:0:755"
)
