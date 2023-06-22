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

    local install_root=${install_root_libs}/adios/${ADIOS_VERSION}

    ${build_cce} && adiosBuildCray ${install_root}
    ${build_gnu} && adiosBuildGnu  ${install_root}
    ${build_amd} && adiosBuildAocc ${install_root}

    adiosInstallModuleFileLua
    adiosInstallationTest

    printf "ARCHER2: Installation test of adios successful\n"
}

function adiosLoadModuleDependencies {

    # Adios v2 requires cmake >= 3.12

    moduleUseLibs
    module load cmake
    module load cray-hdf5-parallel/${CRAY_HDF5_PARALLEL_VERSION}
}

function adiosUnloadModuleDependencies {

    module unload cray-hdf5-parallel
    module unload cmake
}

function adiosBuildAocc {

    local install_root=${1}
    
    # restore pe/compiler

    module load PrgEnv-aocc
    module load aocc/${PE_AOCC_AOCC_VERSION}

    adiosLoadModuleDependencies
    module list

    amd_version=$(moduleToCompilerMajorMinor)
    amd_root=${install_root}/AOCC
    amd_prefix=${amd_root}/${amd_version}

    adiosBuild ${amd_prefix}

    adiosUnloadModuleDependencies
}

function adiosBuildCray {

    local install_root=${1}

    module load PrgEnv-cray
    module load cce/${PE_CRAY_CCE_VERSION}

    adiosLoadModuleDependencies
    module list

    cray_version=$(moduleToCompilerMajorMinor)
    cray_root=${install_root}/CRAYCLANG
    cray_prefix=${cray_root}/${cray_version}

    adiosBuild ${cray_prefix}

    adiosUnloadModuleDependencies
}

function adiosBuildGnu {    

    local install_root=${1}

    module load PrgEnv-gnu
    module load gcc/${PE_GNU_GCC_VERSION}

    adiosLoadModuleDependencies
    module list

    gnu_version=$(moduleToCompilerMajorMinor)
    gnu_root=${install_root}/GNU
    gnu_prefix=${gnu_root}/${gnu_version}

    adiosBuild ${gnu_prefix}

    adiosUnloadModuleDependencies
}

function adiosBuild {

    local prefix=${1}
    
    adiosClean
    adiosBuildMPI ${prefix}
}

function adiosClean {

    rm -rf adios-${ADIOS_VERSION}

}

function adiosBuildMPI {

    # See MPI build above for comments

    local prefix=${1}

    ./sh/adios.sh --jobs=16 --prefix=${prefix} --version=${ADIOS_VERSION}

}

function adiosInstallModuleFileLua {

    local module_preamble=${script_dir}/module_preamble.lua
    local module_boilerplate=${script_dir}/module_boilerplate.lua

    # Destination
    local module_dir=$(moduleInstallDirectory)

    if [[ ! -d ${module_dir}/adios ]]; then
        mkdir ${module_dir}/adios
    fi

    local module_file=${module_dir}/adios/${ADIOS_VERSION}.lua

    # Copy add update the template

    cat ${module_preamble}     > ${module_file}
    cat ${module_boilerplate} >> ${module_file}

    module use ${module_dir}
    module load adios/${ADIOS_VERSION}

    cc --cray-print-opts

    module unload adios
    module unuse ${module_dir}
}

function adiosInstallModuleFile {

    local module_template=${script_dir}/modulefile.tcl

    # Destination
    local module_dir=$(moduleInstallDirectory)
    local time_stamp=$(date)

    if [[ ! -d ${module_dir}/adios ]]; then
	mkdir ${module_dir}/adios
    fi

    local module_file=${module_dir}/adios/${ADIOS_VERSION}

    # Copy and update the template
    cp ${module_template} ${module_file}
    sed -i "s%TEMPLATE_INSTALL_ROOT%${prefix}%" ${module_file}
    sed -i "s%TEMPLATE_ADIOS_VERSION%${ADIOS_VERSION}%" ${module_file}
    sed -i "s%TEMPLATE_TIMESTAMP%${time_stamp}%" ${module_file}
   
    # Make sure hdf5 is loaded.
    adiosLoadModuleDependencies
    local vers=${CRAY_HDF5_PARALLEL_VERSION}
    sed -i "s%TEMPLATE_HDF5PARALLEL_VERSION%${vers}%" ${module_file}

    # Ensure this has worked
    module use ${module_dir}
    module load adios/${ADIOS_VERSION}
    module unload adios
}

function adiosInstallationTest {

    ${test_cce} && adiosTest PrgEnv-cray
    ${test_gnu} && adiosTest PrgEnv-gnu
    ${test_amd} && adiosTest PrgEnv-aocc
}

function adiosTest {

    local prgenv=${1}
    local module_use=$(moduleInstallDirectory)

    printf "Adios test for %s\n" "${prgenv}"

    module load ${prgenv}
    module use ${module_use}

    module load adios/${ADIOS_VERSION}
    
    cd adios-${ADIOS_VERSION}/tests/test_src

    cp ${script_dir}/Makefile.nompi Makefile

    make clean
    make
    
    cd -
    module unload adios
}

main
