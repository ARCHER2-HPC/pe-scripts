# Archer2 parmetis installation

## Build

From the top level directory

```
$ salloc --nodes=1 --exclusive --time=00:10:00 --partition=standard --qos=standard
$ bash ./archer2/libraries/parmetis/parmetis-build.sh --prefix=/work/y07/shared
```

Parmetis depends on metis, which must be installed first. The build
script will automatically load the metis module.

The `salloc` allows parallel executables to be run as part of the
installation test.

## Module file

The module file template is `./modulefile.tcl` will be installed at, e.g.,
```
/work/y07/shared/archer2-modules/modulefiles-cse-libs/parmetis/${version}
```
with `version` as set in `./archer2/versions.sh`. 

The module defines `PARMETIS_DIR` as the root of the installation
for the current prgrogramming environment.

## Installation test

The intallation test will be run automatically at the end of the build
process (provided successful). The installation test incliudes:

- Compilation of a simple C example
- If a batch allocation is available (e.g., via `salloc`), the example will
  be run.

Parmetis doesn't supply any tests of its own (per se).
