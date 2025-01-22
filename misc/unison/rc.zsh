unison-sync() {
  # Usage:
  # unison-sync <local-workplace> <username>@<remote-hostname> <remote-workplace>
  # e.g. unison-sync /workplace ztlevi@kuro /workplace
  # You need to remove local or remote ~/.unison cache if failed
  if [[ $# -ne 3 ]]; then
    echo-fail "Need 3 argments but only have $#"
    echo-info "Usage: unison-sync <local-workplace> <username>@<remote-hostname> <remote-workplace>"
    return 0
  fi
  local remote_arg="ssh://$2/$3"

  (
    if ! pgrep unison >/dev/null; then
      while :; do
        echo "Kill local and remote unison process... " $(date)
        ssh $2 "killall unison" && sleep 1 || true
        killall unison && sleep 1 || true
        killall unison-fsmonitor && sleep 1 || true
        echo "Starting unison process... " $(date)
        unison -ui text default.prf $1 $remote_arg
        echo "Unison process exited.  Sleeping before restarting.  ^C to exit. " $(date)
        sleep 30
      done
      echo "unison is running..."
    fi
  ) &
  pid=$! # Capture the background process ID

  # Wait for up to 16h for the block to complete
  sleep 16h && kill "$pid" 2>/dev/null &
  watcher=$!
  wait "$pid" 2>/dev/null && kill "$watcher" 2>/dev/null
  killall unison && sleep 1 || true
  killall unison-fsmonitor && sleep 1 || true
}

unison-clean() {
  fd -H --no-ignore "\.unison*" | xargs rm -rf {}
}
