#!/bin/sh
#
# Build and install the scotch library.
#
# VERSION >= 7.0.0 using cmake route
# requires an salloc for the tests to pass.
#
# Copyright 2019, 2020, 2021 Hewlett Packard Enterprise Development LP.
####

PACKAGE=scotch
VERSIONS='
  7.0.1:0618e9bc33c02172ea7351600fce4fccd32fe00b3359c4aabb5e415f17c06fed
  7.0.3:5b5351f0ffd6fcae9ae7eafeccaa5a25602845b9ffd1afb104db932dd4d4f3c5
'

_pwd(){ CDPATH= cd -- $1 && pwd; }
_dirname(){ _d=`dirname -- "$1"`;  _pwd $_d; }
top_dir=`_dirname \`_dirname "$0"\``

. $top_dir/.preamble.sh

case "$compiler" in
  cray) CFLAGS_NATIVE="-hcpu=`uname -m`" ;;
  gnu|intel|crayclang) CFLAGS_NATIVE="-march=native" ;;
  pgi) CFLAGS_NATIVE="-tp=x86" ;; # only supported on x86
esac

##
## Optional:
##   - hdf5
##

test -e scotch-v$VERSION.tar.gz \
  || $WGET https://gitlab.inria.fr/scotch/scotch/-/archive/v${VERSION}/scotch-v${VERSION}.tar.gz  \
           || fn_error "wget failed"

echo "$SHA256SUM  scotch-v${VERSION}.tar.gz" | sha256sum --check \
  || fn_error "source hash mismatch"
tar xf scotch-v${VERSION}.tar.gz \
  || fn_error "could not untar source"


cd scotch-v${VERSION}
mkdir _build
cd _build

# Do not use MPI_THREAD_MULTIPLE as this may not be supported in user code
# Do not use THREADS, as this gives race conditions in the tests
# Do not build the scotchmetis library, as this will collide with
# the true metis/parmetis without -DSCOTCH_METIS_PREFIX, which the
# cmake route won't do and still pass the tests.

CFLAGS="${CFLAGS}" cmake \
      -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_C_COMPILER=cc \
      -DCMAKE_CXX_COMPILER=CC \
      -DCMAKE_Fortran_COMPILER=ftn \
      -DCMAKE_VERBOSE_MAKEFILE=1 \
      -DMPI_THREAD_MULTIPLE:BOOL=OFF \
      -DTHREADS:BOOL=OFF \
      -DBUILD_LIBSCOTCHMETIS:BOOL=OFF \
      ..

test "$?" = "0" || fn_error "configuration failed"

# Some evidence of race to dependencies if -j > 1, so restrict to 1

make --jobs=1   || fn_error "build failed"
make test       || fn_error "tests failed"
make install    || fn_error "install failed"

fn_checkpoint_tpsl
