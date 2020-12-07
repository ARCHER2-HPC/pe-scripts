#!/usr/bin/env bash

set -e

# Common functions plus command line argument processing

prefix=${TMPDIR:-/tmp}/$USER

for arg in "$@" ; do

    case $arg in
    -prefix=* | --prefix=*)
    prefix="${arg#*=}"
    shift
    ;;
    esac
done

printf "Overall install prefix: %s\n" "${prefix}"


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
    
    local cse_root=${prefix}
    echo "${cse_root}/archer2-modules/modulefiles-cse-libs"
}

function moduleUseLibs {

    local cse_root=${prefix}
    module use ${cse_root}/archer2-modules/modulefiles-cse-libs

}
