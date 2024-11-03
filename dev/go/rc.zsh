zinit wait lucid for \
  OMZP::golang

if _is_callable go; then
  export GOPATH="$XDG_DATA_HOME/go"
  export GOROOT="$(brew --prefix go)/libexec"
  go env -w GOROOT=$GOROOT
  go env -w GOPATH=$GOPATH

  path=( "$GOPATH/bin" $path )
fi
