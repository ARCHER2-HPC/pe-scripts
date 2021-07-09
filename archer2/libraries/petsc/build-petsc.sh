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

    local install_root=${prefix}/libs/petsc/${PETSC_VERSION}

    ${build_cce} && petscBuildCray ${install_root}
    ${build_gnu} && petscBuildGnu  ${install_root}
    ${build_amd} && petscBuildAocc ${install_root}

    petscInstallModuleFile
    petscInstallationTest

    printf "ARCHER2: PETSC install/test complete\n"
}

function petscLoadModuleDependencies {

    moduleUseLibs
    module load cray-hdf5-parallel/${CRAY_HDF5_PARALLEL_VERSION}
    module load parmetis/${PARMETIS_VERSION}
    module load hypre/${HYPRE_VERSION}
    module load scotch/${SCOTCH_VERSION}
    module load mumps/${MUMPS_VERSION}
    module load superlu/${SUPERLU_VERSION}
    module load superlu-dist/${SUPERLUDIST_VERSION}

}

function petscBuildAocc {

    local install_root=${1}
    
    # restore pe/compiler
    module restore $(moduleCollection PrgEnv-aocc)
    module swap aocc aocc/${PE_AOCC_AOCC_VERSION}

    petscLoadModuleDependencies
    module list

    amd_version=$(moduleToCompilerMajorMinor)
    amd_root=${install_root}/AOCC
    amd_prefix=${amd_root}/${amd_version}

    petscBuild ${amd_prefix}
}

function petscBuildCray {

    local install_root=${1}

    module restore $(moduleCollection PrgEnv-cray)
    module swap cce cce/${PE_CRAY_CCE_VERSION}

    petscLoadModuleDependencies
    module list

    cray_version=$(moduleToCompilerMajorMinor)
    cray_root=${install_root}/CRAYCLANG
    cray_prefix=${cray_root}/${cray_version}

    petscBuild ${cray_prefix}

    # Package config file
    # The Cflags: argument has -Wno-unused-command-line-argument
    # which will crash Fortran, so remove it.

    sed -i 's/^Cflags.*/Cflags: -I${includedir}/' ${cray_prefix}/lib/pkgconfig/petsc.pc
}

function petscBuildGnu {    

    local install_root=${1}

    module restore $(moduleCollection PrgEnv-gnu)
    module swap gcc gcc/${PE_GNU_GCC_VERSION}

    petscLoadModuleDependencies
    module list

    gnu_version=$(moduleToCompilerMajorMinor)
    gnu_root=${install_root}/GNU
    gnu_prefix=${gnu_root}/${gnu_version}

    petscBuild ${gnu_prefix}
}

function petscBuild {

    local prefix=${1}
    
    petscClean
    ./sh/petsc.sh --jobs=16 --prefix=${prefix} --modules \
		  --version=${PETSC_VERSION}

    # Use the PETSc.pc file generated by PETSc.

    pcprefix=${prefix}/lib/pkgconfig
    mv ${pcprefix}/PETSc.pc ${pcprefix}/petsc.pc
}

function petscClean {

    rm -rf petsc-${PETSC_VERSION}

}

function petscBuildMPIOpenMP {

    # AOCC 2.1, 2.2 problems can arise at link stage with OpenMP.
    # As PETSc is not a big supporter of OpenMP anyway, prefer "serial"

    local prefix=${1}

    ./sh/petsc.sh --jobs=16 --prefix=${prefix} --openmp --modules \
		  --version=${PETSC_VERSION}
}

function petscInstallModuleFile {

    local module_template=${script_dir}/modulefile.tcl

    # Destination
    local module_dir=$(moduleInstallDirectory)

    if [[ ! -d ${module_dir}/petsc ]]; then
	mkdir ${module_dir}/petsc
    fi

    local module_file=${module_dir}/petsc/${PETSC_VERSION}

    # Copy add update the template
    cp ${module_template} ${module_file}
    sed -i "s%TEMPLATE_INSTALL_ROOT%${prefix}%" ${module_file}
    sed -i "s%TEMPLATE_PETSC_VERSION%${PETSC_VERSION}%" ${module_file}

    # Make sure hdf5 is loaded.
    petscLoadModuleDependencies
    local vers=${CRAY_HDF5_PARALLEL_VERSION}
    sed -i "s%TEMPLATE_HDF5PARALLEL_VERSION%${vers}%" ${module_file}

    sed -i "s%TEMPLATE_PARMETIS_VERSION%${PARMETIS_VERSION}%" ${module_file}
    sed -i "s%TEMPLATE_HYPRE_VERSION%${HYPRE_VERSION}%" ${module_file}
    sed -i "s%TEMPLATE_SCOTCH_VERSION%${SCOTCH_VERSION}%" ${module_file}
    sed -i "s%TEMPLATE_MUMPS_VERSION%${MUMPS_VERSION}%" ${module_file}
    sed -i "s%TEMPLATE_SUPERLU_VERSION%${SUPERLU_VERSION}%" ${module_file}
    sed -i "s%TEMPLATE_SUPERLUDIST_VERSION%${SUPERLUDIST_VERSION}%" ${module_file}
    
    # Ensure this has worked
    module use ${module_dir}
    module load petsc/${PETSC_VERSION}
    module unload petsc
}

function petscInstallationTest {

    ${test_cce} && petscTest PrgEnv-cray
    ${test_gnu} && petscTest PrgEnv-gnu
    ${test_amd} && petscTest PrgEnv-aocc
}

function petscTest {

    local prgenv=${1}
    local module_use=$(moduleInstallDirectory)

    printf "Petsc test for %s\n" "${prgenv}"
    module restore $(moduleCollection ${prgenv})
    module use ${module_use}

    module load petsc/${PETSC_VERSION}
    printf "PETSC_DIR: %s\n" "${PETSC_DIR}"
    
    cd petsc-${PETSC_VERSION}

    # Standard PETSc "make check"
    # The SUPERLU_DIST_LIB and HDF_LIB variables force the relevant
    # tests which otherwise would not take place (a 'failure' in
    # configuration?).
    # HYPRE_LIB Hypre support added at pe 21.03

    slurmAllocRun "make PETSC_DIR=${PETSC_DIR} PETSC_ARCH= SUPERLU_DIST_LIB=yes HDF5_LIB=yes HYPRE_LIB=yes check"

    cd ..
    module unload petsc
}

main
