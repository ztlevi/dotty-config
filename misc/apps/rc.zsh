_is_callable tensorboard && alias tb="tensorboard"
_is_callable bandwhich && alias bandwhich="sudo $(which bandwhich)"

# used for mas
function find-app-id() {
  /usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' /Applications/"$1".app/Contents/Info.plist
}
