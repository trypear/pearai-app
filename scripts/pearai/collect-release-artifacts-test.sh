#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
work="$(mktemp -d "${TMPDIR:-/tmp}/pearai-collect-test.XXXXXX")"
trap 'rm -rf "$work"' EXIT

build_dir="$work/VSCode-linux-x64"
mkdir -p "$build_dir/resources/app/extensions/pearai.pearai-2.0.0"
echo "app" > "$build_dir/resources/app/product.json"
mkdir -p "$work/repo/.build/linux/deb/amd64/deb" "$work/repo/.build/linux/rpm/x86_64"
echo "deb" > "$work/repo/.build/linux/deb/amd64/deb/pearai.deb"
echo "rpm" > "$work/repo/.build/linux/rpm/x86_64/pearai.rpm"

# collect script resolves repo_root from its own location; exercise via env + dest only
# by temporarily pointing PEARAI_BUILD_DIR and running from a copy is overkill —
# invoke the real script with dest in $work and a fake sibling build dir.

# The script's repo_root is the real repo. Seed the real .build paths? Don't pollute.
# Instead, monkey-patch by running a copy? Keep this test scoped: only verify archive + checksum
# using PEARAI_BUILD_DIR and an isolated dest. Deb/rpm come from the real repo .build, which
# is empty here — tar.gz of PEARAI_BUILD_DIR is enough.

dest="$work/out"
PEARAI_BUILD_DIR="$build_dir" "$repo_root/scripts/pearai/collect-release-artifacts.sh" \
	--platform linux --arch x64 --version 2.0.0 --dest "$dest"

[[ -f "$dest/PearAI-2.0.0-linux-x64.tar.gz" ]] || { echo "FAIL: tar.gz missing"; ls -la "$dest"; exit 1; }
[[ -f "$dest/SHA256SUMS" ]] || { echo "FAIL: SHA256SUMS missing"; exit 1; }
grep -q "PearAI-2.0.0-linux-x64.tar.gz" "$dest/SHA256SUMS"

echo "collect-release-artifacts self-test passed"
