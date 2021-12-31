if _is_callable fd; then
  export FZF_DEFAULT_OPTS="--reverse --ansi"
  export FZF_DEFAULT_COMMAND="fd ."
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND="fd -t d . $HOME"
fi

export FZF_COMPLETION_TRIGGER=','

# sort histroy by index, this seems enabled by default
export FZF_CTRL_R_OPTS="--no-sort"
