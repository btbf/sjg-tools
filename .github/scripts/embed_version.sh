#!/usr/bin/env bash
set -euo pipefail

version="${1}"

for f in ./scripts/install.sh ./scripts/airgap-setup.sh; do
  sed -i -E "s/^spokit_version=.*/spokit_version=\"${version}\"/" "$f"
done