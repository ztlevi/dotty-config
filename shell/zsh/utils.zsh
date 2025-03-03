string_join() {
  local IFS="$1"
  shift
  echo "$*"
}

color-palette() {
  for i in {0..255} ; do
    printf "\x1b[48;5;%sm%3d\e[0m " "$i" "$i"
    if (( i == 15 )) || (( i > 15 )) && (( (i-15) % 6 == 0 )); then
      printf "\n";
    fi
  done
}

b64() {
  image=$(openssl base64 -in $1 | tr -d "\n")
  echo "![img](data:image/png;base64,$image)" | pbcopy
}

function unixtime-convert {
  # Usage: unixtime-convert 1638858888.708148250 UTC
  local TimeZone=${2:-"America/Los_Angeles"}
  TZ=$TimeZone date -d @"$1" +'%Y-%m-%d %H:%M:%S %Nns'
}

center_text() {
  # Function "center_text": center the text with a surrounding border

  # first argument: text to center
  # second argument: glyph which forms the border
  # third argument: width of the padding

  local terminal_width=$(tput cols) # query the Terminfo database: number of columns
  local text="${1:?}"               # text to center
  local glyph="${2:-=}"             # glyph to compose the border
  local padding="${3:-2}"           # spacing around the text

  local text_width=${#text}

  local border_width=$(((terminal_width - (padding * 2) - text_width) / 2))

  local border= # shape of the border

  # create the border (left side or right side)
  for ((i = 0; i < border_width; i++)); do
    border+="${glyph}"
  done

  # a side of the border may be longer (e.g. the right border)
  if (((terminal_width - (padding * 2) - text_width) % 2 == 0)); then
    # the left and right borders have the same width
    local left_border=$border
    local right_border=$left_border
  else
    # the right border has one more character than the left border
    # the text is aligned leftmost
    local left_border=$border
    local right_border="${border}${glyph}"
  fi

  # space between the text and borders
  local spacing=

  for ((i = 0; i < $padding; i++)); do
    spacing+=" "
  done

  # displays the text in the center of the screen, surrounded by borders.
  printf "${left_border}${spacing}${text}${spacing}${right_border}\n"
}

update_topics() {
  declare -a topics
  topics=( "$DOTTY_DATA_HOME"/*.topic(N) )
  for topic in ${${${topics[@]#$DOTTY_DATA_HOME/}%.topic}/.//}; do
    ${DOTTY_HOME}/deploy -l ${topic}
  done
}

sshf() {
  # Forward ssh port
  if [ "$#" -ne 2 ]; then
    echo "usage: sshf 10.0.0.1 6006"
    return 1
  fi
  local host="${1}"
  local port="${2}"
  local process_id="$(lsof -ti:${port})"
  [[ -n $process_id ]] && kill -9 $process_id
  ssh -NfL ${port}:localhost:${port} ${host}
}

# fuzzy find projects
ff_projects() {
  # Each root is consist of PATH:scan_depth
  project_scans=("${HOME}:1" "${HOME}/Dropbox:1" "${HOME}/go/src:1" "${XDG_CONFIG_HOME}:1"
                 "${HOME}/dev:3" "${HOME}/dev-local:2" "${HOME}/git:2")

  projects=()
  local project scan_depth
  for project_scan in ${project_scans[@]}; do
    IFS=: read -r project scan_depth <<<"${project_scan}"
    project="$(readlink $project || echo $project)"
    if [[ -d ${project} ]]; then
      # Suppress errors, some dirs, e.g. .Trash, sometimes are not readable
      {
        if _is_callable fd; then
          dirs=($(fd --max-depth ${scan_depth} -t d . ${project}))
        else
          dirs=($(find ${project} -maxdepth ${scan_depth} -type d))
        fi
        for dir in ${dirs[@]}; do
          if [[ -d ${dir}/.git ]]; then
            projects+=(${dir})
          fi
        done
      } 2>/dev/null
    fi
  done

  local IFS=$'\n'
  if _is_callable sk; then ff_cmd="sk"
  elif _is_callable fzf; then ff_cmd="fzf"
  else
    echo-fail "Please fzf or skim (sk) first"
    return 1
  fi
  selected_project=$(echo "${projects[*]}" | $ff_cmd)

  if [[ -n "$selected_project" ]]; then
    cd ${selected_project}
  fi
}
alias pp=ff_projects

# fkill - fuzzy find kill processes
fkill() {
  if _is_callable sk; then ff_cmd="sk"
  elif _is_callable fzf; then ff_cmd="fzf"
  else
    echo-fail "Please fzf or skim (sk) first"
    return 1
  fi
  pids=($(procs $(whoami) | sed '1,2d' | $ff_cmd -m | awk '{print $1}'))
  echo-info "kill -9 ${pids[@]}"
  kill -9 ${pids[@]} || "Failed to kill ${pids[@]}"
}

# fman - fuzzy find man page
fman() {
  if _is_callable sk; then ff_cmd="sk"
  elif _is_callable fzf; then ff_cmd="fzf"
  else
    echo-fail "Please fzf or skim (sk) first"
    return 1
  fi
  man -k . | $ff_cmd -q "$1" --prompt='man> ' | awk -F'\(' '{print $1}' | xargs -r man
}

update_git_repo() {
  dir=$1
  diff_str=$(
    cd $dir
    git diff
  )
  for repo in $@; do
    (cd ${repo} && git-safe-pull)
  done
}

update_dotty() {
  rm -f ${DOTTY_UPDATE_LOG} && touch ${DOTTY_UPDATE_LOG}

  parallel --jobs 3 -k <<EOF
  cd $DOTTY_CONFIG_HOME && git checkout main && git-safe-pull
  cd $DOTTY_HOME && git-safe-pull
  [[ -d ${DOTTY_ASSETS_HOME} ]] && cd ${DOTTY_ASSETS_HOME} && git-safe-pull
EOF

  update_topics &>/dev/null &  # Run this in the background

  if [[ -d ${XDG_CONFIG_HOME}/doom ]]; then
    local last_doom_rev=$(git -C ${XDG_CONFIG_HOME}/doom rev-parse HEAD)
    update_git_repo ${XDG_CONFIG_HOME}/doom

    local cur_doom_rev=$(git -C ${XDG_CONFIG_HOME}/doom rev-parse HEAD)
    if [[ $cur_doom_rev != $last_doom_rev ]]; then
      echo-ok "Doom Sync Summary"
      doom sync
    fi
  fi &  # Run in background

  echo-info "Update TPM packages"
  local tpm=$TMUX_PLUGIN_MANAGER_PATH/tpm
  if [[ -d $tpm ]]; then
    $tpm/bin/update_plugins all &
  fi

  wait  # Ensure all background processes finish

  _cache_clear
  zinit delete --clean -y
  rm -rf ~/.zinit/snippets/*--dotty*

  $DOTTY_HOME/legacy_sync_script.zsh

  echo-info "Dotty update log"
  cat ${DOTTY_UPDATE_LOG}
  rm -f ${DOTTY_UPDATE_LOG}
}
alias uu='update_dotty'
function uuh() {
  git -C $XDG_CONFIG_HOME/dotty reset --hard HEAD
  git -C $XDG_CONFIG_HOME/dotty/config reset --hard HEAD
  update_dotty
}
