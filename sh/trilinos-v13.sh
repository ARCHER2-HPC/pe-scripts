#!/bin/sh
#
# Build and install the Trilinos library.
#
# Version 13.x
# Copyright 2019, 2020, 2021 Hewlett Packard Enterprise Development LP.
####

PACKAGE=trilinos
VERSIONS='
  12.14.1:10a88f034b8f91904a98970c00fa88b7f4acd59429d2c4870a60c6e297fc044a
  12.18.1:f170a3e92dc8cca338606223fbbce20ee482b863c607bb9bac6730656aec8c69
  13.4.1:
'


_pwd(){ CDPATH= cd -- $1 && pwd; }
_dirname(){ _d=`dirname -- "$1"`;  _pwd $_d; }
top_dir=`_dirname "$0"`

. $top_dir/.preamble.sh



##
## Requirements:
##  - cmake
##  - MPI
##  - BLAS
##  - ScaLAPACK
##  - TPSL (superlu, superlu-dist, metis, parmetis, scotch, mumps, matio)
##  - boost
##  - hdf5
##  - netcdf
##  - tar >= 1.27 for source verification
##

fn_check_includes()
{
  cat >conftest.c <<EOF
#include <$2>
EOF
  { CC -E -I$prefix/include $CPPFLAGS conftest.c >/dev/null 2>&1 && rm conftest.* ; } \
    || fn_error "requires $1"
}
fn_check_link()
{
  cat >conftest.c <<EOF
extern "C" { int $2(); }
int main(){ $2(); }
EOF
  { CC -L$prefix/lib $LDFLAGS conftest.c $LIBS >/dev/null 2>&1 && rm conftest.* ; } \
    || fn_error "requires $1"
}

cmake --version >/dev/null 2>&1 \
  || fn_error "requires cmake"

fn_check_link BLAS dgemm_
fn_check_link ScaLAPACK pdgetrf_
fn_check_includes MPI mpi.h
fn_check_includes METIS metis.h
fn_check_includes ParMETIS parmetis.h
fn_check_includes SuperLU slu_ddefs.h
fn_check_includes SuperLU_DIST superlu_dist_config.h
fn_check_includes Scotch scotch.h
fn_check_includes PT-Scotch ptscotch.h
fn_check_includes MUMPS mumps_c_types.h
#fn_check_includes GLM glm/glm.hpp
fn_check_includes Matio matio.h
fn_check_includes HDF5 hdf5.h
fn_check_includes NetCDF netcdf.h
fn_check_includes Boost::regex boost/regex.hpp
fn_check_includes Boost::timer boost/timer.hpp
fn_check_includes Boost::chrono boost/chrono.hpp
fn_check_includes Boost::program_options boost/program_options.hpp
fn_check_includes Boost::system boost/system/error_code.hpp

# ASSUME directory exists
#mv Trilinos-trilinos-release-13-4-1 trilinos-${VERSION}

cd trilinos-$VERSION


trilinos_enable_packages="
  Amesos
  Amesos2
  Anasazi
  AztecOO
  Belos
  Epetra
  EpetraExt
  FEI
  Galeri
  Ifpack
  Ifpack2
  Intrepid
  Isorropia
  Kokkos
  Komplex
  ML
  Moertel
  MueLu
  NOX
  Pamgen
  Phalanx
  Piro
  Pliris
  ROL
  RTOp
  Rythmos
  Sacado
  Shards
  ShyLU
  STK
  STKSearch
  STKTopology
  STKUtil
  Stokhos
  Stratimikos
  Teko
  Teuchos
  Thyra
  Tpetra
  TrilinosCouplings
  Triutils
  Xpetra
  Zoltan
  Zoltan2
  SEACAS
  SEACASExo2mat
  SEACASMat2exo
"


# The SuperLU and SuperLU_DIST interfaces in Amesos2 don't build well
# with CCE (and possibly newer versions of gcc), so we disable those.
amesos2_OPTIONS="\
Amesos2_ENABLE_SuperLU:BOOL=OFF,\
Amesos2_ENABLE_SuperLUDist:BOOL=OFF,\
Amesos2_ENABLE_KLU2:BOOL=ON,\
Amesos2_ENABLE_Basker:BOOL=ON,\
Amesos2_ENABLE_MUMPS:BOOL=ON"
epetra_OPTIONS="Epetra_ENABLE_THREADS:BOOL=ON"
ifpack_OPTIONS="Ifpack_ENABLE_METIS:BOOL=OFF"
kokkos_OPTIONS="Kokkos_ENABLE_SERIAL:BOOL=ON,Kokkos_ENABLE_OPENMP:BOOL=ON"

# MueLu
muelu_OPTIONS="MueLu_ENABLE_TESTS:STRING=OFF,MueLu_ENABLE_EXAMPLES:STRING=OFF,MueLu_ENABLE_Kokkos_Refactor:STRING=ON"

# Following advice from configure stage: required as Kokkos_SERIAL is set.
tpetra_OPTIONS="Tpetra_INST_SERIAL:BOOL=ON"

# Use ParMETIS in ML and Zoltan, instead of METIS
# ML supports only SuperLU < 5.0
ml_OPTIONS="ML_ENABLE_METIS:BOOL=OFF, ML_ENABLE_SuperLU:BOOL=OFF"
zoltan_OPTIONS="Zoltan_ENABLE_METIS:BOOL=OFF,Zoltan_ENABLE_F90INTERFACE:BOOL=ON"

# CCE aborts when compiling one of Zoltan2's source if OpenMP is enabled.
#zoltan2_OPTIONS="Zoltan2_ENABLE_OpenMP:BOOL=OFF"

# Workaround for https://github.com/trilinos/Trilinos/issues/244
#zoltan2_OPTIONS="$zoltan2_OPTIONS,Zoltan2_ENABLE_Scotch:BOOL=OFF"

: ${CRAY_CPU_TARGET=`uname -m`}
case "$compiler" in
  crayclang)
    FFLAGS="-ef -hnocaf $FFLAGS"
    ;;
  gnu)
    FFLAGS="$FFLAGS"
    ;;
  aocc)
    LIBS="$LIBS${LIBS+ }-lm"
    ;;
esac
case "$compiler" in
  cray|pgi) mpi_long_double=0 ;;
  *) mpi_long_double=1 ;;
esac

if test ${make_using_modules} -eq 1; then
  boost_dir=${BOOST_DIR}
  matio_dir=${MATIO_DIR}
  metis_dir=${METIS_DIR}
  mumps_dir=${MUMPS_DIR}
  parmetis_dir=${PARMETIS_DIR}
  scotch_dir=${SCOTCH_DIR}
  superlu_dir=${SUPERLU_DIR}
  superlu_dist_dir=${SUPERLU_DIST_DIR}
  metis_libs=""
  parmetis_libs=""
  mumps_libs=""
  scotch_libs=""
  superlu_libs=""
  superlu_dist_libs=""
else
  boost_dir=${prefix}
  matio_dir=${prefix}
  metis_dir=${prefix}
  mumps_dir=${prefix}
  parmetis_dir=${prefix}
  scotch_dir=${prefix}
  superlu_dir=${prefix}
  superlu_dist_dir=${prefix}
  metis_libs="metis"
  parmetis_libs="parmetis;metis"
  mumps_libs="dmumps;zmumps;smumps;cmumps;mumps_common;esmumps;ptesmumps;parmetis;ptscotch;scotch;scotcherr;pord"
  scotch_libs="ptscotch;ptscotcherr;scotch;scotcherr"
  superlu_libs="superlu superlu_3.0 superlu_4.0 superlu_4.1 superlu_4.2 superlu_4.3 superlu_5.0 superlu_5.1.1 superlu_5.2.1 superlu_5.2.2"
  superlu_dist_libs="superludist superlu_dist superlu_dist_2.0 superlu_dist_2.5 superlu_dist_4.0"
fi


mkdir -p "_build-${PE_ENV}" && cd "_build-${PE_ENV}"

cat >configure-trilinos.sh <<EOF
#!/bin/sh
: \${CMAKE=`command -v cmake`}
rm -rf CMakeFiles CMakeCache.txt
unset DESTDIR # Prevent installing into anything but \$CMAKE_INSTALL_PREFIX
\$CMAKE \\
  -D CMAKE_BUILD_TYPE:STRING=RELEASE \\
  -D Trilinos_ENABLE_DEVELOPMENT_MODE:BOOL=OFF \\
  -D Trilinos_ASSERT_MISSING_PACKAGES:BOOL=OFF \\
  -D Trilinos_ENABLE_EXPLICIT_INSTANTIATION:BOOL=OFF \\
  -D Trilinos_ENABLE_TESTS:BOOL=OFF \\
  -D Trilinos_ENABLE_ALL_PACKAGES:BOOL=OFF \\
  -D Trilinos_ENABLE_ALL_OPTIONAL_PACKAGES:BOOL=OFF \\
  -D Trilinos_ENABLE_Fortran:BOOL=ON \\
  -D Trilinos_ENABLE_OpenMP:BOOL=ON \\
  -D BUILD_SHARED_LIBS:BOOL=NO \\
  -D TPL_FIND_SHARED_LIBS:BOOL=YES \\
  -D Trilinos_LINK_SEARCH_START_STATIC:BOOL=YES \\
  -D CMAKE_SKIP_INSTALL_RPATH:BOOL=ON \\
  -D Trilinos_ENABLE_EXPORT_MAKEFILES:BOOL=ON \\
  -D Trilinos_DEPS_XML_OUTPUT_FILE:FILEPATH="" \\
  -D CMAKE_C_SIZEOF_DATA_PTR=8 \\
  -D CMAKE_CXX_COMPILER:STRING=CC \\
  -D CMAKE_C_COMPILER:STRING=cc \\
  -D CMAKE_Fortran_COMPILER:STRING=ftn \\
  -D CMAKE_C_FLAGS:STRING="$CPPFLAGS $CFLAGS $CPPFLAGS $CFLAGS" \\
  -D CMAKE_CXX_FLAGS:STRING="$CPPFLAGS $CFLAGS $CXXFLAGS $CPPFLAGS $CXXFLAGS" \\
  -D CMAKE_Fortran_FLAGS:STRING="$CPPFLAGS $FFLAGS $CPPFLAGS $FFLAGS" \\
  -D CMAKE_EXE_LINKER_FLAGS:STRING="$LIBS${LIBS+ }\$LIBS $LDFLAGS${LDFLAGS+ }\$LDFLAGS" \\
  -D CMAKE_C_FLAGS_RELEASE_OVERRIDE="$OPTFLAGS -DNDEBUG" \\
  -D CMAKE_CXX_FLAGS_RELEASE_OVERRIDE="$OPTFLAGS -DNDEBUG" \\
  -D CMAKE_Fortran_FLAGS_RELEASE_OVERRIDE="$OPTFLAGS -DNDEBUG" \\
  -D Trilinos_EXTRA_LINK_FLAGS:STRING="$LIBS${LIBS+ }\$LIBS" ${OMPFLAG+\\
  -D OpenMP_C_FLAGS:STRING="$OMPFLAG" \\
  -D OpenMP_CXX_FLAGS:STRING="$OMPFLAG" \\
  -D OpenMP_Fortran_FLAGS:STRING="$FOMPFLAG" }\\
  -D TPL_ENABLE_BLAS:BOOL=ON \\
  -D TPL_ENABLE_LAPACK:BOOL=ON \\
  -D TPL_ENABLE_SCALAPACK:BOOL=ON \\
  -D BLAS_LIBRARY_NAMES="" \\
  -D LAPACK_LIBRARY_NAMES="" \\
  -D SCALAPACK_LIBRARY_NAMES="" \\
  -D TPL_ENABLE_Scotch:BOOL=ON \\
  -D TPL_Scotch_INCLUDE_DIRS:FILEPATH=${scotch_dir}/include \\
  -D Scotch_LIBRARY_DIRS:FILEPATH=${scotch_dir}/lib \\
  -D Scotch_LIBRARY_NAMES="${scotch_libs}" \\
  -D TPL_ENABLE_SuperLU:BOOL=ON \\
  -D TPL_SuperLU_INCLUDE_DIRS:FILEPATH=${superlu_dir}/include \\
  -D SuperLU_LIBRARY_DIRS:FILEPATH=${superlu_dir}/lib \\
  -D SuperLU_LIBRARY_NAMES="${superlu_libs}" \\
  -D TPL_ENABLE_SuperLUDist:BOOL=ON \\
  -D TPL_SuperLUDist_INCLUDE_DIRS:FILEPATH=${superlu_dist_dir}/include \\
  -D SuperLUDist_LIBRARY_DIRS:FILEPATH=${superlu_dist_dir}/lib \\
  -D SuperLUDist_LIBRARY_NAMES="${superlu_dist_libs}" \\
  -D HAVE_SUPERLUDIST_ENUM_NAMESPACE:BOOL=YES \\
  -D HAVE_SUPERLUDIST_LUSTRUCTINIT_2ARG:BOOL=YES \\
  -D TPL_ENABLE_METIS:BOOL=ON \\
  -D TPL_METIS_INCLUDE_DIRS:FILEPATH=${metis_dir}/include \\
  -D METIS_LIBRARY_DIRS:FILEPATH=${metis_dir}/lib \\
  -D METIS_LIBRARY_NAMES="${metis_libs}" \\
  -D TPL_ENABLE_ParMETIS:BOOL=ON \\
  -D TPL_ParMETIS_INCLUDE_DIRS:FILEPATH="${parmetis_dir}/include" \\
  -D ParMETIS_LIBRARY_DIRS:FILEPATH="${parmetis_dir}/lib" \\
  -D ParMETIS_LIBRARY_NAMES:STRING="${parmetis_libs}" \\
  -D TPL_ENABLE_MUMPS:BOOL=ON \\
  -D TPL_MUMPS_INCLUDE_DIRS:FILEPATH=${mumps_dir}/include \\
  -D MUMPS_LIBRARY_DIRS:FILEPATH="${mumps_dir}/lib" \\
  -D MUMPS_LIBRARY_NAMES:STRING="${mumps_libs}" \\
  -D TPL_ENABLE_Matio:BOOL=ON \\
  -D TPL_Matio_INCLUDE_DIRS:FILEPATH=${matio_dir}/include \\
  -D Matio_LIBRARY_DIRS:FILEPATH=${matio_dir}/lib \\
  -D TPL_ENABLE_GLM:BOOL=OFF \\
  -D TPL_ENABLE_HDF5:BOOL=ON \\
  -D TPL_HDF5_INCLUDE_DIRS:FILEPATH=\$HDF5_DIR/include \\
  -D HDF5_LIBRARY_DIRS:FILEPATH="\$HDF5_DIR/lib" \\
  -D HDF5_LIBRARY_NAMES:STRING="hdf5_hl_parallel;hdf5_parallel;z;dl" \\
  -D TPL_ENABLE_Netcdf:BOOL=ON \\
  -D TPL_Netcdf_INCLUDE_DIRS:FILEPATH=\$NETCDF_DIR/include \\
  -D Netcdf_LIBRARY_DIRS:FILEPATH="\$NETCDF_DIR/lib;\$HDF5_DIR/lib" \\
  -D Netcdf_LIBRARY_NAMES:STRING="netcdf_parallel;hdf5_hl_parallel;hdf5_parallel;z;dl" \\
  -D TPL_ENABLE_Boost:BOOL=ON \\
  -D TPL_Boost_INCLUDE_DIRS:FILEPATH=${boost_dir}/include \\
  -D TPL_ENABLE_BoostLib:BOOL=ON \\
  -D TPL_BoostLib_INCLUDE_DIRS:FILEPATH=${boost_dir}/include \\
  -D BoostLib_LIBRARY_DIRS:FILEPATH=${boost_dir}/lib \\
  -D TPL_ENABLE_X11:BOOL=OFF \\
  -D TPL_ENABLE_MPI:BOOL=ON \\
  -D MPI_BASE_DIR:FILEPATH=$mpich \\
  -D MPI_EXEC:STRING=\${MPIEXEC:-srun} \\
  -D MPI_EXEC_NUMPROCS_FLAG:STRING="-n" \\
  -D CMAKE_INSTALL_PREFIX:PATH=$prefix \\
EOF

for package in $trilinos_enable_packages; do
  cat >>configure-trilinos.sh <<EOF
  -D Trilinos_ENABLE_$package:BOOL=ON \\
EOF
  pkg=`echo $package | tr "A-Z" "a-z"`
  eval pkg_options=\$${pkg}_OPTIONS
  if test -n "$pkg_options"; then
    echo "  -D $pkg_options \\" | sed 's/,/ \\\n  -D /g' >>configure-trilinos.sh
  fi
done


# Include any additional cmake configuration options specified
# SEACAS Supes kills aocc 3.2 Fortran so disable for now
cat >>configure-trilinos.sh <<EOF
  -D Trilinos_ENABLE_SEACASSupes:BOOL=OFF \\
  \$CMAKEFLAGS \\
  ..
EOF

cat >>configure-trilinos.sh <<EOF
# Let the CrayPE compiler drivers determine whether libraries are
# linked statically or dynamically.
echo -n "Removing -Wl,-B... from link lines... "
find . -name link.txt |					\\
  xargs --no-run-if-empty sed --in-place=~		\\
  -e "s/-Wl,-B\(dynamic\|static\)//g" ;
echo "done"
EOF


test "$?" = "0" \
  && chmod +x configure-trilinos.sh \
  && ./configure-trilinos.sh \
  || fn_error "configuration failed"
make --jobs=${make_jobs}
#make --jobs=$make_jobs install || fn_error "build failed"


# Local Variables:
# indent-tabs-mode:nil
# sh-basic-offset:2
# End:

