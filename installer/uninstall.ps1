# Balatro Multiplayer 3P - uninstaller: removes what install.ps1 added and restores backups
param([string]$ModsRoot = "", [switch]$NoPrompt, [switch]$SkipProcessCheck, [switch]$NoPause)
$ErrorActionPreference = 'Stop'
function J([string]$base, [string]$rel) { $p = $base; foreach ($s in $rel.Split('\')) { if ($s) { $p = Join-Path $p $s } }; return $p }
function Say($m, $c = 'White') { Write-Host $m -ForegroundColor $c }
function Finish($code) { if (-not $NoPause) { Write-Host ""; Read-Host "Press Enter to close" | Out-Null }; exit $code }

if (-not $ModsRoot) { $ModsRoot = J $env:APPDATA 'Balatro\Mods' }
$ManifestPath = Join-Path (Split-Path -Parent $ModsRoot) 'MP3P-install.json'
Say "=== Balatro Multiplayer 3P uninstaller ===" Cyan
if (-not (Test-Path -LiteralPath $ManifestPath)) { Say "Nothing to uninstall (no install record found at $ManifestPath)." Yellow; Finish 1 }
if (-not $SkipProcessCheck) {
    while (Get-Process -Name 'Balatro' -ErrorAction SilentlyContinue) {
        Say "Balatro is running. Please close it first." Yellow
        if ($NoPrompt) { Finish 1 }
        Read-Host "Press Enter when closed" | Out-Null
    }
}
$m = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
if (-not $NoPrompt) {
    $a = Read-Host "Remove the 3P mod, Steamodded and Lovely and restore your backups? (y/N)"
    if ($a -notmatch '^[yY]') { Say "Cancelled."; Finish 0 }
}
foreach ($p in @($m.installedPaths)) {
    if ($p -and (Test-Path -LiteralPath $p)) {
        try { Remove-Item -LiteralPath $p -Recurse -Force; Say "  Removed $p" Green }
        catch { Say "  Could not remove $p ($($_.Exception.Message))" Red }
    }
}
foreach ($b in @($m.backups)) {
    if ($b.backup -and (Test-Path -LiteralPath $b.backup)) {
        if (Test-Path -LiteralPath $b.original) { Say "  Skipped restore, already exists: $($b.original)" Yellow; continue }
        Move-Item -LiteralPath $b.backup -Destination $b.original
        Say "  Restored $($b.original)" Green
    }
}
$dirs = @($m.backupDir) + @($m.backups | ForEach-Object { if ($_.backup) { Split-Path -Parent $_.backup } }) | Select-Object -Unique
foreach ($d in $dirs) { if ($d -and (Test-Path -LiteralPath $d) -and -not (Get-ChildItem -LiteralPath $d -Force)) { Remove-Item -LiteralPath $d -Force } }
Remove-Item -LiteralPath $ManifestPath -Force
Say "=== Uninstalled. ===" Cyan
Finish 0
