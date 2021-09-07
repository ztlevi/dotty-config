#!/usr/bin/env zsh
mkdir -p ${XDG_CONFIG_HOME}/fcitx

# 1. System input method
mklink $DOTTY_CONFIG_HOME/misc/chinese/config/fcitx/config ${XDG_CONFIG_HOME}/fcitx/config
mklink $DOTTY_CONFIG_HOME/misc/chinese/config/fcitx/rime/* ${XDG_CONFIG_HOME}/fcitx/rime/
[[ -d ${DOTTY_ASSETS_HOME}/rime-dictionaries ]] && mklink ${DOTTY_ASSETS_HOME}/rime-dictionaries/*.dict.yaml ${XDG_CONFIG_HOME}/fcitx/rime/
mklink pam_environment ${HOME}/.pam_environment

case $(_os) in
  macos)
    mklink ~/.config/fcitx/rime ~/Library/Rime
    ;;
esac

# 2. Emacs input method

# Don't use ${XDG_CONFIG_HOME}/fcitx/rime as your emacs fcitx config dir. It will cause conflict.
mklink $DOTTY_CONFIG_HOME/misc/chinese/config/fcitx/rime/* $XDG_CONFIG_HOME/fcitx/emacs-rime/
[[ -d ${DOTTY_ASSETS_HOME}/rime-dictionaries ]] && mklink ${DOTTY_ASSETS_HOME}/rime-dictionaries/*.dict.yaml $XDG_CONFIG_HOME/fcitx/emacs-rime/

local link_files=("opencc" "emoji_suggestion.yaml" "zhwiki.dict.yaml")
for file in ${link_files[@]}; do
  mklink ${XDG_CONFIG_HOME}/fcitx/rime/$file $XDG_CONFIG_HOME/fcitx/emacs-rime/
done

# Download zhwiki pinyin dictionary
if [[ ! -f $XDG_CONFIG_HOME/fcitx/rime/zhwiki.dict.yaml ]]; then
  [[ ! -f $WGETRC ]] && touch $WGETRC
  wget --no-check-certificate $(get_github_latest_release_url felixonmars/fcitx5-pinyin-zhwiki "\.dict\.yaml") \
    -O $XDG_CONFIG_HOME/fcitx/rime/zhwiki.dict.yaml
fi
