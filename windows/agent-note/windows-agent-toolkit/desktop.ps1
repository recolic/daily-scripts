[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateSet('screenshot', 'move', 'click', 'keys', 'text')]
    [string]$Action,

    [Parameter(Position = 1)]
    [string]$Value,

    [int]$X,
    [int]$Y,

    [ValidateSet('left', 'right', 'middle')]
    [string]$Button = 'left',

    [switch]$Double
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$nircmd = Join-Path $PSScriptRoot 'nircmdc.exe'
if (-not (Test-Path -LiteralPath $nircmd)) {
    throw "Missing $nircmd"
}

switch ($Action) {
    'screenshot' {
        if (-not $Value) {
            $Value = Join-Path $env:TEMP 'copilot-desktop.png'
        }
        $outputPath = [IO.Path]::GetFullPath($Value)
        $directory = Split-Path -Parent $outputPath
        if ($directory -and -not (Test-Path -LiteralPath $directory)) {
            New-Item -ItemType Directory -Path $directory -Force | Out-Null
        }
        Remove-Item -LiteralPath $outputPath -ErrorAction SilentlyContinue
        & $nircmd savescreenshot $outputPath
        if (-not (Test-Path -LiteralPath $outputPath)) {
            throw "NirCmd did not create $outputPath"
        }
        Get-Item -LiteralPath $outputPath
    }

    'move' {
        & $nircmd setcursor $X $Y
    }

    'click' {
        & $nircmd setcursor $X $Y
        & $nircmd sendmouse $Button click
        if ($Double) {
            & $nircmd wait 100
            & $nircmd sendmouse $Button click
        }
    }

    'keys' {
        if (-not $Value) {
            throw 'Provide a NirCmd key sequence, for example: ctrl+s'
        }
        & $nircmd sendkeypress $Value
    }

    'text' {
        if ($null -eq $Value) {
            throw 'Provide text to type.'
        }
        $previousText = Get-Clipboard -Raw -ErrorAction SilentlyContinue
        try {
            Set-Clipboard -Value $Value
            & $nircmd sendkeypress ctrl+v
        }
        finally {
            if ($null -eq $previousText) {
                Set-Clipboard -Value $null
            }
            else {
                Set-Clipboard -Value $previousText
            }
        }
    }
}
