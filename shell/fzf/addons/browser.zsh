#!/usr/bin/env zsh

# c - browse chrome history on OSX/Linux
bhistory() {
  case $(default-browser) in
    *chrome) fzf-history chrome;;
    *edge*) fzf-history edge;;
    *firefox) fzf-firefox-history;;
  esac
}

# b - browse chrome bookmarks on OSX
bbookmark() {
  case $(default-browser) in
    *chrome) fzf-bookmarks chrome ;;
    *edge*) fzf-bookmarks edge;;
    *firefox) fzf-firefox-bookmarks ;;
  esac
}
