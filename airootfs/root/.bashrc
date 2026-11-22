# HorOS root shell — yalnızca etkileşimli oturumlar.
[[ $- == *i* ]] || return

export EDITOR="${EDITOR:-nano}"
export VISUAL="${VISUAL:-$EDITOR}"

alias ll='ls -lAh'

PS1='\[\e[1;33m\]\u@\h\[\e[0m\]:\w\$ '
