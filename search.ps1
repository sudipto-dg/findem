$keywords = Get-Content "keywords.txt"
$root = "C:\Folder-To-Search"
$excludedDirs = @("node_modules", "build", ".git", ".angular", "dist")

foreach ($keyword in $keywords) {
    Write-Host "`n=== Files containing keyword: '$keyword' ===" -ForegroundColor Cyan

    $regex = [regex]"\b$([Regex]::Escape($keyword))\b"

    Get-ChildItem -Path $root -Recurse -File |
    Where-Object {
        # Skip files inside any excluded directory
        foreach ($dir in $excludedDirs) {
            if ($_.FullName -match "\\$dir(\\|$)") { return $false }
        }
        return $true
    } |
    ForEach-Object {
        try {
            $content = Get-Content $_.FullName -Raw -ErrorAction Stop
            if ($regex.IsMatch($content)) {
                $_.FullName
            }
        }
        catch {
            # Skip files that fail to load (e.g. binary or locked files)
        }
    }
}
