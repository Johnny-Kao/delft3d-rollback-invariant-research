#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
python3 tests/check_control_flow.py
mkdir -p build/waq-native
cd build/waq-native
gfortran -std=f2008 -ffree-line-length-none -fcheck=all -O0 \
  ../../tests/stubs.f90 \
  ../../upstream/src/engines_gpl/dflowfm/packages/dflowfm_kernel/src/dflowfm_kernel/prepost/update_waq_lateral_fluxes.f90 \
  ../../tests/waq_retry_driver.f90 -o waq_retry_test
./waq_retry_test
