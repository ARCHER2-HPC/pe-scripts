#%Module
#

# You must replace:
# TEMPLATE_INSTALL_ROOT      e.g., /work/y07/shared/
# TEMPLATE_METIS_VERSION     5.1.0

# whence libs are /work/y07/shared/libs/metis
# modulefiles are /work/y07/shared/archer2-modules

set shared_root TEMPLATE_INSTALL_ROOT
set module_root ${shared_root}/archer2-modules

set metis_version TEMPLATE_METIS_VERSION

source ${module_root}/archer-modules-tcl.lib
source ${module_root}/archer-pkgconfig-tcl.lib

# Clashes

conflict metis

proc ModulesHelp { } {
  puts stderr "metis"
  puts stderr "Installed by: Kevin Stratford, EPCC"
  puts stderr "Date: December 2020\n"
}

set _module_name  [module-info name]
set sys           [uname sysname]

if { ! [ info exists env(PE_ENV) ] } {

  puts stderr "No programming environment available!"

} else {

  set lcName metis
  set ucName [ string toupper $lcName ]

  set prod_level ${metis_version}
  set prod_root ${shared_root}/libs/$lcName/$prod_level

  prepend-path PATH $prod_root/bin

  # Cray integration via pkgconfig
  # Compiler environment and currently loaded compiler version

  set compiler [ epccPrgEnvCompilerEnv ]
  set compiler_version_loaded [ epccPrgEnvCompilerVersion $compiler ]

  setenv PE_${ucName}_MODULE_NAME $lcName

  # Set package config path so pkgconfig can operate
  # OpenMP is available

  set_pkgconfig_paths $prod_root $ucName
  set_pkgconfig_openmp_requires $ucName

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

    # Potential change while module is loaded not handled
    prepend-path PATH $product_curpath/bin

    # load or remove paths for CRAY_LD_LIBRARY_PATH
    if { ! [ module-info mode remove ] } {
      prepend-path CRAY_LD_LIBRARY_PATH $product_curpath/lib
    } else {
      set oldpath $env(CRAY_LD_LIBRARY_PATH)
      foreach mod [ split $oldpath ':' ] {
        if { [ expr [ lsearch [ split $mod '/' ] $lcName ] >= 0 ] } {
	  # This is mode remove so prepend is remove
          prepend-path CRAY_LD_LIBRARY_PATH $mod
        } 
      }
    }
  }

}
