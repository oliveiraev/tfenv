#!/usr/bin/env bats

load test_helper

setup() {
  mkdir -p "${TFENV_TEST_DIR}/myproject"
  cd "${TFENV_TEST_DIR}/myproject"
}

@test "fails without arguments" {
  run tfenv-version-file-read
  assert_failure ""
}

@test "fails for invalid file" {
  run tfenv-version-file-read "non-existent"
  assert_failure ""
}

@test "fails for blank file" {
  echo > my-version
  run tfenv-version-file-read my-version
  assert_failure ""
}

@test "reads simple version file" {
  cat > my-version <<<"1.9.3"
  run tfenv-version-file-read my-version
  assert_success "1.9.3"
}

@test "ignores leading spaces" {
  cat > my-version <<<"  1.9.3"
  run tfenv-version-file-read my-version
  assert_success "1.9.3"
}

@test "reads only the first word from file" {
  cat > my-version <<<"1.9.3-p194@tag 1.8.7 hi"
  run tfenv-version-file-read my-version
  assert_success "1.9.3-p194@tag"
}

@test "loads only the first line in file" {
  cat > my-version <<IN
1.8.7 one
1.9.3 two
IN
  run tfenv-version-file-read my-version
  assert_success "1.8.7"
}

@test "ignores leading blank lines" {
  cat > my-version <<IN

1.9.3
IN
  run tfenv-version-file-read my-version
  assert_success "1.9.3"
}

@test "handles the file with no trailing newline" {
  echo -n "1.8.7" > my-version
  run tfenv-version-file-read my-version
  assert_success "1.8.7"
}

@test "ignores carriage returns" {
  cat > my-version <<< $'1.9.3\r'
  run tfenv-version-file-read my-version
  assert_success "1.9.3"
}

@test "prevents directory traversal" {
  cat > my-version <<<".."
  run tfenv-version-file-read my-version
  assert_failure "tfenv: invalid version in \`my-version'"

  cat > my-version <<<"../foo"
  run tfenv-version-file-read my-version
  assert_failure "tfenv: invalid version in \`my-version'"
}

@test "disallows path segments in version string" {
  cat > my-version <<<"foo/bar"
  run tfenv-version-file-read my-version
  assert_failure "tfenv: invalid version in \`my-version'"
}
