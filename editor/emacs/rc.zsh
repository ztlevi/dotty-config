# Doom  (file-error "Creating pipe" "Too many open files")
# Too many open error on MacOS https://discussions.apple.com/thread/251000125
# `ulimit -a` to display all
# Make it execute by default when zsh starts since ulimit will not be persistent after reboot
ulimit -n 32768

if [[ $(_os) == macos ]]; then
  _is_callable /Applications/Emacs.app/Contents/MacOS/emacs &&
    alias emacs=/Applications/Emacs.app/Contents/MacOS/emacs

  e() { # Emacs version of v
    if pgrep Emacs 2>&1 >/dev/null; then
      emacsclient -n $@
    else
      /Applications/Emacs.app/Contents/MacOS/Emacs $@ &
    fi
  }
else
  alias e='emacsclient -n'
fi
# if encounter Permission denied, /dev/pts/3, try kill tmux server and recreate new onw
# https://github.com/spudlyo/clipetty/issues/20
alias et="emacs -nw"
alias ec="emacsclient"
alias e.="emacsclient ."
alias se="sudo -E emacs"
function doom() {
  env doom "$@"
}
alias magit="emacsclient -n -e \(magit-status\)"
alias ke="pkill -SIGUSR2 -i emacs"
alias edebug="emacs --debug-init"
alias etime="emacs --timed-requires --profile"
function ctagsl() {
  # Input: e.g. c,c++,python
  ctags --languages=$@ --kinds-all='*' --fields='*' --extras='*' -R
}

ediff() { e --eval "(ediff-files \"$1\" \"$2\")"; }

function use-doom() {
  if [ -d "$HOME/.emacs.d-doom" ]; then
    mv ~/.emacs.d ~/.emacs.d-spacemacs && mv ~/.emacs.d-doom ~/.emacs.d
  else
    echo "~/.emacs.d-doom does not exist, use doom failed."
  fi
}

function use-spacemacs() {
  if [ -d "$HOME/.emacs.d-spacemacs" ]; then
    mv ~/.emacs.d ~/.emacs.d-doom && mv ~/.emacs.d-spacemacs ~/.emacs.d
  else
    echo "~/.emacs.d-spacemacs does not exist, use spacemacs failed."
  fi
}
