#!/usr/bin/env bash

set -e

script="$(readlink -fm "$0")"
script_dir="$(dirname "${script}")"
script_root="$(dirname "${script%/*/*}")"

source ${script_root}/pkgconfig-lib.sh
source ${script_root}/versions.sh
source ${script_root}/command_line.sh

function main {

    # Overall prefix must be supplied by command line

    local install_root=${prefix}/libs/trilinos/${TRILINOS_VERSION}

    ${build_amd} && trilinosBuildAocc ${install_root}
    ${build_cce} && trilinosBuildCray ${install_root}
    ${build_gnu} && trilinosBuildGnu  ${install_root}

    trilinosInstallModuleFile
    trilinosInstallationTest
}

function trilinosLoadModuleDependencies {

    moduleUseLibs
    module load cray-hdf5-parallel
    module load cray-netcdf-hdf5parallel
    
    module load parmetis/${PARMETIS_VERSION}
    module load scotch/${SCOTCH_VERSION}
    module load mumps/${MUMPS_VERSION}
    module load superlu/${SUPERLU_VERSION}
    module load superlu-dist/${SUPERLUDIST_VERSION}
    module load matio/${MATIO_VERSION}
    module load glm/${GLM_VERSION}
    module load boost/${BOOST_VERSION}
}

function trilinosBuildAocc {

    local install_root=${1}

    module restore $(moduleCollection PrgEnv-aocc)
    module swap aocc aocc/${PE_AOCC_AOCC_VERSION}

    trilinosLoadModuleDependencies
    module list

    amd_version=$(moduleToCompilerMajorMinor)
    amd_root=${install_root}/AOCC
    amd_prefix=${amd_root}/${amd_version}

    trilinosBuild ${amd_prefix}
}

function trilinosBuildCray {

    local install_root=${1}

    module restore $(moduleCollection PrgEnv-cray)
    module swap cce cce/${PE_CRAY_CCE_VERSION}

    trilinosLoadModuleDependencies
    module list

    cray_version=$(moduleToCompilerMajorMinor)
    cray_root=${install_root}/CRAYCLANG
    cray_prefix=${cray_root}/${cray_version}

    trilinosBuild ${cray_prefix}
}

function trilinosBuildGnu {    

    local install_root=${1}

    module restore $(moduleCollection PrgEnv-gnu)
    module swap gcc gcc/${PE_GNU_GCC_VERSION}

    trilinosLoadModuleDependencies
    module list

    gnu_version=$(moduleToCompilerMajorMinor)
    gnu_root=${install_root}/GNU
    gnu_prefix=${gnu_root}/${gnu_version}

    trilinosBuild ${gnu_prefix}
}

function trilinosBuild {

    local prefix=${1}
    
    trilinosClean
    trilinosBuildMPIOpenMP ${prefix}

    pcCrayPkgGenRunAndProcess ${prefix}
    trilinosPackageConfigFile ${prefix}
}

function trilinosClean {

    rm -rf trilinos-${TRILINOS_VERSION}

}

function trilinosBuildMPIOpenMP {

    # See MPI build above for comments

    local prefix=${1}

    ./sh/trilinos.sh --jobs=16 --prefix=${prefix} --openmp --modules \
		  --version=${TRILINOS_VERSION}
}

function trilinosPackageConfigFile {

    local prefix=${1}
    local prgEnv=$(peEnvUpper)

    declare -A pcmap
    pcmap[name]="trilinos"
    pcmap[version]="${TRILINOS_VERSION}"
    pcmap[description]="Trilinos packages for ${prgEnv} compiler via CC"
    pcmap[has_openmp]=0 # We do, but only make sure -fopenmp appears for link..
    pcmap[libs]="-fopenmp"

    # This list is cobbled together from a reverse of what is
    # reported by the build system. A better way ...
    pcmap[requires]="piro trilinoscouplings stokhos_muelu stokhos_ifpack2 stokhos_amesos2_mp_16_openmp stokhos_amesos2 stokhos_xpetra stokhos_tpetra stokhos_sacado stokhos shylu_ddbddc rol shylu_ddfrosch muelu-adapters locaepetra locathyra localapack muelu-interface loca muelu noxepetra noxlapack nox teko ifpack2-adapters ifpack2 stratimikos fei_trilinos fei_base stratimikosamesos2 stratimikosml stratimikosaztecoo stratimikosamesos ModeLaplace stratimikosbelos stratimikosifpack anasazitpetra anasaziepetra anasazi belostpetra stk_balance_lib belosxpetra belosepetra moertel belos ml stk_balance_test_utils zoltan2 galeri-epetra galeri-xpetra xpetra-sup amesos2 xpetra optipack stk_tools_lib thyratpetra stk_transfer_utils_lib tpetrainout tpetraext stk_transfer_impl stk_search_util_base tpetra kokkostsqr stk_search kokkoskernels ifpack stk_mesh_fixtures stk_unit_test_utils thyraepetraext stk_io_util isorropia amesos stk_io epetraext thyraepetra rythmos stk_ngp Ionit stk_mesh_base Ioexo_fac Iofx komplex triutils aztecoo thyracore dpliris io_info_lib Iogn Iogs Iotr Iohb epetra Ioex Iovs Iopg Ioss phalanx stk_expreval intrepid globipack sacado tpetraclassicnodeapi rtop stk_topology tpetraclassiclinalg tpetraclassic teuchosnumerics stk_util_diag teuchoskokkoscomm teuchoscomm stk_util_env teuchoskokkoscompat stk_util_parallel stk_util_command_line teuchosparameterlist mapvarlib stk_util_util stk_util_registry zoltan aprepro_lib exodus_for exoIIv2for32 nemesis teuchosparser exodus pamgen teuchosremainder chaco teuchoscore suplib stk_ngp_test trilinosss kokkosalgorithms kokkoscontainers gtest stk_math kokkoscore suplib_cpp supes shards pamgen_extras suplib_c"

    pcFileWriteOverallPackageFile "${prefix}/lib/pkgconfig/trilinos-cxx.pc" pcmap
    # Fortran?
}

function trilinosInstallModuleFile {

    local module_template=${script_dir}/modulefile.tcl

    # Destination
    local module_dir=$(moduleInstallDirectory)

    if [[ ! -d ${module_dir}/trilinos ]]; then
	mkdir ${module_dir}/trilinos
    fi

    local module_file=${module_dir}/trilinos/${TRILINOS_VERSION}

    # Copy add update the template
    cp ${module_template} ${module_file}
    sed -i "s%TEMPLATE_INSTALL_ROOT%${prefix}%" ${module_file}
    sed -i "s%TEMPLATE_TRILINOS_VERSION%${TRILINOS_VERSION}%" ${module_file}

    # Make sure hdf5 is loaded.
    trilinosLoadModuleDependencies
    local vers=${CRAY_HDF5_PARALLEL_VERSION}
    sed -i "s%TEMPLATE_HDF5PARALLEL_VERSION%${vers}%" ${module_file}

    sed -i "s%TEMPLATE_PARMETIS_VERSION%${PARMETIS_VERSION}%" ${module_file}
    sed -i "s%TEMPLATE_SCOTCH_VERSION%${SCOTCH_VERSION}%" ${module_file}
    sed -i "s%TEMPLATE_MUMPS_VERSION%${MUMPS_VERSION}%" ${module_file}
    sed -i "s%TEMPLATE_SUPERLU_VERSION%${SUPERLU_VERSION}%" ${module_file}
    sed -i "s%TEMPLATE_SUPERLUDIST_VERSION%${SUPERLUDIST_VERSION}%" ${module_file}
    
    # Ensure this has worked
    module use ${module_dir}
    module load trilinos/${TRILINOS_VERSION}
    module unload trilinos
}

function trilinosInstallationTest {

    ${test_cce} && trilinosTest PrgEnv-cray
    ${test_gnu} && trilinosTest PrgEnv-gnu
    ${test_amd} && trilinosTest PrgEnv-aocc
}

function trilinosTest {

    # See comments in the associated README.md
    
    local prgenv=${1}
    local module_use=$(moduleInstallDirectory)

    printf "Trilinos test for %s\n" "${prgenv}"
    module restore $(moduleCollection ${prgenv})
    module use ${module_use}

    module load trilinos/${TRILINOS_VERSION}

    cd trilinos-${TRILINOS_VERSION}

    cp ${script_dir}/src_file.[ch]pp .
    cp ${script_dir}/main_file.cpp .
    CC -D MYAPP_EPETRA -o test_app src_file.cpp main_file.cpp

    cp ${script_dir}/input-ex1.xml input.xml
    slurmAllocRun "srun -n 4 ./test_app"

    cp ${script_dir}/input-ex2.xml input.xml
    slurmAllocRun "srun -n 2 ./test_app"

    cd -
    module unload trilinos
}

main
