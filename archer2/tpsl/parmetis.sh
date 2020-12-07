#!/usr/bin/env bash

set -e

script="$(readlink -fm "$0")"
script_root="$(dirname "${script%/*}")"

source ${script_root}/pkgconfig-lib.sh
source ${script_root}/versions.sh
source ${script_root}/command_line.sh

function main {

    # Overall prefix must be supplied by command line

    local install_root=${prefix}/metis/${PARMETIS_VERSION}

    metisBuildCray ${install_root}
    metisBuildGnu  ${install_root}
    metisBuildAocc ${install_root}

}

function parmetisBuildAocc {

    local install_root=${1}
    
    # buildVersion AOCC 2.1
    module -s restore PrgEnv-aocc

    amd_version=2.1
    amd_root=${install_root}/AOCC
    amd_prefix=${amd_root}/${amd_version}

    parmetisBuild ${amd_prefix}
}

function parmetisBuildCray {

    local install_root=${1}

    # buildVersion CRAYCLANG 10.0
    module -s restore PrgEnv-cray

    cray_version=10.0
    cray_root=${install_root}/CRAYCLANG
    cray_prefix=${cray_root}/${cray_version}

    parmetisBuild ${cray_prefix}
}

function parmetisBuildGnu {    

    local install_root=${1}

    # buildVersion GNU 9.3
    module -s restore PrgEnv-gnu
    module swap gcc gcc/9.3.0

    gnu_version=9.3
    gnu_root=${install_root}/GNU
    gnu_prefix=${gnu_root}/${gnu_version}

    parmetisBuild ${gnu_prefix}
}

function parmetisBuild {

    local prefix=${1}
    
    # Build OpenMP first and then Serial (prevents clobbering serial version)
    parmetisClean
    parmetisBuildOpenMP ${prefix}
    parmetisClean
    parmetisBuildSerial ${prefix}

    parmetisPackageConfigFiles ${prefix}
}

# Remove any existing build directories

function parmetisClean {
    rm -rf parmetis-${METIS_VERSION}
}

function parmetisBuildSerial {

    # libmetis.a is generated

    local prefix=${1}
    printf "Build parmetis with prefix %s\n" "${prefix}"

    ./sh/tpsl/parmetis.sh --jobs=16 --prefix=${prefix}

    local pe=$(peEnvLower)
    local newname=libmetis_${pe}.a

    mv ${prefix}/lib/libmetis.a ${prefix}/lib/${newname}
    ccSharedFromStatic ${prefix}/lib metis_${pe}
}

function metisBuildOpenMP {

    # libmetis_mp.a is generated

    local prefix=${1}
    printf "Build metis OpenMP with prefix %s\n" "${prefix}"

    local pe=$(peEnvLower)
    local newname=libmetis_${pe}_mp.a

    ./sh/tpsl/metis.sh --jobs=16 --prefix=${prefix} --openmp
    mv ${prefix}/lib/libmetis.a ${prefix}/lib/${newname}
    ccSharedFromStatic ${prefix}/lib metis_${pe}_mp
}

function metisPackageConfigFiles {

    # Here we declare the necessary information required to generate
    # pkgconfig files
    
    local prefix=${1}
    
    declare -A pcmap
    pcmap[name]="metis"
    pcmap[version]=${METIS_VERSION}
    pcmap[description]="metis library for compiler"
    pcmap[has_openmp]=1
    
    pcPackageConfigFiles ${prefix} pcmap
}

main