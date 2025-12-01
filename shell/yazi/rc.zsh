function ya() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

function widget-yazi-cd() {
  BUFFER="ya"
  zle accept-line
}
zle -N widget-yazi-cd

bindkey '^o' widget-yazi-cd
