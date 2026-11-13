# Delft3D #2 rollback candidate — single-pass validation

Date: 2026-11-13 (Asia/Tokyo)  
Upstream: Deltares/Delft3D (read-only copy, **not a GitHub fork**)  
Pinned SHA: `fc48ceb1692afd87699f4cda081884c4bf4d2a91`  
Research repository: Johnny-Kao/delft3d-rollback-invariant-research (private)

## Verified results

Run: `sh tests/run.sh`

| Check | Result | Evidence / interpretation |
|---|---|---|
| Source control-flow structure | PASS | Snapshot before setback; WAQ update in `s1ini` inside setback; `key==2` restore; iteration-limit retry lacks corresponding explicit restore |
| Original lateral WAQ accumulator | PASS | Unmodified upstream `update_waq_lateral_fluxes.f90` compiled with local dependency stubs; output 250 vs 150 |
| Original source/sink WAQ accumulator (2D) | PASS | Unmodified upstream `update_waq_sink_source_fluxes.f90` compiled with local dependency stubs; output 250 vs 150 |
| WAQ writer consumption | PASS (source-level) | `waq_wri_flo` uses cumulative source/sink and lateral flux / `ti_waq`; writer resets accumulators *after* writing |
| Confirm native source revision | PASS | Exact pinned commit |
| Reach nonlinear iteration limit under normal FM + WAQ | **NOT TESTED** | Requires complete D-Flow FM executable and valid model |
| Integrated WAQ output corruption | **NOT PROVEN** | Requires forced retry in native production path and comparison against no-retry baseline |
| Material model impact | **NOT PROVEN** | Requires physics-level scenario and error magnitude |
| Full upstream native solver build | **BLOCKED** | macOS ARM64 has no `ifx` / Conan; upstream Linux build needs Intel oneAPI + third-party-libs and Conan; local Colima Linux VM started but registry `containers.deltares.nl` timed out |

## Interpretation

This is **strong source-level evidence of a likely missing rollback**, **not a verified high-severity production defect**. The tests verify actual original upstream accumulation routines (using stubs for dependencies), NOT the full `step_reduce_hydro` solver and not end-to-end hydrodynamics.

Two hidden-contract hypotheses are weakened: the individual WAQ accumulation routines do not implicitly reset state; the export function does not ignore accumulated values. The decisive remaining question is actual reachable retry with `wrwaqon` and active source/lateral under accepted configurations, and any additional outer orchestration.

The `s1ini` routine calls the source/sink updater on each applicable setup before the nonlinear solve. The iteration-limit path halves `dts` and re-enters `setback` without the explicit restore present in the `key==2` path.

A targeted native acceptance test must explicitly log:
1. `nums1it > maxNonlinearIterations`, with nonzero `wrwaqon` and source/lateral.
2. WAQ accumulator before failed attempt, after rejected attempt, after accepted retry.
3. WAQ `.flo` export against a no-retry baseline and integrated discharge.
4. All triggered warnings, relevant timestep and numerical tolerances.

## Upstream safety

- The Research Repo is independent, private and `isFork=false`.
- Copied upstream files are gitignored; their source contents are not committed to this repo.
- No edits, pushes, issues or PRs have been made to Deltares/Delft3D.
- Do not submit a defect claim until the above native acceptance criteria are passed.

## Reproduce

```sh
sh scripts/bootstrap_upstream.sh
sh tests/run.sh
```

The test suite uses the original Fortran routines, not reimplementations, with small dependency stubs. The full hydrodynamics solver remains unavailable in this environment.
