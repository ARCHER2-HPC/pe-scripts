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

    local install_root=${prefix}/libs/boost/${BOOST_VERSION}

    boostBuildAocc ${install_root}
    boostBuildCray ${install_root}
    boostBuildGnu  ${install_root} "9.3.0"
    boostBuildGnu  ${install_root} "10.1.0"

    boostInstallModuleFile 
    boostInstallationTest

}

function boostBuildAocc {

    local install_root=${1}
    
    # buildVersion AOCC 2.1
    module -s restore PrgEnv-aocc
    module list

    amd_version=2.1
    amd_root=${install_root}/AOCC
    amd_prefix=${amd_root}/${amd_version}

    boostBuild ${amd_prefix}
}

function boostBuildCray {

    local install_root=${1}

    # buildVersion CRAYCLANG 10.0
    module -s restore PrgEnv-cray
    module list

    cray_version=10.0
    cray_root=${install_root}/CRAYCLANG
    cray_prefix=${cray_root}/${cray_version}

    boostBuild ${cray_prefix}
}

function boostBuildGnu {    

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

    boostBuild ${gnu_prefix}
}

function boostBuild {

    local prefix=${1}
    
    boostClean
    boostBuildMPI ${prefix}

    # Package configuration files
    pcCrayPkgGenRunAndProcess ${prefix}
    boostPackageConfigFile ${prefix}

    # Eliminate all shared libraries for now
    IFS="." read -r -a mmp <<< "${BOOST_VERSION}"

    rm ${prefix}/lib/lib*.so
    rm ${prefix}/lib/lib*.so.${mmp[0]}
    rm ${prefix}/lib/lib*.so.${mmp[0]}.${mmp[1]}
    rm ${prefix}/lib/lib*.so.${mmp[0]}.${mmp[1]}.${mmp[2]}

}

function boostClean {

    # Boost, being special, wants to call itself boost_major_minor_patch
    local dir_version=$(echo ${BOOST_VERSION} | tr "." "_")

    rm -rf boost_${dir_version}

}

function boostBuildMPI {

    # Libraries are, as of 1.72, 40-odd archives:
    # libboost_x.a libboost_x.so libboost_x.so.1 ....so.1.72 ....so.1.72.0
    # libboost_exception.a and libboost_test_exec_monitor.a have no .so
    
    local prefix=${1}

    ./sh/boost.sh --jobs=16 --prefix=${prefix} --version=${BOOST_VERSION}

}

function boostPackageConfigFile {

    local prefix=${1}
    local prgEnv=$(peEnvUpper)

    declare -A pcmap
    pcmap[name]="boost"
    pcmap[version]="${BOOST_VERSION}"
    pcmap[description]="boost libraries for ${prgEnv} compiler"
    pcmap[has_openmp]=0
    pcmap[libs]="-lpthread -lm" # AOCC only really

    # Order is important for link stage...
    pcmap[requires]="boost_coroutine boost_log_setup boost_log boost_timer boost_type_erasure boost_wave boost_atomic boost_chrono boost_container boost_fiber boost_context boost_contract boost_date_time boost_filesystem boost_graph_parallel boost_graph boost_mpi boost_iostreams boost_locale boost_math_c99f boost_math_c99l boost_math_c99 boost_math_tr1f boost_math_tr1l boost_math_tr1 boost_prg_exec_monitor boost_program_options boost_random boost_regex boost_wserialization boost_serialization boost_stacktrace_addr2line boost_stacktrace_basic boost_stacktrace_noop boost_system boost_thread boost_unit_test_framework boost_test_exec_monitor boost_exception"

    pcFileWriteOverallPackageFile "${prefix}/lib/pkgconfig/boost-cxx.pc" pcmap

}

function boostInstallModuleFile {

    local module_template=${script_dir}/modulefile.tcl

    # Destination
    local module_dir=$(moduleInstallDirectory)
    local time_stamp=$(date)

    if [[ ! -d ${module_dir}/boost ]]; then
	mkdir ${module_dir}/boost
    fi

    local module_file=${module_dir}/boost/${BOOST_VERSION}

    # Copy add update the template
    cp ${module_template} ${module_file}
    sed -i "s%TEMPLATE_INSTALL_ROOT%${prefix}%" ${module_file}
    sed -i "s%TEMPLATE_BOOST_VERSION%${BOOST_VERSION}%" ${module_file}
    sed -i "s%TEMPLATE_TIMESTAMP%${time_stamp}%" ${module_file}

    # Ensure this has worked
    module use ${module_dir}
    module load boost/${BOOST_VERSION}
    module unload boost

}

function boostInstallationTest {

    boostTest PrgEnv-cray
    boostTest PrgEnv-gnu
    boostTest PrgEnv-aocc
}

function boostTest {

    local prgenv=${1}
    local module_use=$(moduleInstallDirectory)
    local version=${BOOST_VERSION}

    printf "BOOST test for %s\n" "${prgenv}"
    module -s restore ${prgenv}
    module use ${module_use}

    module load boost/${version}

    local src=$(echo $BOOST_VERSION | tr "." "_")
    src="./boost_${src}"

    # A - not completely - random selection of boost examples:
    # 1. boost_graph_parallel depends on boost_mpi
    # 2. boost_log also has significant dependencies on other boost components
    # 3. boost_variant is somewhat random

    boostTest_graph_parallel "${src}"
    boostTest_log "${src}"
    boostTest_variant "${src}"

}

function boostTest_graph_parallel {

    # nb compilation will produce a warning about old-style headers

    local boost_src=${1}

    cd ${boost_src}/libs/graph_parallel/test

    CC -o distributed_page_rank_test distributed_page_rank_test.cpp

    slurmAllocRun "srun -n 2 ./distributed_page_rank_test"

    cd -
}

function boostTest_log {

    local boost_src=${1}

    cd ${boost_src}/libs/log/example/basic_usage

    CC -o main main.cpp
    ./main

    cd -
}

function boostTest_variant {

    local boost_src=${1}

    cd ${boost_src}/libs/variant/test

    CC -o test1 class_a.cpp test1.cpp
    ./test1

    cd -
}

main
