#!/usr/bin/env bash
# Programming environment defaults changed at upgrade 2025.
# However, we'll keep the 'backstop' version in each case.

PE_CPE_VERSION=23.09

# Retain the older compiler versions
PE_CRAY_CCE_VERSION=15.0.0
PE_GNU_GCC_VERSION=10.3.0
PE_AOCC_AOCC_VERSION=3.2.0

# ..but not the older hdf5 etc ...

CRAY_HDF5_PARALLEL_VERSION=1.12.2.7
CRAY_NETCDF_HDF5PARALLEL_VERSION=4.9.0.1
