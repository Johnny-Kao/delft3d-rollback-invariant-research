# Source-level audit — 2026-11-13

## Control flow

Baseline: `fc48ceb1692afd87699f4cda081884c4bf4d2a91`.

- `src/engines_gpl/dflowfm/packages/dflowfm_kernel/src/dflowfm_kernel/compute/step_reduce_hydro.f90`, around lines 81–94: snapshot `source_sinks%cumulative_discharge_waq_previous` and `qlatwaq0` before the `setback` loop.
- Same file around lines 125–126: `call s1ini()` inside the `wetdry` loop, itself inside `setback`.
- Same file around lines 181–209: `key == 2` retry explicitly restores both accumulators, then retries (potentially with timestep reduction).
- Same file around lines 239–260: nonlinear iteration limit halves timestep, restores `s1`, calls `setkfs` and `cycle setback` without the above explicit restore.
- `src/engines_gpl/dflowfm/packages/dflowfm_kernel/src/dflowfm_kernel/compute/s1ini.f90`, around lines 279–289: `source_sinks%update_discharges()` followed by WAQ accumulator updates when `wrwaqon` and corresponding sources/laterals are enabled.
- `src/engines_gpl/dflowfm/packages/dflowfm_kernel/src/dflowfm_kernel/prepost/update_waq_sink_source_fluxes.f90`: accumulates `dts * source_sinks%discharge`; for 3-D, distributes across layer exchanges.
- `src/engines_gpl/dflowfm/packages/dflowfm_kernel/src/dflowfm_kernel/prepost/update_waq_lateral_fluxes.f90`: likewise uses timestep-weighted accumulation.
- `src/engines_gpl/dflowfm/packages/dflowfm_kernel/src/dflowfm_io/wrwaq.F90`: resets accumulated discharges at WAQ-output boundaries.

## Competing explanations to falsify

A. **Genuine missing rollback:** failed timestep values remain counted and exported.
B. **Intentional contract:** another routine clears or overwrites accumulators, or only accepted attempts contribute despite apparent accumulation.
C. **Unreachable combination:** nonlinear-iteration-limit cannot occur together with the relevant WAQ accumulation due to configuration/solver guards.
D. **Non-impacting state:** stored flux may not feed an output that matters in the relevant case.

A is not established until B–D are eliminated.

## Minimal test design

A compact D-Flow FM case with 1 source/sink or lateral, WAQ output enabled, and controlled nonlinear solver limit. Compare:
- a run completing with an accepted timestep without retry;
- a run that first rejects a longer step then completes the shorter one.

Compare integrated source/sink volumes and accepted-solution flux, not merely floating point bitwise differences. Log exact solver branch and timestep to avoid false positives.

## Isolation test result (2026-11-13)

Upstream source copied with Git sparse clone into gitignored `upstream/`, pinned at exact baseline SHA, without GitHub fork relationship. The original Fortran file is compiled directly, unmodified; only its surrounding dependency modules are test stubs.

Run `sh tests/run.sh` (requires `python3` and `gfortran`).

- Static control-flow check: PASS — `key==2` branch explicitly restores both WAQ accumulators, while the nonlinear iteration-limit `cycle setback` branch does not.
- Original upstream `update_waq_lateral_fluxes.f90` compiled with test stubs: PASS.
- Retry arithmetic test: without restore 250.0; with restore 150.0, with initial 100.0, discharge 5.0, rejected `dts=20`, accepted `dts=10`.
- Original upstream `update_waq_sink_source_fluxes.f90` 2D branch compiled with test stubs: PASS, same 250 vs 150 divergence.
- Static WAQ exporter trace: PASS — `.flo` uses both accumulated values and resets them after writing.
- Scope: confirms *function-level cumulative semantics and source-level export consumption*, **not** an end-to-end Delft3D production defect. No complete solver executable or `.flo` export was run.
- Full test matrix and build blocker recorded in `VALIDATION_2026-11-13.md`.

### Hidden contract audit

`step_reduce_hydro` snapshots before `setback`; `s1ini` runs inside `wetdry` inside `setback`. The nonlinear iteration-limit branch resets water level and time step then restarts `setback` without explicit WAQ restores. The original lateral flux updater does not clear its accumulator; it adds `dts * qqLat` to the existing value. This eliminates an *inside-the-updater* implicit-clear hypothesis, not all possible upstream invariants.

Outstanding: whether original production configurations can reach the branch with `wrwaqon` and an active source/lateral; whether external orchestration changes accumulators or ignores corrupted values; check earlier paths and output writer usage. Next step: minimal native solver integration run, ideally Linux isolated, with a forced convergence failure and WAQ output enabled.

## Collision

Check recent and closed upstream PRs involving `step_reduce_hydro`, WAQ cumulative flux and rollback before any contribution.
