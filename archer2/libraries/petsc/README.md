# PETSc installation

## Build

PETSc build is via
```
$ salloc --nodes=1 --time=00:20:00 --partition=standard --qos=standard
$ bash ./archer2/libraries/petsc/build-petsc.sh --prefix=/work/y07/shared
```

Individual builds are driven by `./sh/petsc.sh`.

As the PETSc installation is a little more complex than some of
its dependencies, I have not tried to integrate OpenMP and non-OpenMP
versions with the compiler machinery. Only the OpenMP version is
built with static libraries; as PETSc installs its own package
config file, this is used as the basis of the final package config
file.


## Module

The module file (template modulefile.tcl) expresses the various
dependencies on other modules.

The module defines `PETSC_DIR` for the current programming environment
as the root of the installation. This can be used if wanted, but is not
necessary. The compiler wrappers will pick up the package config information.


## Installation test

The standard PETSc `make check` is performed against the installed
version for each programming environment. For this purpose, the
`build-petsc.sh` script should be preceded by an `salloc` to allow
the tests to run. Any failures need to be investigated.


## Known issues

While PETSc can be built with AOCC, there appears to be a problem
at link time for any applications. The link does not complete in
any finite time, apparently. This needs to be investigated.

The AOCC version is therefore not installed at the moment.
