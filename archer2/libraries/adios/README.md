# Archer2 Adios (v1) installation

## Build

The build is via
```
$ bash ./archer2/libraries/adios/build-adios.sh --prefix=/work/y07/shared

which builds the package in three programming environment. As standard,
adios provides its own MPI and non-MPI libraries.

The build stage runs a small selection of (serial) tests by default.

## Modulefile

The module file with template `./modulefile.tcl` in installed at
```
${prefix}/archer2-modules/modulesfiles-cse-libs/adios/${adios_version}
```

with `${adios_version} determined as in `./archer2/versions.sh`. As
adios provides its own package configuration mechanism, there is no
attempt at automatic integration with the compiler wrappers.

The module defines `ADIOS_DIR` and prepends `ADIOS_DIR/bin` to `PATH`
so that the configuration utility `adios_config` can be run once the
module is loaded.


## Installation test

The `build-adios.sh` scripts performs an installation test which is
a cut down version of the serial build-time tests performed against the
installed version. This uses `Makefile.nompi` which uses `adios_config`
to identify relevant options.

Some further parallel tests would be desirable. (Just haven't reached
that far yet.)

