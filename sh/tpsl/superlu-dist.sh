#!/bin/sh
#
# Build and install the Superlu_DIST library.
#
# Copyright 2019, 2020 Cray, Inc.
####

PACKAGE=superlu-dist
VERSION=6.1.1
SHA256SUM=35d25cff592c724439870444ed45e1d1d15ca2c65f02ccd4b83a6d3c9d220bd1

_pwd(){ CDPATH= cd -- $1 && pwd; }
_dirname(){ _d=`dirname -- "$1"`;  _pwd $_d; }
top_dir=`_dirname \`_dirname "$0"\``

. $top_dir/.preamble.sh

##
## Requirements:
##  - cmake
##  - metis
##  - parmetis
##
cmake --version >/dev/null 2>&1 \
  || fn_error "requires cmake"
cat >conftest.c <<'EOF'
#include <metis.h>
EOF
{ cc -E -I$prefix/include conftest.c >/dev/null 2>&1 && rm conftest.* ; } \
  || fn_error "requires METIS"
cat >conftest.c <<'EOF'
#include <parmetis.h>
EOF
{ cc -E -I$prefix/include conftest.c >/dev/null 2>&1 && rm conftest.* ; } \
  || fn_error "requires ParMETIS"

test -e v${VERSION}.tar.gz \
  || wget https://github.com/xiaoyeli/superlu_dist/archive/v${VERSION}.tar.gz \
  || fn_error "could not download superlu-dist"
echo "$SHA256SUM  v$VERSION.tar.gz" | sha256sum --check \
  || fn_error "source hash mismatch"
tar xf v$VERSION.tar.gz \
  || fn_error "could not untar source"
cd superlu_dist-$VERSION
patch -f -p1 <$top_dir/../patches/superlu-dist-omp.patch \
  || fn_error "could not patch"
patch -f -p1 <<'EOF'
Let SuperLU_DIST configure with a BLAS library that's available
without adding any additional libraries.  User must configure with
"-DBLAS_FOUND:BOOL=YES".

--- SuperLU_DIST_6.1.1/CMakeLists.txt
+++ SuperLU_DIST_6.1.1/CMakeLists.txt
@@ -164,7 +164,7 @@
 if(NOT TPL_ENABLE_BLASLIB)
 #  set(TPL_BLAS_LIBRARIES "" CACHE FILEPATH
 #    "Override of list of absolute path to libs for BLAS.")
-  if(TPL_BLAS_LIBRARIES)
+  if(BLAS_FOUND OR TPL_BLAS_LIBRARIES)
     set(BLAS_FOUND TRUE)
   else()
     find_package(BLAS)
@@ -195,7 +195,7 @@
 
 #--------------------- LAPACK ---------------------
 if(TPL_ENABLE_LAPACKLIB)  ## want to use LAPACK
-  if(TPL_LAPACK_LIBRARIES)
+  if(LAPACK_FOUND OR TPL_LAPACK_LIBRARIES)
     set(LAPACK_FOUND TRUE)
   else()
     find_package(LAPACK)

EOF

if test ${make_using_modules} -eq 1; then
  # Convince cmake that we can find PARMETIS
  # We can't leave these empty or exclude them, so set innocuous values... 
  tpl_parmetis_include_dirs="${PARMETIS_DIR}/include"
  tpl_parmetis_libraries="-lm"
else
  tpl_parmetis_include_dirs="$prefix/include"
  tpl_parmetis_libraries="parmetis;metis"
fi

test "$?" = "0" \
  || fn_error "could not patch"
rm -rf _build && mkdir _build && cd _build
cmake \
  -DCMAKE_INSTALL_PREFIX="$prefix" \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DCMAKE_Fortran_COMPILER:STRING=ftn \
  -DCMAKE_C_COMPILER:STRING=cc \
  -DCMAKE_Fortran_FLAGS="$FFLAGS $FOMPFLAG" \
  -DCMAKE_C_FLAGS="$CFLAGS $C99FLAG $OMPFLAG $CPPFLAGS" \
  -DOpenMP_CXX_FLAGS="$OMPFLAG" \
  -DBUILD_SHARED_LIBS=OFF \
  -DCMAKE_EXE_LINKER_FLAGS:STRING="$LDFLAGS $OMPFLAG -L$prefix/lib" \
  -DTPL_ENABLE_BLASLIB:BOOL=YES \
  -DBLAS_FOUND:BOOL=YES \
  -DTPL_ENABLE_LAPACKLIB:BOOL=YES \
  -DTPL_LAPACK_LIBRARIES="" \
  -DLAPACK_FOUND:BOOL=YES \
  -DTPL_ENABLE_PARMETISLIB:BOOL=yes \
  -DTPL_PARMETIS_LIBRARIES="${tpl_parmetis_libraries}" \
  -DTPL_PARMETIS_INCLUDE_DIRS="${tpl_parmetis_include_dirs}" \
  -DCMAKE_VERBOSE_MAKEFILE=ON \
  -DMPIEXEC_EXECUTABLE:STRING="srun" \
  -DMPIEXEC_MAX_NUMPROCS:STRING="128" \
  .. \
  || fn_error "configuration failed"
case "$compiler" in
  cray)
    find . \( -name 'link.txt' -o -name 'flags.make' \) \
      -exec sed -i 's/-std=c++11/-hstd=c++11/g' {} \+ \
      || fn_error "patching C++11 flags for CCE"
    ;;
esac


make --jobs=$make_jobs \
    || fn_error "build failed"
make install \
    || fn_error "install failed"
fn_checkpoint_tpsl

# Local Variables:
# indent-tabs-mode:nil
# sh-basic-offset:2
# End:
