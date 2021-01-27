# SLEPCc installation

## Build

SLEPc build is via
```
$ salloc --nodes=1 --time=00:20:00 --partition=standard --qos=standard
$ bash ./archer2/libraries/slepc/build-slepc.sh --prefix=/work/y07/shared
```

Individual builds are driven by `./sh/slepc.sh`.

See comments for PETSc. SLEPc is much in the same vein.

The SLURM allocation is required for the parallel installation test.

## Module

The module file (template modulefile.tcl) expresses the various
dependencies on other modules.

The module defines `SLEPC_DIR` for the current programming environment
as the root of the installation. This can be used if wanted, but is not
necessary. The compiler wrappers will pick up the package config information.


## Installation test

The standard SLEPc `make check` is performed against the installed
version for each programming environment. For this purpose, the
`build-petsc.sh` script should be preceded by an `salloc` to allow
the tests to run. Any failures need to be investigated.


## Known issues

While PETSc can be built with AOCC, there appears to be a problem
at link time for any applications. The link does not complete in
any finite time, apparently. This needs to be investigated.

The same therefore applies to SLEPc.

An AOCC version is therefore not installed at the moment.
