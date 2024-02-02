# asdf-awfy [![Build](https://github.com/smarr/asdf-awfy/actions/workflows/build.yml/badge.svg)](https://github.com/smarr/asdf-awfy/actions/workflows/build.yml) [![Lint](https://github.com/smarr/asdf-awfy/actions/workflows/lint.yml/badge.svg)](https://github.com/smarr/asdf-awfy/actions/workflows/lint.yml)

This [asdf](https://asdf-vm.com) plugin provides access to language implementations not covered by other plugins.

# Dependencies

- `bash`, `curl`, `jq`, and [POSIX utilities](https://pubs.opengroup.org/onlinepubs/9699919799/idx/utilities.html)

# Language Implementations

- [GraalJS](https://github.com/oracle/graaljs/) (native, JVM)
- [GraalPy](https://github.com/oracle/graalpython/) (JVM)
- [Pharo](https://pharo.org/)
- [Squeak/Smalltalk](https://squeak.org/)

# Install

Plugin:

```shell
asdf plugin add awfy https://github.com/smarr/asdf-awfy.git
```

awfy:

```shell
# Show all installable versions
asdf list all awfy

# Install latest Graal.js
asdf install awfy latest:graaljs
```

Check [asdf](https://github.com/asdf-vm/asdf) readme for more instructions on how to install & manage versions.

# License

See [LICENSE](LICENSE) © [Stefan Marr](https://github.com/smarr/)
