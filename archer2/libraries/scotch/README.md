# Archer2 Scotch and PT-Scotch installation

## Build

The single installation generates both serial `scotch` and parallel `ptscotch` under
the same banner of `scotch`. E.g.,
```
$ bash ./archer2/libraries/scotch/build-scotch.sh --prefix=/work/y07/shared
```

## Module

The module template is `modulefile.tcl` which does not need to load any
other modules as `scotch` doesn't depend on any.

The module defines, amongst other things, `SCOTCH_DIR` when loaded, which
will be relevant to the current programming environment. The value of
this variable will not, however, reflect any subsequent change in compiler
version.

## Installation tests

The `build-scotch.sh` script checks programs in `scotch_${version}/src/check`, which are
compiled aaginst the module version of `scotch` just generated. These consist of both
serial (`make check`) and parallel (`make ptcheck`) tests.

The `make ptcheck` requires an `salloc` allocation, or else it will be skipped.

## Known issues

The shared objects cause a number of problems a run time, and so are not provided
as part of the module; only the static libraries are available.

Two `make ptcheck` tests are broken. This requires further investigation.
