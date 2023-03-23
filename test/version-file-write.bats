#!/usr/bin/env bats

load test_helper

setup() {
  mkdir -p "$TFENV_TEST_DIR"
  cd "$TFENV_TEST_DIR"
}

@test "invocation without 2 arguments prints usage" {
  run tfenv-version-file-write
  assert_failure "Usage: tfenv version-file-write <file> <version>"
  run tfenv-version-file-write "one" ""
  assert_failure
}

@test "setting nonexistent version fails" {
  assert [ ! -e ".terraform-version" ]
  run tfenv-version-file-write ".terraform-version" "1.8.7"
  assert_failure "tfenv: version \`1.8.7' not installed"
  assert [ ! -e ".terraform-version" ]
}

@test "writes value to arbitrary file" {
  mkdir -p "${TFENV_ROOT}/versions/1.8.7"
  assert [ ! -e "my-version" ]
  run tfenv-version-file-write "${PWD}/my-version" "1.8.7"
  assert_success ""
  assert [ "$(cat my-version)" = "1.8.7" ]
}
