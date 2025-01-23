unison-clean() {
  fd -H --no-ignore "\.unison*" | xargs rm -rf {}
}
