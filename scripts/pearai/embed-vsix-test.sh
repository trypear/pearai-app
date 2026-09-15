#!/usr/bin/env bash
# Offline unit test for embed-vsix.sh — no Electron / gulp required.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
work="$(mktemp -d "${TMPDIR:-/tmp}/pearai-embed-test.XXXXXX")"
trap 'rm -rf "$work"' EXIT
embed="$repo_root/scripts/pearai/embed-vsix.sh"

fail() { echo "FAIL: $*" >&2; exit 1; }

make_vsix() {
	local dest="$1"
	local publisher="$2"
	local name="$3"
	local version="$4"
	local payload="$5"
	local staging="$work/vsix-$name-$version"
	rm -rf "$staging"
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

expect_fail() {
	local msg="$1"
	shift
	if "$@" >/dev/null 2>&1; then
		fail "$msg"
	fi
}

# --- linux: two vsixes, stub removal, publisher.name-version layout ---
build_dir="$work/VSCode-linux-x64"
ext_dir="$build_dir/resources/app/extensions"
mkdir -p "$ext_dir/pearai-submodule" "$ext_dir/PearAI-Roo-Code" "$ext_dir/pearai-ref"
echo "stub" > "$ext_dir/pearai-submodule/README.md"
echo "stub" > "$ext_dir/PearAI-Roo-Code/package.json"
echo "stub" > "$ext_dir/pearai-ref/README.md"

make_vsix "$work/pearai.vsix" "pearai" "pearai" "2.0.0" "pearai-core"
make_vsix "$work/roo.vsix" "PearAI" "pearai-roo-cline" "3.15.3" "roo-agent"

"$embed" --platform linux --arch x64 --build-dir "$build_dir" \
	--vsix "$work/pearai.vsix" --vsix "$work/roo.vsix"

[[ ! -e "$ext_dir/pearai-submodule" ]] || fail "stub pearai-submodule still present"
[[ ! -e "$ext_dir/PearAI-Roo-Code" ]] || fail "stub PearAI-Roo-Code still present"
[[ ! -e "$ext_dir/pearai-ref" ]] || fail "stub pearai-ref still present"
[[ -f "$ext_dir/pearai.pearai-2.0.0/package.json" ]] || fail "pearai.pearai-2.0.0 missing"
[[ -f "$ext_dir/PearAI.pearai-roo-cline-3.15.3/payload.txt" ]] || fail "Roo payload missing"
grep -q "pearai-core" "$ext_dir/pearai.pearai-2.0.0/payload.txt" || fail "pearai payload"
grep -q "roo-agent" "$ext_dir/PearAI.pearai-roo-cline-3.15.3/payload.txt" || fail "roo payload"

# Re-embed a newer version; old versioned folder must go away.
make_vsix "$work/pearai-new.vsix" "pearai" "pearai" "2.0.1" "pearai-v2"
"$embed" --platform linux --arch x64 --build-dir "$build_dir" --vsix "$work/pearai-new.vsix"
[[ -f "$ext_dir/pearai.pearai-2.0.1/payload.txt" ]] || fail "re-embed 2.0.1 missing"
[[ ! -e "$ext_dir/pearai.pearai-2.0.0" ]] || fail "old pearai.pearai-2.0.0 left behind"
grep -q "pearai-v2" "$ext_dir/pearai.pearai-2.0.1/payload.txt" || fail "re-embed payload"

# --- darwin .app layout ---
darwin_dir="$work/VSCode-darwin-arm64/PearAI.app/Contents/Resources/app/extensions"
mkdir -p "$darwin_dir/pearai-submodule"
make_vsix "$work/pearai-darwin.vsix" "pearai" "pearai" "2.0.1" "darwin-payload"
"$embed" --platform darwin --arch arm64 --build-dir "$work/VSCode-darwin-arm64" \
	--vsix "$work/pearai-darwin.vsix"
[[ -f "$darwin_dir/pearai.pearai-2.0.1/payload.txt" ]] || fail "darwin embed missing"
[[ ! -e "$darwin_dir/pearai-submodule" ]] || fail "darwin stub remains"

# --- win32 uses the same resources/app/extensions layout as linux ---
win_dir="$work/VSCode-win32-x64/resources/app/extensions"
mkdir -p "$win_dir/pearai-submodule"
make_vsix "$work/pearai-win.vsix" "pearai" "pearai" "2.0.0" "win-payload"
"$embed" --platform win32 --arch x64 --build-dir "$work/VSCode-win32-x64" \
	--vsix "$work/pearai-win.vsix"
[[ -f "$win_dir/pearai.pearai-2.0.0/payload.txt" ]] || fail "win32 embed missing"
[[ ! -e "$win_dir/pearai-submodule" ]] || fail "win32 stub remains"

# --- CONTRIBUTING typo path: app/extension (singular) ---
typo_root="$work/VSCode-linux-x64-typo"
mkdir -p "$typo_root/resources/app/extension"
make_vsix "$work/pearai-typo.vsix" "pearai" "pearai" "2.0.0" "typo-payload"
"$embed" --platform linux --arch x64 --build-dir "$typo_root" --vsix "$work/pearai-typo.vsix"
[[ -f "$typo_root/resources/app/extension/pearai.pearai-2.0.0/payload.txt" ]] || fail "singular extension/ path"

# --- error paths ---
expect_fail "missing --platform should fail" "$embed" --arch x64 --build-dir "$build_dir" --vsix "$work/pearai.vsix"
expect_fail "missing --vsix should fail" "$embed" --platform linux --arch x64 --build-dir "$build_dir"
expect_fail "missing build dir should fail" "$embed" --platform linux --arch x64 --build-dir "$work/does-not-exist" --vsix "$work/pearai.vsix"

echo "not-a-vsix" > "$work/junk.vsix"
expect_fail "non-zip vsix should fail" "$embed" --platform linux --arch x64 --build-dir "$build_dir" --vsix "$work/junk.vsix"

python3 - "$work/empty.zip" <<'PY'
import sys, zipfile
with zipfile.ZipFile(sys.argv[1], "w") as zf:
    zf.writestr("readme.txt", "no extension/ folder")
PY
expect_fail "zip without extension/package.json should fail" \
	"$embed" --platform linux --arch x64 --build-dir "$build_dir" --vsix "$work/empty.zip"

python3 - "$work/nopub.vsix" <<'PY'
import sys, zipfile
with zipfile.ZipFile(sys.argv[1], "w") as zf:
    zf.writestr("extension/package.json", '{"name":"pearai","version":"1.0.0"}')
PY
expect_fail "vsix missing publisher should fail" \
	"$embed" --platform linux --arch x64 --build-dir "$build_dir" --vsix "$work/nopub.vsix"

echo "embed-vsix self-test passed"
