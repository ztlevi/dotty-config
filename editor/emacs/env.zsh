path=($XDG_CONFIG_HOME/emacs/bin $path)
if [ -d '$HOMEBREW_PREFIX/opt/emacs-plus' ]; then
  path=($HOMEBREW_PREFIX/opt/emacs-plus/bin $path)
else
  path=($HOMEBREW_PREFIX/opt/emacs-mac/bin $path)
fi
export LSP_USE_PLISTS=true
