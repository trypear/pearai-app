#!/usr/bin/env bash
# Import a Developer ID Application .p12 into an ephemeral keychain for CI signing.
# Required env: MACOS_CERT_P12 (base64), MACOS_CERT_PASSWORD
# Optional: RUNNER_TEMP (GitHub Actions), KEYCHAIN_PASSWORD

set -euo pipefail

if [[ -z "${MACOS_CERT_P12:-}" ]]; then
	echo "MACOS_CERT_P12 is empty; skipping certificate import."
	exit 0
fi

if [[ -z "${MACOS_CERT_PASSWORD:-}" ]]; then
	echo "error: MACOS_CERT_PASSWORD is required when MACOS_CERT_P12 is set" >&2
	exit 1
fi

KEYCHAIN_PATH="${KEYCHAIN_PATH:-${RUNNER_TEMP:-/tmp}/pearai-signing.keychain-db}"
KEYCHAIN_PASSWORD="${KEYCHAIN_PASSWORD:-$(openssl rand -base64 24)}"
CERT_PATH="${RUNNER_TEMP:-/tmp}/pearai-certificate.p12"

cleanup() {
	rm -f "$CERT_PATH"
}
trap cleanup EXIT

security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"

python3 - "$CERT_PATH" <<'PY'
import base64, os, sys
path = sys.argv[1]
raw = os.environ["MACOS_CERT_P12"].encode("ascii")
open(path, "wb").write(base64.b64decode(raw))
PY

security import "$CERT_PATH" \
	-k "$KEYCHAIN_PATH" \
	-P "$MACOS_CERT_PASSWORD" \
	-T /usr/bin/codesign \
	-T /usr/bin/security \
	-T /usr/bin/productsign

security set-key-partition-list \
	-S "apple-tool:,apple:,codesign:" \
	-s -k "$KEYCHAIN_PASSWORD" \
	"$KEYCHAIN_PATH"

existing="$(security list-keychains -d user | tr -d '"' | head -n 1 || true)"
if [[ -n "$existing" ]]; then
	security list-keychains -d user -s "$KEYCHAIN_PATH" "$existing"
else
	security list-keychains -d user -s "$KEYCHAIN_PATH"
fi

{
	echo "KEYCHAIN_PATH=$KEYCHAIN_PATH"
	echo "KEYCHAIN_PASSWORD=$KEYCHAIN_PASSWORD"
} >> "${GITHUB_ENV:-/dev/null}"

echo "Imported macOS signing certificate into ephemeral keychain."
