#!/bin/sh
#
# Build and install the SUPERLU library.
#
# Copyright 2019, 2020 Cray, Inc.
####

PACKAGE=superlu
VERSION=5.2.1
SHA256SUM=77582501dedef295eb74e4dc9433e2816d2d8be211eae307379c13d93c65bc71

_pwd(){ CDPATH= cd -- $1 && pwd; }
_dirname(){ _d=`dirname -- "$1"`;  _pwd $_d; }
top_dir=`_dirname \`_dirname "$0"\``

. $top_dir/.preamble.sh

##
## Requirements:
##  - cmake
##  - metis
##
cmake --version >/dev/null 2>&1 \
  || fn_error "requires cmake"

test -e v${VERSION}.tar.gz \
    || $WGET https://github.com/xiaoyeli/superlu/archive/v${VERSION}.tar.gz \
    || fn_error "could not download superlu"
echo "$SHA256SUM  v${VERSION}.tar.gz" | sha256sum --check \
  || fn_error "source hash mismatch"
tar xf v${VERSION}.tar.gz \
  || fn_error "could not untar source"
cd superlu-$VERSION
patch -f -p1 <<'EOF'
Let SuperLU configure with a BLAS library that's available without
adding any additional libraries.  User must configure with
"-DBLAS_FOUND:BOOL=YES".

--- SuperLU_5.2.1/CMakeLists.txt	2016-05-22 10:58:44.000000000 -0500
+++ SuperLU_5.2.1/CMakeLists.txt	2018-09-24 11:03:34.000000000 -0500
@@ -76,7 +76,7 @@
 #
 #--------------------- BLAS ---------------------
 if(NOT enable_blaslib)
-  if (TPL_BLAS_LIBRARIES)
+  if (BLAS_FOUND OR TPL_BLAS_LIBRARIES)
     set(BLAS_FOUND TRUE)
   else()
     find_package(BLAS)

EOF
test "$?" = "0" \
  || fn_error "could not patch"
rm -rf _build && mkdir _build && cd _build
cmake \
  -DCMAKE_BUILD_TYPE:STRING=RELEASE \
  -DCMAKE_INSTALL_PREFIX="$prefix" \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DCMAKE_Fortran_COMPILER:STRING=ftn \
  -DCMAKE_C_COMPILER:STRING=cc \
  -DCMAKE_Fortran_FLAGS="$FFLAGS" \
  -DCMAKE_C_FLAGS="$CFLAGS" \
  -DBUILD_SHARED_LIBS=OFF \
  -DCMAKE_EXE_LINKER_FLAGS:STRING="$LDFLAGS $OMPFLAG" \
  -Denable_blaslib:BOOL=FALSE \
  -DBLAS_FOUND:BOOL=TRUE \
  -DCMAKE_VERBOSE_MAKEFILE=ON \
  .. \
  || fn_error "configuration failed"
make --jobs=$make_jobs \
  || fn_error "build failed"
make test \
  || fn_error "tests failed"
make install \
  || fn_error "install failed"
fn_checkpoint_tpsl

# Local Variables:
# indent-tabs-mode:nil
# sh-basic-offset:2
# End:
