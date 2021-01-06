# HYPRE installation

## Build

Installation is via, e.g.,

```
$ salloc --nodes=1 --time=00:30:00 --partition=standard --qos=standard 
$ bash ./archer2/libraries/hypre/build-hypre.sh --prefix=/work/y07/shared
```

## Module

The HYPRE module has no additional dependencies, and the module template
is `modulefile.tcl`

The module defines `HYPRE_DIR` which can be used if needed. `HYPRE_DIR`
is not volatile if the compiler version is swapped.


## Installation test

On successfull installation, the `build-hypre.sh` script compiles and
runs the standard HYPRE tests found in `hypre-${version}/src/examples`
by compiling against the module installation.

An `salloc` allocation is required for the tests to be executed.

The HYPRE test system is a little difficult to follow. A much larger
set of regression tests exists.


