#!/usr/bin/env bash
# Offline unit test for collect-release-artifacts.sh — no gulp / Electron.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
work="$(mktemp -d "${TMPDIR:-/tmp}/pearai-collect-test.XXXXXX")"
trap 'rm -rf "$work"' EXIT
collect="$repo_root/scripts/pearai/collect-release-artifacts.sh"

fail() { echo "FAIL: $*" >&2; exit 1; }

# --- linux: sibling tree + fake .build deb/rpm, unsigned suffix ---
fake_repo="$work/repo"
build_dir="$work/VSCode-linux-x64"
mkdir -p "$build_dir/resources/app/extensions/pearai.pearai-2.0.0"
echo "app" > "$build_dir/resources/app/product.json"
mkdir -p "$fake_repo/.build/linux/deb/amd64/deb" "$fake_repo/.build/linux/rpm/x86_64"
echo "deb" > "$fake_repo/.build/linux/deb/amd64/deb/pearai.deb"
echo "rpm" > "$fake_repo/.build/linux/rpm/x86_64/pearai.rpm"

dest="$work/out-linux"
PEARAI_REPO_ROOT="$fake_repo" PEARAI_BUILD_DIR="$build_dir" \
	"$collect" --platform linux --arch x64 --version 2.0.0 --dest "$dest" --unsigned

[[ -f "$dest/PearAI-2.0.0-linux-x64-unsigned.tar.gz" ]] || fail "linux tar.gz missing"
[[ -f "$dest/PearAI-2.0.0-linux-x64-unsigned.deb" ]] || fail "linux deb missing"
[[ -f "$dest/PearAI-2.0.0-linux-x64-unsigned.rpm" ]] || fail "linux rpm missing"
[[ -f "$dest/SHA256SUMS" ]] || fail "linux SHA256SUMS missing"
grep -q "PearAI-2.0.0-linux-x64-unsigned.tar.gz" "$dest/SHA256SUMS" || fail "checksum tar"
grep -q "PearAI-2.0.0-linux-x64-unsigned.deb" "$dest/SHA256SUMS" || fail "checksum deb"
# SHA256SUMS must not checksum itself
if grep -q ' SHA256SUMS$' "$dest/SHA256SUMS"; then
	fail "SHA256SUMS listed itself"
fi

# --- darwin: .app zip + dmg sitting next to the app ---
darwin_root="$work/VSCode-darwin-arm64"
mkdir -p "$darwin_root/PearAI.app/Contents/Resources/app/extensions"
echo "app" > "$darwin_root/PearAI.app/Contents/Resources/app/product.json"
echo "dmg" > "$darwin_root/PearAI-darwin-arm64.dmg"
dest="$work/out-darwin"
PEARAI_REPO_ROOT="$fake_repo" PEARAI_BUILD_DIR="$darwin_root" \
	"$collect" --platform darwin --arch arm64 --version 2.0.0 --dest "$dest"
[[ -f "$dest/PearAI-2.0.0-darwin-arm64.zip" ]] || fail "darwin zip missing"
[[ -f "$dest/PearAI-2.0.0-darwin-arm64.dmg" ]] || fail "darwin dmg missing"
# signed path: no -unsigned suffix when --unsigned is omitted
[[ ! -e "$dest/PearAI-2.0.0-darwin-arm64-unsigned.zip" ]] || fail "darwin unexpectedly unsigned"

# --- win32: Inno setup exe + tree zip ---
win_root="$work/VSCode-win32-x64"
mkdir -p "$win_root/resources/app" "$fake_repo/.build/win32-x64/user-setup"
echo "exe" > "$win_root/PearAI.exe"
echo "setup" > "$fake_repo/.build/win32-x64/user-setup/VSCodeSetup.exe"
dest="$work/out-win"
PEARAI_REPO_ROOT="$fake_repo" PEARAI_BUILD_DIR="$win_root" \
	"$collect" --platform win32 --arch x64 --version 2.0.0 --dest "$dest" --unsigned
[[ -f "$dest/PearAI-2.0.0-win32-x64-unsigned.zip" ]] || fail "win32 zip missing"
[[ -f "$dest/PearAI-2.0.0-win32-x64-UserSetup-unsigned.exe" ]] || fail "win32 setup missing"

# --- empty inputs must fail ---
empty="$work/empty"
mkdir -p "$empty"
if PEARAI_REPO_ROOT="$empty" PEARAI_BUILD_DIR="$empty/missing" \
	"$collect" --platform linux --arch x64 --version 0 --dest "$work/out-empty" 2>/dev/null; then
	fail "empty collect should fail"
fi

echo "collect-release-artifacts self-test passed"
