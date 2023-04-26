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

    local install_root=${install_root_libs}/slepc/${SLEPC_VERSION}

    ${build_cce} && slepcBuildCray ${install_root}
    ${build_gnu} && slepcBuildGnu  ${install_root}
    ${build_amd} && slepcBuildAocc ${install_root}

    slepcInstallModuleFileLua
    slepcInstallationTest

    printf "ARCHER2: successful installation and test of SLEPc\n"
}

function slepcLoadModuleDependencies {

    moduleUseLibs
    module load petsc/${PETSC_VERSION}

}

function slepcUnloadModuleDependencies {

    module unload petsc

}

function slepcBuildAocc {

    local install_root=${1}
    
    module load PrgEnv-aocc
    module load aocc/${PE_AOCC_AOCC_VERSION}

    slepcLoadModuleDependencies
    module list

    amd_version=$(moduleToCompilerMajorMinor)
    amd_root=${install_root}/AOCC
    amd_prefix=${amd_root}/${amd_version}

    slepcBuild ${amd_prefix}

    slepcUnloadModuleDependencies
}

function slepcBuildCray {

    local install_root=${1}

    module load PrgEnv-cray
    module load cce/${PE_CRAY_CCE_VERSION}

    slepcLoadModuleDependencies
    module list

    cray_version=$(moduleToCompilerMajorMinor)
    cray_root=${install_root}/CRAYCLANG
    cray_prefix=${cray_root}/${cray_version}

    slepcBuild ${cray_prefix}

    slepcUnloadModuleDependencies

    # Package config file
    # The Cflags: argument has -Wno-unused-command-line-argument
    # which will crash Fortran, so remove it.

    sed -i 's/^Cflags.*/Cflags: -I${includedir}/' ${cray_prefix}/lib/pkgconfig/slepc.pc
}

function slepcBuildGnu {    

    local install_root=${1}

    module load PrgEnv-gnu
    module load gcc/${PE_GNU_GCC_VERSION}

    slepcLoadModuleDependencies
    module list

    gnu_version=$(moduleToCompilerMajorMinor)
    gnu_root=${install_root}/GNU
    gnu_prefix=${gnu_root}/${gnu_version}

    slepcBuild ${gnu_prefix}

    slepcUnloadModuleDependencies
}

function slepcBuild {

    local prefix=${1}
    
    slepcClean
    slepcBuildMPI ${prefix}

    slepcPackageConfigFiles "${prefix}"
    # Remove temp shared object used only for pkgconfig step
    rm ${prefix}/lib/lib*.so
}

function slepcClean {

    rm -rf slepc-${SLEPC_VERSION}

}

function slepcBuildMPI {

    # Build produces libslepc.a

    local prefix=${1}
    local pe=$(peEnvLower)

    ./sh/slepc.sh --jobs=16 --prefix=${prefix} --modules \
		  --version=${SLEPC_VERSION}

    # The pkgconfig integration will look for slepc_crayclang_mpi
    # others may wish to use the original "slepc", so provide a
    # link to ensure that doesn't break.

    cd ${prefix}/lib

    mv libslepc.a libslepc_${pe}_mpi.a
    ln -s libslepc_${pe}_mpi.a libslepc.a

    cd -

    ccSharedFromStatic ${prefix}/lib "slepc_${pe}_mpi"
}

function slepcPackageConfigFiles {

    # Here we declare the necessary information required to generate
    # pkgconfig files
    
    local prefix=${1}
    local prgEnv=$(peEnvLower)
    local ext="${prgEnv}_mpi"

    declare -A pcmap
    pcmap[name]="slepc"
    pcmap[version]=${SLEPC_VERSION}
    pcmap[description]="slepc library for ${prgEnv} compiler"
    pcmap[has_openmp]=0

    pcmap[requires]="slepc_${ext}"

    # SLEPC produces its own "SLEPc.pc" or "slepc.pc" which we will remove
    # as it will fail looking for "PETSc"
    rm -f ${prefix}/lib/pkgconfig/slepc.pc
    rm -f ${prefix}/lib/pkgconfig/SLEPc.pc

    pcRefactorPackageConfigFiles ${prefix} pcmap
    pcFileWriteOverallPackageFile "${prefix}/lib/pkgconfig/slepc.pc" pcmap

}


function slepcInstallModuleFileLua {

    local module_preamble=${script_dir}/module_preamble.lua
    local module_boilerplate=${script_dir}/module_boilerplate.lua

    # Destination
    local module_dir=$(moduleInstallDirectory)

    if [[ ! -d ${module_dir}/slepc ]]; then
        mkdir ${module_dir}/slepc
    fi

    local module_file=${module_dir}/slepc/${SLEPC_VERSION}.lua

    # Copy add update the template

    cat ${module_preamble}     > ${module_file}
    cat ${module_boilerplate} >> ${module_file}

    sed -i "s/PETSC_VERSION_TAG/${PETSC_VERSION}/" ${module_file}

    module use ${module_dir}
    module load slepc/${SLEPC_VERSION}

    cc --cray-print-opts

    module unload slepc
    module unuse ${module_dir}

}

function slepcInstallModuleFile {

    local module_template=${script_dir}/modulefile.tcl

    # Destination
    local module_dir=$(moduleInstallDirectory)

    if [[ ! -d ${module_dir}/slepc ]]; then
	mkdir ${module_dir}/slepc
    fi

    local module_file=${module_dir}/slepc/${SLEPC_VERSION}

    # Copy add update the template
    cp ${module_template} ${module_file}
    sed -i "s%TEMPLATE_INSTALL_ROOT%${prefix}%" ${module_file}
    sed -i "s%TEMPLATE_PETSC_VERSION%${PETSC_VERSION}%" ${module_file}
    sed -i "s%TEMPLATE_SLEPC_VERSION%${SLEPC_VERSION}%" ${module_file}
    
    # Ensure this has worked
    module use ${module_dir}
    module load slepc/${SLEPC_VERSION}

    cc --cray-print-opts

    module unload slepc
    module unuse ${module_dir}
}

function slepcInstallationTest {

    ${test_cce} && slepcTest PrgEnv-cray
    ${test_gnu} && slepcTest PrgEnv-gnu
    ${test_amd} && slepcTest PrgEnv-aocc
}

function slepcTest {

    local prgenv=${1}
    local module_use=$(moduleInstallDirectory)

    printf "Slepc test for %s\n" "${prgenv}"

    module load ${prgenv}
    module use ${module_use}

    module load slepc/${SLEPC_VERSION}
    printf "SLEPC_DIR: %s\n" "${SLEPC_DIR}"

    cd slepc-${SLEPC_VERSION}

    # Standard "make check"

    slurmAllocRun "make SLEPC_DIR=${SLEPC_DIR} PETSC_DIR=${PETSC_DIR} \
                   PETSC_ARCH= check"

    cd -
    module unload slepc
}

main
