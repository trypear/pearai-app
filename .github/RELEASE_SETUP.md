# Automated Package & Release — Setup Guide

This document explains every step a maintainer needs to perform **once** to
enable the fully-automated release pipeline added by this PR.

---

## How it works

```
git push origin v1.2.3
        │
        ▼
GitHub Actions triggers `.github/workflows/release.yml`
        │
        ├─► macOS x64  runner  → builds .dmg (Intel)
        ├─► macOS arm64 runner → builds .dmg (Apple Silicon)
        ├─► Windows x64 runner → builds .exe (NSIS installer)
        ├─► Linux x64  runner  → builds .deb / .rpm / .tar.gz
        └─► Linux arm64 runner → builds .deb / .rpm (cross-compiled)
                │
                ▼ (all jobs finish)
        Release job collects artifacts, generates SHA-256 checksums,
        and publishes a GitHub Release with all assets attached.
```

No local machine, no contributor dependency, no manual steps.

---

## One-time setup (15–20 minutes)

### 1 · macOS code-signing certificate

You need an **Apple Developer ID Application** certificate.

```bash
# Export your certificate from Keychain Access as a .p12 file, then:
base64 -i YourCert.p12 | pbcopy   # copies base64 string to clipboard
```

Add to **Settings → Secrets and variables → Actions**:

| Secret name          | Value                                    |
|----------------------|------------------------------------------|
| `MACOS_CERT_P12`     | Base64 string of the .p12 file           |
| `MACOS_CERT_PASSWORD`| Password used to protect the .p12        |
| `APPLE_ID`           | Your Apple ID email (for notarization)   |
| `APPLE_ID_PASSWORD`  | App-specific password (appleid.apple.com)|
| `APPLE_TEAM_ID`      | 10-char team ID from developer.apple.com |

> **Tip:** The signing step is skipped automatically if `MACOS_CERT_P12` is
> not present — useful for forks/draft PRs that just want to verify the build.

---

### 2 · Windows code-signing certificate

You need a valid **EV or OV Code Signing** certificate in PFX/P12 format.

```powershell
# On Windows, export from Certificate Manager as .pfx, then:
[Convert]::ToBase64String([IO.File]::ReadAllBytes("YourCert.pfx")) | clip
```

| Secret name            | Value                              |
|------------------------|------------------------------------|
| `WINDOWS_CERT_P12`     | Base64 string of the .pfx file     |
| `WINDOWS_CERT_PASSWORD`| Password for the .pfx              |

---

### 3 · Trigger a release

**Option A — Git tag (recommended for real releases):**
```bash
git tag v1.2.3
git push origin v1.2.3
```

**Option B — Manual trigger (for testing):**
Go to **Actions → 🚀 Package & Release PearAI → Run workflow**. You can
set `dry_run = true` to build all platforms without publishing a release.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| `security: SecKeychainItemImport: Unknown format in import.` | Wrong base64 encoding | Re-encode: `base64 -i file.p12` (no wrapping flags) |
| `codesign: error: No identity found` | Certificate not imported | Check `MACOS_CERT_P12` secret is set correctly |
| `The file "certificate.pfx" does not exist` | Windows secret missing | Add `WINDOWS_CERT_P12` secret |
| Linux `.deb` build fails on arm64 | Missing cross-compiler | Already handled in workflow — file a bug if seen |
| Artifacts not found after build | Gulp target path changed | Update `dist-artifacts` glob patterns in the workflow |

---

## Adjusting gulp targets

PearAI's gulp tasks may differ slightly from upstream VSCode. If a step
fails with *"Task not found"*, check the available targets with:

```bash
yarn gulp --tasks | grep vscode
```

Then update the `gulp_target` values in the matrix section of
`.github/workflows/release.yml` to match.
