param(
    [string]$Godot = "godot",
    [string]$Python = "python",
    [switch]$Export
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$AuditCount = 0
$RuntimeCount = 0

function Assert-LastExitCode {
    param([string]$Label)
    if ($LASTEXITCODE -ne 0) {
        throw "$Label failed with exit code $LASTEXITCODE."
    }
}

function Invoke-Checked {
    param(
        [string]$Label,
        [scriptblock]$Action
    )
    Write-Host ""
    Write-Host "=== $Label ==="
    & $Action
    Assert-LastExitCode $Label
}

Push-Location $Root
try {
    Write-Host "VEX local validation"
    Write-Host "Root: $Root"

    $PythonVersion = & $Python --version 2>&1
    Assert-LastExitCode "Python version check"
    Write-Host "Python: $PythonVersion"
    if ($PythonVersion -notmatch '^Python 3\.12(?:\.|$)') {
        throw "VEX requires Python 3.12.x; detected: $PythonVersion"
    }

    $GodotVersion = & $Godot --version 2>&1
    Assert-LastExitCode "Godot version check"
    Write-Host "Godot: $GodotVersion"
    if ($GodotVersion -notmatch '^4\.7(?:\.|$)') {
        throw "VEX requires Godot 4.7.x; detected: $GodotVersion"
    }

    $Audits = Get-ChildItem -Path (Join-Path $Root "tests") -Filter "*_audit.py" -File | Sort-Object Name
    foreach ($Audit in $Audits) {
        Invoke-Checked "Audit: $($Audit.Name)" {
            & $Python $Audit.FullName
        }
        $AuditCount += 1
    }

    Invoke-Checked "Godot clean import / parse" {
        & $Godot --headless --editor --path $Root --quit
    }

    $RuntimeScenes = @(
        Join-Path $Root "tests/integrity_test.tscn"
    )
    $RuntimeScenes += Get-ChildItem -Path (Join-Path $Root "tests") -Filter "*_runtime_test.tscn" -File |
        Sort-Object Name |
        ForEach-Object { $_.FullName }

    $RuntimeScenes = $RuntimeScenes | Select-Object -Unique
    foreach ($ScenePath in $RuntimeScenes) {
        $SceneName = Split-Path -Leaf $ScenePath
        $ResourcePath = "tests/$SceneName"
        Invoke-Checked "Runtime: $SceneName" {
            & $Godot --headless --path $Root $ResourcePath
        }
        $RuntimeCount += 1
    }

    if ($Export) {
        $BuildDirectory = Join-Path $Root "build/windows"
        New-Item -ItemType Directory -Force -Path $BuildDirectory | Out-Null
        Invoke-Checked "Windows release export" {
            & $Godot --headless --path $Root --export-release "Windows Desktop" "build/windows/VEX.exe"
        }
    }

    Write-Host ""
    Write-Host "VEX LOCAL VALIDATION PASSED"
    Write-Host "Python audits: $AuditCount"
    Write-Host "Godot runtime scenes: $RuntimeCount"
    Write-Host "Windows export: $(if ($Export) { 'checked' } else { 'skipped (use -Export)' })"
}
finally {
    Pop-Location
}
