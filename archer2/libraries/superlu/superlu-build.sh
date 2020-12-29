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

    local install_root=${prefix}/libs/superlu/${SUPERLU_VERSION}

    superluBuildAocc ${install_root}
    superluBuildCray ${install_root}
    superluBuildGnu  ${install_root}

    superluInstallModuleFile 
    superluInstallationTest
    printf "Completed installation of superlu successfully\n"
}

function superluBuildAocc {

    local install_root=${1}
    
    # buildVersion AOCC 2.1
    module -s restore PrgEnv-aocc

    amd_version=2.1
    amd_root=${install_root}/AOCC
    amd_prefix=${amd_root}/${amd_version}

    superluBuild ${amd_prefix}
}

function superluBuildCray {

    local install_root=${1}

    # buildVersion CRAYCLANG 10.0
    module -s restore PrgEnv-cray
    
    cray_version=10.0
    cray_root=${install_root}/CRAYCLANG
    cray_prefix=${cray_root}/${cray_version}

    superluBuild ${cray_prefix}
}

function superluBuildGnu {    

    local install_root=${1}

    # buildVersion GNU 9.3
    module -s restore PrgEnv-gnu
    module swap gcc gcc/9.3.0
    
    gnu_version=9.3
    gnu_root=${install_root}/GNU
    gnu_prefix=${gnu_root}/${gnu_version}

    superluBuild ${gnu_prefix}
}

function superluBuild {

    local prefix=${1}
    
    superluClean
    superluBuildSerial ${prefix}
    superluPackageConfigFiles ${prefix}
}

function superluClean {
    rm -rf superlu-${SUPERLU_VERSION}
}

function superluBuildSerial {

    # libsuperlu.a is generated

    local prefix=${1}

    ./sh/tpsl/superlu.sh --jobs=16 --prefix=${prefix}

    local pe=$(peEnvLower)
    local newname=libsuperlu_${pe}.a

    mv ${prefix}/lib/libsuperlu.a ${prefix}/lib/${newname}
    ccSharedFromStatic ${prefix}/lib superlu_${pe}
}

function superluPackageConfigFiles {

    # Here we declare the necessary information required to generate
    # pkgconfig files
    
    local prefix=${1}
    local prgEnv=$(peEnvUpper)
    
    declare -A pcmap
    pcmap[name]="superlu"
    pcmap[version]=${SUPERLU_VERSION}
    pcmap[description]="superlu library for ${prgEnv}"
    pcmap[has_openmp]=0
    pcmap[extra_libs]=""

    if [[ "${prgEnv}" == "AOCC" ]]; then
	# Requires explicit -lm
	pcmap[extra_libs]="-lm"
    fi
    
    pcPackageConfigFiles ${prefix} pcmap
}

function superluInstallModuleFile {

    local module_template=${script_dir}/modulefile.tcl

    # Destination
    local module_dir=$(moduleInstallDirectory)

    if [[ ! -d ${module_dir}/superlu ]]; then
	mkdir ${module_dir}/superlu
    fi

    local module_file=${module_dir}/superlu/${SUPERLU_VERSION}

    # Copy add update the template
    cp ${module_template} ${module_file}
    sed -i "s%TEMPLATE_INSTALL_ROOT%${prefix}%" ${module_file}
    sed -i "s%TEMPLATE_SUPERLU_VERSION%${SUPERLU_VERSION}%" ${module_file}

    # Ensure this has worked
    module use ${module_dir}
    module load superlu/${SUPERLU_VERSION}
    module unload superlu

}

function superluInstallationTest {

    superluTest PrgEnv-cray
    superluTest PrgEnv-gnu
    superluTest PrgEnv-aocc

}

function superluTest {

    local prgenv=${1}
    local module_use=$(moduleInstallDirectory)
    local version=${SUPERLU_VERSION}

    printf "Superlu test for %s\n" "${prgenv}"
    module -s restore ${prgenv}
    module use ${module_use}

    module load superlu/${version}

    superluClean
    tar xf v${version}.tar.gz

    # Provide make.inc
    # Remove "-I$(HEADER)" from compilation rule
    cp ${script_dir}/make.inc superlu-${version}

    cd superlu-${version}/EXAMPLE
    sed -i 's/-I\$(HEADER)//' Makefile

    make clean
    make

    # Run examples
    ./superlu

    ./dlinsol   < g20.rua
    ./dlinsolx  < g20.rua
    ./dlinsolx1 < g20.rua
    ./dlinsolx2 < g20.rua
    ./dlinsolx3 < g20.rua

    ./zlinsol   < cg20.cua
    ./zlinsolx  < cg20.cua
    ./zlinsolx1 < cg20.cua
    ./zlinsolx2 < cg20.cua
    ./zlinsolx3 < cg20.cua

    ./ditersol  -h < g20.rua
    ./ditersol1 -h < g20.rua
    ./zitersol  -h < cg20.cua
    ./zitersol1 -h < cg20.cua

    # Fortran (is similar)

    cd ../FORTRAN
    sed -i 's/-I\$(HEADER)//' Makefile

    make clean
    make

    ./df77exm  < ../EXAMPLE/g20.rua
    ./zf77exm  < ../EXAMPLE/cg20.cua

    cd ../..
}

main
