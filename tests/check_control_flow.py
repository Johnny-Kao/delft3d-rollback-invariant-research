#!/usr/bin/env python3
"""Read original upstream code to report observable rollback-control-flow facts.

Not an integration test of the nonlinear solver.
"""
from pathlib import Path

root = Path(__file__).resolve().parents[1]
code = (root / "upstream/src/engines_gpl/dflowfm/packages/dflowfm_kernel/src/dflowfm_kernel/compute/step_reduce_hydro.f90").read_text()
s1 = (root / "upstream/src/engines_gpl/dflowfm/packages/dflowfm_kernel/src/dflowfm_kernel/compute/s1ini.f90").read_text()
assert "setback: do" in code and "call s1ini()" in code
# The first 'end if' is nested; use a wider delimiter for the rollback block.
key_section = code.split("else if (key == 2) then", 1)[1].split("if (nonlin >= 2) then", 1)[0]
limit_section = code.split("if (nums1it > maxNonlinearIterations) then", 1)[1].split("cycle setback", 1)[0]
for symbol in ("source_sinks%cumulative_discharge_waq = source_sinks%cumulative_discharge_waq_previous", "qlatwaq = qlatwaq0"):
    assert symbol in key_section, f"missing expected key=2 restore: {symbol}"
    assert symbol not in limit_section, f"nonlinear branch already restores: {symbol}"
nested_retry = code.split("if (nonlin1D >= 3 .and. firstnniteration) then ! jposhcheck==-1", 1)[1].split("cycle wetdry", 1)[0]
for symbol in ("source_sinks%cumulative_discharge_waq =", "qlatwaq = qlatwaq0"):
    assert symbol not in nested_retry, f"unexpected nested-Newton restore: {symbol}"
assert "call update_waq_lateral_fluxes()" in s1
assert "call update_waq_sink_source_fluxes()" in s1
assert s1.index("call source_sinks%update_discharges()") < s1.index("call update_waq_sink_source_fluxes()")
writer = (root / "upstream/src/engines_gpl/dflowfm/packages/dflowfm_kernel/src/dflowfm_io/wrwaq.F90").read_text()
flo = writer.split("subroutine waq_wri_flo(itim, ti_waq, filename, lun)", 1)[1].split("end subroutine waq_wri_flo", 1)[0]
for expression in (
    "source_sinks%cumulative_discharge_waq(isrc) / real(ti_waq, kind=dp)",
    "qlatwaq(ilatwaq) / real(ti_waq, kind=dp)",
):
    assert expression in flo, f"WAQ writer expression absent: {expression}"
cycle = writer.split("subroutine waq_wri_couple_files(time)", 1)[1].split("end subroutine waq_wri_couple_files", 1)[0]
assert cycle.index("call waq_wri_flo(itim_prev") < cycle.rindex("qlatwaq = 0.0_dp")
assert cycle.index("call waq_wri_flo(itim_prev") < cycle.rindex("source_sinks%cumulative_discharge_waq = 0.0_dp")
print("PASS: original exporter consumes WAQ source/lateral accumulators before output-boundary reset")
print("PASS: source snapshot shows asymmetric WAQ restore; native solver reachability not proven")
