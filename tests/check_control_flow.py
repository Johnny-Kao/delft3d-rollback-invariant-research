#!/usr/bin/env python3
"""Read original upstream code to report observable rollback-control-flow facts.

Not an integration test of the nonlinear solver.
"""
from pathlib import Path

root = Path(__file__).resolve().parents[1]
code = (root / "upstream/src/engines_gpl/dflowfm/packages/dflowfm_kernel/src/dflowfm_kernel/compute/step_reduce_hydro.f90").read_text()
s1 = (root / "upstream/src/engines_gpl/dflowfm/packages/dflowfm_kernel/src/dflowfm_kernel/compute/s1ini.f90").read_text()
assert "setback: do" in code and "call s1ini()" in code
key_branch = code.split("else if (key == 2) then", 1)[1].split("end if", 1)[0]
# The first 'end if' is nested; use a wider delimiter for the rollback block.
key_section = code.split("else if (key == 2) then", 1)[1].split("if (nonlin >= 2) then", 1)[0]
limit_section = code.split("if (nums1it > maxNonlinearIterations) then", 1)[1].split("cycle setback", 1)[0]
for symbol in ("source_sinks%cumulative_discharge_waq = source_sinks%cumulative_discharge_waq_previous", "qlatwaq = qlatwaq0"):
    assert symbol in key_section, f"missing expected key=2 restore: {symbol}"
    assert symbol not in limit_section, f"nonlinear branch already restores: {symbol}"
assert "call update_waq_lateral_fluxes()" in s1
assert "call update_waq_sink_source_fluxes()" in s1
print("PASS: source snapshot shows asymmetric WAQ restore; native solver reachability not proven")
