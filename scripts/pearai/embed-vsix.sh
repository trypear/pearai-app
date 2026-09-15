#!/usr/bin/env bash
# Embed one or more .vsix payloads into a gulp-packaged PearAI / VS Code tree.
#
# This replaces the manual CONTRIBUTING.md step:
#   "Right-click the .vsix → Install vsix as Extension → copy
#    ~/.vscode/extensions/publisher.name-version into the packaged app"
#
# A .vsix is a zip. Installing it in VS Code / PearAI just unpacks
# `extension/` into the user extensions folder. Doing that with unzip
# (no GUI, no local install) produces the same on-disk layout.
#
# Usage:
#   scripts/pearai/embed-vsix.sh --platform linux --arch x64 \
#       --vsix path/to/pearai.vsix [--vsix path/to/roo.vsix]
#
# Environment:
#   PEARAI_BUILD_DIR   Override the gulp output directory
#                      (default: <repo>/../VSCode-<platform>-<arch>)
#   PEARAI_APP_NAME    Darwin .app name without .app (default: PearAI)

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
platform=""
arch=""
build_dir="${PEARAI_BUILD_DIR:-}"
app_name="${PEARAI_APP_NAME:-PearAI}"
vsix_files=()

usage() {
	sed -n '2,20p' "$0"
	exit 1
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--platform) platform="${2:-}"; shift 2 ;;
		--arch) arch="${2:-}"; shift 2 ;;
		--build-dir) build_dir="${2:-}"; shift 2 ;;
		--vsix) vsix_files+=("${2:-}"); shift 2 ;;
		-h|--help) usage ;;
		*)
			echo "Unknown argument: $1" >&2
			usage
			;;
	esac
done

if [[ -z "$platform" || -z "$arch" ]]; then
	echo "error: --platform and --arch are required" >&2
	exit 1
fi

if [[ ${#vsix_files[@]} -eq 0 ]]; then
	echo "error: pass at least one --vsix path" >&2
	exit 1
fi

if [[ -z "$build_dir" ]]; then
	build_dir="$(cd "$repo_root/.." && pwd)/VSCode-${platform}-${arch}"
fi

if [[ ! -d "$build_dir" ]]; then
	echo "error: gulp output directory not found: $build_dir" >&2
	echo "hint: yarn gulp vscode-${platform}-${arch} writes a sibling folder of the repo" >&2
	exit 1
fi

find_extensions_dir() {
	local root="$1"
	local candidate

	if [[ "$platform" == "darwin" ]]; then
		for candidate in \
			"$root/${app_name}.app/Contents/Resources/app/extensions" \
			"$root/Visual Studio Code - OSS.app/Contents/Resources/app/extensions" \
			"$root/Code - OSS.app/Contents/Resources/app/extensions"
		do
			if [[ -d "$candidate" ]]; then
				printf '%s\n' "$candidate"
				return 0
			fi
		done
		candidate="$(find "$root" -maxdepth 6 -type d -path '*/Contents/Resources/app/extensions' 2>/dev/null | head -n 1 || true)"
		if [[ -n "$candidate" ]]; then
			printf '%s\n' "$candidate"
			return 0
		fi
	fi

	if [[ -d "$root/resources/app/extensions" ]]; then
		printf '%s\n' "$root/resources/app/extensions"
		return 0
	fi

	# CONTRIBUTING.md has a one-line typo (`app/extension` singular) — accept it if present.
	if [[ -d "$root/resources/app/extension" ]]; then
		printf '%s\n' "$root/resources/app/extension"
		return 0
	fi

	return 1
}

extensions_dir="$(find_extensions_dir "$build_dir")" || {
	echo "error: could not find resources/app/extensions under $build_dir" >&2
	echo "tree (depth 4):" >&2
	find "$build_dir" -maxdepth 4 -type d >&2 || true
	exit 1
}

echo "Embedding into $extensions_dir"

# Source trees gulp may have copied (Roo has a root package.json, so vsce.listFiles
# can include an unbuilt copy). Always remove these stubs after a real vsix embed.
remove_stub() {
	local name="$1"
	if [[ -e "$extensions_dir/$name" ]]; then
		echo "Removing unpackaged stub $extensions_dir/$name"
		rm -rf "$extensions_dir/$name"
	fi
}

remove_stub "pearai-submodule"
remove_stub "pearai-ref"
remove_stub "PearAI-Roo-Code"

python_bin="${PYTHON:-}"
if [[ -z "$python_bin" ]]; then
	if command -v python3 >/dev/null 2>&1; then
		python_bin="python3"
	elif command -v python >/dev/null 2>&1; then
		python_bin="python"
	else
		echo "error: python3 is required to unpack .vsix files" >&2
		exit 1
	fi
fi

embed_one() {
	local vsix="$1"
	if [[ ! -f "$vsix" ]]; then
		echo "error: vsix not found: $vsix" >&2
		exit 1
	fi

	local work
	work="$(mktemp -d "${TMPDIR:-/tmp}/pearai-vsix.XXXXXX")"

	if ! "$python_bin" - "$vsix" "$work" <<'PY'
import sys, zipfile
vsix, dest = sys.argv[1], sys.argv[2]
try:
    with zipfile.ZipFile(vsix) as zf:
        zf.extractall(dest)
except zipfile.BadZipFile as exc:
    raise SystemExit(f"error: {vsix} is not a zip/.vsix ({exc})")
PY
	then
		rm -rf "$work"
		exit 1
	fi

	local manifest="$work/extension/package.json"
	if [[ ! -f "$manifest" ]]; then
		echo "error: $vsix is not a valid vsix (missing extension/package.json)" >&2
		exit 1
	fi

	local publisher name version dest_name
	publisher="$("$python_bin" -c "import json; print(json.load(open(r'''$manifest''')).get('publisher',''))")"
	name="$("$python_bin" -c "import json; print(json.load(open(r'''$manifest''')).get('name',''))")"
	version="$("$python_bin" -c "import json; print(json.load(open(r'''$manifest''')).get('version',''))")"

	if [[ -z "$publisher" || -z "$name" || -z "$version" ]]; then
		echo "error: $vsix package.json is missing publisher/name/version" >&2
		exit 1
	fi

	# Same folder name VS Code / PearAI uses after "Install vsix as Extension".
	dest_name="${publisher}.${name}-${version}"

	# Drop any previous copy of this extension (with or without version suffix).
	rm -rf "$extensions_dir/${publisher}.${name}" "$extensions_dir/${publisher}.${name}-"*
	rm -rf "$extensions_dir/$name"

	mkdir -p "$extensions_dir"
	cp -R "$work/extension" "$extensions_dir/$dest_name"

	if [[ ! -f "$extensions_dir/$dest_name/package.json" ]]; then
		echo "error: failed to copy $vsix into $extensions_dir/$dest_name" >&2
		exit 1
	fi

	echo "Embedded $publisher.$name@$version -> $extensions_dir/$dest_name"
	rm -rf "$work"
}

for vsix in "${vsix_files[@]}"; do
	embed_one "$vsix"
done

echo "VSIX embed complete."
