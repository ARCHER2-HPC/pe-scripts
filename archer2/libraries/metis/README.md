# Archer2 metis installation

## Build

From the top level directory, e.g.,
```
$ bash ./archer2/libraries/metis/metis-build.sh --prefix=/work/y07/shared
```

The current version is set in `./archer2/versions.sh`.

## Module file

The template module file is `modulefile.tcl`. This is installed in a
location determined by `prefix` as part of the build.

## Installation test

For each programming environment:

- The stand-alone utility programs are run
- A simple C example is compiled and run
- A simple Fortran example is compiled and run

The metis package does not contain any tests as such. These installation
tests will run as part of the build procedure.

The test will report a successful completion.
