# Archer2 GLM instaation

## Build

E.g.,
```
$ ./archer2/libraries/glm/build-glm.sh --prefix=/work/y07/shared
```
The buidsl are entirely serial; four builds (including gcc/9.3.0
and gcc/10.1.0) are performed. Individual builds are driven by
```
./sh/tpsl/glm.sh
```
which runs a full build test by default.


## Modulefile

Note that while GLM only really features an `include` directory,
there is also a `lib/pkgconfig` directory holding the `pkg-config`
file.

The relevant module template is `modulefile.tcl`.


## Installation test

We assume the GLM build tests are performed and only a minimal test
of the installation itself is required: a test program is compiled
against the installed headers.

The test should really cover gcc/9.3.0 as well.
