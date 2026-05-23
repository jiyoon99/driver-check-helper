param()

$testPath = $PSScriptRoot

Import-Module Pester -ErrorAction Stop
$result = Invoke-Pester -Script $testPath -PassThru

if ($result.FailedCount -gt 0) {
    exit 1
}
