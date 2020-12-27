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

## Module file

The template module file is `./modulefile.tcl`.
Note that SuperLU has no relevant OpenMP version here.

## Installation test

For each programming environment, a simple example program is
compiled against the module that has just be installed (and
the program is run).
