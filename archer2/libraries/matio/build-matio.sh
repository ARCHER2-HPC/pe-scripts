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

    local install_root=${prefix}/libs/matio/${MATIO_VERSION}

    matioBuildAocc ${install_root}
    matioBuildCray ${install_root}
    matioBuildGnu  ${install_root}

    matioInstallModuleFile
    matioInstallationTest

    printf "Matio installation was successful\n"
}

function matioBuildAocc {

    local install_root=${1}
    
    # buildVersion AOCC 2.1
    module -s restore PrgEnv-aocc

    amd_version=2.1
    amd_root=${install_root}/AOCC
    amd_prefix=${amd_root}/${amd_version}

    matioBuild ${amd_prefix}
}

function matioBuildCray {

    local install_root=${1}

    # buildVersion CRAYCLANG 10.0
    module -s restore PrgEnv-cray
    
    cray_version=10.0
    cray_root=${install_root}/CRAYCLANG
    cray_prefix=${cray_root}/${cray_version}

    matioBuild ${cray_prefix}
}

function matioBuildGnu {    

    local install_root=${1}

    # buildVersion GNU 9.3
    module -s restore PrgEnv-gnu
    module swap gcc gcc/9.3.0
    
    gnu_version=9.3
    gnu_root=${install_root}/GNU
    gnu_prefix=${gnu_root}/${gnu_version}

    matioBuild ${gnu_prefix}
}

function matioBuild {

    local prefix=${1}
    
    matioClean
    matioBuildSerial ${prefix}

}

function matioClean {

    rm -rf matio-${MATIO_VERSION}

}

function matioBuildSerial {

    # libmatio.a is generated
    # the build gives its own pkg-config file which is good enough
    # for the time being
    
    local prefix=${1}

    ./sh/tpsl/matio.sh --jobs=16 --prefix=${prefix}

}

function matioInstallModuleFile {

    local module_template=${script_dir}/modulefile.tcl

    # Destination
    local module_dir=$(moduleInstallDirectory)
    local time_stamp=$(date)

    if [[ ! -d ${module_dir}/matio ]]; then
	mkdir ${module_dir}/matio
    fi

    local module_file=${module_dir}/matio/${MATIO_VERSION}

    # Copy add update the template
    cp ${module_template} ${module_file}
    sed -i "s%TEMPLATE_INSTALL_ROOT%${prefix}%" ${module_file}
    sed -i "s%TEMPLATE_MATIO_VERSION%${MATIO_VERSION}%" ${module_file}
    sed -i "s%TEMPLATE_TIMESTAMP%${time_stamp}%" ${module_file}

    # Ensure this has worked
    module use ${module_dir}
    module load matio/${MATIO_VERSION}
    module unload matio
}

function matioInstallationTest {

    matioTest PrgEnv-cray
    matioTest PrgEnv-gnu
    matioTest PrgEnv-aocc
}

function matioTest {

    local prgenv=${1}
    local module_use=$(moduleInstallDirectory)
    local version=${MATIO_VERSION}

    printf "Matio test for %s\n" "${prgenv}"
    module -s restore ${prgenv}
    module use ${module_use}

    module load matio/${version}

    # PATH should contain "matdump"

    matdump --help

    # Test presence of includes/library

    cd matio-${version}

    cp ${script_dir}/example-test.c .
    cc -o example-test example-test.c
    ./example-test

    cd -
}

main
