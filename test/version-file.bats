#!/usr/bin/env bats

load test_helper

setup() {
  mkdir -p "$TFENV_TEST_DIR"
  cd "$TFENV_TEST_DIR"
}

create_file() {
  mkdir -p "$(dirname "$1")"
  echo "system" > "$1"
}

@test "detects global 'version' file" {
  create_file "${TFENV_ROOT}/version"
  run tfenv-version-file
  assert_success "${TFENV_ROOT}/version"
}

@test "prints global file if no version files exist" {
  assert [ ! -e "${TFENV_ROOT}/version" ]
  assert [ ! -e ".terraform-version" ]
  run tfenv-version-file
  assert_success "${TFENV_ROOT}/version"
}

@test "in current directory" {
  create_file ".terraform-version"
  run tfenv-version-file
  assert_success "${TFENV_TEST_DIR}/.terraform-version"
}

@test "in parent directory" {
  create_file ".terraform-version"
  mkdir -p project
  cd project
  run tfenv-version-file
  assert_success "${TFENV_TEST_DIR}/.terraform-version"
}

@test "topmost file has precedence" {
  create_file ".terraform-version"
  create_file "project/.terraform-version"
  cd project
  run tfenv-version-file
  assert_success "${TFENV_TEST_DIR}/project/.terraform-version"
}

@test "TFENV_DIR has precedence over PWD" {
  create_file "widget/.terraform-version"
  create_file "project/.terraform-version"
  cd project
  TFENV_DIR="${TFENV_TEST_DIR}/widget" run tfenv-version-file
  assert_success "${TFENV_TEST_DIR}/widget/.terraform-version"
}

@test "PWD is searched if TFENV_DIR yields no results" {
  mkdir -p "widget/blank"
  create_file "project/.terraform-version"
  cd project
  TFENV_DIR="${TFENV_TEST_DIR}/widget/blank" run tfenv-version-file
  assert_success "${TFENV_TEST_DIR}/project/.terraform-version"
}

@test "finds version file in target directory" {
  create_file "project/.terraform-version"
  run tfenv-version-file "${PWD}/project"
  assert_success "${TFENV_TEST_DIR}/project/.terraform-version"
}

@test "fails when no version file in target directory" {
  run tfenv-version-file "$PWD"
  assert_failure ""
}
