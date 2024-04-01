zinit light-mode for OMZP::kubectl

unalias k

function k() {
  if _is_callable jq; then
    kubectl "$@" -o json | jq;
  else
    kubectl "$@"
  fi
}
