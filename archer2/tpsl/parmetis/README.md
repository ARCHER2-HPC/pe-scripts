# Archer2 parmetis installation

## Build

From the top level directory

```
$ bash ./archer2/libraries/parmetis/parmetis-build.sh --prefix=/work/y07/shared
```

Parmetis depends on metis, which must be installed first. The build
script will automatically load the metis module.

## Module file

The module file template is `./modulefile.tcl`

## Installation test

The intallation test will be run automatically at the end of the build
process (provided successful). The installation test incliudes:

- Compilation of a simple C example
- If a batch allocation is available (e.g., via `salloc`), the example will
  be run.


