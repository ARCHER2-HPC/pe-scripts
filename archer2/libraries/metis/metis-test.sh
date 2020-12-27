#!/usr/bin/env bash

set -e

# Standard input graphs which are part of the Metis package for tests...

graph_dir=`pwd`/metis-${METIS_VERSION}/graphs

function metisInstallationTest {

    cd archer2/libraries/metis
    metisTest PrgEnv-cray
    metisTest PrgEnv-gnu
    metisTest PrgEnv-aocc
    cd -
    printf "Completed metis installation test successfully\n"
}

function metisTest {

    local prgenv=${1}
    local module_use=$(moduleInstallDirectory)

    module -s restore ${prgenv}
    module use ${module_use}

    module load metis/${METIS_VERSION}
    
    metisTestCompileC
    metisTestCompileFortran
    metisTestgpmetis
    metisTestmpmetis
    metisTestndmetis
    metisTestm2gmetis
}

function metisTestCompileC {

    # Just run the serial version.
    cc -fopenmp metis-install-test.c
    cc metis-install-test.c
    ./a.out
}

function metisTestCompileFortran {

    ftn -fopenmp metis.f90 metis-install-test.f90
    ftn metis.f90 metis-install-test.f90
    ./a.out
}

function metisTestgpmetis {

    gpmetis -help
    gpmetis ${graph_dir}/test.mgraph 4
    gpmetis ${graph_dir}/4elt.graph 5
}

function metisTestmpmetis {

    mpmetis -help
    mpmetis ${graph_dir}/metis.mesh 8
}

function metisTestndmetis {

    ndmetis -help
    ndmetis ${graph_dir}/copter2.graph 7
}

function metisTestm2gmetis {

    m2gmetis -help
    m2gmetis ${graph_dir}/metis.mesh /dev/null
}
