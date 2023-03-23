#!/usr/bin/env bats

load test_helper

@test "blank invocation" {
  run tfenv
  assert_failure
  assert_line 0 "$(tfenv---version)"
}

@test "invalid command" {
  run tfenv does-not-exist
  assert_failure
  assert_output "tfenv: no such command \`does-not-exist'"
}

@test "default TFENV_ROOT" {
  TFENV_ROOT="" HOME=/home/mislav run tfenv root
  assert_success
  assert_output "/home/mislav/.tfenv"
}

@test "inherited TFENV_ROOT" {
  TFENV_ROOT=/opt/tfenv run tfenv root
  assert_success
  assert_output "/opt/tfenv"
}

@test "default TFENV_DIR" {
  run tfenv echo TFENV_DIR
  assert_output "$(pwd)"
}

@test "inherited TFENV_DIR" {
  dir="${BATS_TMPDIR}/myproject"
  mkdir -p "$dir"
  TFENV_DIR="$dir" run tfenv echo TFENV_DIR
  assert_output "$dir"
}

@test "invalid TFENV_DIR" {
  dir="${BATS_TMPDIR}/does-not-exist"
  assert [ ! -d "$dir" ]
  TFENV_DIR="$dir" run tfenv echo TFENV_DIR
  assert_failure
  assert_output "tfenv: cannot change working directory to \`$dir'"
}

@test "adds its own libexec to PATH" {
  run tfenv echo "PATH"
  assert_success "${BATS_TEST_DIRNAME%/*}/libexec:$PATH"
}

@test "adds plugin bin dirs to PATH" {
  mkdir -p "$TFENV_ROOT"/plugins/terraform-build/bin
  mkdir -p "$TFENV_ROOT"/plugins/tfenv-each/bin
  run tfenv echo -F: "PATH"
  assert_success
  assert_line 0 "${BATS_TEST_DIRNAME%/*}/libexec"
  assert_line 1 "${TFENV_ROOT}/plugins/tfenv-each/bin"
  assert_line 2 "${TFENV_ROOT}/plugins/terraform-build/bin"
}

@test "TFENV_HOOK_PATH preserves value from environment" {
  TFENV_HOOK_PATH=/my/hook/path:/other/hooks run tfenv echo -F: "TFENV_HOOK_PATH"
  assert_success
  assert_line 0 "/my/hook/path"
  assert_line 1 "/other/hooks"
  assert_line 2 "${TFENV_ROOT}/tfenv.d"
}

@test "TFENV_HOOK_PATH includes tfenv built-in plugins" {
  unset TFENV_HOOK_PATH
  run tfenv echo "TFENV_HOOK_PATH"
  assert_success "${TFENV_ROOT}/tfenv.d:${BATS_TEST_DIRNAME%/*}/tfenv.d:/usr/local/etc/tfenv.d:/etc/tfenv.d:/usr/lib/tfenv/hooks"
}
