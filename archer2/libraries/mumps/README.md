# Mumps installation

## Build

The Mumps package is installed via, e.g.,
```
$ bash ./archer2/libraries/mumps/build-mumps.sh --prefix=/work/y07/shared
```

Versions are build with and without OpenMP for three programming
environments.

## Module

Mumps is dependent on `parmetis` (and `metis`) and `scotch`, and apprpropriate
versions of these modules are loaded by the `mumps` module. The template
module file is: `modulefile.tcl`

The module file defines `MUMPS_DIR` which is appropriate for the
current programming environment. However, `MUMPS_DIR` will not
reflect any subsequent change in compiler version (without
unloading and re-loading).

## Installation test

On succesfull install, the `build-mumps.sh` script compiles and runs
the examples in `MUMPS_${version}/exmaples` with a doctored `Makefile`.
The build is against the module installed version.

All the tests are compiled, but will require an `salloc` allocation
to run (or else they will be skipped).

### Known issues

The AOCC OpenMP build is problematic. Almost all the test problems
deadlock (other PrgEnvs ok). OpenMP is therefore "disabled" for AOCC
by taking it out of the top level package config file.

