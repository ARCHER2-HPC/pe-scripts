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

    ${build_cce} && glmBuildCray ${install_root}
    ${build_gnu} && glmBuildGnu  ${install_root}
    ${build_amd} && glmBuildAocc ${install_root}
    
    glmInstallModuleFile 
    glmInstallationTest

    printf "ARCHER2: glm install/test complete"
}

function glmBuildAocc {

    local install_root=${1}

    # Restore PE/Compiler
    module restore $(moduleCollection PrgEnv-aocc)
    module swap aocc aocc/${PE_AOCC_AOCC_VERSION}
    module list

    amd_version=$(moduleToCompilerMajorMinor)
    amd_root=${install_root}/AOCC
    amd_prefix=${amd_root}/${amd_version}

    glmBuild ${amd_prefix}
}

function glmBuildCray {

    local install_root=${1}

    module restore $(moduleCollection PrgEnv-cray)
    module swap cce cce/${PE_CRAY_CCE_VERSION}
    module list

    cray_version=$(moduleToCompilerMajorMinor)
    cray_root=${install_root}/CRAYCLANG
    cray_prefix=${cray_root}/${cray_version}

    glmBuild ${cray_prefix}
}

function glmBuildGnu {    

    local install_root=${1}

    module restore $(moduleCollection PrgEnv-gnu)
    module swap gcc gcc/${PE_GNU_GCC_VERSION}
    module list

    gnu_version=$(moduleToCompilerMajorMinor)
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

    ${test_cce} && glmTest PrgEnv-cray
    ${test_gnu} && glmTest PrgEnv-gnu
    ${test_amd} && glmTest PrgEnv-aocc
}

function glmTest {

    local prgenv=${1}
    local module_use=$(moduleInstallDirectory)
    local version=${GLM_VERSION}

    printf "GLM test for %s\n" "${prgenv}"
    module restore $(moduleCollection ${prgenv})
    module use ${module_use}

    module load glm/${version}

    cd glm-${version}

    # We assume begin able to locate the include directory is a
    # sufficient test that the installation is correct.

    cp ${script_dir}/test.cpp .
    CC -o test test.cpp
    ./test

    cd -
    module unload glm
}

main
