#%Module
#

# This module file has been automatically generated

set shared_root TEMPLATE_INSTALL_ROOT
set module_root ${shared_root}/archer2-modules

set hdf5_parallel_version TEMPLATE_HDF5PARALLEL_VERSION
set parmetis_version TEMPLATE_PARMETIS_VERSION
set scotch_version   TEMPLATE_SCOTCH_VERSION
set mumps_version TEMPLATE_MUMPS_VERSION
set superlu_version  TEMPLATE_SUPERLU_VERSION
set superlu_dist_version TEMPLATE_SUPERLUDIST_VERSION

set petsc_version TEMPLATE_PETSC_VERSION

source ${module_root}/archer-modules-tcl.lib
source ${module_root}/archer-pkgconfig-tcl.lib

# Clashes

conflict petsc

proc ModulesHelp { } {
  puts stderr "PETSc"
  puts stderr "Installed by: Kevin Stratford, EPCC"
  puts stderr "Date: December 2020\n"
}

set _module_name  [module-info name]
set sys           [uname sysname]

if { ! [ info exists env(PE_ENV) ] } {

  puts stderr "No programming environment available!"

} else {

  module load cray-hdf5-parallel/${hdf5_parallel_version}
  module load parmetis/${parmetis_version}
  module load scotch/${scotch_version}
  module load mumps/${mumps_version}
  module load superlu/${superlu_version}
  module load superlu-dist/${superlu_dist_version}
  
  setenv PE_PETSC_REQUIRED_PRODUCTS "PE_HDF5_PARALLEL PE_PARMETIS PE_SCOTCH PE_SUPERLU PE_SUPERLU_DIST PE_MUMPS"

  set lcName "petsc"
  set ucName [ string toupper $lcName ]

  set prod_level ${petsc_version}
  set prod_root ${shared_root}/libs/${lcName}/$prod_level

  # Cray integration via pkgconfig
  # Compiler environment and currently loaded compiler version

  set compiler [ epccPrgEnvCompilerEnv ]
  set compiler_version_loaded [ epccPrgEnvCompilerVersion $compiler ]

  setenv PE_${ucName}_MODULE_NAME $lcName

  # Set package config path so pkgconfig can operate

  set_pkgconfig_paths $prod_root $ucName

  set pe_product_dir $prod_root
  set pe_pkgconfig_libs $lcName

  prepend-path PE_PKGCONFIG_LIBS $pe_pkgconfig_libs
  setenv PE_${ucName}_PKGCONFIG_LIBS  $pe_pkgconfig_libs

  # If the currently loaded compiler version is not available,
  # look for the most recent previous version...

  if { ! [ file isdirectory $pe_product_dir/$compiler ] } {
    puts stderr "Missing $pe_product_dir/$compiler"
    exit
  } else {

    # Is the current loaded compiler version available in $pe_product_dir ?
    # If not, is there a previous version available?

    set available [ epccProductAvailableVersions $pe_product_dir $compiler ]

    if { [ llength $available ] == 0 } {
      puts stderr "No compiler builds available in $pe_product_dir/$compiler !"
    } else {
 
      # What's the most recent version in the list <= loaded compiler
      foreach candidate [ lsort -real $available ] {
        if { $candidate <= $compiler_version_loaded } {
          set gen_compiler $candidate
        }
      }
    }
  } 

  # Set compiler-dependent information

  if { ! [ info exists gen_compiler ] } {
    puts stderr "$lcName cannot support the loaded compiler version"
    exit
  } else {
    set product_curpath $pe_product_dir/$compiler/$gen_compiler

    setenv ${ucName}_DIR ${product_curpath}  

  }

}
