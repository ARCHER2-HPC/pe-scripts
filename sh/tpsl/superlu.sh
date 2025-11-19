#!/bin/sh
#
# Build and install the SUPERLU library.
#
# Copyright 2019, 2020, 2021 Hewlett Packard Enterprise Development LP.
####

PACKAGE=superlu
VERSIONS='
  5.2.1:77582501dedef295eb74e4dc9433e2816d2d8be211eae307379c13d93c65bc71
  5.2.2:470334a72ba637578e34057f46948495e601a5988a602604f5576367e606a28c
  5.3.0:3e464afa77335de200aeb739074a11e96d9bef6d0b519950cfa6684c4be1f350
  6.0.1:6c5a3a9a224cb2658e9da15a6034eed44e45f6963f5a771a6b4562f7afb8f549
  7.0.0:d7b91d4e0bb52644ca74c1a4dd466a694ddf1244a7bbf93cb453e8ca1f6527eb
  7.0.1:86dcca1e086f8b8079990d07f00eb707fc9ef412cf3b2ce808b37956f0de2cb8
'

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

test -e superlu-${VERSION}.tar.gz \
    || $WGET https://github.com/xiaoyeli/superlu/archive/v${VERSION}.tar.gz \
             -O superlu-${VERSION}.tar.gz \
    || fn_error "could not download superlu"
echo "$SHA256SUM  superlu-${VERSION}.tar.gz" | sha256sum --check \
  || fn_error "source hash mismatch"
tar xf superlu-${VERSION}.tar.gz \
  || fn_error "could not untar source"

cd superlu-$VERSION

case ${VERSION} in
  7*)
    printf "Patches for version 7\n"
    # Note the -ffast-math breaks some tests, so remove if present ...
    #sed 's/\-ffast\-math//g' <<<"${CFLAGS}"
    #sed 's/\-ffast\-math//g' <<<"${FFLAGS}"
    CFLAGS="$(echo ${CFLAGS} | sed 's/\-ffast\-math//g')"
    FFLAGS="$(echo ${FFLAGS} | sed 's/\-ffast\-math//g')"
    printf "CFLAGS: %s\n" "${CFLAGS}"
    printf "FFLAGS: %s\n" "${FFLAGS}"
    ;;
  6*)
    printf "Patches for version 6\n"
    # A stray close comment will prevent compilation in ...
    sed -i 's#    \*/##' EXAMPLE/dreadtriple_noheader.c
  ;;
  5*)
patch -f -p1 <<'EOF'
Let SuperLU configure with a BLAS library that's available without
adding any additional libraries.  User must configure with
"-DBLAS_FOUND:BOOL=YES".

--- a/CMakeLists.txt
+++ b/CMakeLists.txt
@@ -76,4 +76,4 @@
-  if (TPL_BLAS_LIBRARIES)
+  if (BLAS_FOUND OR TPL_BLAS_LIBRARIES)
     set(BLAS_FOUND TRUE)
   else()
     find_package(BLAS)
EOF
test "$?" = "0" \
  || fn_error "could not patch"
;;
esac

rm -rf _build-${PE_ENV} && mkdir _build-${PE_ENV} && cd _build-${PE_ENV}
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
  -Denable_fortran:BOOL=TRUE \
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
