# for app silicon
if [ -d /opt/homebrew/ ]; then
  path=(/opt/homebrew/bin $path)
fi

export GNUPGHOME="$HOME/.gnupg"

# export CC=/usr/bin/clang
# export CXX=/usr/bin/clang++
# export CXXFLAGS="-I/usr/local/include"
export C_INCLUDE_PATH="/usr/local/include"
export CPLUS_INCLUDE_PATH="/usr/local/include"
export LIBRARY_PATH="/usr/local/lib"
# export LDFLAGS="-L/usr/local/lib"

export LESS='-g -i -M -R -S -w -z-4'
if _is_callable lesspipe; then
  export LESSOPEN='| /usr/bin/env lesspipe %s 2>&-'
fi
