if (-not $script:BaseDirectory) {
    $script:BaseDirectory = Split-Path -Parent $PSScriptRoot
}

. (Join-Path $script:BaseDirectory "scripts\rules\vendors.ps1")
. (Join-Path $script:BaseDirectory "scripts\rules\patterns.ps1")
