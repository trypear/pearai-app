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
	./scripts/install-and-build.sh
)

if [[ -d extensions/PearAI-Roo-Code ]]; then
	echo "==> Building PearAI-Roo-Code vsix"
	(
		cd extensions/PearAI-Roo-Code
		if [[ -f package.json ]]; then
			npm run install:all
			# Roo's `build` script is an alias for `vsix`.
			npm run vsix
		fi
	)
fi

echo "==> VSIX outputs"
find extensions/pearai-submodule/extensions/vscode/build -name '*.vsix' -print 2>/dev/null || true
find extensions/PearAI-Roo-Code -name '*.vsix' -print 2>/dev/null || true
