# The surround module wasn't working if KEYTIMEOUT was <= 10. Specifically,
# (delete|change)-surround immediately abort into insert mode if KEYTIMEOUT <=
# 8. If <= 10, then add-surround does the same. At 11, all these issues vanish.
# Very strange!
export KEYTIMEOUT=15

autoload -U is-at-least

# Copied from https://github.com/jeffreytse/zsh-vi-mode/blob/master/zsh-vi-mode.zsh
# Edit command line in EDITOR
function edit-command-line() {
  # Create a temporary file and save the BUFFER to it
  local tmp_file=$(mktemp ${TMPDIR:-/tmp}/zshXXXXXX)

  # Some users may config the noclobber option to prevent from
  # overwriting existing files with the > operator, we should
  # use >! operator to ignore the noclobber.
  echo "$BUFFER" >! "$tmp_file"

  # Edit the file with the specific editor, in case of
  # the warning about input not from a terminal (e.g.
  # vim), we should tell the editor input is from the
  # terminal and not from standard input.
  "${(@Q)${(z)${EDITOR:-nvim}}}" $tmp_file </dev/tty

  # Reload the content to the BUFFER from the temporary
  # file after editing, and delete the temporary file.
  BUFFER=$(cat $tmp_file)
  rm -f "$tmp_file"
}
# Open current prompt in external editor
zle -N edit-command-line
bindkey '^ ' edit-command-line

bindkey -M viins '^K' kill-line
bindkey -M viins '^U' backward-kill-line
bindkey -M viins '^W' backward-kill-word
bindkey -M viins '^H' backward-delete-char
bindkey -M viins '^?' backward-delete-char # backspace key
bindkey -M viins '^D' delete-char
bindkey -M viins '^B' backward-char
bindkey -M viins '^F' forward-char
bindkey -M viins '^G' push-line-or-edit
bindkey -M viins '^A' beginning-of-line
bindkey -M viins '^E' end-of-line

# Shift + Tab
bindkey -M viins '^[[Z' reverse-menu-complete
