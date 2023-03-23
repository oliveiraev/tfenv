#!/usr/bin/env bats

load test_helper

@test "shell integration disabled" {
  run tfenv shell
  assert_failure "tfenv: shell integration not enabled. Run \`tfenv init' for instructions."
}

@test "shell integration enabled" {
  eval "$(tfenv init -)"
  run tfenv shell
  assert_success "tfenv: no shell-specific version configured"
}

@test "no shell version" {
  mkdir -p "${TFENV_TEST_DIR}/myproject"
  cd "${TFENV_TEST_DIR}/myproject"
  echo "1.2.3" > .terraform-version
  TFENV_VERSION="" run tfenv-sh-shell
  assert_failure "tfenv: no shell-specific version configured"
}

@test "shell version" {
  TFENV_SHELL=bash TFENV_VERSION="1.2.3" run tfenv-sh-shell
  assert_success 'echo "$TFENV_VERSION"'
}

@test "shell version (fish)" {
  TFENV_SHELL=fish TFENV_VERSION="1.2.3" run tfenv-sh-shell
  assert_success 'echo "$TFENV_VERSION"'
}

@test "shell revert" {
  TFENV_SHELL=bash run tfenv-sh-shell -
  assert_success
  assert_line 0 'if [ -n "${TFENV_VERSION_OLD+x}" ]; then'
}

@test "shell revert (fish)" {
  TFENV_SHELL=fish run tfenv-sh-shell -
  assert_success
  assert_line 0 'if set -q TFENV_VERSION_OLD'
}

@test "shell unset" {
  TFENV_SHELL=bash run tfenv-sh-shell --unset
  assert_success
  assert_output <<OUT
TFENV_VERSION_OLD="\${TFENV_VERSION-}"
unset TFENV_VERSION
OUT
}

@test "shell unset (fish)" {
  TFENV_SHELL=fish run tfenv-sh-shell --unset
  assert_success
  assert_output <<OUT
set -gu TFENV_VERSION_OLD "\$TFENV_VERSION"
set -e TFENV_VERSION
OUT
}

@test "shell change invalid version" {
  run tfenv-sh-shell 1.2.3
  assert_failure
  assert_output <<SH
tfenv: version \`1.2.3' not installed
false
SH
}

@test "shell change version" {
  mkdir -p "${TFENV_ROOT}/versions/1.2.3"
  TFENV_SHELL=bash run tfenv-sh-shell 1.2.3
  assert_success
  assert_output <<OUT
TFENV_VERSION_OLD="\${TFENV_VERSION-}"
export TFENV_VERSION="1.2.3"
OUT
}

@test "shell change version (fish)" {
  mkdir -p "${TFENV_ROOT}/versions/1.2.3"
  TFENV_SHELL=fish run tfenv-sh-shell 1.2.3
  assert_success
  assert_output <<OUT
set -gu TFENV_VERSION_OLD "\$TFENV_VERSION"
set -gx TFENV_VERSION "1.2.3"
OUT
}
