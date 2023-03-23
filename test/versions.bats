#!/usr/bin/env bats

load test_helper

create_version() {
  mkdir -p "${TFENV_ROOT}/versions/$1"
}

setup() {
  mkdir -p "$TFENV_TEST_DIR"
  cd "$TFENV_TEST_DIR"
}

stub_system_terraform() {
  local stub="${TFENV_TEST_DIR}/bin/terraform"
  mkdir -p "$(dirname "$stub")"
  touch "$stub" && chmod +x "$stub"
}

@test "no versions installed" {
  stub_system_terraform
  assert [ ! -d "${TFENV_ROOT}/versions" ]
  run tfenv-versions
  assert_success "* system"
}

@test "not even system terraform available" {
  PATH="$(path_without terraform)" run tfenv-versions
  assert_failure
  assert_output "Warning: no Terraform detected on the system"
}

@test "bare output no versions installed" {
  assert [ ! -d "${TFENV_ROOT}/versions" ]
  run tfenv-versions --bare
  assert_success ""
}

@test "single version installed" {
  stub_system_terraform
  create_version "1.9"
  run tfenv-versions
  assert_success
  assert_output <<OUT
* system
  1.9
OUT
}

@test "single version bare" {
  create_version "1.9"
  run tfenv-versions --bare
  assert_success "1.9"
}

@test "multiple versions" {
  stub_system_terraform
  create_version "1.8.7"
  create_version "1.9.3-p13"
  create_version "1.9.3-p2"
  create_version "2.2.10"
  create_version "2.2.3"
  create_version "2.2.3-pre.2"
  run tfenv-versions
  assert_success
  assert_output <<OUT
* system
  1.8.7
  1.9.3-p2
  1.9.3-p13
  2.2.3-pre.2
  2.2.3
  2.2.10
OUT
}

@test "indicates current version" {
  stub_system_terraform
  create_version "1.9.3"
  create_version "2.0.0"
  TFENV_VERSION=1.9.3 run tfenv-versions
  assert_success
  assert_output <<OUT
  system
* 1.9.3 (set by TFENV_VERSION environment variable)
  2.0.0
OUT
}

@test "bare doesn't indicate current version" {
  create_version "1.9.3"
  create_version "2.0.0"
  TFENV_VERSION=1.9.3 run tfenv-versions --bare
  assert_success
  assert_output <<OUT
1.9.3
2.0.0
OUT
}

@test "globally selected version" {
  stub_system_terraform
  create_version "1.9.3"
  create_version "2.0.0"
  cat > "${TFENV_ROOT}/version" <<<"1.9.3"
  run tfenv-versions
  assert_success
  assert_output <<OUT
  system
* 1.9.3 (set by ${TFENV_ROOT}/version)
  2.0.0
OUT
}

@test "per-project version" {
  stub_system_terraform
  create_version "1.9.3"
  create_version "2.0.0"
  cat > ".terraform-version" <<<"1.9.3"
  run tfenv-versions
  assert_success
  assert_output <<OUT
  system
* 1.9.3 (set by ${TFENV_TEST_DIR}/.terraform-version)
  2.0.0
OUT
}

@test "ignores non-directories under versions" {
  create_version "1.9"
  touch "${TFENV_ROOT}/versions/hello"

  run tfenv-versions --bare
  assert_success "1.9"
}

@test "lists symlinks under versions" {
  create_version "1.8.7"
  ln -s "1.8.7" "${TFENV_ROOT}/versions/1.8"

  run tfenv-versions --bare
  assert_success
  assert_output <<OUT
1.8
1.8.7
OUT
}

@test "doesn't list symlink aliases when --skip-aliases" {
  create_version "1.8.7"
  ln -s "1.8.7" "${TFENV_ROOT}/versions/1.8"
  mkdir moo
  ln -s "${PWD}/moo" "${TFENV_ROOT}/versions/1.9"

  run tfenv-versions --bare --skip-aliases
  assert_success

  assert_output <<OUT
1.8.7
1.9
OUT
}
