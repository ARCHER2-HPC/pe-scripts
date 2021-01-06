#%Module
#

# This file was (semi-)automatically generated

set shared_root TEMPLATE_INSTALL_ROOT
set module_root ${shared_root}/archer2-modules

set adios_version TEMPLATE_ADIOS_VERSION
set hdf5_parallel_version TEMPLATE_HDF5PARALLEL_VERSION
source ${module_root}/archer-modules-tcl.lib
#source ${module_root}/archer-pkgconfig-tcl.lib

# Clashes

conflict adios

proc ModulesHelp { } {
  puts stderr "Adios $::adios_version"
  puts stderr "See https://docs.archer2.ac.uk/software-libraries/adios/"
  puts stderr "Installed by: Kevin Stratford, EPCC"
  puts stderr "Date: TEMPLATE_TIMESTAMP\n"
}

set _module_name  [module-info name]
set sys           [uname sysname]

if { ! [ info exists env(PE_ENV) ] } {

  puts stderr "No programming environment available!"

} else {

  module load cray-hdf5-parallel/${hdf5_parallel_version}

  set lcName adios
  set ucName [ string toupper $lcName ]

  set prod_level ${adios_version}
  set prod_root ${shared_root}/libs/$lcName/$prod_level

  # Compiler environment and currently loaded compiler version

  set compiler [ epccPrgEnvCompilerEnv ]
  set compiler_version_loaded [ epccPrgEnvCompilerVersion $compiler ]

  set pe_product_dir $prod_root

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

    # Potential compiler change while module is loaded not handled

    setenv ${ucName}_DIR ${product_curpath}  

    # load or remove paths
    if { ! [ module-info mode remove ] } {
      prepend-path PATH $product_curpath/bin
    } else {
      set oldpath $env(PATH)
      foreach mod [ split $oldpath ':' ] {
        if { [ expr [ lsearch [ split $mod '/' ] $lcName ] >= 0 ] } {
	  # This is mode remove so prepend is remove
          prepend-path PATH $mod
        } 
      }
    }
  }

}
