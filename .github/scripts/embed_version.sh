#!/usr/bin/env bash
set -e
version="$1"

for f in ./scripts/install.sh ./scripts/airgap-setup.sh; do
  echo "Updating version in $f"
  sed -i -E "s/^# version:.*/# version: ${version}/" "$f"
  sed -i -E "s/^spokit_version=.*/spokit_version=\"${version}\"/" "$f"
done