zman() { PAGER="less -g -I -s '+/^       "$1"'" man zshall; }

# aliases common to all shells
alias src="omz reload"
alias q=exit
alias pv=printenv
alias open=open_command
alias clr=clear
unalias unexport
nobrew () {
  eval "$(unexport $(brew --prefix)/bin)"
}
k9() {
  # Usage: k9 22234 1213 or k9 chrome
  if echo $@ | rg -q "[\d\s\t]+"; then
    process_ids=("${(@f)}$@")
    kill -9 ${process_ids[@]} || "no process found by searching $@"
  else
    pkill -9 -f $@
  fi
}
sk9() {
  # Usage: k9 22234 1213 or k9 chrome
  if echo $@ | rg -q "[\d\s\t]+"; then
    process_ids=("${(@f)}$@")
    sudo kill -9 ${process_ids[@]} || "no process found by searching $@"
  else
    sudo pkill -9 -f $@
  fi
}
alias ka=killall

alias te="trash-empty -f 15"

unalias cp 2>/dev/null || true
_is_callable ds && alias du=ds
alias dud="du -d 1"

_is_callable exa && alias ls="exa --color=auto --group-directories-first"
alias ll="ls -lgh"
alias la='ls -laFh'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'
alias ~='cd $HOME'
alias /='cd /'

alias ln="${aliases[ln]:-ln} -v" # verbose ln
alias mkdir='mkdir -p'
unalias fd 2>/dev/null || true

alias gurl='curl --compressed'
alias wget='wget -c' # Resume dl if possible
alias cssh='$EDITOR $HOME/.ssh/config'

alias ag="ag -p $XDG_CONFIG_HOME/ag/agignore"
function prg() {ps aux | rg -i $@}
function grep_search() { echo $2 | grep -qiP $1; }
function rg_search() { echo $2 | rg -qS $1; }
function vread() {
  (
    $@ > /tmp/dummy_vread_file
    nvim +Man! /tmp/dummy_vread_file
    rm -f /tmp/dummy_vread_file
  )
}

# For example, to list all directories that contain a certain file: find . -name .gitattributes | map dirname
alias xmap="xargs -n1"

# Convenience
alias mk=make
if _is_callable bat; then
  alias bat="bat --theme OneHalfLight"
  alias cat=bat
fi
_is_callable neofetch && alias nf="neofetch"
_is_callable cmatrix && alias cm="cmatrix -C red"

take() { mkdir "$1" && cd "$1"; }
hex() { echo -n $@ | xxd -psdu; }

function format-all-dos2unix() {
  if [[ -z $1 ]]; then
    echo "Missing file extension as first argument, e.g. java..."
  fi
  for filename in ./**/*.$1; do
    dos2unix $filename
  done
}

function format-all-shfmt() {
  fd -x shfmt -w -ci -i 2 -ln bash {} \; --regex '_init' .
  fd -x shfmt -w -ci -i 2 -ln bash {} \; -e zsh -e sh .
}

unalias duf 2>/dev/null || true

alias get_window_class="xprop | grep WM_CLASS"

alias nr="nix repl '<nixpkgs>'" # input `pkgs.vscode`
