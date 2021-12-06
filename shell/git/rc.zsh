zinit wait lucid for \
  OMZP::git \
  OMZP::gitignore
# OMZP::gh
# OMZP::git-extras
# wfxr/forgit
# TODO: https://github.com/zdharma/zinit/issues/477
# zinit ice svn wait lucid; zinit snippet OMZP::gitfast

alias git='noglob git'
alias g="git"
alias gci="gh pr checks"
alias gcpr="gh pr create --assignee ztlevi"
alias gist="gh gist create -p"
alias gistp="gh gist create" # secret
alias git-scan-secrets="git secrets --scan-history"

# Use after you change your branch name from master to main
# https://github.com/<user>/<project-name>/settings/branches
function git-rename-master-to-main() {
  git branch -m master main
  git fetch origin
  git branch -u origin/main main
  git remote set-head origin -a
}
