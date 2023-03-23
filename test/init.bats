#!/usr/bin/env bats

load test_helper

@test "creates shims and versions directories" {
  assert [ ! -d "${TFENV_ROOT}/shims" ]
  assert [ ! -d "${TFENV_ROOT}/versions" ]
  run tfenv-init -
  assert_success
  assert [ -d "${TFENV_ROOT}/shims" ]
  assert [ -d "${TFENV_ROOT}/versions" ]
}

@test "auto rehash" {
  run tfenv-init -
  assert_success
  assert_line "command tfenv rehash 2>/dev/null"
}

@test "setup shell completions" {
  root="$(cd $BATS_TEST_DIRNAME/.. && pwd)"
  run tfenv-init - bash
  assert_success
  assert_line "source '${root}/test/../completions/tfenv.bash'"
}

@test "detect parent shell" {
  SHELL=/bin/false run tfenv-init -
  assert_success
  assert_line "export TFENV_SHELL=bash"
}

@test "detect parent shell from script" {
  mkdir -p "$TFENV_TEST_DIR"
  cd "$TFENV_TEST_DIR"
  cat > myscript.sh <<OUT
#!/bin/sh
eval "\$(tfenv-init -)"
echo \$TFENV_SHELL
OUT
  chmod +x myscript.sh
  run ./myscript.sh
  assert_success "sh"
}

@test "skip shell completions (fish)" {
  root="$(cd $BATS_TEST_DIRNAME/.. && pwd)"
  run tfenv-init - fish
  assert_success
  local line="$(grep '^source' <<<"$output")"
  [ -z "$line" ] || flunk "did not expect line: $line"
}

@test "posix shell instructions" {
  run tfenv-init bash
  assert [ "$status" -eq 1 ]
  assert_line 'eval "$(tfenv init - bash)"'
}

@test "fish instructions" {
  run tfenv-init fish
  assert [ "$status" -eq 1 ]
  assert_line 'status --is-interactive; and tfenv init - fish | source'
}

@test "option to skip rehash" {
  run tfenv-init - --no-rehash
  assert_success
  refute_line "tfenv rehash 2>/dev/null"
}

@test "adds shims to PATH" {
  export PATH="${BATS_TEST_DIRNAME}/../libexec:/usr/bin:/bin:/usr/local/bin"
  run tfenv-init - bash
  assert_success
  assert_line 0 'export PATH="'${TFENV_ROOT}'/shims:${PATH}"'
}

@test "adds shims to PATH (fish)" {
  export PATH="${BATS_TEST_DIRNAME}/../libexec:/usr/bin:/bin:/usr/local/bin"
  run tfenv-init - fish
  assert_success
  assert_line 0 "set -gx PATH '${TFENV_ROOT}/shims' \$PATH"
}

@test "can add shims to PATH more than once" {
  export PATH="${TFENV_ROOT}/shims:$PATH"
  run tfenv-init - bash
  assert_success
  assert_line 0 'export PATH="'${TFENV_ROOT}'/shims:${PATH}"'
}

@test "can add shims to PATH more than once (fish)" {
  export PATH="${TFENV_ROOT}/shims:$PATH"
  run tfenv-init - fish
  assert_success
  assert_line 0 "set -gx PATH '${TFENV_ROOT}/shims' \$PATH"
}

@test "outputs sh-compatible syntax" {
  run tfenv-init - bash
  assert_success
  assert_line '  case "$command" in'

  run tfenv-init - zsh
  assert_success
  assert_line '  case "$command" in'
}

@test "outputs fish-specific syntax (fish)" {
  run tfenv-init - fish
  assert_success
  assert_line '  switch "$command"'
  refute_line '  case "$command" in'
}
