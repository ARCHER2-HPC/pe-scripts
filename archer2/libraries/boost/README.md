# Archer2 Boost installation

## Boost tests

The Boost tests take a significant amount of effort, and it is
suggested that tests should be run as a preliminary step for
each programming environment after a build has been completed.
A batch job is required:
```
cd boost_1_72_0/status
../b2 -j 32
```
Submit a batch job for one hour.


## Build

A single build for each programming environment/compiler is driven
by
```
$ ./archer2/libraries/boost/build-boost.sj --prefix=/work/y07/shared
```
Individual builds are via
```
$ ./sh/boost.sh
```

Boost installs both static and shared libraries; at the moment the
shared versions are removed so no link time problems occur.

The top-level `pkg-config` file expresses the dependencies between
the various libraries via the order of the requirements
(currently determined by hand).

## Module

For Boost, the module sets only `PE_CXX_PKGCONFIG_LIBS` so that only
the CC wrapper picks up the Boost stuff. (Fortran would need a
separate package config file.) Anyone rash enough to try linking
with anything other than `CC` will need to do it by hand.

The template modulefile `modulefile.tcl` defines `BOOST_DIR`.
There are no dependencies on other modules.

## Installation test

A limited installation test is performed by compiling a small
sellection of Boost examples against the installed module.

An `salloc` allocation is required to allow the parallel examples
to be run. There is no atempt by the `build-boost.sh` to run the
full Boost tests.

## Known issues

There is a known issue with some of the `coroutine` headers in
version 1.72.0. We could avoid building it.
