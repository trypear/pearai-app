#!/usr/bin/env bash
# Copy gulp / installer outputs into a flat directory for GitHub Actions upload.
#
# Usage:
#   scripts/pearai/collect-release-artifacts.sh \
#       --platform linux --arch x64 --version 2.0.0 --dest dist-artifacts \
#       [--unsigned]

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
platform=""
arch=""
version="dev"
dest="dist-artifacts"
unsigned="false"

while [[ $# -gt 0 ]]; do
	case "$1" in
		--platform) platform="${2:-}"; shift 2 ;;
		--arch) arch="${2:-}"; shift 2 ;;
		--version) version="${2:-}"; shift 2 ;;
		--dest) dest="${2:-}"; shift 2 ;;
		--unsigned) unsigned="true"; shift ;;
		*) echo "Unknown argument: $1" >&2; exit 1 ;;
	esac
done

if [[ -z "$platform" || -z "$arch" ]]; then
	echo "error: --platform and --arch are required" >&2
	exit 1
fi

suffix=""
if [[ "$unsigned" == "true" ]]; then
	suffix="-unsigned"
fi

build_dir="${PEARAI_BUILD_DIR:-$(cd "$repo_root/.." && pwd)/VSCode-${platform}-${arch}}"
mkdir -p "$dest"
dest="$(cd "$dest" && pwd)"

copy_if() {
	local src="$1"
	local name="$2"
	if [[ -f "$src" ]]; then
		cp -f "$src" "$dest/$name"
		echo "collected $name"
	fi
}

archive_tree() {
	local src="$1"
	local name="$2"
	if [[ ! -e "$src" ]]; then
		return 1
	fi
	local out="$dest/$name"
	if command -v ditto >/dev/null 2>&1 && [[ "$platform" == "darwin" ]]; then
		ditto -c -k --keepParent "$src" "$out"
	elif [[ "$name" == *.tar.gz ]]; then
		tar -C "$(dirname "$src")" -czf "$out" "$(basename "$src")"
	else
		# zip is present on GitHub-hosted macOS / Windows / Linux runners.
		(
			cd "$(dirname "$src")"
			if command -v zip >/dev/null 2>&1; then
				zip -ryq "$out" "$(basename "$src")"
			else
				python3 - "$src" "$out" <<'PY'
import sys, zipfile, os
src, out = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as zf:
    if os.path.isdir(src):
        for root, _dirs, files in os.walk(src):
            for f in files:
                path = os.path.join(root, f)
                zf.write(path, os.path.relpath(path, os.path.dirname(src)))
    else:
        zf.write(src, os.path.basename(src))
PY
			fi
		)
	fi
	echo "collected $name"
}

# Installers first (they already include the embedded vsix when built after embed).
case "$platform" in
	linux)
		deb_arch="amd64"
		rpm_arch="x86_64"
		if [[ "$arch" == "arm64" ]]; then
			deb_arch="arm64"
			rpm_arch="aarch64"
		elif [[ "$arch" == "armhf" ]]; then
			deb_arch="armhf"
			rpm_arch="armv7hl"
		fi
		shopt -s nullglob
		for f in "$repo_root/.build/linux/deb/${deb_arch}/deb/"*.deb; do
			copy_if "$f" "PearAI-${version}-linux-${arch}${suffix}.deb"
		done
		for f in "$repo_root/.build/linux/rpm/${rpm_arch}/"*.rpm; do
			copy_if "$f" "PearAI-${version}-linux-${arch}${suffix}.rpm"
		done
		shopt -u nullglob
		if [[ -d "$build_dir" ]]; then
			archive_tree "$build_dir" "PearAI-${version}-linux-${arch}${suffix}.tar.gz" || true
		fi
		;;
	darwin)
		shopt -s nullglob
		for f in "$build_dir"/*.dmg "$repo_root/.build/darwin/"*.dmg; do
			copy_if "$f" "PearAI-${version}-darwin-${arch}${suffix}.dmg"
		done
		shopt -u nullglob
		app=""
		for candidate in "$build_dir/PearAI.app" "$build_dir/Visual Studio Code - OSS.app"; do
			if [[ -d "$candidate" ]]; then
				app="$candidate"
				break
			fi
		done
		if [[ -z "$app" && -d "$build_dir" ]]; then
			app="$(find "$build_dir" -maxdepth 2 -name '*.app' -type d | head -n 1 || true)"
		fi
		if [[ -n "$app" ]]; then
			archive_tree "$app" "PearAI-${version}-darwin-${arch}${suffix}.zip"
		fi
		;;
	win32)
		shopt -s nullglob
		for f in \
			"$repo_root/.build/win32-${arch}/user-setup/"*.exe \
			"$repo_root/.build/win32-${arch}/system-setup/"*.exe
		do
			kind="UserSetup"
			if [[ "$f" == *system-setup* ]]; then
				kind="Setup"
			fi
			copy_if "$f" "PearAI-${version}-win32-${arch}-${kind}${suffix}.exe"
		done
		shopt -u nullglob
		if [[ -d "$build_dir" ]]; then
			archive_tree "$build_dir" "PearAI-${version}-win32-${arch}${suffix}.zip" || true
		fi
		;;
	*)
		echo "error: unknown platform $platform" >&2
		exit 1
		;;
esac

count="$(find "$dest" -type f ! -name 'SHA256SUMS' | wc -l | tr -d ' ')"
if [[ "$count" -eq 0 ]]; then
	echo "error: no artifacts collected from $build_dir or .build/" >&2
	exit 1
fi

(
	cd "$dest"
	rm -f SHA256SUMS
	if command -v sha256sum >/dev/null 2>&1; then
		sha256sum -- * > SHA256SUMS
	else
		shasum -a 256 -- * > SHA256SUMS
	fi
	echo "checksums:"
	cat SHA256SUMS
)

echo "Collected $count artifact(s) into $dest"
