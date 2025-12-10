param(
    [Parameter(Mandatory = $true)]
    [string]$Root
)

$ErrorActionPreference = 'Stop'

Import-Module "$PSScriptRoot/FindEm/FindEm.psm1" -Force

$keywordsPath = Join-Path $PSScriptRoot "keywords.txt"
$excludedDirs = @("node_modules", "build", ".git", ".angular", "dist", ".circleci", ".vscode", "clones", ".build")

$keywords = Get-Keywords -Path $keywordsPath
$regex = New-KeywordRegex -Keywords $keywords
if (-not $regex) {
    Write-Host "No keywords provided. Update keywords.txt and re-run." -ForegroundColor Yellow
    exit
}

Write-Host "Scanning files under $Root..." -ForegroundColor Yellow
$files = Find-Files -Root $Root -ExcludeDirectories $excludedDirs
if (-not $files -or $files.Count -eq 0) { exit }

Invoke-FileScan -Files $files -KeywordRegex $regex


