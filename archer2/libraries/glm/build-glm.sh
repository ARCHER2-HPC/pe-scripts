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

    local install_root=${prefix}/libs/glm/${GLM_VERSION}

    glmBuildAocc ${install_root}
    glmBuildCray ${install_root}
    glmBuildGnu  ${install_root} "9.3.0"
    glmBuildGnu  ${install_root} "10.1.0"
    
    glmInstallModuleFile 
    glmInstallationTest

}

function glmBuildAocc {

    local install_root=${1}
    
    # buildVersion AOCC 2.1
    module -s restore PrgEnv-aocc
    module list

    amd_version=2.1
    amd_root=${install_root}/AOCC
    amd_prefix=${amd_root}/${amd_version}

    glmBuild ${amd_prefix}
}

function glmBuildCray {

    local install_root=${1}

    # buildVersion CRAYCLANG 10.0
    module -s restore PrgEnv-cray
    module list

    cray_version=10.0
    cray_root=${install_root}/CRAYCLANG
    cray_prefix=${cray_root}/${cray_version}

    glmBuild ${cray_prefix}
}

function glmBuildGnu {    

    local install_root=${1}
    local gcc_version=${2}

    module -s restore PrgEnv-gnu
    module swap gcc gcc/${gcc_version}
    module list

    # Directory name is just "major.minor" version
    IFS="." read -r -a mmp <<< "${gcc_version}"
    gnu_version="${mmp[0]}.${mmp[1]}"

    gnu_root=${install_root}/GNU
    gnu_prefix=${gnu_root}/${gnu_version}

    glmBuild ${gnu_prefix}
}

function glmBuild {

    local prefix=${1}
    
    glmClean
    glmBuildSerial ${prefix}

}

function glmClean {

    rm -rf glm-${GLM_VERSION}

}

function glmBuildSerial {

    # GLM produces no libraries, but does produce its own pkg-config
    # which we will use.

    local prefix=${1}

    ./sh/tpsl/glm.sh --jobs=16 --prefix=${prefix} --version=${GLM_VERSION}

}

function glmInstallModuleFile {

    local module_template=${script_dir}/modulefile.tcl

    # Destination
    local module_dir=$(moduleInstallDirectory)
    local time_stamp=$(date)

    if [[ ! -d ${module_dir}/glm ]]; then
	mkdir ${module_dir}/glm
    fi

    local module_file=${module_dir}/glm/${GLM_VERSION}

    # Copy add update the template
    cp ${module_template} ${module_file}
    sed -i "s%TEMPLATE_INSTALL_ROOT%${prefix}%" ${module_file}
    sed -i "s%TEMPLATE_GLM_VERSION%${GLM_VERSION}%" ${module_file}
    sed -i "s%TEMPLATE_TIMESTAMP%${time_stamp}%" ${module_file}

    # Ensure this has worked
    module use ${module_dir}
    module load glm/${GLM_VERSION}
    module unload glm

}

function glmInstallationTest {

    glmTest PrgEnv-cray
    glmTest PrgEnv-gnu
    glmTest PrgEnv-aocc
}

function glmTest {

    local prgenv=${1}
    local module_use=$(moduleInstallDirectory)
    local version=${GLM_VERSION}

    printf "GLM test for %s\n" "${prgenv}"
    module -s restore ${prgenv}
    module use ${module_use}

    module load glm/${version}

    cd glm-${version}

    # We assume begin able to locate the include directory is a
    # sufficient test that the installation is correct.

    cp ${script_dir}/test.cpp .
    CC -o test test.cpp
    ./test

    cd -
}

main
