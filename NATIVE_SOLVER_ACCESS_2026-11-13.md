# Native D-Flow FM Solver access investigation — 2026-11-13

## Goal

Run the **entire D-Flow FM solver at the pinned upstream SHA** `fc48ceb1692afd87699f4cda081884c4bf4d2a91`, with WAQ enabled and a legal model forcing one or both nonlinear retry branches. Compare output `.flo` against an accepted-timestep reference. No upstream writes or forks.

## Public GitHub Actions registry probe

- Workflow: [Public probe](https://github.com/Johnny-Kao/delft3d-rollback-invariant-research/actions/workflows/solver-probe.yml)
- First complete network probe run: https://github.com/Johnny-Kao/delft3d-rollback-invariant-research/actions/runs/43443926819
- Anonymous Docker manifest attempt: https://github.com/Johnny-Kao/delft3d-rollback-invariant-research/actions/runs/43444151654
- `GET https://containers.deltares.nl/v2/`: HTTP 401. A 401 alone is standard registry authentication challenge, **not proof** of a non-public image.
- `docker manifest inspect containers.deltares.nl/delft3d/delft3dfm:2026.02-release`: `no such manifest`, exit 1.
- `docker manifest inspect containers.deltares.nl/delft3d-dev/delft3d-third-party-libs:oneapi-2024-ifx-release`: `no such manifest`, exit 1.
- Deltares' devcontainer documentation explicitly requires account access to the `delft3d-dev` Harbor project and `docker login`; credentials are not present and must not be committed to this public research repo.

## Alternative compiler toolchain

Intel publishes a public `intel/hpckit:2024.2.1-0-devel-rockylinux9` image on Docker Hub including oneAPI compilers. This may provide a non-Deltares toolchain, **but is not an actual D-Flow FM runtime** and does not satisfy all non-Conan dependencies.

Official upstream `doc/compiling_Linux.md` states external developers must build missing Conan packages locally; `ci/dockerfiles/linux/third-party-libs.Dockerfile` also builds libraries such as HDF5, netCDF C/Fortran and ESMF. An Intel compiler image alone does not solve this dependency chain. The repository's Linux Conan default profile targets AlmaLinux 8, making a different public image a nontrivial build port.

## Public solver availability

Official Delft3D FM download documentation lists precompiled kernels and Apptainer for service-package users; open-source kernels are available as source. Official Harbor images may need a MyDeltares login. The GitHub `DIMRset_2026.02` release has no downloadable binary assets; the latest upstream repository Actions artifacts scan returned no accessible executables.

## Current sign-off

**Native full solver: NOT RUN. No genuine `.flo` file produced or compared.**

The independent original Fortran source/sink and lateral update routines and exporter source-path checks pass on public Ubuntu CI; they do not prove real-world corruption. Do not represent the registry diagnostics workflow as a solver test. The currently defensible conclusion remains *source-level missing-rollback candidate*.

## Next executable options (in priority order)

1. Obtain authorized, distributable Delft3D FM runtime/build container access and ensure its source revision matches the pinned commit; runtime release containers from another revision only establish a regression baseline, not this commit.
2. Build the pinned commit in an authorized Linux build environment using official upstream external-developer Conan workflow, with dependencies verified upfront. Avoid repeated expensive attempts without a dependency-complete image.
3. Run a small legitimate D-Flow FM model with WAQ source/lateral flux enabled; capture `nums1it > maxNonlinearIterations` and `nonlin1D >= 3` retry cases; compare original and isolated-research patched builds plus exported flow and conservation metrics.

No upstream changes, issue, PR or external message has been sent.
