#!/usr/bin/env bats

load test_helper

@test "prints usage help given no argument" {
  run tfenv-hooks
  assert_failure "Usage: tfenv hooks <command>"
}

@test "prints list of hooks" {
  path1="${TFENV_TEST_DIR}/tfenv.d"
  path2="${TFENV_TEST_DIR}/etc/tfenv_hooks"
  TFENV_HOOK_PATH="$path1"
  create_hook exec "hello.bash"
  create_hook exec "ahoy.bash"
  create_hook exec "invalid.sh"
  create_hook which "boom.bash"
  TFENV_HOOK_PATH="$path2"
  create_hook exec "bueno.bash"

  TFENV_HOOK_PATH="$path1:$path2" run tfenv-hooks exec
  assert_success
  assert_output <<OUT
${TFENV_TEST_DIR}/tfenv.d/exec/ahoy.bash
${TFENV_TEST_DIR}/tfenv.d/exec/hello.bash
${TFENV_TEST_DIR}/etc/tfenv_hooks/exec/bueno.bash
OUT
}

@test "supports hook paths with spaces" {
  path1="${TFENV_TEST_DIR}/my hooks/tfenv.d"
  path2="${TFENV_TEST_DIR}/etc/tfenv hooks"
  TFENV_HOOK_PATH="$path1"
  create_hook exec "hello.bash"
  TFENV_HOOK_PATH="$path2"
  create_hook exec "ahoy.bash"

  TFENV_HOOK_PATH="$path1:$path2" run tfenv-hooks exec
  assert_success
  assert_output <<OUT
${TFENV_TEST_DIR}/my hooks/tfenv.d/exec/hello.bash
${TFENV_TEST_DIR}/etc/tfenv hooks/exec/ahoy.bash
OUT
}

@test "does not canonicalize paths" {
  TFENV_HOOK_PATH="${TFENV_TEST_DIR}/tfenv.d"
  create_hook exec "hello.bash"
  mkdir -p "$HOME"

  TFENV_HOOK_PATH="${HOME}/../tfenv.d" run tfenv-hooks exec
  assert_success "${TFENV_TEST_DIR}/home/../tfenv.d/exec/hello.bash"
}

@test "does not resolve symlinks" {
  path="${TFENV_TEST_DIR}/tfenv.d"
  mkdir -p "${path}/exec"
  mkdir -p "$HOME"
  touch "${HOME}/hola.bash"
  ln -s "../../home/hola.bash" "${path}/exec/hello.bash"
  touch "${path}/exec/bright.sh"
  ln -s "bright.sh" "${path}/exec/world.bash"

  TFENV_HOOK_PATH="$path" run tfenv-hooks exec
  assert_success
  assert_output <<OUT
${TFENV_TEST_DIR}/tfenv.d/exec/hello.bash
${TFENV_TEST_DIR}/tfenv.d/exec/world.bash
OUT
}
