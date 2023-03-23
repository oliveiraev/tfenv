if [[ ! -o interactive ]]; then
    return
fi

compctl -K _tfenv tfenv

_tfenv() {
  local words completions
  read -cA words

  emulate -L zsh

  if [ "${#words}" -eq 2 ]; then
    completions="$(tfenv commands)"
  else
    completions="$(tfenv completions ${words[2,-2]})"
  fi

  reply=("${(ps:\n:)completions}")
}
