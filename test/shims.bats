#!/usr/bin/env bats

load test_helper

@test "no shims" {
  run tfenv-shims
  assert_success
  assert [ -z "$output" ]
}

@test "shims" {
  mkdir -p "${TFENV_ROOT}/shims"
  touch "${TFENV_ROOT}/shims/terraform"
  touch "${TFENV_ROOT}/shims/irb"
  run tfenv-shims
  assert_success
  assert_line "${TFENV_ROOT}/shims/terraform"
  assert_line "${TFENV_ROOT}/shims/irb"
}

@test "shims --short" {
  mkdir -p "${TFENV_ROOT}/shims"
  touch "${TFENV_ROOT}/shims/terraform"
  touch "${TFENV_ROOT}/shims/irb"
  run tfenv-shims --short
  assert_success
  assert_line "irb"
  assert_line "terraform"
}
