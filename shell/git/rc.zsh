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

# Use after you change your branch name from master to main
# https://github.com/<user>/<project-name>/settings/branches
function git-rename-master-to-main() {
  git branch -m master main
  git fetch origin
  git branch -u origin/main main
  git remote set-head origin -a
}

function _is_git_submodule() {
  if (cd "$(git rev-parse --show-toplevel)/.." && git rev-parse --is-inside-work-tree) &> /dev/null ; then
    return 0
  fi
  return 1
}

function git-bump-submodules() {
  # Usaeg: In a git repo, do `git-bump-submodules "shell/zsh: update config"`
  if [[ -z $1 ]]; then
    echo "Missing commit message parameter. Usage: git-bump-submodules 'shell/zsh: update config'"
    return 1
  fi
  if ! (git rev-parse --is-inside-work-tree) &> /dev/null; then
    echo "Not inside a git repository..."
    return 1
  fi
  local git_root=$(git rev-parse --show-toplevel)
  if _is_git_submodule; then
    git_root=$git_root/..
  fi
  pushd $git_root >/dev/null
  local submodules=($(git config --file .gitmodules --get-regexp path | awk '{ print $2 }'))
  local updated_submodules=()
  for submodule in ${submodules[@]}; do
    pushd $git_root/$submodule >/dev/null
    if ! (git diff --quiet); then
      git add .
      git cm -m $1
      git push
      updated_submodules+=($submodule)
    fi
    popd >/dev/null
    git add $submodule
  done
  git cm -m "BUMP ${updated_submodules[@]}"
  git push
  popd >/dev/null
}
