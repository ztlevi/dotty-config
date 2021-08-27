#!/usr/bin/env zsh

# c - browse chrome history on OSX/Linux
c() {
  case $(default-browser) in
    *chrome) fzf-chrome-history;;
    *firefox) fzf-firefox-history;;
  esac
}

# b - browse chrome bookmarks on OSX
b() {
  case $(default-browser) in
    *chrome) fzf-chrome-bookmarks ;;
    *firefox) fzf-firefox-bookmarks ;;
  esac
}
