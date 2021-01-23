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

    local install_root=${prefix}/libs/mumps/${MUMPS_VERSION}

    mumpsBuildCray ${install_root}
    mumpsBuildGnu  ${install_root}
    mumpsBuildAocc ${install_root}

    mumpsInstallModuleFile
    mumpsInstallationTest
}

function mumpsBuildAocc {

    local install_root=${1}
    
    # buildVersion AOCC 2.1
    module -s restore PrgEnv-aocc

    moduleUseLibs
    module load parmetis/${PARMETIS_VERSION}
    module load scotch/${SCOTCH_VERSION}
    module list

    amd_version=2.1
    amd_root=${install_root}/AOCC
    amd_prefix=${amd_root}/${amd_version}

    mumpsBuild ${amd_prefix}
}

function mumpsBuildCray {

    local install_root=${1}

    # buildVersion CRAYCLANG 10.0
    module -s restore PrgEnv-cray

    moduleUseLibs
    module load parmetis/${PARMETIS_VERSION}
    module load scotch/${SCOTCH_VERSION}
    module list

    cray_version=10.0
    cray_root=${install_root}/CRAYCLANG
    cray_prefix=${cray_root}/${cray_version}

    mumpsBuild ${cray_prefix}
}

function mumpsBuildGnu {    

    local install_root=${1}

    # buildVersion GNU 9.3
    module -s restore PrgEnv-gnu
    module swap gcc gcc/9.3.0

    moduleUseLibs
    module load parmetis/${PARMETIS_VERSION}
    module load scotch/${SCOTCH_VERSION}
    module list

    gnu_version=9.3
    gnu_root=${install_root}/GNU
    gnu_prefix=${gnu_root}/${gnu_version}

    mumpsBuild ${gnu_prefix}
}

function mumpsBuild {

    local prefix=${1}
    
    # Build OpenMP first and then MPI
    mumpsClean
    mumpsBuildMPIOpenMP ${prefix}
    mumpsClean
    mumpsBuildMPI ${prefix}

    mumpsPackageConfigFiles ${prefix}

    # Clear up temporaryy shared objects
    rm ${prefix}/lib/lib*.so

}

function mumpsClean {

    rm -rf MUMPS_${MUMPS_VERSION}

}

function mumpsBuildMPI {

    # The build generates:
    # lib[cdsz]mumps.a (4 archives)
    # libmumps_common.a
    # libpord.a

    local prefix=${1}

    ./sh/tpsl/mumps.sh --jobs=8 --prefix=${prefix} --modules \
		       --version=${MUMPS_VERSION}

    local pe=$(peEnvLower)
    local prefixlib="${prefix}/lib"
    
    for lib in cmumps dmumps smumps zmumps mumps_common pord; do
      mv ${prefixlib}/lib${lib}.a ${prefixlib}/lib${lib}_${pe}_mpi.a
      ccSharedFromStatic ${prefixlib} ${lib}_${pe}_mpi
    done
}

function mumpsBuildMPIOpenMP {

    # See MPI build above for comments

    local prefix=${1}

    ./sh/tpsl/mumps.sh --jobs=16 --prefix=${prefix} --openmp --modules \
		       --version=${MUMPS_VERSION}

    local pe=$(peEnvLower)
    local prefixlib="${prefix}/lib"
    
    for lib in cmumps dmumps smumps zmumps mumps_common pord; do
      mv ${prefixlib}/lib${lib}.a ${prefixlib}/lib${lib}_${pe}_mpi_mp.a
      ccSharedFromStatic ${prefixlib} ${lib}_${pe}_mpi_mp
    done
}

function mumpsPackageConfigFiles {

    # Here we declare the necessary information required to generate
    # pkgconfig files
    
    local prefix=${1}
    local prgEnv=$(peEnvLower)
    local ext="${prgEnv}_mpi"

    declare -A pcmap
    pcmap[name]="mumps"
    pcmap[version]=${MUMPS_VERSION}
    pcmap[description]="mumps library for ${prgEnv}"
    pcmap[has_openmp]=1

    # While AOCC OpenMP is unreliable, disable with expedient...
    if [[ "${prgEnv}" == "aocc" ]]; then
	pcmap[has_openmp]=0
    fi
    
    pcmap[requires]="smumps_${ext} dmumps_${ext} cmumps_${ext} zmumps_${ext} mumps_common_${ext} pord_${ext}"

    pcRefactorPackageConfigFiles ${prefix} pcmap
    pcFileWriteOverallPackageFile "${prefix}/lib/pkgconfig/mumps.pc" pcmap
}

function mumpsInstallModuleFile {

    local module_template=${script_dir}/modulefile.tcl

    # Destination
    local module_dir=$(moduleInstallDirectory)

    if [[ ! -d ${module_dir}/mumps ]]; then
	mkdir ${module_dir}/mumps
    fi

    local module_file=${module_dir}/mumps/${MUMPS_VERSION}

    # Copy add update the template
    cp ${module_template} ${module_file}
    sed -i "s%TEMPLATE_INSTALL_ROOT%${prefix}%" ${module_file}
    sed -i "s%TEMPLATE_MUMPS_VERSION%${MUMPS_VERSION}%" ${module_file}

    sed -i "s%TEMPLATE_PARMETIS_VERSION%${PARMETIS_VERSION}%" ${module_file}
    sed -i "s%TEMPLATE_SCOTCH_VERSION%${SCOTCH_VERSION}%" ${module_file}
    
    # Ensure this has worked
    module use ${module_dir}
    module load mumps/${MUMPS_VERSION}
    module unload mumps
}

function mumpsInstallationTest {

    mumpsTest PrgEnv-cray
    mumpsTest PrgEnv-gnu
    mumpsTest PrgEnv-aocc

}

function mumpsTest {

    local prgenv=${1}
    local module_use=$(moduleInstallDirectory)

    printf "Mumps test for %s\n" "${prgenv}"
    module -s restore ${prgenv}
    module use ${module_use}

    module load mumps/${MUMPS_VERSION}
    printf "MUMPS_DIR: %s\n" "${MUMPS_DIR}"

    cd MUMPS_${MUMPS_VERSION}/examples
    cp ${script_dir}/Makefile.examples Makefile

    make clean
    make all
    slurmAllocRun "make test"

    make clean
    make OMPFLAG=-fopenmp all
    export OMP_NUM_THREADS=2
    slurmAllocRun "make test"

    cd ../..
}

main
