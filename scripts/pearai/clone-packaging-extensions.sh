#!/usr/bin/env bash
# Clone the PearAI extension repos used during packaging.
#
# The parent repo lists these in .gitmodules, but it does not record gitlink
# SHAs (and pearai-submodule is gitignored). `actions/checkout` with
# `submodules: recursive` therefore clones nothing.
#
# Usage:
#   scripts/pearai/clone-packaging-extensions.sh
#
# Environment:
#   PEARAI_SUBMODULE_REPO  default https://github.com/trypear/pearai-submodule.git
#   PEARAI_SUBMODULE_REF   default main
#   PEARAI_ROO_REPO        default https://github.com/trypear/PearAI-Roo-Code.git
#   PEARAI_ROO_REF         default main

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"
export GIT_TERMINAL_PROMPT=0

clone_or_update() {
	local dest="$1"
	local url="$2"
	local ref="$3"

	if [[ -d "$dest/.git" ]]; then
		echo "Updating $dest to $ref"
		git -C "$dest" fetch --depth 1 origin "$ref"
		git -C "$dest" checkout --force FETCH_HEAD
		git -C "$dest" submodule update --init --recursive --depth 1 || true
		return
	fi

	if [[ -e "$dest" && ! -d "$dest/.git" ]]; then
		echo "Removing non-git placeholder at $dest"
		rm -rf "$dest"
	fi

	echo "Cloning $url ($ref) -> $dest"
	git clone --depth 1 --branch "$ref" --recurse-submodules "$url" "$dest" \
		|| git clone --depth 1 --recurse-submodules "$url" "$dest"
}

clone_or_update \
	"extensions/pearai-submodule" \
	"${PEARAI_SUBMODULE_REPO:-https://github.com/trypear/pearai-submodule.git}" \
	"${PEARAI_SUBMODULE_REF:-main}"

clone_or_update \
	"extensions/PearAI-Roo-Code" \
	"${PEARAI_ROO_REPO:-https://github.com/trypear/PearAI-Roo-Code.git}" \
	"${PEARAI_ROO_REF:-main}"

echo "Packaging extensions are present."
