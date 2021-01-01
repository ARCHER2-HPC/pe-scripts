# HYPRE installation

## Build

Installation is via, e.g.,

```
$ bash ./archer2/libraries/hypre/build-hypre.sh --prefix=/work/y07/shared
```

## Module

The HYPRE module has no additional dependencies, and the module template
is `modulefile.tcl`

The module defines `HYPRE_DIR` which can be used if needed. `HYPRE_DIR`
is not volatile if the compiler version is swapped.


## Installation test

On successfull installation, the `build-hypre.sh` script compiles and
runs the standard HYPRE tests found in `hypre-${version}/src/test`
by comiling against the module installation.

Pending: the tests are compiled by not run.

