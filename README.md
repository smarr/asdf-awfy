# asdf-awfy [![Build](https://github.com/smarr/asdf-awfy/actions/workflows/build.yml/badge.svg)](https://github.com/smarr/asdf-awfy/actions/workflows/build.yml) [![Lint](https://github.com/smarr/asdf-awfy/actions/workflows/lint.yml/badge.svg)](https://github.com/smarr/asdf-awfy/actions/workflows/lint.yml)

This [asdf](https://asdf-vm.com) plugin provides access to language implementations not covered by other plugins.

# Contents

- [Dependencies](#dependencies)
- [Install](#install)
- [Contributing](#contributing)
- [License](#license)

# Dependencies


- `bash`, `curl`, `jq`, and [POSIX utilities](https://pubs.opengroup.org/onlinepubs/9699919799/idx/utilities.html)

**TODO: adapt this section**

- `bash`, `curl`, `tar`.
- `SOME_ENV_VAR`: set this environment variable in your shell config to load the correct version of tool x.

# Language Implementations

- GraalJS (native, JVM)
- GraalPy (JVM)

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

# License

See [LICENSE](LICENSE) © [Stefan Marr](https://github.com/smarr/)
