#!/usr/bin/env bash
# Offline unit test for embed-vsix.sh — no Electron / gulp required.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
work="$(mktemp -d "${TMPDIR:-/tmp}/pearai-embed-test.XXXXXX")"
trap 'rm -rf "$work"' EXIT

build_dir="$work/VSCode-linux-x64"
ext_dir="$build_dir/resources/app/extensions"
mkdir -p "$ext_dir/pearai-submodule" "$ext_dir/PearAI-Roo-Code"
echo "stub" > "$ext_dir/pearai-submodule/README.md"
echo "stub" > "$ext_dir/PearAI-Roo-Code/package.json"

make_vsix() {
	local dest="$1"
	local publisher="$2"
	local name="$3"
	local version="$4"
	local payload="$5"
	local staging="$work/vsix-$name"
	mkdir -p "$staging/extension"
	cat > "$staging/extension/package.json" <<EOF
{"name":"$name","publisher":"$publisher","version":"$version","engines":{"vscode":"^1.80.0"}}
EOF
	echo "$payload" > "$staging/extension/payload.txt"
	python3 - "$staging" "$dest" <<'PY'
import sys, zipfile, os
staging, dest = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(dest, "w") as zf:
    for dirpath, _dirs, files in os.walk(staging):
        for f in files:
            path = os.path.join(dirpath, f)
            zf.write(path, os.path.relpath(path, staging))
PY
}

make_vsix "$work/pearai.vsix" "pearai" "pearai" "2.0.0" "pearai-core"
make_vsix "$work/roo.vsix" "PearAI" "pearai-roo-cline" "3.15.3" "roo-agent"

"$repo_root/scripts/pearai/embed-vsix.sh" \
	--platform linux \
	--arch x64 \
	--build-dir "$build_dir" \
	--vsix "$work/pearai.vsix" \
	--vsix "$work/roo.vsix"

[[ ! -e "$ext_dir/pearai-submodule" ]] || { echo "FAIL: stub pearai-submodule still present"; exit 1; }
[[ ! -e "$ext_dir/PearAI-Roo-Code" ]] || { echo "FAIL: stub PearAI-Roo-Code still present"; exit 1; }
[[ -f "$ext_dir/pearai.pearai-2.0.0/package.json" ]] || { echo "FAIL: pearai.pearai-2.0.0 missing"; exit 1; }
[[ -f "$ext_dir/PearAI.pearai-roo-cline-3.15.3/payload.txt" ]] || { echo "FAIL: Roo payload missing"; exit 1; }

grep -q "pearai-core" "$ext_dir/pearai.pearai-2.0.0/payload.txt"
grep -q "roo-agent" "$ext_dir/PearAI.pearai-roo-cline-3.15.3/payload.txt"

# Darwin layout
darwin_dir="$work/VSCode-darwin-arm64/PearAI.app/Contents/Resources/app/extensions"
mkdir -p "$darwin_dir/pearai-submodule"
make_vsix "$work/pearai2.vsix" "pearai" "pearai" "2.0.1" "darwin-payload"
"$repo_root/scripts/pearai/embed-vsix.sh" \
	--platform darwin \
	--arch arm64 \
	--build-dir "$work/VSCode-darwin-arm64" \
	--vsix "$work/pearai2.vsix"
[[ -f "$darwin_dir/pearai.pearai-2.0.1/payload.txt" ]] || { echo "FAIL: darwin embed missing"; exit 1; }
[[ ! -e "$darwin_dir/pearai-submodule" ]] || { echo "FAIL: darwin stub remains"; exit 1; }

# Reject a zip that is not a vsix
echo "not-a-vsix" > "$work/junk.vsix"
if "$repo_root/scripts/pearai/embed-vsix.sh" --platform linux --arch x64 --build-dir "$build_dir" --vsix "$work/junk.vsix"; then
	echo "FAIL: invalid vsix should be rejected"
	exit 1
fi

echo "embed-vsix self-test passed"
