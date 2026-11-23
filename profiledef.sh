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
airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '3' '-b' '1M')
bootstrap_tarball_compression=(zstd -c -T0 --long -19)
file_permissions=(
  # Not: airootfs/etc/shadow yok (live'ta getty doğrudan installer'ı açıyor).
  # Root şifresi/girisi istenirse airootfs/etc/shadow ekleyip bu izni geri getir.
  ["/etc/sudoers.d"]="0:0:750"
  ["/etc/sudoers.d/10-wheel"]="0:0:440"
  ["/root"]="0:0:750"
  ["/usr/local/bin/horos"]="0:0:755"
  ["/usr/local/bin/horos-installer-core"]="0:0:644"
  ["/usr/local/bin/horos-installer-tui"]="0:0:755"
  ["/usr/local/bin/horos-tui-theme"]="0:0:644"
)
