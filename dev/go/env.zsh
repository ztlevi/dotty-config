if _is_callable go; then
  go env -w GOPATH "$XDG_DATA_HOME/go"
  _is_callable go && go env -w GOROOT "$(go env GOROOT)"
  # go env -w GOPROXY=direct

  # Adds $GOPATH/bin's to PATH
  path=( `printf '%s/bin\n' ${(@s/:/)GOPATH}` $path )
fi
