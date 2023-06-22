#!/usr/bin/env bash

set -e

# Switch off paging (esp. for long listings)
export LMOD_PAGER="None"

# Library versions
source $(pwd)/archer2/versions.sh

# Default location, PE
cse_root=/work/y07/shared
cpe_version=22.12

# Common functions plus command line argument processing

prefix=${TMPDIR:-/tmp}/$USER

build_cce=true
build_gnu=true
build_amd=true
test_cce=true
test_gnu=true
test_amd=true

for arg in "$@" ; do

    case $arg in
    -prefix=* | --prefix=*)
    prefix="${arg#*=}"
    shift
    ;;
    -modprefix=* | --modprefix=*)
    modprefix="${arg#*=}"
    shift
    ;;
    -cpe=* | --cpe=*)
    cpe_version="${arg#*=}"
    shift
    ;;
    esac
done

# libraries to: ${install_root_libs}
# modules   to: ${install_root_mods}

install_root_libs=${prefix}/libs/core
install_root_utils=${prefix}/utils/core
if [[ -n ${modprefix} ]]; then
    install_root_mods=${modprefix}
else
    modprefix=${prefix}
    install_root_mods=${prefix}/archer2-lmod/libs/core
fi

mkdir -p ${install_root_libs}
mkdir -p ${install_root_mods}
mkdir -p ${prefix}/archer2-lmod/utils/core

# Check programming environment

prgenv_dir="$(pwd)/archer2/module/${cpe_version}"

if [ ! -d "${prgenv_dir}" ]; then
    printf "Programming environment %s not available\n" "${cpe_version}"
    exit -1
else
    source ${prgenv_dir}/defaults.sh
    printf "CPE version:            %s\n" "${cpe_version}"
    printf "Cray CCE version:       %s\n" "${PE_CRAY_CCE_VERSION}"
    printf "Gnu  GCC version:       %s\n" "${PE_GNU_GCC_VERSION}"
    printf "AMD AOCC version:       %s\n" "${PE_AOCC_AOCC_VERSION}"
fi

printf "Overall install prefix: %s\n" "${prefix}"
printf "Libraries to:           %s\n" "${install_root_libs}"
printf "Module files to:        %s\n" "${install_root_mods}"

function peEnvUpper {

    # Return "CRAY" "CRAYCLANG" "GNU" or "AOCC"

    [ -z ${PE_ENV} ] && exit -1

    local pe=${PE_ENV}
    if [ ${pe} == "CRAY" ]; then
	[ ! -z ${CRAY_PE_USE_CLANG} ] && pe="CRAYCLANG" 
    fi

    echo ${pe}
}

function peEnvLower {

    # Return lowercase version of peEnvUpper

    local pe=$(peEnvUpper)

    echo ${pe} | tr '[:upper:]' '[:lower:]'
}

function moduleCollection {

    local prgenv=$1

    echo ${prgenv}
}

function moduleToCompilerMajorMinor {

    # E.g., for currently loaded module cce/10.2.0 return "10.2"

    local str=""

    case ${PE_ENV} in
        "CRAY")
            str=${CRAY_CC_VERSION}
            ;;
        "GNU")
            str=${GCC_VERSION}
            ;;
        "AOCC")
            str=${CRAY_AOCC_VERSION}
            ;;
        *)
            printf "No PE_ENV value\n"
            exit
    esac

    IFS='.' read -r -a array <<< "$str"

    echo "${array[0]}.${array[1]}"
}


function ccSharedFromStatic {

    # Utility to build a shred library from an appropriate static one.

    local prefix=${1}
    local name=${2}

    cc -shared -o ${prefix}/lib${name}.so \
       -Wl,--whole-archive ${prefix}/lib${name}.a -Wl,--no-whole-archive
}

function ftnSharedFromStatic {

    local prefix=${1}
    local name=${2}

    ftn -shared -o ${prefix}/lib${name}.so \
	-Wl,--whole-archive ${prefix}/lib${name}.a -Wl,--no-whole-archive
}



function moduleInstallDirectory {

    # Return path for library modulefiles
    
    echo "${install_root_mods}"
}

function moduleUseLibs {

    module use ${install_root_mods}
    printf "MODULEPATH: %s\n" "${MODULEPATH}"

}

function moduleInstallDirectoryUtils {

    echo "${prefix}/archer2-lmod/utils/core"
}

function moduleUseUtils {

    module use $(moduleInstallDirectoryUtils)

}

function moduleLoad {

    # A wrapper to "module restore" to allow loading of a relevant
    # module file. "PrgEnv-cray" or "PrgEnv-gnu" or "PrgEnv-aocc"

    local prgenv=$1

    module load ${prgenv}
}

function slurmAllocRun {

    # Run command if we have a SLURM allocation
    # (which we determine here by checking for non-zero SLURM_JOB_NAME)

    command="${1}"

    if [[ ! -z "${SLURM_JOB_NAME}" ]]; then
        eval "${command}"
    fi

}
