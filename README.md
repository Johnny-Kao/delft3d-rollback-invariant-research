# Delft3D timestep rollback invariant research

Independent, **non-fork** research repository. No changes to Deltares/Delft3D.

## Scope

Investigate whether a D-Flow FM nonlinear solver timestep retry can retain WAQ cumulative source/sink or lateral flux from an unsuccessful attempt.

**Status: source-level candidate only. No native solver reproduction and no confirmed bug.**

Upstream: https://github.com/Deltares/Delft3D
Pinned baseline: `fc48ceb1692afd87699f4cda081884c4bf4d2a91` (main, inspected 2026-11-13).

## Initial evidence

- `step_reduce_hydro.f90` saves WAQ accumulated values before `setback: do`.
- `s1ini.f90` calls `update_waq_sink_source_fluxes()` and `update_waq_lateral_fluxes()` inside normal solver setup when enabled.
- The `poshcheck(key==2)` retry path explicitly restores the two WAQ accumulators.
- The `nums1it > maxNonlinearIterations` retry path halves `dts`, resets `s1=s0`, calls `setkfs()`, and cycles `setback`; the same explicit WAQ restoration is not present there.

This asymmetry is a *hypothesis*, not proof. We must check call reachability, update ordering, any implicit clear/recompute contract, and actual outputs.

## Acceptance criteria before proposing any upstream change

1. Show a normal, supported configuration (`wrwaqon`, sources or laterals, implicit FM solver) that enters the nonlinear-iteration-limit retry.
2. Record WAQ accumulator immediately before failed attempt, after failure, and after successful retry.
3. Compare exported WAQ volume/mass flux against a baseline with the same accepted timestep; distinguish retry artifacts from legitimate iterative accumulation.
4. Check other retries and alternative solver contracts; inspect current upstream issues and PRs for collision.
5. Run a real upstream executable or original Fortran routines; an arithmetic model alone does not qualify.
6. Only then prepare a minimal patch and regression tests in this repo (never upstream without separate approval).

## Boundaries

- Do not fork the upstream repository.
- Do not push to upstream branches, open issues, or create upstream PRs.
- No AI or co-author markers in outward-facing contribution material.
- Do not claim a serious physical-result defect without native production-path evidence.
