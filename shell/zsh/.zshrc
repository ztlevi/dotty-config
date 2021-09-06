_load shell/zsh/zinit-init-hook.zsh

_load shell/zsh/config.zsh
_load shell/zsh/utils.zsh
_load shell/zsh/completion.zsh
_load shell/zsh/keybinds.zsh
_load shell/zsh/proxy.zsh

_load_all rc.zsh
[[ -f ${ZDOTDIR}/extra.zshrc ]] && _load ${ZDOTDIR}/extra.zshrc

_load shell/zsh/zinit-post-hook.zsh
