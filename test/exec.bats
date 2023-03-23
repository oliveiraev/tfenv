#!/usr/bin/env bats

load test_helper

create_executable() {
  name="${1?}"
  shift 1
  bin="${TFENV_ROOT}/versions/${TFENV_VERSION}/bin"
  mkdir -p "$bin"
  { if [ $# -eq 0 ]; then cat -
    else echo "$@"
    fi
  } | sed -Ee '1s/^ +//' > "${bin}/$name"
  chmod +x "${bin}/$name"
}

@test "fails with invalid version" {
  export TFENV_VERSION="2.0"
  run tfenv-exec terraform -v
  assert_failure "tfenv: version \`2.0' is not installed (set by TFENV_VERSION environment variable)"
}

@test "fails with invalid version set from file" {
  mkdir -p "$TFENV_TEST_DIR"
  cd "$TFENV_TEST_DIR"
  echo 1.9 > .terraform-version
  run tfenv-exec rspec
  assert_failure "tfenv: version \`1.9' is not installed (set by $PWD/.terraform-version)"
}

@test "completes with names of executables" {
  export TFENV_VERSION="2.0"
  create_executable "terraform" "#!/bin/sh"
  create_executable "rake" "#!/bin/sh"

  tfenv-rehash
  run tfenv-completions exec
  assert_success
  assert_output <<OUT
--help
rake
terraform
OUT
}

@test "carries original IFS within hooks" {
  create_hook exec hello.bash <<SH
hellos=(\$(printf "hello\\tugly world\\nagain"))
echo HELLO="\$(printf ":%s" "\${hellos[@]}")"
SH

  export TFENV_VERSION=system
  IFS=$' \t\n' run tfenv-exec env
  assert_success
  assert_line "HELLO=:hello:ugly:world:again"
}

@test "forwards all arguments" {
  export TFENV_VERSION="2.0"
  create_executable "terraform" <<SH
#!$BASH
echo \$0
for arg; do
  # hack to avoid bash builtin echo which can't output '-e'
  printf "  %s\\n" "\$arg"
done
SH

  run tfenv-exec terraform -w "/path to/terraform script.rb" -- extra args
  assert_success
  assert_output <<OUT
${TFENV_ROOT}/versions/2.0/bin/terraform
  -w
  /path to/terraform script.rb
  --
  extra
  args
OUT
}

@test "supports terraform -S <cmd>" {
  export TFENV_VERSION="2.0"

  # emulate `terraform -S' behavior
  create_executable "terraform" <<SH
#!$BASH
if [[ \$1 == "-S"* ]]; then
  found="\$(PATH="\${TERRAFORMPATH:-\$PATH}" which \$2)"
  # assert that the found executable has terraform for shebang
  if head -n1 "\$found" | grep terraform >/dev/null; then
    \$BASH "\$found"
  else
    echo "terraform: no Terraform script found in input (LoadError)" >&2
    exit 1
  fi
else
  echo 'terraform 2.0 (tfenv test)'
fi
SH

  create_executable "rake" <<SH
#!/usr/bin/env terraform
echo hello rake
SH

  tfenv-rehash
  run terraform -S rake
  assert_success "hello rake"
}
