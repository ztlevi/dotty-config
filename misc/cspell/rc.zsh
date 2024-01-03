#!/usr/bin/env zsh

alias cspell="cspell --config '$XDG_CONFIG_HOME/cspell/cspell.json'"
alias cspell-all="cspell '**/*.{js,jsx,ts,tsx,c,cc,cpp,h,hh,hpp,go,json,py,java}'"
alias cspell-changed="git diff --name-only HEAD | xargs -I{} cspell"
