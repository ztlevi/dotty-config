#!/usr/bin/env zsh

# 1. System input method
mkdir -p $XDG_CONFIG_HOME/fcitx/rime

ln -s -f $DOTTY_CONFIG_HOME/misc/chinese/config/fcitx/config $XDG_CONFIG_HOME/fcitx/config
ln -s -f $DOTTY_CONFIG_HOME/misc/chinese/config/fcitx/rime/* $XDG_CONFIG_HOME/fcitx/rime/
ln -s -f $DOTTY_CONFIG_HOME/misc/chinese/config/fcitx/pam_environment ${HOME}/.pam_environment

[[ -d ${DOTTY_ASSETS_HOME}/rime-dictionaries ]] && ln -s -f $DOTTY_ASSETS_HOME/rime-dictionaries/*.dict.yaml $XDG_CONFIG_HOME/fcitx/rime/

case $(_os) in
  macos)
    ln -s -f ~/.config/fcitx/rime ~/Library/Rime
    ;;
esac

# 2. Emacs input method

# Don't use $XDG_CONFIG_HOME/fcitx/rime as your emacs fcitx config dir. It will cause conflict.
mkdir -p $XDG_CONFIG_HOME/fcitx/emacs-rime/
ln -s -f $DOTTY_CONFIG_HOME/misc/chinese/config/fcitx/rime/* $XDG_CONFIG_HOME/fcitx/emacs-rime/
[[ -d $DOTTY_ASSETS_HOME/rime-dictionaries ]] && ln -s -f $DOTTY_ASSETS_HOME/rime-dictionaries/*.dict.yaml $XDG_CONFIG_HOME/fcitx/emacs-rime/

link_files=("opencc" "emoji_suggestion.yaml" "zhwiki.dict.yaml")
for file in ''${link_files[@]}; do
  ln -s -f $XDG_CONFIG_HOME/fcitx/rime/$file $XDG_CONFIG_HOME/fcitx/emacs-rime/
done

# Download zhwiki pinyin dictionary
if [[ ! -f $XDG_CONFIG_HOME/fcitx/rime/zhwiki.dict.yaml ]]; then
  [[ ! -f $WGETRC ]] && touch $WGETRC
  wget -c https://github.com/felixonmars/fcitx5-pinyin-zhwiki/releases/download/0.2.1/zhwiki-20200601.dict.yaml \
    -O $XDG_CONFIG_HOME/fcitx/rime/zhwiki.dict.yaml || echo "Download zhwiki failed"
fi
