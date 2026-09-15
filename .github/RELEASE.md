# PearAI package-release automation

This repository ships a GitHub Actions workflow that packages PearAI for every
supported desktop OS **without a contributor laptop** and **without opening
VS Code / PearAI to “Install vsix as Extension”**.

- Workflow: [`.github/workflows/package-release.yml`](./workflows/package-release.yml)
- Issue: [trypear/pearai-app#44](https://github.com/trypear/pearai-app/issues/44)

## Reviewer map

| Read first | Why |
|---|---|
| `scripts/pearai/embed-vsix.sh` | The hard #44 step: unpack `.vsix` → `publisher.name-version`, delete stubs |
| `scripts/pearai/clone-packaging-extensions.sh` | `.gitmodules` has no gitlink SHAs; `submodules: recursive` clones nothing |
| This file (secrets + gulp paths) | What maintainers must add vs the unsigned CI path |
| `CONTRIBUTING.md` § Packaging | Local fallback; same scripts as CI |

Offline tests (no Electron): `scripts/pearai/embed-vsix-test.sh` and `scripts/pearai/collect-release-artifacts-test.sh`. The `validate` job on this workflow runs both.

## Why not “one machine builds all OS”?

Issue #44 asked for a single machine to produce every OS build. That is not a
honest Electron / VS Code-fork path:

| Constraint | Why a single host fails |
|---|---|
| Native modules in `pearai-submodule` | The vsix validates `onnxruntime`, `sqlite3`, `lancedb`, `esbuild`, `ripgrep` **for the host OS/arch**. An x64 Ubuntu job cannot emit a correct linux-arm64 vsix. |
| Apple notarization | `notarytool` + Developer ID need a macOS keychain. |
| Authenticode | `signtool` needs a Windows SDK and a PFX. |
| gulp output | `npm run gulp -- vscode-<platform>-<arch>` (or `yarn gulp` locally) writes `../VSCode-<platform>-<arch>` and pulls the matching Electron binary. |

VS Code itself uses a **cloud matrix** (Azure Pipelines), not one VM. This
workflow does the same with GitHub-hosted runners:

| Artifact | Runner | Notes |
|---|---|---|
| Linux x64 `.tar.gz` / `.deb` / `.rpm` | `ubuntu-22.04` | Native |
| Linux arm64 `.tar.gz` / `.deb` / `.rpm` | `ubuntu-24.04-arm` | Native ARM. Not qemu-on-x64. |
| macOS Intel `.zip` / `.dmg` | `macos-13` | Intel. If GitHub retires this image, keep the job and change the label. |
| macOS Apple Silicon `.zip` / `.dmg` | `macos-14` | Native ARM |
| Windows x64 zip + Inno user setup | `windows-2022` | Setup task is `vscode-win32-x64-user-setup` (not `vscode-win32-x64-setup`) |

## The hard step (vsix embed)

`CONTRIBUTING.md` used to require:

1. `npm run package` in `extensions/pearai-submodule/extensions/vscode`
2. Right-click the `.vsix` in VS Code / PearAI → **Install vsix as Extension**
3. Copy `~/.vscode/extensions/pearai.pearai-<version>` into the packaged app
4. Delete the `pearai-submodule` stub inside the packaged app

A `.vsix` is a zip whose `extension/` folder **is** that installed tree.
`scripts/pearai/embed-vsix.sh` unpacks it and writes
`resources/app/extensions/<publisher>.<name>-<version>` — the same layout the
GUI installer creates. No editor process is required.

The vsix **must be built on the same OS/arch as the editor** because
`prepackage.js` copies native bindings for the host.

CI packaging workarounds (extension-repo issues, not gulp):

- `package-extensions.sh` clears `GITHUB_ACTIONS` for `pearai-submodule`’s
  `install-and-build.sh`. On ARM, `prepackage.js` otherwise curls
  `continue-server-binaries.s3.../<target>/esbuild.zip`, which is no longer a
  zip. Native ARM runners should use npm’s `esbuild@0.17.19` instead.
- Roo’s `vscode:prepublish` runs `lint:extension`
  (`ESLINT_USE_FLAT_CONFIG=false eslint`), which Windows `cmd` cannot parse.
  CI rewrites that hook to `build:webview` + `build:esbuild` only.

### Submodules are not gitlinks

`.gitmodules` lists `pearai-submodule` and `PearAI-Roo-Code`, but this repo does
**not** record submodule SHAs (`pearai-submodule` is gitignored).
`actions/checkout` with `submodules: recursive` therefore clones nothing.

`scripts/pearai/clone-packaging-extensions.sh` clones those repos explicitly
(`main` by default; override with workflow inputs).

Do **not** run `scripts/pearai/setup-environment.sh` in CI. It deletes the
extension folders, `git pull`s `origin/main` (non-reproducible), and the
Windows script launches an elevated UAC symlink helper.

## Triggering a build

**Manual (recommended first run — dry-run, unsigned artifacts):**

1. Actions → **Package & Release** → **Run workflow**
2. Leave `dry_run = true`
3. Download the `pearai-<platform>-<arch>` artifacts from the run

**Real release:**

```bash
git tag v2.0.0
git push origin v2.0.0
```

Tag pushes create a **draft** GitHub Release (maintainers review, then publish).
`workflow_dispatch` with `dry_run = false` does the same.

CI installs the editor with `npm ci` (same as `.github/workflows/basic.yml`). Do not
switch the workflow back to `yarn --frozen-lockfile` until someone repairs
`yarn.lock` on main — Yarn 1.22 currently errors with `Invalid value type 386:0`.
That lockfile bug is pre-existing and is out of scope for #44.

## Maintainer secrets

None of these are required to produce usable CI artifacts. If a secret is
missing, that platform is uploaded with an `-unsigned` suffix.

### macOS signing + notarization

Export a **Developer ID Application** certificate as `.p12`:

```bash
base64 -i DeveloperID.p12 | pbcopy
```

| Secret | Required for | Value |
|---|---|---|
| `MACOS_CERT_P12` | codesign | Base64 `.p12` |
| `MACOS_CERT_PASSWORD` | codesign | `.p12` password |
| `MACOS_CERT_IDENTITY` | codesign (optional) | e.g. `Developer ID Application: PearAI (TEAMID)` — auto-detected if omitted |
| `APPLE_ID` | notarization | Apple ID email |
| `APPLE_APP_SPECIFIC_PASSWORD` | notarization | [appleid.apple.com](https://appleid.apple.com) app password |
| `APPLE_TEAM_ID` | notarization | 10-character Team ID |

Without the Apple ID trio the `.app` is **signed but not notarized** (Gatekeeper
will still warn until you staple).

### Windows Authenticode

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("PearAI.pfx")) | Set-Clipboard
```

| Secret | Required for | Value |
|---|---|---|
| `WINDOWS_CERT_P12` | signtool | Base64 `.pfx` / `.p12` |
| `WINDOWS_CERT_PASSWORD` | signtool | PFX password |

The gulp Inno task always passes Microsoft’s internal ESRP hook
(`/sesrp=...`) but only enables it with `--sign`. This workflow does **not**
pass `--sign`. PearAI signing is `signtool` against the PFX above.

`vscode-win32-x64-setup` is **not** a real gulp task. The real names are
`vscode-win32-<arch>-user-setup` and `vscode-win32-<arch>-system-setup`.

### Linux

No signing secrets. Packages are produced with the stock gulp
`prepare-deb` / `build-deb` / `prepare-rpm` / `build-rpm` tasks **after** the
vsix is embedded (those tasks copy `../VSCode-linux-<arch>`).

## Local commands (same scripts as CI)

```bash
# 1. Extensions (must match the OS you are packaging)
./scripts/pearai/clone-packaging-extensions.sh
./scripts/pearai/package-extensions.sh

# 2. Editor (~1 hour). Output is a *sibling* of the repo:
#    ../VSCode-linux-x64, ../VSCode-darwin-arm64, ../VSCode-win32-x64
# CI uses npm ci + npm run gulp because Yarn 1.22 cannot parse this repo's
# yarn.lock (pre-existing `Invalid value type 386:0` on main).
npm ci
npm run gulp -- vscode-linux-x64    # or vscode-darwin-arm64 / vscode-win32-x64

# 3. Embed vsix (replaces the GUI install step)
./scripts/pearai/embed-vsix.sh --platform linux --arch x64 \
  --vsix extensions/pearai-submodule/extensions/vscode/build/*.vsix

# 4. Optional installers
npm run gulp -- vscode-linux-x64-prepare-deb
npm run gulp -- vscode-linux-x64-build-deb
npm run gulp -- vscode-win32-x64-user-setup
```

Offline checks (no Electron):

```bash
./scripts/pearai/embed-vsix-test.sh
./scripts/pearai/collect-release-artifacts-test.sh
```

## Artifact paths gulp actually uses

There is no `dist/*.dmg` folder. Competing PR #283 collected from `*/dist/*`,
which will always be empty in this tree.

| Platform | Unpackaged tree | Installer output |
|---|---|---|
| Darwin | `../VSCode-darwin-<arch>/PearAI.app` | `hdiutil` DMG next to the `.app` (no `vscode-*-build-dmg` task exists here) |
| Windows | `../VSCode-win32-<arch>/` | `.build/win32-<arch>/user-setup/VSCodeSetup.exe` |
| Linux | `../VSCode-linux-<arch>/` | `.build/linux/deb/<debArch>/deb/*.deb`, `.build/linux/rpm/<rpmArch>/*.rpm` |

## What this does not do

- Ship a Microsoft-signed update feed / `updateUrl` backend.
- Cross-compile linux-arm64 on an x64 runner.
- Use Electron Forge. PearAI is a VS Code gulp fork; Forge would replace the
  packaging system rather than automate it.
- Guarantee `macos-13` stays available forever — Intel is a labeled runner, not
  a cross-compile from Apple Silicon.
