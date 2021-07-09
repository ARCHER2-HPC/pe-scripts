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

    ${build_amd} && matioBuildAocc ${install_root}
    ${build_cce} && matioBuildCray ${install_root}
    ${build_gnu} && matioBuildGnu  ${install_root}

    matioInstallModuleFile
    matioInstallationTest

    printf "ARCHER2: Matio installation was successful\n"
}

function matioBuildAocc {

    local install_root=${1}
    
    # restore pe/compiler
    module restore $(moduleCollection PrgEnv-aocc)
    module swap aocc aocc/${PE_AOCC_AOCC_VERSION}
    module list

    amd_version=$(moduleToCompilerMajorMinor)
    amd_root=${install_root}/AOCC
    amd_prefix=${amd_root}/${amd_version}

    matioBuild ${amd_prefix}
}

function matioBuildCray {

    local install_root=${1}

    module restore $(moduleCollection PrgEnv-cray)
    module swap cce cce/${PE_CRAY_CCE_VERSION}
    module list

    cray_version=$(moduleToCompilerMajorMinor)
    cray_root=${install_root}/CRAYCLANG
    cray_prefix=${cray_root}/${cray_version}

    matioBuild ${cray_prefix}
}

function matioBuildGnu {    

    local install_root=${1}

    module restore $(moduleCollection PrgEnv-gnu)
    module swap gcc gcc/${PE_GNU_GCC_VERSION}
    module list

    gnu_version=$(moduleToCompilerMajorMinor)
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

    ./sh/tpsl/matio.sh --jobs=16 --prefix=${prefix} \
		       --version=${MATIO_VERSION}

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

    ${test_cce} && matioTest PrgEnv-cray
    ${test_gnu} && matioTest PrgEnv-gnu
    ${test_amd} && matioTest PrgEnv-aocc
}

function matioTest {

    local prgenv=${1}
    local module_use=$(moduleInstallDirectory)
    local version=${MATIO_VERSION}

    printf "Matio test for %s\n" "${prgenv}"
    module restore $(moduleCollection ${prgenv})
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
    module unload matio
}

main
