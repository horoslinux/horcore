# HorOS: kurulum arayüzü tty1'de systemd tarafından başlatılır (getty@tty1 drop-in'i);
# bu dosya yalnızca diğer girişlerde (tty2, SSH) kabuğa devam eder.
[[ -f ~/.bashrc ]] && . ~/.bashrc
