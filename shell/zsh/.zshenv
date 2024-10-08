# NIXOS copy .zshenv to nix store, source the absolute path
if [[ -n ${DOTTY_CONFIG_HOME} ]]; then
  source ${DOTTY_CONFIG_HOME}/env
else
  source $(cd ${${(%):-%x}:A:h}/../.. && pwd -P)/env
fi

export ZSH_CONFIG_HOME="$XDG_CONFIG_HOME/zsh"

export LC_ALL="en_US.UTF-8"
export LANG='en_US.UTF-8'
export LANGUAGE=en_US.UTF-8
export TERM="xterm-24bit"
export ARCHFLAGS="-arch x86_64"
export SSH_KEY_PATH="~/.ssh/rsa_id"
export MANPATH="$HOMEBREW_PREFIX/man:$MANPATH"
_is_callable nvim && export MANPAGER="nvim +Man!"

# No github credentials
export HOMEBREW_NO_GITHUB_API=1

# Load homebrew env more eagerly here. Make sure HOMEBREW_PREFIX is set before `_load_all env.zsh`
if [[ $(_os) = "macos" ]]; then
  if [[ -d /opt/homebrew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    eval "$(/usr/local/bin/brew shellenv)"
  fi
elif [[ $(_os) = "linux-*" ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Bat
if [[ $DOTTY_THEME == "dark" ]]; then
    export BAT_THEME="OneHalfDark"
else
    export BAT_THEME="OneHalfLight"
fi
export BAT_STYLE="header,grid"

# Do not upgrade outdated packages after brew install
export HOMEBREW_NO_INSTALL_UPGRADE=1

# Uncomment the following line to change how often to auto-update (in days).
export UPDATE_ZSH_DAYS=30

export ZSH_CACHE="$XDG_CACHE_HOME/zsh"

# paths
typeset -gU cdpath fpath mailpath path
fpath=( $XDG_BIN_HOME $fpath )

# envvars
# export SHELL=$(command -v zsh)
export LANG=${LANG:-en_US.UTF-8}
export PAGER="bat --style=grid"
export LESS='-R -i -w -M -z-4'
export LESSHISTFILE="$XDG_DATA_HOME/lesshst"
export PASSWORD_STORE_DIR="$XDG_DATA_HOME/password-store"

# wget
export WGETRC="$XDG_CONFIG_HOME/wgetrc"

# ripgep
export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgreprc"

# added by Nix installer
if [ -e $HOME/.nix-profile/etc/profile.d/nix.sh ]; then . $HOME/.nix-profile/etc/profile.d/nix.sh; fi

# initialize enabled topics
_load_all env.zsh
[[ -f ${ZSH_CONFIG_HOME}/extra.zshenv ]] && _load ${ZSH_CONFIG_HOME}/extra.zshenv
