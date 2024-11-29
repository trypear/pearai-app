# GitHub Action Input Variables
param (
	[bool]$IS_GITHUB_ACTION = $false,
    [string]$Input_PearappCommitHash = $null,
    [string]$Input_SubmoduleCommitHash = $null,
	[string]$Input_CustomPearappVersion = $null,
    [bool]$Input_ForceBuild = $false
)

# Print GitHub Environment Variables
Write-Host "GitHub Environment Variables:"
Write-Host "IS_GITHUB_ACTION: $env:GITHUB_ACTION"
Write-Host "IS_GITHUB_ACTION: $env:GITHUB_ACTIONS"
Write-Host "GITHUB_WORKSPACE: $env:GITHUB_WORKSPACE"
Write-Host "GITHUB_SHA: $env:GITHUB_SHA"
Write-Host "GITHUB_REF: $env:GITHUB_REF"
Write-Host "GITHUB_ACTOR: $env:GITHUB_ACTOR"
Write-Host "GITHUB_REPOSITORY: $env:GITHUB_REPOSITORY"
Write-Host "GITHUB_EVENT_NAME: $env:GITHUB_EVENT_NAME"
Write-Host "GITHUB_RUN_ID: $env:GITHUB_RUN_ID"
Write-Host "GITHUB_RUN_NUMBER: $env:GITHUB_RUN_NUMBER"

# Print Workflow-set Variables
Write-Host "`nWorkflow-set Variables:"
Write-Host "build_path: $env:build_path"
Write-Host "build_cache_hit: $env:build_cache_hit"
Write-Host "needs_rebuild: $env:needs_rebuild"

# Print Workflow Input Variables
Write-Host "`nWorkflow Input Variables:"
Write-Host "IS_GITHUB_ACTION: $IS_GITHUB_ACTION"
Write-Host "pearapp_commit_hash: $Input_PearappCommitHash"
Write-Host "submodule_commit_hash: $Input_SubmoduleCommitHash"
Write-Host "custom_pearapp_version: $Input_CustomPearappVersion"
Write-Host "force_build: $Input_ForceBuild"

# # Print all environment variables (optional)
# Write-Host "`nAll Environment Variables:"
# Get-ChildItem env: | ForEach-Object {
#     Write-Host "$($_.Name): $($_.Value)"
# }

cd $env:GITHUB_WORKSPACE
yarn gulp vscode-win32-x64
