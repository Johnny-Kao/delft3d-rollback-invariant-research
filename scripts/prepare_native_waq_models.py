#!/usr/bin/env python3
"""Prepare native VALIDATION CANDIDATES from an unchanged upstream Delft3D example.

Does not run the solver. A runnable model and actual retry must be demonstrated
before calling this a Delft3D reproduction.
"""
from pathlib import Path
import os
import re
import shutil

root = Path(__file__).resolve().parents[1]
upstream = Path(os.environ.get("DELFT3D_SOURCE_ROOT", root / "upstream"))
source = upstream / "examples/dflowfm/12_dflowfm_pre_C_SUMO/fm"
target = root / "build/native-waq-models"
assert source.is_dir(), "Fetch pinned upstream model: git -C upstream sparse-checkout add examples/dflowfm/12_dflowfm_pre_C_SUMO"

def replace_property(content: str, key: str, value: str) -> str:
    pattern = rf"(?im)^([ \t]*{re.escape(key)}[ \t]*=[ \t]*)([^#\r\n]*)(.*)$"
    matches = list(re.finditer(pattern, content))
    assert len(matches) == 1, f"Expected exactly one {key} entry, got {len(matches)}"
    return re.sub(pattern, lambda m: m.group(1) + value.ljust(16) + m.group(3), content, count=1)

for label, maxiter in (("baseline", 100), ("one-iteration-limit", 1), ("two-iteration-limit", 2), ("three-iteration-limit", 3)):
    dest = target / label
    if dest.exists():
        shutil.rmtree(dest)
    shutil.copytree(source, dest)
    mdu_path = dest / "FlowFM.mdu"
    mdu = mdu_path.read_text()
    changes = {
        "Conveyance2D": "1",       # required by 2D nonlinear volume setting
        "Nonlin2D": "1",           # requires BedlevType=3 (upstream example already uses 3)
        "DtInit": "40",
        "DtMax": "40",
        "TStop": "600",            # shorten example runtime
        "WaqInterval": "60",       # enable DELWAQ flux output
        "WAQOutputDir": ".",      # make .flo observable beside MDU
        "ExtForceFileNew": "FlowFM-new.ext sources.ext",  # enable existing upstream SourceSink examples
    }
    for key, value in changes.items():
        mdu = replace_property(mdu, key, value)
    assert "maxNonlinearIterations" not in mdu
    mdu = mdu.replace("[numerics]", f"[numerics]\nmaxNonlinearIterations = {maxiter}", 1)
    assert mdu.count("maxNonlinearIterations") == 1
    assert (dest / "sources.ext").exists()
    assert (dest / "source.bc").exists()
    assert (dest / "2dis_net.nc").exists()
    mdu_path.write_text(mdu)
    print(f"{label}: candidate MDU created with nonlinear 2D, WAQ, source/sinks and maxNonlinearIterations={maxiter}")
print("NOTE: configuration is UNEXECUTED; full-solver acceptance and actual nonconvergence log are mandatory.")
