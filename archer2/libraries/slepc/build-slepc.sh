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

    local install_root=${prefix}/libs/slepc/${SLEPC_VERSION}

    slepcBuildCray ${install_root}
    slepcBuildGnu  ${install_root}
    # AOCC is omitted pending availability of working PETSc
    #slepcBuildAocc ${install_root}

    slepcInstallModuleFile
    slepcInstallationTest
}

function slepcLoadModuleDependencies {

    moduleUseLibs
    module load petsc/${PETSC_VERSION}

}

function slepcBuildAocc {

    local install_root=${1}
    
    # buildVersion AOCC 2.1
    module -s restore PrgEnv-aocc

    slepcLoadModuleDependencies
    module list

    amd_version=2.1
    amd_root=${install_root}/AOCC
    amd_prefix=${amd_root}/${amd_version}

    slepcBuild ${amd_prefix}
}

function slepcBuildCray {

    local install_root=${1}

    # buildVersion CRAYCLANG 10.0
    module -s restore PrgEnv-cray

    slepcLoadModuleDependencies
    module list

    cray_version=10.0
    cray_root=${install_root}/CRAYCLANG
    cray_prefix=${cray_root}/${cray_version}

    slepcBuild ${cray_prefix}

    # Package config file
    # The Cflags: argument has -Wno-unused-command-line-argument
    # which will crash Fortran, so remove it.

    sed -i 's/^Cflags.*/Cflags: -I${includedir}/' ${cray_prefix}/lib/pkgconfig/slepc.pc
}

function slepcBuildGnu {    

    local install_root=${1}

    # buildVersion GNU 9.3
    module -s restore PrgEnv-gnu
    module swap gcc gcc/9.3.0

    slepcLoadModuleDependencies
    module list

    gnu_version=9.3
    gnu_root=${install_root}/GNU
    gnu_prefix=${gnu_root}/${gnu_version}

    slepcBuild ${gnu_prefix}
}

function slepcBuild {

    local prefix=${1}
    
    slepcClean
    slepcBuildMPIOpenMP ${prefix}

    slepcPackageConfigFiles "${prefix}"
    # Remove temp shared object used only for pkgconfig step
    rm ${prefix}/lib/lib*.so
}

function slepcClean {

    rm -rf slepc-${SLEPC_VERSION}

}

function slepcBuildMPIOpenMP {

    # Build produces libslepc.a

    local prefix=${1}
    local pe=$(peEnvLower)

    ./sh/slepc.sh --jobs=16 --prefix=${prefix} --openmp --modules \
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

    # SLEPC produces its own "SLEPc.pc" which we will remove
    # as it will fail looking for "PETSc"
    rm ${prefix}/lib/pkgconfig/SLEPc.pc

    pcRefactorPackageConfigFiles ${prefix} pcmap
    pcFileWriteOverallPackageFile "${prefix}/lib/pkgconfig/slepc.pc" pcmap

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
    module unload slepc
}

function slepcInstallationTest {

    slepcTest PrgEnv-cray
    slepcTest PrgEnv-gnu

    # AOCC not working. Link fails to complete in any reasonable time.
    # slepcTest PrgEnv-aocc
}

function slepcTest {

    local prgenv=${1}
    local module_use=$(moduleInstallDirectory)

    printf "Slepc test for %s\n" "${prgenv}"
    module -s restore ${prgenv}
    module use ${module_use}

    module load slepc/${SLEPC_VERSION}
    printf "SLEPC_DIR: %s\n" "${SLEPC_DIR}"

    cd slepc-${SLEPC_VERSION}

    # Standard "make check"

    slurmAllocRun "make SLEPC_DIR=${SLEPC_DIR} PETSC_DIR=${PETSC_DIR} \
                   PETSC_ARCH= check"

    cd -
}

main