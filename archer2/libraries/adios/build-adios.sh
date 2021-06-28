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

    local install_root=${prefix}/libs/adios/${ADIOS_VERSION}

    adiosBuildCray ${install_root}
    adiosBuildGnu  ${install_root}
    adiosBuildAocc ${install_root}

    adiosInstallModuleFile
    adiosInstallationTest

    printf "ARCHER2: Installation test of adios successful\n"
}

function adiosLoadModuleDependencies {

    moduleUseLibs
    module load cray-hdf5-parallel/${CRAY_HDF5_PARALLEL_VERSION}

}

function adiosBuildAocc {

    local install_root=${1}
    
    # restore pe/compiler
    module restore $(moduleCollection PrgEnv-aocc)
    module swap aocc aocc/${PE_AOCC_AOCC_VERSION}

    adiosLoadModuleDependencies
    module list

    amd_version=$(moduleToCompilerMajorMinor)
    amd_root=${install_root}/AOCC
    amd_prefix=${amd_root}/${amd_version}

    adiosBuild ${amd_prefix}
}

function adiosBuildCray {

    local install_root=${1}

    module restore $(moduleCollection PrgEnv-cray)
    module swap cce cce/${PE_CRAY_CCE_VERSION}

    adiosLoadModuleDependencies
    module list

    cray_version=$(moduleToCompilerMajorMinor)
    cray_root=${install_root}/CRAYCLANG
    cray_prefix=${cray_root}/${cray_version}

    adiosBuild ${cray_prefix}
}

function adiosBuildGnu {    

    local install_root=${1}

    module restore $(moduleCollection PrgEnv-gnu)
    module swap gcc gcc/${PE_GNU_GCC_VERSION}

    adiosLoadModuleDependencies
    module list

    gnu_version=$(moduleToCompilerMajorMinor)
    gnu_root=${install_root}/GNU
    gnu_prefix=${gnu_root}/${gnu_version}

    adiosBuild ${gnu_prefix}
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

    adiosTest PrgEnv-cray
    adiosTest PrgEnv-gnu
    adiosTest PrgEnv-aocc
}

function adiosTest {

    local prgenv=${1}
    local module_use=$(moduleInstallDirectory)

    printf "Adios test for %s\n" "${prgenv}"
    module restore $(moduleCollection ${prgenv})
    module use ${module_use}

    module load adios/${ADIOS_VERSION}
    
    cd adios-${ADIOS_VERSION}/tests/test_src

    cp ${script_dir}/Makefile.nompi Makefile

    make clean
    make
    
    cd -
}

main
