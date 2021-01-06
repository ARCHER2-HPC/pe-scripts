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

    local install_root=${prefix}/libs/hypre/${HYPRE_VERSION}

    hypreBuildCray ${install_root}
    hypreBuildGnu  ${install_root}
    hypreBuildAocc ${install_root}

    hypreInstallModuleFile
    hypreInstallationTest

    printf "HYPRE installed successfully\n"
}

function hypreBuildAocc {

    local install_root=${1}
    
    # buildVersion AOCC 2.1
    module -s restore PrgEnv-aocc

    amd_version=2.1
    amd_root=${install_root}/AOCC
    amd_prefix=${amd_root}/${amd_version}

    hypreBuild ${amd_prefix}
}

function hypreBuildCray {

    local install_root=${1}

    # buildVersion CRAYCLANG 10.0
    module -s restore PrgEnv-cray
    
    cray_version=10.0
    cray_root=${install_root}/CRAYCLANG
    cray_prefix=${cray_root}/${cray_version}

    hypreBuild ${cray_prefix}
}

function hypreBuildGnu {    

    local install_root=${1}

    # buildVersion GNU 9.3
    module -s restore PrgEnv-gnu
    module swap gcc gcc/9.3.0
    
    gnu_version=9.3
    gnu_root=${install_root}/GNU
    gnu_prefix=${gnu_root}/${gnu_version}

    hypreBuild ${gnu_prefix}
}

function hypreBuild {

    local prefix=${1}
    
    # Build OpenMP version, then MPI only version
    hypreClean
    hypreBuildMPIOpenMP ${prefix}
    hypreClean
    hypreBuildMPI ${prefix}

    hyprePackageConfigFiles ${prefix}
}

function hypreClean {

    rm -rf hypre-${HYPRE_VERSION}
}

function hypreBuildMPI {

    # libHYPRE.a is generated (with captial HYPRE)

    local prefix=${1}

    ./sh/tpsl/hypre.sh --jobs=16 --prefix=${prefix} --modules

    local pe=$(peEnvLower)
    local newname=libHYPRE_${pe}_mpi.a

    mv ${prefix}/lib/libHYPRE.a ${prefix}/lib/${newname}
    ccSharedFromStatic ${prefix}/lib HYPRE_${pe}_mpi
}

function hypreBuildMPIOpenMP {

    # libHYPRE.a is generated by build

    local prefix=${1}

    local pe=$(peEnvLower)
    local newname=libHYPRE_${pe}_mpi_mp.a

    ./sh/tpsl/hypre.sh --jobs=16 --prefix=${prefix} --openmp --modules
    mv ${prefix}/lib/libHYPRE.a ${prefix}/lib/${newname}
    ccSharedFromStatic ${prefix}/lib HYPRE_${pe}_mpi_mp
}

function hyprePackageConfigFiles {

    # Here we declare the necessary information required to generate
    # pkgconfig files
    
    local prefix=${1}
    local prgEnv=$(peEnvLower)
    
    declare -A pcmap
    pcmap[name]="hypre"
    pcmap[version]=${HYPRE_VERSION}
    pcmap[description]="hypre library for ${prgEnv}"
    pcmap[has_openmp]=1

    pcmap[requires]="HYPRE_${prgEnv}_mpi"

    pcmap[extra_libs]=""
    if [[ "${prgEnv}" == "aocc" ]]; then
        pcmap[extra_libs]="-lm"
    fi

    pcRefactorPackageConfigFiles ${prefix} pcmap
    pcFileWriteOverallPackageFile "${prefix}/lib/pkgconfig/hypre.pc" pcmap
}

function hypreInstallModuleFile {

    local module_template=${script_dir}/modulefile.tcl

    # Destination
    local module_dir=$(moduleInstallDirectory)

    if [[ ! -d ${module_dir}/hypre ]]; then
	mkdir ${module_dir}/hypre
    fi

    local module_file=${module_dir}/hypre/${HYPRE_VERSION}

    # Copy add update the template
    cp ${module_template} ${module_file}
    sed -i "s%TEMPLATE_INSTALL_ROOT%${prefix}%" ${module_file}
    sed -i "s%TEMPLATE_HYPRE_VERSION%${HYPRE_VERSION}%" ${module_file}

    # Ensure this has worked
    module use ${module_dir}
    module load hypre/${HYPRE_VERSION}
    module unload hypre
}

function hypreInstallationTest {

    hypreTest PrgEnv-cray
    hypreTest PrgEnv-gnu
    hypreTest PrgEnv-aocc

}

function hypreTest {

    local prgenv=${1}
    local module_use=$(moduleInstallDirectory)

    printf "Hypre test for %s\n" "${prgenv}"
    module -s restore ${prgenv}
    module use ${module_use}

    module load hypre/${HYPRE_VERSION}

    # Remove shared objects from the package config stage
    rm -f ${HYPRE_DIR}/lib/*.so

    # First compile examples
    # Then move to test directory to run the driver
    cd hypre-${HYPRE_VERSION}/src/examples

    cp ${script_dir}/Makefile.examples Makefile
    make clean
    make
    cd -

    cd hypre-${HYPRE_VERSION}/src/test
    sed -i 's/type -p mpirun/type -p srun/' runtest.sh
    sed -i 's/Prefix -np/Prefix -n/' runtest.sh

    slurmAllocRun "./runtest.sh -t TEST_examples/*sh"

    # Compile OpenMP tests in test directory; but not run
    cp ${script_dir}/Makefile.test Makefile
    make clean
    make all

    make clean
    make all COMPFLAG=-fopenmp FOMPFLAG=-fopenmp
    
    cd -
}

main
