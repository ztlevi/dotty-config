function string_join() {
  local IFS="$1"
  shift
  echo "$*"
}

function palette() {
  for i in {0..255} ; do
    printf "\x1b[48;5;%sm%3d\e[0m " "$i" "$i"
    if (( i == 15 )) || (( i > 15 )) && (( (i-15) % 6 == 0 )); then
      printf "\n";
    fi
  done
}

function b64() {
  image=$(openssl base64 -in $1 | tr -d "\n")
  echo "![img](data:image/png;base64,$image)" | pbcopy
}

function unixtime-convert {
  # Usage: unixtime-convert 1638858888.708148250
  local TimeZone=${2:-"America/Los_Angeles"}
  echo $TimeZone
  TZ=$TimeZone date -d @"$1" +'%Y-%m-%d %H:%M:%S %Nns'
}

function envrehash() {
  for cmd in ${env_rehash_cmds[@]}; do
    eval "$cmd"
  done
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

function update_topics {
  declare -a topics
  topics=( "$DOTTY_DATA_HOME"/*.topic(N) )
  for topic in ${${${topics[@]#$DOTTY_DATA_HOME/}%.topic}/.//}; do
    ${DOTTY_HOME}/deploy -l ${topic}
  done
}

function update_git_repo() {
  local ERROR_SUMMARY_FILE=/tmp/update_dotty_error_summary
  dir=$1
  diff_str=$(
    cd $dir
    git diff
  )
  if [[ -d ${dir} && -z ${diff_str} ]]; then
    for repo in $@; do
      (cd ${repo} && git pull)
    done
  else
    echo "${dir} repo is dirty..." >>${ERROR_SUMMARY_FILE}
  fi
}

function update_dotty() {
  local ERROR_SUMMARY_FILE=/tmp/update_dotty_error_summary
  rm -f ${ERROR_SUMMARY_FILE} && touch ${ERROR_SUMMARY_FILE}

  echo-info "update $DOTTY_HOME"
  update_git_repo $DOTTY_HOME
  (
    cd $DOTTY_HOME
    git submodule update --remote --merge config
    echo-info "update ${DOTTY_ASSETS_HOME}"
    [[ -d ${DOTTY_ASSETS_HOME} ]] && cd ${DOTTY_ASSETS_HOME} && git pull
    update_topics &>/dev/null
  )


  if [[ -d ${XDG_CONFIG_HOME}/doom ]]; then
    local last_doom_rev=$(git -C ${XDG_CONFIG_HOME}/doom rev-parse HEAD)
    update_git_repo ${XDG_CONFIG_HOME}/doom &
    PID1=$!
    wait ${PID1}

    local cur_doom_rev=$(git -C ${XDG_CONFIG_HOME}/doom rev-parse HEAD)
    if [[ $cur_doom_rev != $last_doom_rev ]]; then
      echo-ok "Doom Sync Summary"
      doom sync
    fi
  fi

  echo-info "Update TPM packages"
  local tpm=$TMUX_PLUGIN_MANAGER_PATH/tpm
  if [[ -d $tpm ]]; then
    $tpm/bin/update_plugins all &
    PID2=$!
    wait ${PID2}
  fi

  _cache_clear

  echo-info "Error Summary"
  cat ${ERROR_SUMMARY_FILE}

  rm -f ${ERROR_SUMMARY_FILE}

  # Sync uninstalled some software if we deleted on one machine
  $DOTTY_HOME/legacy_sync_script.zsh
}
alias uu='update_dotty'
