function Get-Keywords {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        $exampleKeywords = @(
            "keyword1",
            "keyword2"
        )
        $exampleKeywords | Out-File -FilePath $Path -Encoding UTF8
        Write-Host "Created example keywords file at: $Path" -ForegroundColor Yellow
        return $exampleKeywords
    }

    return (Get-Content $Path | Where-Object { $_.Trim() -ne "" })
}

function New-KeywordRegex {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Keywords
    )

    if (-not $Keywords -or $Keywords.Count -eq 0) {
        return $null
    }

    $escapedWords = $Keywords | ForEach-Object { [regex]::Escape($_) }
    return [regex]::new("\b($($escapedWords -join '|'))\b", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
}

function Find-Files {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Root,
        [string[]]$ExcludeDirectories = @("node_modules", "build", ".git", ".angular", "dist", ".circleci", ".vscode", "clones", ".build")
    )

    if (-not (Test-Path $Root)) {
        Write-Host "Root path not found: $Root" -ForegroundColor Red
        return @()
    }

    $spinnerChars = @('/', '-', '\\', '|')
    $gatherSpinnerIndex = 0
    $gatherCount = 0
    $result = New-Object System.Collections.Generic.List[System.IO.FileInfo]

    # Build exclusion patterns for Get-ChildItem
    $excludePatterns = $ExcludeDirectories | ForEach-Object { "*\$_" }

    Get-ChildItem -Path $Root -Recurse -File -Exclude $excludePatterns -ErrorAction SilentlyContinue | ForEach-Object {
        [void]$result.Add($_)
        $gatherCount++
        $spinnerChar = $spinnerChars[$gatherSpinnerIndex % 4]
        $gatherSpinnerIndex++
        Write-Host "`rGathering files... $spinnerChar ($gatherCount found)" -NoNewline -ForegroundColor Yellow
    }

    Write-Host "`r$(' ' * 80)`r" -NoNewline
    Write-Host "Found $gatherCount files to scan." -ForegroundColor Green
    return ,$result
}

function Invoke-FileScan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[System.IO.FileInfo]]$Files,
        [Parameter(Mandatory = $true)]
        [regex]$KeywordRegex
    )

    if (-not $Files -or $Files.Count -eq 0) { return }
    $spinnerChars = @('/', '-', '\\', '|')
    $spinnerIndex = 0
    $fileCount = 0
    $totalFiles = $Files.Count

    foreach ($file in $Files) {
        $fileCount++
        try {
            $content = Get-Content $file.FullName -Raw -ErrorAction Stop
            $foundMatches = $KeywordRegex.Matches($content) | Select-Object -ExpandProperty Value -Unique
            if ($foundMatches.Count -gt 0) {
                Write-Host "`r$(' ' * 80)`r" -NoNewline
                Write-Host "`n$($file.FullName)" -ForegroundColor Cyan
                foreach ($match in $foundMatches) {
                    Write-Host "  - $match" -ForegroundColor Green
                }
            }
        }
        catch {
            # ignore unreadable files
        }

        $spinnerChar = $spinnerChars[$spinnerIndex % 4]
        $spinnerIndex++
        Write-Host "`rScanning... $spinnerChar ($fileCount / $totalFiles files scanned)" -NoNewline -ForegroundColor Yellow
    }

    Write-Host "`r$(' ' * 80)`r" -NoNewline
    Write-Host "Scan complete. $fileCount files scanned." -ForegroundColor Green
}

Export-ModuleMember -Function Get-Keywords, New-KeywordRegex, Find-Files, Invoke-FileScan


