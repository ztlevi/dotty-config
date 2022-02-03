zinit pack"bgn-binary+keys" for fzf

# replace zsh completion with fzf
zinit ice wait lucid atload"zicompinit; zicdreplay" blockf
zinit light Aloxaf/fzf-tab
zstyle ':fzf-tab:*' default-color $'\033[39m'      # change default color from white to default foreground color
zstyle ':fzf-tab:*' fzf-flags '--color=hl:4,hl+:4' # see `man fzf` `--color`
zstyle ':fzf-tab:*' switch-group ',' '.'           # switch group using `,` and `.`

bindkey '^[x' fzf-history-widget
bindkey '^[p' fzf-file-widget
bindkey '^r' fzf-history-widget

for file in ${0:A:h}/addons/*.zsh; do
  source ${file}
done
