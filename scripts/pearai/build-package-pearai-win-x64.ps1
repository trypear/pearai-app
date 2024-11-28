# Function to execute a command and check its status
function Invoke-CMD {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Command,
		[Parameter(Mandatory=$false)]
		[string]$SuccessMessage,
        [Parameter(Mandatory=$true)]
        [string]$ErrorMessage
    )

    & cmd /c $Command
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error - $ErrorMessage" -ForegroundColor Red
        exit 1
    }
	if ($SuccessMessage) {
		Write-Host "$SuccessMessage" -ForegroundColor Green
	}
}

$currentUsername = $env:USERNAME
Write-Host "Username: $currentUsername"

$currentUserHomeDir = $env:USERPROFILE
Write-Host "User home directory: $currentUserHomeDir"

$desktopDir = Join-Path -Path $currentUserHomeDir -ChildPath "desktop"
Write-Host "User Desktop: $desktopDir"

$pearaiDir = $env:GITHUB_WORKSPACE
if (!$pearaiDir -or $pearaiDir -eq "") {
	$pearaiDir = Join-Path -Path $desktopDir -ChildPath "pearai-app"
}
Write-Host "PEARAI-APP directory: $pearaiDir"



$pearaiRefDir = Join-Path -Path $pearaiDir -ChildPath "/extensions/pearai-ref"
Write-Host "PEARAI-APP Symbolic link directory: $pearaiRefDir"

$pearaiSubmoduleDir = Join-Path -Path $pearaiDir -ChildPath "/extensions/pearai-submodule"
Write-Host "PEARAI-APP Submodule directory: $pearaiSubmoduleDir"

$pearaiVSCodeExtensionDir = Join-Path -Path $pearaiSubmoduleDir -ChildPath "/extensions/vscode"
Write-Host "PEARAI-APP VSCode extension directory: $pearaiVSCodeExtensionDir"

$pearaiExtensionBuildDir = Join-Path -Path $pearaiVSCodeExtensionDir -ChildPath "/build"
Write-Host "PEARAI-APP extension build directory: $pearaiExtensionBuildDir"

$productJsonPath = Join-Path -Path $pearaiDir -ChildPath "product.json"
$productJsonContent = Get-Content -Path $productJsonPath | ConvertFrom-Json
$pearAIVersion = $productJsonContent.pearAIVersion
Write-Host "PEARAI-APP Version: $pearAIVersion"

$extensionPackageJsonPath = Join-Path -Path $pearaiVSCodeExtensionDir -ChildPath "package.json"
$extensionPackageJsonContent = Get-Content -Path $extensionPackageJsonPath | ConvertFrom-Json
$extensionVersion = $extensionPackageJsonContent.version
Write-Host "PEARAI-EXTENSION version: $extensionVersion"

$pearaiExtension = Join-Path -Path $pearaiExtensionBuildDir -ChildPath "pearai-$extensionVersion.vsix"
Write-Host "PEARAI-EXTENSION VSIX file: $pearaiExtension"

$buildOutputDir = Join-Path -Path $desktopDir -ChildPath "VSCode-win32-x64"
Write-Host "BUILT-APP output directory: $buildOutputDir"

$builtAppPearAIExePath = Join-Path -Path $buildOutputDir -ChildPath "PearAI.exe"
Write-Host "BUILT-APP PearAI EXE path: $builtAppPearAIExePath"

$builtAppPearAIExtensionDir = Join-Path -Path $buildOutputDir -ChildPath "resources/app/extensions"
Write-Host "BUILT-APP EXTENSION directory: $builtAppPearAIExtensionDir"

$rceditExe = Join-Path -Path $pearaiDir -ChildPath "build/win32/rcedit.exe"
Write-Host "rcedit.exe: $rceditExe"

$pearIconPath = Join-Path -Path $pearaiDir -ChildPath "build/win32/pearicon.ico"
Write-Host "Pear icon path: $pearIconPath"

cd $pearaiDir
git checkout main

# Remove pearai-ref directory if it exists
if (Test-Path $pearaiRefDir) {
	Write-Host "Removing pearai-ref directory"
    Remove-Item $pearaiRefDir -Recurse -Force
}

# If you have not already, run ./scripts/pearai/setup-environment.[sh,ps1]
# If already ran that upon your first install, run ./scripts/pearai/install-dependencies.[sh,ps1]

# Build the PEARAI app
# yarn gulp vscode-win32-x64

# Build the PEARAI extension (Submodule)
cd $pearaiSubmoduleDir
git checkout main
$installAndBuildScript = Join-Path -Path $pearaiSubmoduleDir -ChildPath 'scripts\install-and-build.ps1'
Invoke-Expression "powershell.exe -ExecutionPolicy Bypass -File $installAndBuildScript"

# copy .vsix to .zip
$pearaiExtensionZipPath = Join-Path -Path $pearaiExtensionBuildDir -ChildPath "pearai.pearai.zip"
Copy-Item -Path $pearaiExtension -Destination $pearaiExtensionZipPath
Write-Host "Copied $pearaiExtension to $pearaiExtensionZipPath"

# Extract the PEARAI extension
$extractDir = Join-Path -Path $pearaiExtensionBuildDir -ChildPath "pearaiExtensionExtracted"
if (Test-Path $extractDir) {
    Write-Host "Deleting existing extract directory"
    Remove-Item $extractDir -Recurse -Force
}
if (-not (Test-Path $extractDir)) {
    New-Item -ItemType Directory -Path $extractDir
}
Expand-Archive -Path $pearaiExtensionZipPath -DestinationPath $extractDir -Force
Write-Host "Extracted $pearaiExtension to $extractDir"
if (Test-Path (Join-Path -Path $builtAppPearAIExtensionDir -ChildPath "pearai.pearai")) {
    Write-Host "Deleting existing pearai.pearai directory in built app"
    Remove-Item (Join-Path -Path $builtAppPearAIExtensionDir -ChildPath "pearai.pearai") -Recurse -Force
}
Copy-Item -Path (Join-Path -Path $extractDir -ChildPath "extension") -Destination (Join-Path -Path $builtAppPearAIExtensionDir -ChildPath "pearai.pearai") -Recurse
Write-Host "Extension copied to $builtAppPearAIExtensionDir"

if (Test-Path $pearaiExtensionZipPath) {
    Write-Host "Deleting PEARAI extension zip file"
    Remove-Item $pearaiExtensionZipPath -Force
}
if (Test-Path $extractDir) {
    Write-Host "Deleting extract directory"
    Remove-Item $extractDir -Recurse -Force
}

# double check if pearai-ref directory exists
$pearaiRefPath = Join-Path -Path $builtAppPearAIExtensionDir -ChildPath "pearai-ref"
if (Test-Path $pearaiRefPath) {
    Write-Host "Removing pearai-ref directory"
    Remove-Item $pearaiRefPath -Recurse -Force
}

# double check if pearai-submodule directory exists
$pearaiSubmodulePath = Join-Path -Path $builtAppPearAIExtensionDir -ChildPath "pearai-submodule"
if (Test-Path $pearaiSubmodulePath) {
    Write-Host "Removing pearai-submodule directory"
    Remove-Item $pearaiSubmodulePath -Recurse -Force
}


# extract python 2023 extensions to the built app
$python2023ExtensionsZip = Join-Path -Path $pearaiDir -ChildPath "extensions/windows-python-2023-extensions.zip"
Expand-Archive -Path $python2023ExtensionsZip -DestinationPath $builtAppPearAIExtensionDir -Force
Write-Host "Python 2023 extensions extracted to $builtAppPearAIExtensionDir"


# Set Version info for the built app
$versionInfo = @{
    'FileDescription' = 'PearAI';
    'ProductName' = 'PearAI';
	'InternalName' = 'PearAI';
    'CompanyName' = 'PearAI, Inc.';
    'FileVersion' = $pearAIVersion;
    'ProductVersion' = $pearAIVersion;
	'LegalCopyright' = 'Copyright (C) 2015 Microsoft, Inc. All rights reserved.';
	'OriginalFilename' = 'PearAI.exe';
}

$updateVersionInfoCommand = "$rceditExe `"$builtAppPearAIExePath`" " +
    "--set-icon `"$pearIconPath`" " +
    "--set-version-string `"FileDescription`" `"$($versionInfo['FileDescription'])`" " +
    "--set-version-string `"ProductName`" `"$($versionInfo['ProductName'])`" " +
    "--set-version-string `"InternalName`" `"$($versionInfo['InternalName'])`" " +
    "--set-version-string `"CompanyName`" `"$($versionInfo['CompanyName'])`" " +
    "--set-version-string `"FileVersion`" `"$($versionInfo['FileVersion'])`" " +
    "--set-version-string `"ProductVersion`" `"$($versionInfo['ProductVersion'])`" " +
    "--set-version-string `"LegalCopyright`" `"$($versionInfo['LegalCopyright'])`" " +
    "--set-version-string `"OriginalFilename`" `"$($versionInfo['OriginalFilename'])`" " +
	"--set-file-version `"$($versionInfo['FileVersion'])`" " +
	"--set-product-version `"$($versionInfo['ProductVersion'])`" "

Invoke-CMD -Command $updateVersionInfoCommand -SuccessMessage "Successfully set icon and version info" -ErrorMessage "Failed to set icon and version info"


# make setup using Inno Setup Compiler
$innoSetupCompiler = Join-Path -Path $pearaiDir -ChildPath "build/win32/Inno Setup 6/ISCC.exe"
Write-Host "Inno Setup Compiler: $innoSetupCompiler"
$innoSetupScript = Join-Path -Path $pearaiDir -ChildPath "build/win32/pearai.iss"
Write-Host "Inno Setup script: $innoSetupScript"
& $innoSetupCompiler "/dMyAppVersion=$pearAIVersion" $innoSetupScript

cd $desktopDir
