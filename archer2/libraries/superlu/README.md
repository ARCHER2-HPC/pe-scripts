# Archer2 SuperLU installation

## Build

From the top-level directory
```
$ bash ./archer2/libraries/superlu/superlu-build.sh --prefix=/work/y07/shared
```

builds the serial version of SuperLU. There are no additional
dependencies required.

As the standard SuperLU tests are quick, these are run after the
compilation in each case.

The module defines `SUPERLU_DIR` as the root of the installation
for each programming environment.

## Module file

The template module file is `./modulefile.tcl`.
Note that SuperLU has no relevant OpenMP version here.

## Installation test

For each programming environment, standard C exmaples from
the `EXAMPLES` subdirectory of the distribution are compiled
against the installed module using an adjusted Makefile, and run.

Standard Fortran examples from the `FORTRAN` subdirectory of
the distribution are also compiled and run.
