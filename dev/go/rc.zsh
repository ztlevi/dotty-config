zinit wait lucid for \
  OMZP::golang

if _is_callable go; then
  export GOPATH="$XDG_DATA_HOME/go"
  export GOROOT="$(brew --prefix go)/libexec"

  path=( "$GOPATH/bin" $path )
fi
