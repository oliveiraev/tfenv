#!/usr/bin/env bats

load test_helper

export GIT_DIR="${TFENV_TEST_DIR}/.git"

setup() {
  mkdir -p "$HOME"
  git config --global user.name  "Tester"
  git config --global user.email "tester@test.local"
  cd "$TFENV_TEST_DIR"
}

git_commit() {
  git commit --quiet --allow-empty -m "empty"
}

@test "default version" {
  assert [ ! -e "$TFENV_ROOT" ]
  run tfenv---version
  assert_success
  [[ $output == "tfenv "?.?.? ]]
}

@test "doesn't read version from non-tfenv repo" {
  git init
  git remote add origin https://github.com/homebrew/homebrew.git
  git_commit
  git tag v1.0

  run tfenv---version
  assert_success
  [[ $output == "tfenv "?.?.? ]]
}

@test "reads version from git repo" {
  git init
  git remote add origin https://github.com/tfenv/tfenv.git
  git_commit
  git tag v0.4.1
  git_commit
  git_commit

  run tfenv---version
  assert_success "tfenv 0.4.1-2-g$(git rev-parse --short HEAD)"
}

@test "prints default version if no tags in git repo" {
  git init
  git remote add origin https://github.com/tfenv/tfenv.git
  git_commit

  run tfenv---version
  [[ $output == "tfenv "?.?.? ]]
}
