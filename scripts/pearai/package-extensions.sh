#!/usr/bin/env bash
# Build the PearAI extension .vsix files that get embedded into a release.
# Must run on the target OS/arch: the Continue-based vsix ships native binaries
# (onnxruntime, sqlite3, lancedb, esbuild, ripgrep) validated per platform.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

if [[ ! -d extensions/pearai-submodule/extensions/vscode ]]; then
	echo "Cloning packaging extensions first..."
	"$repo_root/scripts/pearai/clone-packaging-extensions.sh"
fi

echo "==> Building pearai-submodule vsix"
(
	cd extensions/pearai-submodule
	chmod +x scripts/install-and-build.sh
	# prepackage.js treats GITHUB_ACTIONS+ARM as "download esbuild.zip from
	# continue-server-binaries.s3...". That object is no longer a zip
	# (`unzip: cannot find zipfile directory`). The comment in prepackage
	# says GHA has no ARM runners — it does now, so the npm esbuild@0.17.19
	# path (the non-GHA branch) is the correct one on ubuntu-24.04-arm / macos-14.
	# Empty GITHUB_ACTIONS makes `!!process.env.GITHUB_ACTIONS` false.
	GITHUB_ACTIONS= ./scripts/install-and-build.sh
)

if [[ "${PEARAI_INCLUDE_ROO:-true}" == "true" && -d extensions/PearAI-Roo-Code && -f extensions/PearAI-Roo-Code/package.json ]]; then
	echo "==> Building PearAI-Roo-Code vsix"
	if (
		cd extensions/PearAI-Roo-Code
		npm run install:all
		# `npm run vsix` -> vsce -> vscode:prepublish -> npm run package -> lint.
		# lint:extension is `ESLINT_USE_FLAT_CONFIG=false eslint ...`, which
		# Windows cmd treats as a command name (exit 1). Lint is not part of #44.
		# Keep the production webview/esbuild compile; drop lint/check-types.
		npm pkg set scripts.vscode:prepublish="npm-run-all -l -p build:webview build:esbuild"
		npm run vsix
	); then
		echo "Roo vsix built."
	else
		echo "warning: PearAI-Roo-Code vsix failed; continuing with pearai-submodule only" >&2
	fi
fi

echo "==> VSIX outputs"
find extensions/pearai-submodule/extensions/vscode/build -name '*.vsix' -print 2>/dev/null || true
find extensions/PearAI-Roo-Code -name '*.vsix' -print 2>/dev/null || true
