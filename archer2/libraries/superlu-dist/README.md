# Archer2 SuperLU_DIST installation

## Build

From the top level, e.g.,
```
$ bash ./archer2/libraries/superlu-dist/build-superlu-dist.sh --prefix=/work/y07/shared
```

## Module file

The module automatically loads the relevant `parmetis` module and
declares a dependency via `PE_PARMETIS`.

The module prepends, amongst other path variables:
```
SUPERLU_DIST_DIR      base of the installation for this PE/COMPILER
CSE_LD_LIBRARY_PATH   ${SUPERLU_DIST_DIR}/lib
```

Note that the module file is `superlu-dist` (not `superlu_dist`). However,
the package config file is `superlu_dist.pc`.


## Installation test

An installation test is performed by using the examples provided
in `./EXAMPLE` and `./FORTRAN`. These are compiled against the
installed module, and run in serial. The installation test is
automatically run by the build script.
