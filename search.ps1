# Check if keywords.txt exists, create it with examples if missing
if (-not (Test-Path "keywords.txt")) {
    Write-Host "keywords.txt file not found. Creating it with example keywords..." -ForegroundColor Yellow
    
    $exampleKeywords = @(
        "keyword1", 
        "keyword2"
    )
    
    $exampleKeywords | Out-File -FilePath "keywords.txt" -Encoding UTF8
    
    Write-Host "keywords.txt has been created with example keywords:" -ForegroundColor Green
    Write-Host "  - $($exampleKeywords -join ", ")" -ForegroundColor Cyan
    Write-Host "`nPlease edit keywords.txt to add your own keywords, then re-run the script." -ForegroundColor Yellow
    exit
}

$keywords = Get-Content "keywords.txt" | Where-Object { $_.Trim() -ne "" }
$root = "C:\Freshprints-github"
$excludedDirs = @("node_modules", "build", ".git", ".angular", "dist")

# Short-circuit if root does not exist
if (-not (Test-Path $root)) {
    Write-Host "Root path not found: $root" -ForegroundColor Red
    Write-Host "Please update the root path in the script and re-run." -ForegroundColor Yellow
    exit
}

# Build one regex combining all keywords (case-insensitive)
$escapedWords = $keywords | ForEach-Object { [regex]::Escape($_) }
$regex = [regex]::new("\b($($escapedWords -join '|'))\b", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

Write-Host "Scanning files under $root..." -ForegroundColor Yellow

# Initialize spinner and gather files with live progress
$spinnerChars = @('/', '-', '\', '|')
$gatherSpinnerIndex = 0
$gatherCount = 0
$allFiles = New-Object System.Collections.Generic.List[System.IO.FileInfo]

Get-ChildItem -Path $root -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
    foreach ($dir in $excludedDirs) {
        if ($_.FullName -match "\\$dir(\\|$)") { return }
    }

    [void]$allFiles.Add($_)
    $gatherCount++
    $spinnerChar = $spinnerChars[$gatherSpinnerIndex % 4]
    $gatherSpinnerIndex++
    Write-Host "`rGathering files... $spinnerChar ($gatherCount found)" -NoNewline -ForegroundColor Yellow
}

# Clear gather spinner line and report
Write-Host "`r$(' ' * 80)`r" -NoNewline
Write-Host "Found $gatherCount files to scan." -ForegroundColor Green

# Initialize scan-phase spinner variables
$spinnerIndex = 0
$fileCount = 0
$totalFiles = $allFiles.Count

foreach ($file in $allFiles) {
    $fileCount++
    
    try {
        $content = Get-Content $file.FullName -Raw -ErrorAction Stop
        $foundMatches = $regex.Matches($content) | Select-Object -ExpandProperty Value -Unique

        if ($foundMatches.Count -gt 0) {
            # Clear the spinner line before printing results
            Write-Host "`r$(' ' * 80)`r" -NoNewline
            
            Write-Host "`n$($file.FullName)" -ForegroundColor Cyan
            foreach ($match in $foundMatches) {
                Write-Host "  - $match" -ForegroundColor Green
            }
        }
    }
    catch {
        # Ignore unreadable files
    }
    
    # Update spinner
    $spinnerChar = $spinnerChars[$spinnerIndex % 4]
    $spinnerIndex++
    Write-Host "`rScanning... $spinnerChar ($fileCount / $totalFiles files scanned)" -NoNewline -ForegroundColor Yellow
}

# Clear spinner and show completion message
Write-Host "`r$(' ' * 80)`r" -NoNewline
Write-Host "Scan complete. $fileCount files scanned." -ForegroundColor Green