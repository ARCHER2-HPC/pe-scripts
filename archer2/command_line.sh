#!/usr/bin/env bash

set -e

cse_root=/work/y07/shared

# Common functions plus command line argument processing

prefix=${TMPDIR:-/tmp}/$USER

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
    esac
done

# libraries to: ${install_root_libs}
# modules   to: ${install_root_mods}

install_root_libs=${prefix}/libs
if [[ -n ${modprefix} ]]; then
    install_root_mods=${modprefix}
else
    modprefix=${prefix}
    install_root_mods=${prefix}/archer2-modules/modulefiles-cse-libs
fi

mkdir -p ${install_root_libs}
mkdir -p ${install_root_mods}

# We need ${cse_root}/archer2-modules/archer-modules-tcl.lib
# and     ${cse_root}/archer2-modules/archer-pkgconfig-tcl.lib
# for testing purposes.

if [ ! -f "${modprefix}/archer2-modules/archer-modules-tcl.lib" ]; then
    cp ${cse_root}/archer2-modules/archer-modules-tcl.lib \
       ${modprefix}/archer2-modules/archer-modules-tcl.lib
fi

if [ ! -f "${modprefix}/archer2-modules/archer-pkgconfig-tcl.lib" ]; then
    cp ${cse_root}/archer2-modules/archer-pkgconfig-tcl.lib \
       ${modprefix}/archer2-modules/archer-pkgconfig-tcl.lib
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

function ccSharedFromStatic {

    # Utility to build a shred library from an appropriate static one.

    local prefix=${1}
    local name=${2}

    cc -shared -o ${prefix}/lib${name}.so \
       -Wl,--whole-archive ${prefix}/lib${name}.a -Wl,--no-whole-archive
}

function moduleInstallDirectory {

    # Return path for library modulefiles
    
    echo "${install_root_mods}"
}

function moduleUseLibs {

    module use ${install_root_mods}

}

function slurmAllocRun {

    # Run command if we have a SLURM allocation
    # (which we determine here by checking for non-zero SLURM_JOB_NAME)

    command="${1}"

    if [[ ! -z "${SLURM_JOB_NAME}" ]]; then
        eval "${command}"
    fi

}
