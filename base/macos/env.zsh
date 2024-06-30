# for app silicon
if [ -d /opt/homebrew/ ]; then
  path=(/opt/homebrew/bin $path)
fi

export GNUPGHOME="$HOME/.gnupg"

# export CC=/usr/bin/clang
# export CXX=/usr/bin/clang++
# export CXXFLAGS="-I$HOMEBREW_PREFIX/include"
export C_INCLUDE_PATH="$HOMEBREW_PREFIX/include"
export CPLUS_INCLUDE_PATH="$HOMEBREW_PREFIX/include"
export LIBRARY_PATH="$HOMEBREW_PREFIX/lib"
# export LDFLAGS="-L$HOMEBREW_PREFIX/lib"

export LESS='-g -i -M -R -S -w -z-4'
if _is_callable lesspipe; then
  export LESSOPEN='| /usr/bin/env lesspipe %s 2>&-'
fi
