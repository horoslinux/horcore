# HorOS: etkileşimli root girişinde menüyü aç (HOROS_NO_MENU=1 ile atlanır)
if [[ -z "${HOROS_NO_MENU:-}" && -t 0 && -t 1 && -x /usr/local/bin/horos ]]; then
  exec /usr/local/bin/horos
fi
[[ -f ~/.bashrc ]] && . ~/.bashrc
