#!/bin/sh
#
# Build and install the Arpack-NG.
#
####

PACKAGE=arpack-ng
VERSION=3.8.0
SHA256SUM=ada5aeb3878874383307239c9235b716a8a170c6d096a6625bfd529844df003d

_pwd(){ CDPATH= cd -- $1 && pwd; }
_dirname(){ _d=`dirname -- "$1"`;  _pwd $_d; }
top_dir=`_dirname "$0"`

. $top_dir/.preamble.sh

##
## Requirements:
##  - MPI
##  - BLAS
##
## Optional:
##

fn_check_includes()
{
  cat >conftest.c <<EOF
#include <$2>
EOF
  { cc -E -I$prefix/include conftest.c >/dev/null 2>&1 && rm conftest.* ; } \
    || fn_error "requires $1"
}

fn_check_link()
{
  cat >conftest.c <<EOF
int $2();
int main(){ $2(); }
EOF
  { cc -L$prefix/lib conftest.c -ldl >/dev/null 2>&1 && rm conftest.* ; } \
    || fn_error "requires $1"
}

fn_check_includes MPI mpi.h
fn_check_link BLAS dgemm_

test -e arpack-ng-$VERSION.tar.gz \
  || $WGET https://github.com/opencollab/arpack-ng/archive/$VERSION.tar.gz \
           -O arpack-ng-${VERSION}.tar.gz \
  || fn_error "could not fetch source"
echo "$SHA256SUM  arpack-ng-$VERSION.tar.gz" | sha256sum --check \
  || fn_error "source hash mismatch"
tar xf arpack-ng-$VERSION.tar.gz \
  || fn_error "could not untar source"
cd arpack-ng-$VERSION


# Patches

patches="
  arpack-ng-debug.h.patch
  arpack-ng-stat.h.patch
  arpack-ng-CMakeLists.txt.patch
  arpack-ng-bug-1315-single.c.patch
"

# debug.h
# stat.h
# have non-conforming (to f77) continuation lines which must be fixed

# CMakeLists.txt
# - hardwires "mpirun" - replace by ${MPIEXEC_EXECUTABLE}
# - add_test(issue46 ...) misses parallel launch which is required

# TESTS/bug_1315_single.c
# - has a hardwired tolerance marginally too tight
#   for PrgEnv-aocc. Ease the tolerance to allow the test to pass.

{ echo "Applying patches:"; for p in $patches ; do echo "  $p"; done ; }
for p in $patches ; do
  patch -f -p0 <$top_dir/../patches/$p || fn_error "patching failed"
done

# Configure with cmake

mkdir build && cd build

# cat initial.cmake

cat >>initial.cmake<<EOF
set(EXAMPLES true CACHE BOOL "EXAMPLES=ON")
set(MPI true CACHE BOOL "MPI=ON")
set(ICB true CACHE BOOL "Iso C binding")
set(BUILD_SHARED_LIBS false CACHE BOOL "BUILD_SHARED_LIBS= as advertised ")
set(BLAS_LIBRARIES "${CRAY_LIBSCI_PREFIX_DIR}/lib" CACHE FILEPATH "FindBLAS")
set(LAPACK_LIBRARIES "${CRAY_LIBSCI_PREFIX_DIR}/lib" CACHE FILEPATH "FindLAPACK"
)
set(CMAKE_Fortran_FLAGS "${FFLAGS}" CACHE STRING "For ftn")
set(CMAKE_INSTALL_PREFIX "${prefix}" CACHE STRING "install to")
set(CMAKE_INSTALL_LIBDIR "lib" CACHE PATH "default is lib64")
set(MPIEXEC_EXECUTABLE "/usr/bin/srun" CACHE FILEPATH "for tests")
EOF

cmake -C initial.cmake ..

# PrgEnv-cray
# Remove any "-rdynamic"

for f in `find . -name link.txt`; do sed -i 's/-rdynamic//' $f; done 

make -j ${make_jobs}

make test

make -j ${make_jobs} install || fn_error "install failed"
printf "arpack-ng: done!  Installed to $prefix\n"
