# Archer2 Scotch and PT-Scotch installation

## Build

The single installation generates both serial `scotch` and parallel
`ptscotch` under the same banner of `scotch`. E.g.,
```
$ salloc --nodes=1 --time=00:30:00 --partition=standard --qos=standard
$ bash ./archer2/libraries/scotch/build-scotch.sh --prefix=/work/y07/shared
```

Note that v6 and v7 have different baseline build scripts in `./sh/tpsl/scotch.sh` and `./sh/tpsl/scotchv7.sh` respectively. The version 7 has moved to the
`cmake` build route, which has the advantage that the testing is much
easier, but the disadvantage that it doesn't handle the `libscotchmetis`
build so well (it would have to look more like the v6 build without
tests). So the `libscotchmetis` build in v7 is switched off entirely.
This prevent collisions between the scotchmetis versions and the true
metis and partmetis versions in places where both are active (e.g., PETSc).


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
