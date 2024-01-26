<div align="center">

# asdf-awfy [![Build](https://github.com/smarr/asdf-awfy/actions/workflows/build.yml/badge.svg)](https://github.com/smarr/asdf-awfy/actions/workflows/build.yml) [![Lint](https://github.com/smarr/asdf-awfy/actions/workflows/lint.yml/badge.svg)](https://github.com/smarr/asdf-awfy/actions/workflows/lint.yml)

[awfy](https://github.com/smarr/are-we-fast-yet) plugin for the [asdf version manager](https://asdf-vm.com).

</div>

# Contents

- [Dependencies](#dependencies)
- [Install](#install)
- [Contributing](#contributing)
- [License](#license)

# Dependencies

**TODO: adapt this section**

- `bash`, `curl`, `tar`, and [POSIX utilities](https://pubs.opengroup.org/onlinepubs/9699919799/idx/utilities.html).
- `SOME_ENV_VAR`: set this environment variable in your shell config to load the correct version of tool x.

# Install

Plugin:

```shell
asdf plugin add awfy
# or
asdf plugin add awfy https://github.com/smarr/asdf-awfy.git
```

awfy:

```shell
# Show all installable versions
asdf list-all awfy

# Install specific version
asdf install awfy latest

# Set a version globally (on your ~/.tool-versions file)
asdf global awfy latest

# Now awfy commands are available
awfy --version
```

Check [asdf](https://github.com/asdf-vm/asdf) readme for more instructions on how to
install & manage versions.

# Contributing

Contributions of any kind welcome! See the [contributing guide](contributing.md).

[Thanks goes to these contributors](https://github.com/smarr/asdf-awfy/graphs/contributors)!

# License

See [LICENSE](LICENSE) © [Stefan Marr](https://github.com/smarr/)
