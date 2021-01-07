# Matio

## Build

The Matio utility is entirely serial, so a single serial
build per programming environment is appropriate:
```
$ bash ./archer2/libraries/matio/build-matio.sh --prefix=/work/y07/shared
```

Do not be tempted to try to configure Matio with `cray-hdf5`. This
may collide with `cray-hdf5-parallel` soemwhere down the line.

## Module

The module (template `modulefile.tcl`) links the pkg-config
file with the compiler wrappers. Only static archives are
built.

Environment variables `PATH` and `MANPATH` are also relevant.


## Installation test

The full Matio test suite is not easy to run against the installed
version (it's also a tad long), so a short test of compile/link
options is performed. The presence of the utility `matdump` in
`PATH` is checked.

