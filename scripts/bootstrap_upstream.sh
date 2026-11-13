#!/bin/sh
# Reproduce the independent read-only sparse source copy. No fork or upstream push.
set -eu
cd "$(dirname "$0")/.."
sha=fc48ceb1692afd87699f4cda081884c4bf4d2a91
if [ -d upstream/.git ]; then
  current=$(git -C upstream rev-parse HEAD)
  if [ "$current" != "$sha" ]; then
    echo "Existing upstream SHA differs: $current" >&2
    exit 1
  fi
  echo "Upstream copy already matches $sha"
  exit 0
fi
git clone --filter=blob:none --sparse --no-checkout --depth=1 https://github.com/Deltares/Delft3D.git upstream
git -C upstream fetch --filter=blob:none --depth=1 origin "$sha"
git -C upstream sparse-checkout set \
  src/engines_gpl/dflowfm/packages/dflowfm_kernel/src/dflowfm_kernel/compute \
  src/engines_gpl/dflowfm/packages/dflowfm_kernel/src/dflowfm_kernel/prepost \
  src/engines_gpl/dflowfm/packages/dflowfm_kernel/src/dflowfm_io
git -C upstream checkout --detach "$sha"
test "$(git -C upstream rev-parse HEAD)" = "$sha"
echo "Copied pinned upstream sources ($sha) without fork"
