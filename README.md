# Seamlessly manage your app’s Terraform environment with tfenv.

tfenv is a version manager tool for Terraform on Unix-like systems. It is useful for switching between multiple Terraform versions on the same machine and for ensuring that each project you are working on always runs on the correct Terraform version.

## How It Works

After tfenv injects itself into your PATH at installation time, any invocation of `terraform` or other Terraform-related executable will first activate tfenv. Then, tfenv scans the current project directory for a file named `.terraform-version`. If found, that file determines the version of Terraform that should be used within that directory. Finally, tfenv looks up that Terraform version among those installed under `~/.tfenv/versions/`.

You can choose the Terraform version for your project with, for example:
```sh
cd myproject
# choose Terraform version 1.4.2:
tfenv local 1.4.2
```

Doing so will create or update the `.terraform-version` file in the current directory with the version that you've chosen. A different project of yours that is another directory might be using a different version of Terraform altogether—tfenv will seamlessly transition from one Terraform version to another when you switch projects.

Finally, almost every aspect of tfenv's mechanism is plugins written in bash.

## Installation

### Basic Git Checkout

This will get you going with the latest version of tfenv without needing a system-wide install.

1. Clone tfenv into `~/.tfenv`.

    ```sh
    git clone https://github.com/oliveiraev/tfenv.git ~/.tfenv
    ```

2. Configure your shell to load tfenv:

   * For **bash**:
     
     _Ubuntu Desktop_ users should configure `~/.bashrc`:
     ```bash
     echo 'eval "$(~/.tfenv/bin/tfenv init - bash)"' >> ~/.bashrc
     ```

     On _other platforms_, bash is usually configured via `~/.bash_profile`:
     ```bash
     echo 'eval "$(~/.tfenv/bin/tfenv init - bash)"' >> ~/.bash_profile
     ```
     
   * For **Zsh**:
     ```zsh
     echo 'eval "$(~/.tfenv/bin/tfenv init - zsh)"' >> ~/.zshrc
     ```
   
   * For **Fish shell**:
     ```fish
     echo 'status --is-interactive; and ~/.tfenv/bin/tfenv init - fish | source' >> ~/.config/fish/config.fish
     ```

   If you are curious, see here to [understand what `init` does](#how-tfenv-hooks-into-your-shell).

3. Restart your shell so that these changes take effect. (Opening a new terminal tab will usually do it.)

### Installing Terraform versions

You can download Terraform manually as a subdirectory of `~/.tfenv/versions`. An entry in that directory can also be a symlink to a Terraform version installed elsewhere on the filesystem.

#### Uninstalling Terraform versions

As time goes on, Terraform versions you install will accumulate in your `~/.tfenv/versions` directory.

To remove old Terraform versions, simply `rm -rf` the directory of the version you want to remove. You can find the directory of a particular Terraform version with the `tfenv prefix` command, e.g. `tfenv prefix 0.15.5`.

## Command Reference

The main tfenv commands you need to know are:

### tfenv versions

Lists all Terraform versions known to tfenv, and shows an asterisk next to the currently active version.

    $ tfenv versions
      1.4.2
      0.15.5
    * 0.13.7 (set by /Users/oliveiraev/.tfenv/version)

### tfenv version

Displays the currently active Terraform version, along with information on how it was set.

    $ tfenv version
    1.4.2 (set by /Users/oliveiraev/.tfenv/version)

### tfenv local

Sets a local application-specific Terraform version by writing the version name to a `.terraform-version` file in the current directory. This version overrides the global version, and can be overridden itself by setting the `TFENV_VERSION` environment variable or with the `tfenv shell` command.

    tfenv local 0.14.11

When run without a version number, `tfenv local` reports the currently configured local version. You can also unset the local version:

    tfenv local --unset

### tfenv global

Sets the global version of Terraform to be used in all shells by writing the version name to the `~/.tfenv/version` file. This version can be overridden by an application-specific `.terraform-version` file, or by setting the `TFENV_VERSION` environment variable.

    tfenv global 1.3.9

The special version name `system` tells tfenv to use the system Terraform (detected by searching your `$PATH`).

When run without a version number, `tfenv global` reports the currently configured global version.

### tfenv shell

Sets a shell-specific Terraform version by setting the `TFENV_VERSION` environment variable in your shell. This version overrides application-specific versions and the global version.

    tfenv shell 1.2.9

When run without a version number, `tfenv shell` reports the current value of `TFENV_VERSION`. You can also unset the shell version:

    tfenv shell --unset

Note that you'll need tfenv's shell integration enabled (step 3 of the installation instructions) in order to use this command. If you prefer not to use shell integration, you may simply set the `TFENV_VERSION` variable yourself:

    export TFENV_VERSION=0.12.31

### tfenv rehash

Installs shims for all Terraform executables known to tfenv (`~/.tfenv/versions/*/bin/*`). Typically you do not need to run this command, as it will run automatically after installing gems.

    tfenv rehash

## Environment variables

You can affect how tfenv operates with the following settings:

| name              | default    | description                                                                                     |
|-------------------|------------|-------------------------------------------------------------------------------------------------|
| `TFENV_VERSION`   |            | Specifies the Terraform version to be used.<br>Also see [`tfenv shell`](#tfenv-shell)           |
| `TFENV_ROOT`      | `~/.tfenv` | Defines the directory under which Terraform versions and shims reside.<br>Also see `tfenv root` |
| `TFENV_DEBUG`     |            | Outputs debug information.<br>Also as: `tfenv --debug <subcommand>`                             |
| `TFENV_HOOK_PATH` | hooks      | Colon-separated list of paths searched for tfenv hooks.                                         |
| `TFENV_DIR`       | `$PWD`     | Directory to start searching for `.terraform-version` files.                                    |

### How tfenv hooks into your shell

`tfenv init` is a helper command to bootstrap tfenv into a shell. This helper is part of the recommended installation instructions, but optional, as an advanced user can set up the following tasks manually. Here is what the command does when its output is `eval`'d:

1. Adds `tfenv` executable to PATH if necessary.

2. Prepends `~/.tfenv/shims` directory to PATH. This is basically the only requirement for tfenv to function properly.

3. Installs shell completion for tfenv commands.

4. Regenerates tfenv shims. If this step slows down your shell startup, you can invoke `tfenv init -` with the `--no-rehash` flag.

5. Installs the "sh" dispatcher. This bit is also optional, but allows tfenv and plugins to change variables in your current shell, making commands like `tfenv shell` possible.

You can run `tfenv init -` for yourself to inspect the generated script.

### Uninstalling tfenv

The simplicity of tfenv makes it easy to temporarily disable it, or uninstall from the system.

1. To **disable** tfenv managing your Terraform versions, simply comment or remove the `tfenv init` line from your shell startup configuration. This will remove tfenv shims directory from PATH, and future invocations like `terraform` will execute the system Terraform version, bypassing tfenv completely.

   While disabled, `tfenv` will still be accessible on the command line, but your Terraform apps won't be affected by version switching.

2. To completely **uninstall** tfenv, perform step (1) and then remove the tfenv root directory. This will **delete all Terraform versions** that were installed under `` `tfenv root`/versions/ ``:

       rm -rf "$(tfenv root)"

## Development

Tests are executed using [Bats](https://github.com/sstephenson/bats):

    $ bats test
    $ bats test/<file>.bats

Please feel free to submit pull requests and file bugs on the [issue tracker](https://github.com/oliveiraev/tfenv/issues).
