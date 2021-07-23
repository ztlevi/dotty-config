_cache rbenv init - --no-rehash
env_rehash_cmds+=("rbenv rehash")

zinit wait lucid for \
  OMZP::ruby \
  OMZP::rbenv \
  OMZP::gem

alias rb="ruby"
alias rbe="rbenv"
alias rdb="pry -r"

alias rk="noglob ${aliases[rk]:-rake}"
alias rkg="noglob ${aliases[rkg]:-rake -g}"

alias bu="bundle"
alias bue="bundle exec"
alias bui="bundle install -path vendor"
