# GitHub Action Input Variables
param (
	[bool]$IS_GITHUB_ACTION = $false,
    [string]$Input_PearappCommitHash = $null,
    [string]$Input_SubmoduleCommitHash = $null,
	[string]$Input_CustomPearAppVersion = $null,
    [bool]$Input_ForceBuild = $false
)

$printInputs = $IS_GITHUB_ACTION -or
              $Input_PearappCommitHash -or
              $Input_SubmoduleCommitHash -or
              $Input_CustomPearAppVersion -or
              $Input_ForceBuild

if ($printInputs) {
    Write-Host "-----------------INPUTS-----------------------"
}
if ($IS_GITHUB_ACTION) {
	Write-Host "IS_GITHUB_ACTION: $IS_GITHUB_ACTION"
}
if ($Input_PearappCommitHash) {
	Write-Host "Input_PearappCommitHash: $Input_PearappCommitHash"
}
if ($Input_SubmoduleCommitHash) {
	Write-Host "Input_SubmoduleCommitHash: $Input_SubmoduleCommitHash"
}
if ($Input_CustomPearAppVersion) {
	Write-Host "Input_CustomPearAppVersion: $Input_CustomPearAppVersion"
}
if ($Input_ForceBuild) {
	Write-Host "Input_ForceBuild: $Input_ForceBuild"
}


Write-Host "----------------------------------------------"

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

$extensionPackageJsonPath = Join-Path -Path $pearaiVSCodeExtensionDir -ChildPath "package.json"
$extensionPackageJsonContent = Get-Content -Path $extensionPackageJsonPath | ConvertFrom-Json
$extensionVersion = $extensionPackageJsonContent.version

$pearaiExtension = Join-Path -Path $pearaiExtensionBuildDir -ChildPath "pearai-$extensionVersion.vsix"
Write-Host "PEARAI-EXTENSION VSIX file: $pearaiExtension"

$buildOutputDir = Join-Path -Path $desktopDir -ChildPath "VSCode-win32-x64"
Write-Host "BUILT-APP output directory: $buildOutputDir"

$builtAppPearAIExePath = Join-Path -Path $buildOutputDir -ChildPath "PearAI.exe"
Write-Host "BUILT-APP PearAI EXE path: $builtAppPearAIExePath"

$builtAppPearAIExtensionDir = Join-Path -Path $buildOutputDir -ChildPath "resources/app/extensions"
Write-Host "BUILT-APP EXTENSION directory: $builtAppPearAIExtensionDir"

$cacheBuildCommitFilePath = Join-Path -Path $buildOutputDir -ChildPath ".pearai-app-build-commit"
Write-Host "Cache build commit file path: $cacheBuildCommitFilePath"

$rceditExe = Join-Path -Path $pearaiDir -ChildPath "build/win32/rcedit.exe"
Write-Host "rcedit.exe: $rceditExe"

$pearIconPath = Join-Path -Path $pearaiDir -ChildPath "build/win32/pearicon.ico"
Write-Host "Pear icon path: $pearIconPath"

cd $pearaiDir
$pearaiLatestCommitHash = (git rev-parse HEAD).Trim()
cd $pearaiSubmoduleDir
$pearaiSubmoduleLatestCommitHash = (git rev-parse HEAD).Trim()

Write-Host "----------------------------------------"
Write-Host "PEARAI-APP Version: $pearAIVersion" -ForegroundColor Green
Write-Host "PEARAI-EXTENSION version: $extensionVersion" -ForegroundColor Green
Write-Host "PEARAI-APP Latest commit hash: $pearaiLatestCommitHash" -ForegroundColor Green
Write-Host "PEARAI-SUBMODULE Latest commit hash: $pearaiSubmoduleLatestCommitHash" -ForegroundColor Green
Write-Host "----------------------------------------"

# Update cache commit file if custom version is specified
if ($Input_CustomPearAppVersion) {
    Write-Host "CUSTOM PEARAI-APP VERSION SPECIFIED: $Input_CustomPearAppVersion" -ForegroundColor Green
    $pearAIVersion = $Input_CustomPearAppVersion
    Write-Host "CUSTOM PEARAI-APP VERSION: $pearAIVersion" -ForegroundColor Green
    $extensionVersion = $Input_CustomPearAppVersion
    Write-Host "CUSTOM PEARAI-EXTENSION VERSION: $extensionVersion" -ForegroundColor Green
    # Update cache commit file to ensure build is skipped
    if (Test-Path $buildOutputDir) {
        if (Test-Path $cacheBuildCommitFilePath) {
            Remove-Item $cacheBuildCommitFilePath -Force
        }
        Set-Content -Path $cacheBuildCommitFilePath -Value $pearaiLatestCommitHash
        Write-Host "Updated cache commit file to skip build" -ForegroundColor Green
        Write-Host "CACHE COMMIT BYPASSED, CACHE COMMIT WILL HIT" -ForegroundColor Green
    } else {
        Write-Host "CUSTOM PEARAI-APP VERSION SPECIFIED, BUT NO PREVIOUS BUILD FOUND, WILL BUILD PEARAI-APP" -ForegroundColor Green
        Write-Host "CACHE COMMIT WILL MISS" -ForegroundColor Green
    }
    Write-Host "----------------------------------------"
}

cd $pearaiDir
if ((git rev-parse --abbrev-ref HEAD) -eq "main") {
    Write-Host "ON MAIN BRANCH" -ForegroundColor Green
} else {
    Write-Host "WARNING: ** NOT ON MAIN BRANCH - $(git rev-parse --abbrev-ref HEAD) **" -ForegroundColor Yellow
}

if (-not (git status --porcelain)) {
    Write-Host "CLEAN GIT STATE" -ForegroundColor Green
} else {
    Write-Host "WARNING: ** UNCOMMITTED CHANGES **" -ForegroundColor Yellow
}

try {
    if ($Input_PearappCommitHash) {
        git checkout $Input_PearappCommitHash
    }
} catch {
    Write-Host "Error checking out PEARAI-APP commit $Input_PearappCommitHash" -ForegroundColor Red
    exit 1
}

# # Remove pearai-ref directory if it exists
# if (Test-Path $pearaiRefDir) {
# 	Write-Host "Removing pearai-ref directory"
#     Remove-Item $pearaiRefDir -Recurse -Force
# }

# # If you have not already, run ./scripts/pearai/setup-environment.[sh,ps1]
# # If already ran that upon your first install, run ./scripts/pearai/install-dependencies.[sh,ps1]

# # Build the PEARAI app
# $cacheCommitHit = $false
# if (Test-Path $cacheBuildCommitFilePath) {
#     $cacheCommitHit = (Get-Content $cacheBuildCommitFilePath) -eq $pearaiLatestCommitHash
# }

# if ($Input_ForceBuild -or -not $cacheCommitHit) {
#     if ($Input_ForceBuild) {
#         Write-Host ""
#         Write-Host "----------------------------------------"
#         Write-Host "FORCE BUILD FLAG IS TRUE - BUILDING PEARAI-APP" -ForegroundColor Green
#         Write-Host "----------------------------------------"
#         Write-Host ""
#     } else {
#         Write-Host ""
#         Write-Host "----------------------------------------"
#         if (-not (Test-Path $cacheBuildCommitFilePath)) {
#             Write-Host "CACHE COMMIT FILE NOT FOUND" -ForegroundColor Green
#         } else {
#             Write-Host "CACHE COMMIT MISMATCH" -ForegroundColor Green
#             Write-Host "CACHED COMMIT: $(Get-Content $cacheBuildCommitFilePath)" -ForegroundColor Green
#             Write-Host "LATEST COMMIT: $pearaiLatestCommitHash" -ForegroundColor Green
#         }
#         Write-Host "CACHE COMMIT MISS - BUILDING PEARAI-APP" -ForegroundColor Green
#     }


#     if (Test-Path $buildOutputDir) {
#         try {
#             $creationDate = (Get-Item $buildOutputDir).CreationTime
#         } catch {
#             $creationDate = Get-Date
#         }
#         $backupBuildOutputName = $creationDate.ToString("ddMMyyyy-HHmm") + "-" + (Get-Item $buildOutputDir).Name
#         try {
#             Rename-Item -Path $buildOutputDir -NewName $backupBuildOutputName
#         } catch {
#             Write-Host "Failed to backup/rename `"$buildOutputDir`" - TO - `"$backupBuildOutputName`"" -ForegroundColor Red
#             Write-Host "Please close any apps using the directory or backup/rename the directory manually and re-run the script" -ForegroundColor Red
#             Write-Host "Error: $_" -ForegroundColor Red
#             exit 1
#         }
#         Write-Host "PREVIOUS BUILD FOUND, RENAMED to $backupBuildOutputName" -ForegroundColor Green
#     } else {
#         Write-Host "NO PREVIOUS BUILD FOUND" -ForegroundColor Green
#     }

#     Write-Host "----------------------------------------"
#     Write-Host ""

#     if (-not $IS_GITHUB_ACTION) {
#         for ($i = 3; $i -gt 0; $i--) {
#             Write-Host "PEARAI-APP BUILD STARTING IN $i SECONDS..." -ForegroundColor Green
#             Start-Sleep -Seconds 1
#         }
#     }

# 	Write-Host "PEARAI-APP BUILD STARTED" -ForegroundColor Green
# 	# yarn gulp vscode-win32-x64
#     Write-Host "PEARAI-APP BUILD COMPLETED" -ForegroundColor Green
# 	Set-Content -Path $cacheBuildCommitFilePath -Value $pearaiLatestCommitHash
#     Write-Host "PEARAI-APP BUILD COMMIT HASH CACHED - $pearaiLatestCommitHash" -ForegroundColor Green
# } else {
# 	Write-Host "PEARAI-APP CACHE COMMIT HIT, SKIPPING PEARAI-APP BUILD" -ForegroundColor Green
#     Write-Host "----------------------------------------"
# }


# if (-not $IS_GITHUB_ACTION) {
#     for ($i = 3; $i -gt 0; $i--) {
#         Write-Host "PEARAI-SUBMODULE BUILD STARTING IN $i SECONDS..." -ForegroundColor Green
#         Start-Sleep -Seconds 1
#     }
# }
# # Build the PEARAI extension (Submodule)
# cd $pearaiSubmoduleDir
# git checkout main
# $installAndBuildScript = Join-Path -Path $pearaiSubmoduleDir -ChildPath 'scripts\install-and-build.ps1'
# Invoke-Expression "powershell.exe -ExecutionPolicy Bypass -File $installAndBuildScript"

# # copy .vsix to .zip
# $pearaiExtensionZipPath = Join-Path -Path $pearaiExtensionBuildDir -ChildPath "pearai.pearai.zip"
# Copy-Item -Path $pearaiExtension -Destination $pearaiExtensionZipPath
# Write-Host "Copied $pearaiExtension to $pearaiExtensionZipPath"

# # Extract the PEARAI extension
# $extractDir = Join-Path -Path $pearaiExtensionBuildDir -ChildPath "pearaiExtensionExtracted"
# if (Test-Path $extractDir) {
#     Write-Host "Deleting existing extract directory"
#     Remove-Item $extractDir -Recurse -Force
# }
# if (-not (Test-Path $extractDir)) {
#     New-Item -ItemType Directory -Path $extractDir
# }
# Expand-Archive -Path $pearaiExtensionZipPath -DestinationPath $extractDir -Force
# Write-Host "Extracted $pearaiExtension to $extractDir"
# if (Test-Path (Join-Path -Path $builtAppPearAIExtensionDir -ChildPath "pearai.pearai")) {
#     Write-Host "Deleting existing pearai.pearai directory in built app"
#     Remove-Item (Join-Path -Path $builtAppPearAIExtensionDir -ChildPath "pearai.pearai") -Recurse -Force
# }
# Copy-Item -Path (Join-Path -Path $extractDir -ChildPath "extension") -Destination (Join-Path -Path $builtAppPearAIExtensionDir -ChildPath "pearai.pearai") -Recurse
# Write-Host "Extension copied to $builtAppPearAIExtensionDir"

# if (Test-Path $pearaiExtensionZipPath) {
#     Write-Host "Deleting PEARAI extension zip file"
#     Remove-Item $pearaiExtensionZipPath -Force
# }
# if (Test-Path $extractDir) {
#     Write-Host "Deleting extract directory"
#     Remove-Item $extractDir -Recurse -Force
# }

# # double check if pearai-ref directory exists
# $pearaiRefPath = Join-Path -Path $builtAppPearAIExtensionDir -ChildPath "pearai-ref"
# if (Test-Path $pearaiRefPath) {
#     Write-Host "Removing pearai-ref directory"
#     Remove-Item $pearaiRefPath -Recurse -Force
# }

# # double check if pearai-submodule directory exists
# $pearaiSubmodulePath = Join-Path -Path $builtAppPearAIExtensionDir -ChildPath "pearai-submodule"
# if (Test-Path $pearaiSubmodulePath) {
#     Write-Host "Removing pearai-submodule directory"
#     Remove-Item $pearaiSubmodulePath -Recurse -Force
# }


# # extract python 2023 extensions to the built app
# $python2023ExtensionsZip = Join-Path -Path $pearaiDir -ChildPath "extensions/windows-python-2023-extensions.zip"
# Expand-Archive -Path $python2023ExtensionsZip -DestinationPath $builtAppPearAIExtensionDir -Force
# Write-Host "Python 2023 extensions extracted to $builtAppPearAIExtensionDir"


# if ($Input_CustomPearAppVersion) {
#     # Don't serialize the JSON, it messes up the formatting, read it raw.
#     Write-Host "----------------------------------------"
#     Write-Host "CUSTOM PEARAI-APP VERSION SPECIFIED, UPDATING VERSION INFO" -ForegroundColor Green

#     # Update product.json while preserving original formatting
#     $builtAppProductJsonPath = Join-Path -Path $buildOutputDir -ChildPath "resources/app/product.json"
#     $productJsonContent = Get-Content -Path $builtAppProductJsonPath -Raw
#     $productJsonContent = $productJsonContent -replace '"pearAIVersion"\s*:\s*"[^"]*"', "`"pearAIVersion`": `"$pearAIVersion`""
#     Set-Content -Path $builtAppProductJsonPath -Value $productJsonContent -NoNewline
#     Write-Host "Updated pearAIVersion in pearai-app product.json to $pearAIVersion" -ForegroundColor Green

#     # Update package.json while preserving original formatting
#     $builtExtensionPackageJsonPath = Join-Path -Path $builtAppPearAIExtensionDir -ChildPath "pearai.pearai/package.json"
#     $packageJsonContent = Get-Content -Path $builtExtensionPackageJsonPath -Raw
#     $packageJsonContent = $packageJsonContent -replace '"version"\s*:\s*"[^"]*"', "`"version`": `"$extensionVersion`""
#     Set-Content -Path $builtExtensionPackageJsonPath -Value $packageJsonContent -NoNewline
#     Write-Host "Updated version in extension package.json to $extensionVersion" -ForegroundColor Green
#     Write-Host "----------------------------------------"
# }


# # Set Version info for the built app
# $versionInfo = @{
#     'FileDescription' = 'PearAI';
#     'ProductName' = 'PearAI';
# 	'InternalName' = 'PearAI';
#     'CompanyName' = 'PearAI, Inc.';
#     'FileVersion' = $pearAIVersion;
#     'ProductVersion' = $pearAIVersion;
# 	'LegalCopyright' = 'Copyright (C) 2015 Microsoft, Inc. All rights reserved.';
# 	'OriginalFilename' = 'PearAI.exe';
# }

# $updateVersionInfoCommand = "$rceditExe `"$builtAppPearAIExePath`" " +
#     "--set-icon `"$pearIconPath`" " +
#     "--set-version-string `"FileDescription`" `"$($versionInfo['FileDescription'])`" " +
#     "--set-version-string `"ProductName`" `"$($versionInfo['ProductName'])`" " +
#     "--set-version-string `"InternalName`" `"$($versionInfo['InternalName'])`" " +
#     "--set-version-string `"CompanyName`" `"$($versionInfo['CompanyName'])`" " +
#     "--set-version-string `"FileVersion`" `"$($versionInfo['FileVersion'])`" " +
#     "--set-version-string `"ProductVersion`" `"$($versionInfo['ProductVersion'])`" " +
#     "--set-version-string `"LegalCopyright`" `"$($versionInfo['LegalCopyright'])`" " +
#     "--set-version-string `"OriginalFilename`" `"$($versionInfo['OriginalFilename'])`" " +
# 	"--set-file-version `"$($versionInfo['FileVersion'])`" " +
# 	"--set-product-version `"$($versionInfo['ProductVersion'])`" "

# Invoke-CMD -Command $updateVersionInfoCommand -SuccessMessage "Successfully set icon and version info on EXE" -ErrorMessage "Failed to set icon and version info on EXE"


# # make setup using Inno Setup Compiler
# $innoSetupCompiler = Join-Path -Path $pearaiDir -ChildPath "build/win32/Inno Setup 6/ISCC.exe"
# Write-Host "Inno Setup Compiler: $innoSetupCompiler"
# $innoSetupScript = Join-Path -Path $pearaiDir -ChildPath "build/win32/pearai.iss"
# Write-Host "Inno Setup script: $innoSetupScript"
# & $innoSetupCompiler "/dMyAppVersion=$pearAIVersion" $innoSetupScript

# cd $pearaiDir
