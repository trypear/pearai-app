#!/usr/bin/env bash
# codesign (+ optional notarytool) a packaged PearAI.app.
# Signing is skipped cleanly when no identity is available.
#
# Required: PEARAI_BUILD_DIR or --app path
# Optional secrets: MACOS_CERT_IDENTITY, APPLE_ID, APPLE_APP_SPECIFIC_PASSWORD, APPLE_TEAM_ID
# Optional: KEYCHAIN_PATH (from import-macos-cert.sh)

set -euo pipefail

app_path="${1:-}"
arch="${2:-${VSCODE_ARCH:-}}"

if [[ -z "$app_path" || ! -d "$app_path" ]]; then
	build_dir="${PEARAI_BUILD_DIR:-}"
	if [[ -z "$build_dir" && -n "$arch" ]]; then
		build_dir="$(pwd)/../VSCode-darwin-${arch}"
	fi
	if [[ -n "$build_dir" ]]; then
		if [[ -d "$build_dir/PearAI.app" ]]; then
			app_path="$build_dir/PearAI.app"
		else
			app_path="$(find "$build_dir" -maxdepth 2 -name '*.app' -type d | head -n 1 || true)"
		fi
	fi
fi

if [[ -z "$app_path" || ! -d "$app_path" ]]; then
	echo "error: packaged .app not found (${app_path:-unset})" >&2
	exit 1
fi

identity="${MACOS_CERT_IDENTITY:-}"
if [[ -z "$identity" ]]; then
	identity="$(security find-identity -v -p codesigning 2>/dev/null | awk -F'\"' '/Developer ID Application/{print $2; exit}')"
fi

if [[ -z "$identity" ]]; then
	echo "No Developer ID identity in the keychain; leaving $app_path unsigned."
	echo "signed=false" >> "${GITHUB_OUTPUT:-/dev/null}"
	exit 0
fi

echo "Signing $app_path as $identity"
codesign --force --deep --options runtime --timestamp --sign "$identity" "$app_path"
codesign --verify --deep --strict --verbose=2 "$app_path"

if [[ -n "${APPLE_ID:-}" && -n "${APPLE_APP_SPECIFIC_PASSWORD:-}" && -n "${APPLE_TEAM_ID:-}" ]]; then
	zip_path="${RUNNER_TEMP:-/tmp}/pearai-notarize.zip"
	ditto -c -k --keepParent "$app_path" "$zip_path"
	echo "Submitting to Apple notarization..."
	xcrun notarytool submit "$zip_path" \
		--apple-id "$APPLE_ID" \
		--password "$APPLE_APP_SPECIFIC_PASSWORD" \
		--team-id "$APPLE_TEAM_ID" \
		--wait
	xcrun stapler staple "$app_path"
	rm -f "$zip_path"
	echo "Notarization complete."
else
	echo "Apple notarization secrets not set; app is signed but not notarized."
fi

echo "signed=true" >> "${GITHUB_OUTPUT:-/dev/null}"
