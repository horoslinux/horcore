# HorOS: tty1'de otomatik girişte kurulumu doğrudan başlat
# (HOROS_NO_MENU=1 ile atlanır; SSH/diğer tty'lerde çalışmaz)
if [[ -z "${HOROS_NO_MENU:-}" && "$(tty)" == /dev/tty1 && -x /usr/local/bin/horos ]]; then
  exec /usr/local/bin/horos
fi
[[ -f ~/.bashrc ]] && . ~/.bashrc
