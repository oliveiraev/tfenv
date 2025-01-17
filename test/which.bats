#!/usr/bin/env bats

load test_helper

create_executable() {
  local bin
  if [[ $1 == */* ]]; then bin="$1"
  else bin="${TFENV_ROOT}/versions/${1}/bin"
  fi
  mkdir -p "$bin"
  touch "${bin}/$2"
  chmod +x "${bin}/$2"
}

@test "outputs path to executable" {
  create_executable "1.8" "terraform"
  create_executable "2.0" "rspec"

  TFENV_VERSION=1.8 run tfenv-which terraform
  assert_success "${TFENV_ROOT}/versions/1.8/bin/terraform"

  TFENV_VERSION=2.0 run tfenv-which rspec
  assert_success "${TFENV_ROOT}/versions/2.0/bin/rspec"
}

@test "searches PATH for system version" {
  create_executable "${TFENV_TEST_DIR}/bin" "kill-all-humans"
  create_executable "${TFENV_ROOT}/shims" "kill-all-humans"

  TFENV_VERSION=system run tfenv-which kill-all-humans
  assert_success "${TFENV_TEST_DIR}/bin/kill-all-humans"
}

@test "searches PATH for system version (shims prepended)" {
  create_executable "${TFENV_TEST_DIR}/bin" "kill-all-humans"
  create_executable "${TFENV_ROOT}/shims" "kill-all-humans"

  PATH="${TFENV_ROOT}/shims:$PATH" TFENV_VERSION=system run tfenv-which kill-all-humans
  assert_success "${TFENV_TEST_DIR}/bin/kill-all-humans"
}

@test "searches PATH for system version (shims appended)" {
  create_executable "${TFENV_TEST_DIR}/bin" "kill-all-humans"
  create_executable "${TFENV_ROOT}/shims" "kill-all-humans"

  PATH="$PATH:${TFENV_ROOT}/shims" TFENV_VERSION=system run tfenv-which kill-all-humans
  assert_success "${TFENV_TEST_DIR}/bin/kill-all-humans"
}

@test "searches PATH for system version (shims spread)" {
  create_executable "${TFENV_TEST_DIR}/bin" "kill-all-humans"
  create_executable "${TFENV_ROOT}/shims" "kill-all-humans"

  PATH="${TFENV_ROOT}/shims:${TFENV_ROOT}/shims:/tmp/non-existent:$PATH:${TFENV_ROOT}/shims" \
    TFENV_VERSION=system run tfenv-which kill-all-humans
  assert_success "${TFENV_TEST_DIR}/bin/kill-all-humans"
}

@test "doesn't include current directory in PATH search" {
  mkdir -p "$TFENV_TEST_DIR"
  cd "$TFENV_TEST_DIR"
  touch kill-all-humans
  chmod +x kill-all-humans
  PATH="$(path_without "kill-all-humans")" TFENV_VERSION=system run tfenv-which kill-all-humans
  assert_failure "tfenv: kill-all-humans: command not found"
}

@test "version not installed" {
  create_executable "2.0" "rspec"
  TFENV_VERSION=1.9 run tfenv-which rspec
  assert_failure "tfenv: version \`1.9' is not installed (set by TFENV_VERSION environment variable)"
}

@test "no executable found" {
  create_executable "1.8" "rspec"
  TFENV_VERSION=1.8 run tfenv-which rake
  assert_failure "tfenv: rake: command not found"
}

@test "no executable found for system version" {
  PATH="$(path_without "rake")" TFENV_VERSION=system run tfenv-which rake
  assert_failure "tfenv: rake: command not found"
}

@test "executable found in other versions" {
  create_executable "1.8" "terraform"
  create_executable "1.9" "rspec"
  create_executable "2.0" "rspec"

  TFENV_VERSION=1.8 run tfenv-which rspec
  assert_failure
  assert_output <<OUT
tfenv: rspec: command not found

The \`rspec' command exists in these Terraform versions:
  1.9
  2.0
OUT
}

@test "carries original IFS within hooks" {
  create_hook which hello.bash <<SH
hellos=(\$(printf "hello\\tugly world\\nagain"))
echo HELLO="\$(printf ":%s" "\${hellos[@]}")"
exit
SH

  IFS=$' \t\n' TFENV_VERSION=system run tfenv-which anything
  assert_success
  assert_output "HELLO=:hello:ugly:world:again"
}

@test "discovers version from tfenv-version-name" {
  mkdir -p "$TFENV_ROOT"
  cat > "${TFENV_ROOT}/version" <<<"1.8"
  create_executable "1.8" "terraform"

  mkdir -p "$TFENV_TEST_DIR"
  cd "$TFENV_TEST_DIR"

  TFENV_VERSION='' run tfenv-which terraform
  assert_success "${TFENV_ROOT}/versions/1.8/bin/terraform"
}
