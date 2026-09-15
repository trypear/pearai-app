#!/usr/bin/env bash
# Create a simple UDZO DMG from PearAI.app. There is no vscode-*-build-dmg gulp
# task in this fork (that name exists only in competing PR #283).

set -euo pipefail

arch="${1:-}"
app_path="${2:-}"

if [[ -z "$app_path" || ! -d "$app_path" ]]; then
	build_dir="${PEARAI_BUILD_DIR:-../VSCode-darwin-${arch}}"
	if [[ -d "$build_dir/PearAI.app" ]]; then
		app_path="$build_dir/PearAI.app"
	else
		app_path="$(find "$build_dir" -maxdepth 2 -name '*.app' -type d | head -n 1 || true)"
	fi
fi

if [[ -z "$app_path" || ! -d "$app_path" ]]; then
	echo "error: app not found (arch=${arch}, PEARAI_BUILD_DIR=${PEARAI_BUILD_DIR:-unset})" >&2
	exit 1
fi

build_dir="$(cd "$(dirname "$app_path")" && pwd)"
stage="${RUNNER_TEMP:-/tmp}/pearai-dmg-${arch}"
rm -rf "$stage"
mkdir -p "$stage"
cp -R "$app_path" "$stage/PearAI.app"
ln -s /Applications "$stage/Applications"

dmg="$build_dir/PearAI-darwin-${arch}.dmg"
rm -f "$dmg"
hdiutil create -volname "PearAI" -srcfolder "$stage" -ov -format UDZO "$dmg"
rm -rf "$stage"
echo "Created $dmg"
