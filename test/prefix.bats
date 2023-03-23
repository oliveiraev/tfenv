#!/usr/bin/env bats

load test_helper

@test "prefix" {
  mkdir -p "${TFENV_TEST_DIR}/myproject"
  cd "${TFENV_TEST_DIR}/myproject"
  echo "1.2.3" > .terraform-version
  mkdir -p "${TFENV_ROOT}/versions/1.2.3"
  run tfenv-prefix
  assert_success "${TFENV_ROOT}/versions/1.2.3"
}

@test "prefix for invalid version" {
  TFENV_VERSION="1.2.3" run tfenv-prefix
  assert_failure "tfenv: version \`1.2.3' not installed"
}

@test "prefix for system" {
  mkdir -p "${TFENV_TEST_DIR}/bin"
  touch "${TFENV_TEST_DIR}/bin/terraform"
  chmod +x "${TFENV_TEST_DIR}/bin/terraform"
  TFENV_VERSION="system" run tfenv-prefix
  assert_success "$TFENV_TEST_DIR"
}

@test "prefix for system in /" {
  mkdir -p "${BATS_TEST_DIRNAME}/libexec"
  cat >"${BATS_TEST_DIRNAME}/libexec/tfenv-which" <<OUT
#!/bin/sh
echo /bin/terraform
OUT
  chmod +x "${BATS_TEST_DIRNAME}/libexec/tfenv-which"
  TFENV_VERSION="system" run tfenv-prefix
  assert_success "/"
  rm -f "${BATS_TEST_DIRNAME}/libexec/tfenv-which"
}

@test "prefix for invalid system" {
  PATH="$(path_without terraform)" run tfenv-prefix system
  assert_failure <<EOF
tfenv: terraform: command not found
tfenv: system version not found in PATH"
EOF
}
