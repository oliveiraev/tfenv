#!/usr/bin/env bats

load test_helper

@test "without args shows summary of common commands" {
  run tfenv-help
  assert_success
  assert_line "Usage: tfenv <command> [<args>...]"
  assert_line "Some useful tfenv commands are:"
}

@test "usage flag" {
  run tfenv-help --usage
  assert_success
  assert_output "Usage: tfenv <command> [<args>...]"
}

@test "invalid command" {
  run tfenv-help hello
  assert_failure "tfenv: no such command \`hello'"
}

@test "shows help for a specific command" {
  mkdir -p "${TFENV_TEST_DIR}/bin"
  cat > "${TFENV_TEST_DIR}/bin/tfenv-hello" <<SH
#!shebang
# Usage: tfenv hello <world>
# Summary: Says "hello" to you, from tfenv
# This command is useful for saying hello.
echo hello
SH

  run tfenv-help hello
  assert_success
  assert_output <<SH
Usage: tfenv hello <world>

This command is useful for saying hello.
SH
}

@test "replaces missing extended help with summary text" {
  mkdir -p "${TFENV_TEST_DIR}/bin"
  cat > "${TFENV_TEST_DIR}/bin/tfenv-hello" <<SH
#!shebang
# Usage: tfenv hello <world>
# Summary: Says "hello" to you, from tfenv
echo hello
SH

  run tfenv-help hello
  assert_success
  assert_output <<SH
Usage: tfenv hello <world>

Says "hello" to you, from tfenv
SH
}

@test "extracts only usage" {
  mkdir -p "${TFENV_TEST_DIR}/bin"
  cat > "${TFENV_TEST_DIR}/bin/tfenv-hello" <<SH
#!shebang
# Usage: tfenv hello <world>
# Summary: Says "hello" to you, from tfenv
# This extended help won't be shown.
echo hello
SH

  run tfenv-help --usage hello
  assert_success "Usage: tfenv hello <world>"
}

@test "multiline usage section" {
  mkdir -p "${TFENV_TEST_DIR}/bin"
  cat > "${TFENV_TEST_DIR}/bin/tfenv-hello" <<SH
#!shebang
# Usage: tfenv hello <world>
#        tfenv hi [everybody]
#        tfenv hola --translate
# Summary: Says "hello" to you, from tfenv
# Help text.
echo hello
SH

  run tfenv-help hello
  assert_success
  assert_output <<SH
Usage: tfenv hello <world>
       tfenv hi [everybody]
       tfenv hola --translate

Help text.
SH
}

@test "multiline extended help section" {
  mkdir -p "${TFENV_TEST_DIR}/bin"
  cat > "${TFENV_TEST_DIR}/bin/tfenv-hello" <<SH
#!shebang
# Usage: tfenv hello <world>
# Summary: Says "hello" to you, from tfenv
# This is extended help text.
# It can contain multiple lines.
#
# And paragraphs.

echo hello
SH

  run tfenv-help hello
  assert_success
  assert_output <<SH
Usage: tfenv hello <world>

This is extended help text.
It can contain multiple lines.

And paragraphs.
SH
}
