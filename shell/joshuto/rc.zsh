function joshuto-cd() {
  joshuto --lastdir /tmp/joshuto-lastdir
  LASTDIR="$(cat /tmp/joshuto-lastdir)"
  [ "$LASTDIR" != "$(pwd)" ] && cd "$LASTDIR"
}

function widget-joshuto-cd() {
  BUFFER="joshuto-cd"
  zle accept-line
}
zle -N widget-joshuto-cd

bindkey '^o' widget-joshuto-cd
