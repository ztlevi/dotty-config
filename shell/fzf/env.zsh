export FZF_DEFAULT_COMMAND='
  (git ls-tree -r --name-only HEAD ||
   find . -path "*/\.*" -prune -o -type f -print -o -type l -print |
      sed s/^..//) 2> /dev/null'

export FZF_CTRL_T_COMMAND='
  (rg --files ||
   find . -path "*/\.*" -prune -o -type f -print -o -type l -print |
      sed s/^..//) 2> /dev/null'

export FZF_COMPLETION_TRIGGER=','

# sort histroy by index, this seems enabled by default
export FZF_CTRL_R_OPTS="--no-sort"
