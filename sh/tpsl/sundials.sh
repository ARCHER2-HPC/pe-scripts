#!/bin/sh
#
# Build and install the SUNDIALS library.
#
# Copyright 2019, 2020 Cray, Inc.
####

PACKAGE=sundials
VERSIONS='
  2.7.0:d39fcac7175d701398e4eb209f7e92a5b30a78358d4a0c0fcc23db23c11ba104
  4.1.0:280de1c27b2360170a6f46cb3799b2aee9dff3bddbafc8b08c291a47ab258aa5
  5.3.0:88dff7e11a366853d8afd5de05bf197a8129a804d9d4461fb64297f1ef89bca7
'

_pwd(){ CDPATH= cd -- $1 && pwd; }
_dirname(){ _d=`dirname -- "$1"`;  _pwd $_d; }
top_dir=`_dirname \`_dirname "$0"\``

. $top_dir/.preamble.sh

##
## Requirements:
##  - cmake
##
cmake --version >/dev/null 2>&1 \
  || fn_error "requires cmake"

test -e sundials-$VERSION.tar.gz \
  || $WGET https://computation.llnl.gov/projects/sundials/download/sundials-$VERSION.tar.gz \
  || fn_error "could not fetch source"
echo "$SHA256SUM  sundials-$VERSION.tar.gz" | sha256sum --check \
  || fn_error "source hash mismatch"
tar xf sundials-$VERSION.tar.gz \
  || fn_error "could not untar source"
cd sundials-$VERSION
rm -rf _build && mkdir _build && cd _build
cmake \
  -DCMAKE_INSTALL_PREFIX="$prefix" \
  -DCMAKE_VERBOSE_MAKEFILE=ON \
  -DCMAKE_Fortran_COMPILER:STRING=ftn \
  -DCMAKE_C_COMPILER:STRING=cc \
  -DCMAKE_Fortran_FLAGS="$FFLAGS" \
  -DCMAKE_C_FLAGS="$CFLAGS" \
  -DCMAKE_INSTALL_LIBDIR:PATH=lib \
  -DCMAKE_EXE_LINKER_FLAGS:STRING=-ldl \
  -DSUNDIALS_RT_LIBRARY:STRING=-lrt \
  -DBUILD_SHARED_LIBS=ON \
  -DEXAMPLES_ENABLE:BOOL=YES \
  -DEXAMPLES_ENABLE_C:BOOL=YES \
  -DEXAMPLES_ENABLE_CXX:BOOL=YES \
  -DEXAMPLES_ENABLE_F77:BOOL=NO \
  -DEXAMPLES_ENABLE_F90:BOOL=NO \
  -DEXAMPLES_INSTALL:BOOL=NO \
  -DFCMIX_ENABLE=ON \
  -DSUNDIALS_INDEX_SIZE=32 \
  -DBLAS_LIBRARIES:STRING="${CRAY_LIBSCI_PREFIX_DIR}/lib" \
  -BLAPACK_LIBRARIES:STRING="${CRAY_LIBSCI_PREFIX_DIR}/lib" \
  -DLAPACK_ENABLE=ON \
  -DLAPACK_LIBRARY="" \
  -DLAPACK_FOUND:BOOL=YES \
  -DMPI_ENABLE=ON \
  -DMPI_MPICC:STRING=cc \
  -DMPI_MPIF77:STRING=ftn \
  -DMPIEXEC_EXECUTABLE:STRING=srun \
  -DMPIEXEC_MAX_NUMPROCS:STRING=4 \
  -DOPENMP_ENABLE:BOOL=ON \
  .. \
  || fn_error "configuration failed"
make --jobs=$make_jobs install \
  || fn_error "build failed"
fn_checkpoint_tpsl

# Local Variables:
# indent-tabs-mode:nil
# sh-basic-offset:2
# End:
