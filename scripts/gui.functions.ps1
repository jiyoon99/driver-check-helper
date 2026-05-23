if (-not $script:BaseDirectory) {
    $script:BaseDirectory = Split-Path -Parent $PSScriptRoot
}

. (Join-Path $script:BaseDirectory "scripts\common.functions.ps1")
. (Join-Path $script:BaseDirectory "scripts\report.schema.functions.ps1")
. (Join-Path $script:BaseDirectory "scripts\gui.report.functions.ps1")
. (Join-Path $script:BaseDirectory "scripts\gui.search.functions.ps1")
. (Join-Path $script:BaseDirectory "scripts\gui.actions.functions.ps1")
