function ya() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXX")"
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

function widget-yazi-cd() {
  BUFFER="ya"
  zle accept-line
}
zle -N widget-yazi-cd

bindkey '^o' widget-yazi-cd
