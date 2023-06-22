#!/bin/sh
#
# Build and install the GLM library.
#
# Copyright 2019, 2020 Cray, Inc.
####

PACKAGE=glm
VERSIONS='
  0.9.6.3:14651b56b10fa68082446acaf6a1116d56b757c8d375b34b5226a83140acd2b2
  0.9.9.6:9db7339c3b8766184419cfe7942d668fecabe9013ccfec8136b39e11718817d0
  0.9.9.7:6b79c3d06d9745d1cce3f38c0c15666596f9aefff25ddb74df3af0a02f011ee1
  0.9.9.8:37e2a3d62ea3322e43593c34bae29f57e3e251ea89f4067506c94043769ade4c
'

_pwd(){ CDPATH= cd -- $1 && pwd; }
_dirname(){ _d=`dirname -- "$1"`;  _pwd $_d; }
top_dir=`_dirname \`_dirname "$0"\``

. $top_dir/.preamble.sh

##
## Requirements:
##  - unzip
##  - cmake
##
unzip >/dev/null 2>&1 \
  || fn_error "requires unzip for source"
cmake --version >/dev/null 2>&1 \
  || fn_error "requires cmake"

test -e glm-$VERSION.zip \
  || $WGET https://github.com/g-truc/glm/releases/download/$VERSION/glm-$VERSION.zip \
  || fn_error "could not fetch source"
echo "$SHA256SUM  glm-$VERSION.zip" | sha256sum --check \
  || fn_error "source hash mismatch"
unzip -d glm-$VERSION glm-$VERSION.zip \
  || fn_error "could not unzip source"
cd glm-$VERSION/glm
{ printf "converting to unix line-endings..." ;
  find . -type f -exec sed -i 's/$//' {} \; && echo "done" ; } \
    || fn_error "could not patch line endings"
case $VERSION in
  0.9.9.6) patch --reverse -p1 <$top_dir/../patches/glm-cmake-install.patch \
             || fn_error "could not patch source" ;;
esac


# All versions. remove bad utf-8 characters from two files:
for f in test/gtc/gtc_quaternion.cpp glm/gtx/matrix_factorisation.inl
do
  iconv -c -f utf-8 -t ascii $f > tmp.cpp
  mv tmp.cpp $f
done       


case "$compiler" in
  crayclang)
    CXXFLAGS="-Wno-implicit-int-float-conversion $CXXFLAGS"
    case "${CRAY_CC_VERSION}" in
      15.0*) CXXFLAGS="-Wno-implicit-int-conversion ${CXXFLAGS}"
    esac
    ;;
  aocc)
    # AAOC 2.1 cannot use this (not recognised option)
    # AOCC 2.2 must use this to compile with -Werror -Weverything
    case "${CRAY_AOCC_VERSION}" in
      2.2*) CXXFLAGS="-Wno-implicit-int-float-conversion $CXXFLAGS" ;;
      3.2*) CXXFLAGS="-Wno-implicit-int-float-conversion -Wno-implicit-int-conversion -Wno-unused-but-set-variable ${CXXFLAGS}";;
    esac
esac

cmake \
  -DGLM_TEST_ENABLE=ON \
  -DCMAKE_CXX_COMPILER=CC \
  -DCMAKE_CXX_FLAGS="$CXXFLAGS" \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DCMAKE_INSTALL_PREFIX=$prefix \
  || fn_error "configuration failed"
make -j $make_jobs \
  || fn_error "build failed"
make test \
  || fn_error "tests failed"
make preinstall && cmake -P cmake_install.cmake \
  || fn_error "install failed"

fn_checkpoint_tpsl

# Local Variables:
# indent-tabs-mode:nil
# sh-basic-offset:2
# End:
