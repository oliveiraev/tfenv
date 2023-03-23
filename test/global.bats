#!/usr/bin/env bats

load test_helper

@test "default" {
  run tfenv-global
  assert_success
  assert_output "system"
}

@test "read TFENV_ROOT/version" {
  mkdir -p "$TFENV_ROOT"
  echo "1.2.3" > "$TFENV_ROOT/version"
  run tfenv-global
  assert_success
  assert_output "1.2.3"
}

@test "set TFENV_ROOT/version" {
  mkdir -p "$TFENV_ROOT/versions/1.2.3"
  run tfenv-global "1.2.3"
  assert_success
  run tfenv-global
  assert_success "1.2.3"
}

@test "fail setting invalid TFENV_ROOT/version" {
  mkdir -p "$TFENV_ROOT"
  run tfenv-global "1.2.3"
  assert_failure "tfenv: version \`1.2.3' not installed"
}
