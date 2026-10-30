# herdr: show a Nerd Font icon for the running program in the tab name and, via
# the "$icon" pane token, in the sidebar agents panel.
# No-op outside a herdr pane.
[[ $HERDR_ENV == 1 && -n $HERDR_PANE_ID ]] || return 0
(( $+commands[herdr] && $+commands[jq] )) || return 0

autoload -Uz add-zsh-hook

typeset -g _HERDR_ICON_LAST=""

# Map the command being run to a glyph.
_herdr_icon_for() {
  local -a w segs=(${(s:;:)${${1//&&/;}//||/;}})
  local c seg
  # `et` expands to "unset SSH_TTY && emacs -nw": skip setup-only segments
  for seg in $segs; do
    w=(${(z)seg})
    while (( $#w )) && [[ $w[1] == *=* ]]; do shift w; done
    case $w[1] in cd|unset|export|set|source|.|true|pushd|popd|"") ;; *) break ;; esac
  done
  # skip VAR=val prefixes and common wrappers
  while (( $#w )); do
    c=$w[1]
    case $c in
      *=*|sudo|env|time|nohup|exec|command|builtin|noglob|nocorrect) shift w ;;
      *) break ;;
    esac
  done
  c=${c:t}
  case $c in
    claude*)                         print -rn -- "" ;;  # asterisk
    kiro*)                           print -rn -- "󰊠" ;; # ghost
    codex*)                          print -rn -- "" ;;  # hubot
    python*|pip*|uv|uvx|ipython|poetry|pytest) print -rn -- "" ;;
    java|javac|mvn|gradle|gradlew|brazil-build|bb) print -rn -- "" ;;
    node|npm|npx|pnpm|yarn|bun|deno|tsc|ts-node) print -rn -- "" ;;
    go|gofmt)                        print -rn -- "" ;;
    cargo|rustc|rustup)              print -rn -- "" ;;
    ruby|gem|bundle|rake)            print -rn -- "" ;;
    lua|luajit)                      print -rn -- "" ;;
    bash|sh|zsh|fish)                print -rn -- "" ;;
    emacs*)                          print -rn -- "" ;;  # emacs
    vim|nvim|vi|nano)                print -rn -- "" ;;
    git|lazygit|tig|gh)              print -rn -- "" ;;
    docker|podman|docker-compose)    print -rn -- "" ;;
    kubectl|k9s|helm|kind)           print -rn -- "󱃾" ;;
    aws|cdk|ada|isengardcli)         print -rn -- "" ;;
    ssh|mosh|scp)                    print -rn -- "󰌗" ;;
    make|cmake|just)                 print -rn -- "" ;;
    htop|btop|top)                   print -rn -- "" ;;
    *)                               print -rn -- "" ;;  # generic terminal
  esac
}

_herdr_report_icon() {
  local icon=$1
  [[ $icon == $_HERDR_ICON_LAST ]] && return 0
  _HERDR_ICON_LAST=$icon
  [[ -n $HERDR_TAB_ID ]] || return 0
  {
    # "$icon" token for the sidebar agents panel (ui.sidebar.agents.rows)
    herdr pane report-metadata $HERDR_PANE_ID --source dotty-icon --token icon=$icon
    # Re-read the label each time so a manual rename is kept: only the leading
    # "<glyph> " we added earlier is stripped, then the new icon is prefixed.
    local label=$(herdr tab get $HERDR_TAB_ID | jq -r '.result.tab.label // empty')
    [[ -n $label ]] || return 0
    [[ $label =~ '^[^[:alnum:]]+ (.*)$' ]] && label=$match[1]
    herdr tab rename $HERDR_TAB_ID "$icon $label"
  } &>/dev/null &!
}

# back at the prompt: the pane is just a shell again
# $3 is the alias-expanded line, so aliases like `c` and `et` resolve to the real program
_herdr_icon_preexec() { _herdr_report_icon "$(_herdr_icon_for "${3:-$1}")" }
_herdr_icon_precmd()  { _herdr_report_icon "" }

add-zsh-hook preexec _herdr_icon_preexec
add-zsh-hook precmd  _herdr_icon_precmd
