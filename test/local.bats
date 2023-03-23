#!/usr/bin/env bats

load test_helper

setup() {
  mkdir -p "${TFENV_TEST_DIR}/myproject"
  cd "${TFENV_TEST_DIR}/myproject"
}

@test "no version" {
  assert [ ! -e "${PWD}/.terraform-version" ]
  run tfenv-local
  assert_failure "tfenv: no local version configured for this directory"
}

@test "local version" {
  echo "1.2.3" > .terraform-version
  run tfenv-local
  assert_success "1.2.3"
}

@test "discovers version file in parent directory" {
  echo "1.2.3" > .terraform-version
  mkdir -p "subdir" && cd "subdir"
  run tfenv-local
  assert_success "1.2.3"
}

@test "ignores TFENV_DIR" {
  echo "1.2.3" > .terraform-version
  mkdir -p "$HOME"
  echo "2.0-home" > "${HOME}/.terraform-version"
  TFENV_DIR="$HOME" run tfenv-local
  assert_success "1.2.3"
}

@test "sets local version" {
  mkdir -p "${TFENV_ROOT}/versions/1.2.3"
  run tfenv-local 1.2.3
  assert_success ""
  assert [ "$(cat .terraform-version)" = "1.2.3" ]
}

@test "changes local version" {
  echo "1.0-pre" > .terraform-version
  mkdir -p "${TFENV_ROOT}/versions/1.2.3"
  run tfenv-local
  assert_success "1.0-pre"
  run tfenv-local 1.2.3
  assert_success ""
  assert [ "$(cat .terraform-version)" = "1.2.3" ]
}

@test "unsets local version" {
  touch .terraform-version
  run tfenv-local --unset
  assert_success ""
  assert [ ! -e .terraform-version ]
}
