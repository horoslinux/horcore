# Start HorOS menu on interactive root login
if [[ -t 0 && -t 1 ]]; then
  exec /usr/local/bin/horos
fi
