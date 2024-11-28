# Print GitHub Environment Variables
Write-Host "GitHub Environment Variables:"
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
Write-Host "main_commit_hash: $env:GITHUB_EVENT_INPUT_MAIN_COMMIT_HASH"
Write-Host "submodule_commit_hash: $env:GITHUB_EVENT_INPUT_SUBMODULE_COMMIT_HASH"
Write-Host "force_build: $env:GITHUB_EVENT_INPUT_FORCE_BUILD"

# # Print all environment variables (optional)
# Write-Host "`nAll Environment Variables:"
# Get-ChildItem env: | ForEach-Object {
#     Write-Host "$($_.Name): $($_.Value)"
# }



if ($env:build_cache_hit -eq "true") {
    Write-Host "Cache hit!"
} else {
    Write-Host "Cache miss!"
}

# Create dummy folder and file
$username = [Environment]::UserName
$dummyOutput = $env:build_path  # Access the environment variable directly
mkdir -Force $dummyOutput
Set-Content -Path "$dummyOutput\temp.txt" -Value "This is a temporary test file."

Write-Host "Created dummy folder at: $dummyOutput"
Write-Host "Created temp.txt inside the folder"

