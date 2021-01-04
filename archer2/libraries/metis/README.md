# Archer2 metis installation

## Build

From the top level directory, e.g.,
```
$ bash ./archer2/libraries/metis/build-metis.sh --prefix=/work/y07/shared
```

Both OpenMP and non-OpenMP versions are compiled and installed in the
same location.


## Module file

The template module file is `modulefile.tcl`. This is installed in a
location determined by `prefix` as part of the build:
```
${prefix}/archer2-modules/modulefiles-cse/libs/metis/${metis_version}
```
with `${metis_version}` as defined in `./archer2/versions.sh`.

The module file defines `METIS_DIR`, which can be used if wanted.
`METIS_DIR` will not respond to a change in compiler version in
a given programming environment


## Installation test

For each programming environment:

- A simple C example is compiled and run
- A simple Fortran example is compiled and run
- The stand-alone utility programs are run

The metis package does not contain any tests as such. These installation
tests will run as part of the build procedure in `build-metis.sh`.

The test will report a successful completion. If it does not, something
has failed.
