if (-not $script:BaseDirectory) {
    $script:BaseDirectory = Split-Path -Parent $PSScriptRoot
}

. (Join-Path $script:BaseDirectory "scripts\common.functions.ps1")
. (Join-Path $script:BaseDirectory "scripts\report.schema.functions.ps1")
. (Join-Path $script:BaseDirectory "scripts\main.rules.ps1")
. (Join-Path $script:BaseDirectory "scripts\main.system.functions.ps1")
. (Join-Path $script:BaseDirectory "scripts\main.analysis.functions.ps1")
. (Join-Path $script:BaseDirectory "scripts\main.report.functions.ps1")
