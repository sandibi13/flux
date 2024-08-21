# Flux

A package manager wrapper for DNF and Flatpak.

### Usage

```
USAGE: flux [function] {flag} <input>

functions:
    install: Install package(s) - Prompts user to respond with
             the number(s) associated with the desired package(s).

    remove:  Uninstall package(s) - Prompts user to respond with
             the number(s) associated with the desired package(s).

    search:  Search for package(s) - Does not have a second prompt.

    update:  Updates all packages accessible to the wrapper - does
             not accept <input>, instead use install to update
             individual packages. Has a confirmation prompt.

    cleanup: Attempts to repair broken dependencies and remove any
             unused packages. Does not accept <input>, but has
             a confirmation prompt.

flags:
    --help/-h: Display this page

    --description/-d: By default, flux will only display packages
    that contain <input> within their name. Use this flag to increase
    range and display packages with <input> in their description.

    -y: Makes functions with confirmation prompts run promptless.

input:
    Provide a package name or description.

Example execution:
    $ flux install foobar
    Found packages matching 'foobar':

    [0]: pyfoobar (dnf)
    [1]: foobarshell (dnf)
    [2]: foobar (flatpak)

    Select which package to install [0-2]: 0 1 2
    Selecting 'pyfoobar' from package manager 'dnf'
    Selecting 'foobarshell' from package manager 'dnf'
    Selecting 'foobar' from package manager 'flatpak'
    Are you sure? (y/N)
    [...]
```

### Contribute

Contributions are welcome! Whether it's fixing bugs, adding features, or improving documentation, your help is appreciated. Just fork the repo, create a branch, and submit a pull request. Feel free to open an issue if you find any problems or have suggestions.

### Acknowledgements

Flux is inspired by [rhino-pkg](https://github.com/rhino-linux/rhino-pkg). Special thanks to the contributors of [rhino-pkg](https://github.com/rhino-linux/rhino-pkg) for their work!
