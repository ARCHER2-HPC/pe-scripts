#!/usr/bin/env bash

set -e

# script: full path to this script
# script_dir: this metis directory
# script_root: /path/as/far/as/archer2 directory

script="$(readlink -fm "$0")"
script_dir="$(dirname "${script}")"
script_root="$(dirname "${script%/*/*}")"

source ${script_root}/pkgconfig-lib.sh
source ${script_root}/versions.sh
source ${script_root}/command_line.sh

function main {

    # Overall prefix must be supplied by command line

    local install_root=${prefix}/libs/metis/${METIS_VERSION}

    metisBuildCray ${install_root}
    metisBuildGnu  ${install_root}
    metisBuildAocc ${install_root}

    metisInstallModuleFile
    metisInstallationTest
}

function metisBuildAocc {

    local install_root=${1}
    
    # buildVersion AOCC 2.1
    module -s restore PrgEnv-aocc
    module list

    amd_version=2.1
    amd_root=${install_root}/AOCC
    amd_prefix=${amd_root}/${amd_version}

    metisBuild ${amd_prefix}
}

function metisBuildCray {

    local install_root=${1}

    # buildVersion CRAYCLANG 10.0
    module -s restore PrgEnv-cray
    module list

    cray_version=10.0
    cray_root=${install_root}/CRAYCLANG
    cray_prefix=${cray_root}/${cray_version}

    metisBuild ${cray_prefix}
}

function metisBuildGnu {    

    local install_root=${1}

    # buildVersion GNU 9.3
    module -s restore PrgEnv-gnu
    module swap gcc gcc/9.3.0
    module list

    gnu_version=9.3
    gnu_root=${install_root}/GNU
    gnu_prefix=${gnu_root}/${gnu_version}

    metisBuild ${gnu_prefix}
}

function metisBuild {

    local prefix=${1}
    
    # Build OpenMP first and then Serial (prevents clobbering serial version)
    metisClean
    metisBuildOpenMP ${prefix}
    metisClean
    metisBuildSerial ${prefix}

    metisPackageConfigFiles ${prefix}
}

function metisClean {

    rm -rf metis-${METIS_VERSION}

}

function metisBuildSerial {

    # libmetis.a is generated

    local prefix=${1}
    printf "Build metis with prefix %s\n" "${prefix}"

    ./sh/tpsl/metis.sh --jobs=16 --prefix=${prefix} --version=${METIS_VERSION}

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

    ./sh/tpsl/metis.sh --jobs=16 --prefix=${prefix} --openmp --version=${METIS_VERSION}
    mv ${prefix}/lib/libmetis.a ${prefix}/lib/${newname}
    ccSharedFromStatic ${prefix}/lib metis_${pe}_mp
}

function metisPackageConfigFiles {

    # Here we declare the necessary information required to generate
    # pkgconfig files
    
    local prefix=${1}
    local prgEnv=$(peEnvLower)
    
    declare -A pcmap
    pcmap[name]="metis"
    pcmap[version]=${METIS_VERSION}
    pcmap[description]="metis library for ${prgEnv} compiler"
    pcmap[has_openmp]=1
    pcmap[extra_libs]=""

    if [[ "${prgEnv}" == "aocc" ]]; then
	# AOCC requires -lm to ensure resolve math.h stuff
	pcmap[extra_libs]="-lm"
    fi

    pcmap[requires]="metis_${prgEnv}"

    pcRefactorPackageConfigFiles ${prefix} pcmap
    pcFileWriteOverallPackageFile "${prefix}/lib/pkgconfig/metis.pc" pcmap
}

function metisInstallModuleFile {

    local module_template=${script_dir}/modulefile.tcl

    # Destination
    local module_dir=$(moduleInstallDirectory)
    local time_stamp=$(date)

    if [[ ! -d ${module_dir}/metis ]]; then
	mkdir ${module_dir}/metis
    fi

    local module_file=${module_dir}/metis/${METIS_VERSION}

    # Copy add update the template
    cp ${module_template} ${module_file}
    sed -i "s%TEMPLATE_INSTALL_ROOT%${prefix}%" ${module_file}
    sed -i "s%TEMPLATE_METIS_VERSION%${METIS_VERSION}%" ${module_file}
    sed -i "s%TEMPLATE_TIMESTAMP%${time_stamp}%" ${module_file}

    module use ${module_dir}
    module load metis/${METIS_VERSION}
    module unload metis
}

function metisInstallationTest {

    metisTest PrgEnv-cray
    metisTest PrgEnv-gnu
    metisTest PrgEnv-aocc

    printf "Completed metis installation test successfully\n"
}

function metisTest {

    local prgenv=${1}
    local module_use=$(moduleInstallDirectory)
    local graph_dir="graphs" # standard metis inputs

    printf "Metis installation test for %s\n" "${prgenv}"

    module -s restore ${prgenv}
    module use ${module_use}

    module load metis/${METIS_VERSION}

    # Remove shared objects here
    rm -f ${METIS_DIR}/lib/*so
    
    cd metis-${METIS_VERSION}

    cp ${script_dir}/metis-install-test.c .
    cc -fopenmp metis-install-test.c
    ./a.out

    cp ${script_dir}/metis*f90 .
    ftn metis.f90 metis-install-test.f90
    ./a.out

    # Standalone utilities: gpmetis, mpmetis, ndmetis, m2gmetis

    gpmetis ${graph_dir}/test.mgraph 4
    gpmetis ${graph_dir}/4elt.graph 5
    mpmetis ${graph_dir}/metis.mesh 8
    ndmetis ${graph_dir}/copter2.graph 7
    m2gmetis ${graph_dir}/metis.mesh /dev/null

    cd -
}

main
