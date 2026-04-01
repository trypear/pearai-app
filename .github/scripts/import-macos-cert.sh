#!/usr/bin/env bash
# .github/scripts/import-macos-cert.sh
#
# Imports the P12 signing certificate into a temporary keychain so that
# codesign / notarytool can use it without any GUI prompts.
#
# Required env vars (injected by the workflow via GitHub Secrets):
#   MACOS_CERT_P12       – Base64-encoded .p12 certificate
#   MACOS_CERT_PASSWORD  – Password for the .p12 file

set -euo pipefail

echo "🔐 Setting up macOS code-signing keychain…"

KEYCHAIN_NAME="pearai-build.keychain-db"
KEYCHAIN_PATH="$RUNNER_TEMP/$KEYCHAIN_NAME"
KEYCHAIN_PASSWORD="$(openssl rand -base64 24)"   # ephemeral, only lives for this job
CERT_PATH="$RUNNER_TEMP/certificate.p12"

# ── Create a fresh, locked keychain ────────────────────────────────────────
security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"

# Keep it unlocked for the life of the runner (6 hours max)
security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"

# ── Decode and import the certificate ──────────────────────────────────────
echo "$MACOS_CERT_P12" | base64 --decode > "$CERT_PATH"

security import "$CERT_PATH" \
  -k "$KEYCHAIN_PATH" \
  -P "$MACOS_CERT_PASSWORD" \
  -T /usr/bin/codesign \
  -T /usr/bin/security

# Allow codesign to use the key without prompting
security set-key-partition-list \
  -S "apple-tool:,apple:,codesign:" \
  -s -k "$KEYCHAIN_PASSWORD" \
  "$KEYCHAIN_PATH"

# ── Add to the search list so tools find it automatically ──────────────────
security list-keychains -d user -s "$KEYCHAIN_PATH" "$(security list-keychains -d user | tr -d '"' | head -1)"

echo "✅  Certificate imported successfully."

# Cleanup the raw file — the keychain is ephemeral anyway
rm -f "$CERT_PATH"
