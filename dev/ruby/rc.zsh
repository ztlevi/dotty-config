zinit wait lucid for \
  OMZP::ruby \
  OMZP::gem
zinit light-mode for OMZP::rbenv

alias rb="ruby"
alias rbe="rbenv"
alias rdb="pry -r"

alias rk="${aliases[rk]:-rake}"
alias rkg="${aliases[rkg]:-rake -g}"

alias bu="bundle"
alias bue="bundle exec"
alias bui="bundle install -path vendor"
