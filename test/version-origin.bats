#!/usr/bin/env bats

load test_helper

setup() {
  mkdir -p "$TFENV_TEST_DIR"
  cd "$TFENV_TEST_DIR"
}

@test "reports global file even if it doesn't exist" {
  assert [ ! -e "${TFENV_ROOT}/version" ]
  run tfenv-version-origin
  assert_success "${TFENV_ROOT}/version"
}

@test "detects global file" {
  mkdir -p "$TFENV_ROOT"
  touch "${TFENV_ROOT}/version"
  run tfenv-version-origin
  assert_success "${TFENV_ROOT}/version"
}

@test "detects TFENV_VERSION" {
  TFENV_VERSION=1 run tfenv-version-origin
  assert_success "TFENV_VERSION environment variable"
}

@test "detects local file" {
  echo "system" > .terraform-version
  run tfenv-version-origin
  assert_success "${PWD}/.terraform-version"
}

@test "reports from hook" {
  create_hook version-origin test.bash <<<"TFENV_VERSION_ORIGIN=plugin"

  TFENV_VERSION=1 run tfenv-version-origin
  assert_success "plugin"
}

@test "carries original IFS within hooks" {
  create_hook version-origin hello.bash <<SH
hellos=(\$(printf "hello\\tugly world\\nagain"))
echo HELLO="\$(printf ":%s" "\${hellos[@]}")"
SH

  export TFENV_VERSION=system
  IFS=$' \t\n' run tfenv-version-origin env
  assert_success
  assert_line "HELLO=:hello:ugly:world:again"
}

@test "doesn't inherit TFENV_VERSION_ORIGIN from environment" {
  TFENV_VERSION_ORIGIN=ignored run tfenv-version-origin
  assert_success "${TFENV_ROOT}/version"
}
