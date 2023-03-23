#!/usr/bin/env bats

load test_helper

create_version() {
  mkdir -p "${TFENV_ROOT}/versions/$1"
}

setup() {
  mkdir -p "$TFENV_TEST_DIR"
  cd "$TFENV_TEST_DIR"
}

@test "no version selected" {
  assert [ ! -d "${TFENV_ROOT}/versions" ]
  run tfenv-version
  assert_success "system"
}

@test "set by TFENV_VERSION" {
  create_version "1.9.3"
  TFENV_VERSION=1.9.3 run tfenv-version
  assert_success "1.9.3 (set by TFENV_VERSION environment variable)"
}

@test "set by local file" {
  create_version "1.9.3"
  cat > ".terraform-version" <<<"1.9.3"
  run tfenv-version
  assert_success "1.9.3 (set by ${PWD}/.terraform-version)"
}

@test "set by global file" {
  create_version "1.9.3"
  cat > "${TFENV_ROOT}/version" <<<"1.9.3"
  run tfenv-version
  assert_success "1.9.3 (set by ${TFENV_ROOT}/version)"
}

@test "prefer local over global file" {
  create_version "1.9.3"
  create_version "3.0.0"
  cat > ".terraform-version" <<<"1.9.3"
  cat > "${TFENV_ROOT}/version" <<<"3.0.0"
  run tfenv-version
  assert_success "1.9.3 (set by ${PWD}/.terraform-version)"
}
