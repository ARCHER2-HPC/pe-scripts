#!/bin/sh
#
# Build and install the matio library.
#
# Copyright 2019, 2020 Cray, Inc.
####

PACKAGE=matio
VERSIONS='
  1.5.13:feadb2f54ba7c9db6deba8c994e401d7a1a8e7afd0fe74487691052b8139e5cb
  1.5.18:5fad71a63a854d821cc6f4e8c84da837149dd5fb57e1e2baeffd85fa0f28fe25
'

_pwd(){ CDPATH= cd -- $1 && pwd; }
_dirname(){ _d=`dirname -- "$1"`;  _pwd $_d; }
top_dir=`_dirname \`_dirname "$0"\``

. $top_dir/.preamble.sh

##
## Optional:
##   - hdf5
##

test -e matio-$VERSION.tar.gz \
  || $WGET http://sourceforge.net/projects/matio/files/matio/$VERSION/matio-$VERSION.tar.gz \
  || fn_error "could not fetch source"
echo "$SHA256SUM  matio-$VERSION.tar.gz" | sha256sum --check \
  || fn_error "source hash mismatch"
tar xf matio-$VERSION.tar.gz \
  || fn_error "could not untar source"
cd matio-$VERSION
./configure \
  cross_compiling=yes \
  ac_cv_va_copy=C99 \
  CC=cc CXX=CC F77=ftn \
  --prefix="$prefix" \
  CFLAGS="$CFLAGS" \
  --enable-extended-sparse \
  --enable-static \
  --disable-shared \
  || fn_error "configuration failed"
make --jobs=$make_jobs install \
  || fn_error "build failed"
fn_checkpoint_tpsl

# Local Variables:
# indent-tabs-mode:nil
# sh-basic-offset:2
# End:
