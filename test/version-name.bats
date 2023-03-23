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
  run tfenv-version-name
  assert_success "system"
}

@test "system version is not checked for existence" {
  TFENV_VERSION=system run tfenv-version-name
  assert_success "system"
}

@test "TFENV_VERSION can be overridden by hook" {
  create_version "1.8.7"
  create_version "1.9.3"
  create_hook version-name test.bash <<<"TFENV_VERSION=1.9.3"

  TFENV_VERSION=1.8.7 run tfenv-version-name
  assert_success "1.9.3"
}

@test "carries original IFS within hooks" {
  create_hook version-name hello.bash <<SH
hellos=(\$(printf "hello\\tugly world\\nagain"))
echo HELLO="\$(printf ":%s" "\${hellos[@]}")"
SH

  export TFENV_VERSION=system
  IFS=$' \t\n' run tfenv-version-name env
  assert_success
  assert_line "HELLO=:hello:ugly:world:again"
}

@test "TFENV_VERSION has precedence over local" {
  create_version "1.8.7"
  create_version "1.9.3"

  cat > ".terraform-version" <<<"1.8.7"
  run tfenv-version-name
  assert_success "1.8.7"

  TFENV_VERSION=1.9.3 run tfenv-version-name
  assert_success "1.9.3"
}

@test "local file has precedence over global" {
  create_version "1.8.7"
  create_version "1.9.3"

  cat > "${TFENV_ROOT}/version" <<<"1.8.7"
  run tfenv-version-name
  assert_success "1.8.7"

  cat > ".terraform-version" <<<"1.9.3"
  run tfenv-version-name
  assert_success "1.9.3"
}

@test "missing version" {
  TFENV_VERSION=1.2 run tfenv-version-name
  assert_failure "tfenv: version \`1.2' is not installed (set by TFENV_VERSION environment variable)"
}

@test "version with prefix in name" {
  create_version "1.8.7"
  cat > ".terraform-version" <<<"terraform-1.8.7"
  run tfenv-version-name
  assert_success
  assert_output "1.8.7"
}
