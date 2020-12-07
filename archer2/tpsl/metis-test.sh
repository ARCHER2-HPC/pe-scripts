#!/usr/bin/env bash

set -e


graph_dir=`pwd`/metis-${VERSION}/graphs

function main {

    metisTestCompileCC
    metisTestCompileFortran
    #metisTestgpmetis
    
}

function metisTestCompileCC {

    ${CC} metis-install-test.c
    ./a.out
}

function metisTestCompileFortran {

    ${FC} metis.f90 metis-install-test.f90
    ./a.out
}

main
