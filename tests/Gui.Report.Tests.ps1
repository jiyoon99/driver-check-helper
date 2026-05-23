$projectRoot = Split-Path -Parent $PSScriptRoot

. (Join-Path $projectRoot "scripts\common.functions.ps1")
. (Join-Path $projectRoot "scripts\report.schema.functions.ps1")
. (Join-Path $projectRoot "scripts\gui.report.functions.ps1")

$script:BaseDirectory = $projectRoot
$script:ExpectedSchemaVersion = 4

function Normalize-Newlines {
    param([string]$Text)

    if ($null -eq $Text) {
        return $Text
    }

    return $Text.Replace("`r`n", "`n").TrimEnd("`r", "`n")
}

Describe "Resolve-GeneratedJsonReportPath" {
    $resolvedPath = Join-Path $projectRoot "reports\driver-report-test.json"

    BeforeEach {
        if (-not (Test-Path -LiteralPath (Split-Path -Parent $resolvedPath))) {
            New-Item -ItemType Directory -Path (Split-Path -Parent $resolvedPath) -Force | Out-Null
        }
        '{}' | Set-Content -LiteralPath $resolvedPath -Encoding UTF8
    }

    AfterEach {
        if (Test-Path -LiteralPath $resolvedPath) {
            Remove-Item -LiteralPath $resolvedPath -Force
        }
    }

    It "extracts a valid JSON report path from process output" {
        $output = "JSON_REPORT_PATH::$resolvedPath"

        $path = Resolve-GeneratedJsonReportPath -ProcessOutput $output

        $path | Should Be $resolvedPath
    }

    It "returns null when the referenced file does not exist" {
        $output = "JSON_REPORT_PATH::C:\missing-report.json"

        $path = Resolve-GeneratedJsonReportPath -ProcessOutput $output

        $path | Should Be $null
    }
}

Describe "Load-ReportData" {
    $testReportDir = Join-Path $PSScriptRoot "tmp-reports"
    $validReportPath = Join-Path $testReportDir "driver-report-20260411-210000.json"
    $olderReportPath = Join-Path $testReportDir "driver-report-20260410-210000.json"
    $oldSchemaPath = Join-Path $testReportDir "driver-report-20260409-210000.json"
    $missingFieldsPath = Join-Path $testReportDir "driver-report-20260408-210000.json"
    $originalBaseDirectory = $script:BaseDirectory

    BeforeEach {
        if (Test-Path -LiteralPath $testReportDir) {
            Remove-Item -LiteralPath $testReportDir -Recurse -Force
        }

        New-Item -ItemType Directory -Path $testReportDir -Force | Out-Null
        $script:BaseDirectory = $testReportDir
        $script:ReportDirectory = $testReportDir
        $script:LatestReport = $null

        [pscustomobject]@{
            SchemaVersion = 4
            GeneratedAt = "2026-04-11T21:00:00"
            IsPreflight = $false
            Preflight = [pscustomobject]@{
                IsAdministrator = $true
                CanAccessCim = $true
                CanWriteReportDirectory = $true
                Message = "Ready"
            }
            ComputerProfile = [pscustomobject]@{
                Manufacturer = "Dell"
                Model = "Latitude"
                SystemFamily = "Laptop"
                DriverTargetOS = "Windows 11 x64"
            }
            SupportResources = @()
            Summary = [pscustomobject]@{}
            AllDevices = @(
                [pscustomobject]@{
                    Name = "Unknown device"
                    InferredName = "Bluetooth Device"
                    Category = "Bluetooth"
                    Manufacturer = "Intel"
                    ComponentVendor = "Intel"
                    PriorityScore = 83
                    PriorityLevel = "High"
                    PriorityReason = "Connectivity is blocked."
                    NextAction = "Install the wireless package first."
                    ProblemGroup = "Network Group"
                    DriverPackageCandidates = @()
                    Recommendations = @()
                }
            )
            ProblemDevices = @()
        } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $validReportPath -Encoding UTF8

        [pscustomobject]@{
            SchemaVersion = 4
            GeneratedAt = "2026-04-10T21:00:00"
            IsPreflight = $false
            Preflight = [pscustomobject]@{
                IsAdministrator = $true
                CanAccessCim = $true
                CanWriteReportDirectory = $true
                Message = "Ready"
            }
            ComputerProfile = [pscustomobject]@{
                Manufacturer = "Dell"
                Model = "Latitude"
                SystemFamily = "Laptop"
                DriverTargetOS = "Windows 11 x64"
            }
            SupportResources = @()
            Summary = [pscustomobject]@{}
            AllDevices = @()
            ProblemDevices = @()
        } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $olderReportPath -Encoding UTF8

        [pscustomobject]@{
            SchemaVersion = 3
            GeneratedAt = "2026-04-09T21:00:00"
            IsPreflight = $false
            Preflight = [pscustomobject]@{
                IsAdministrator = $true
                CanAccessCim = $true
                CanWriteReportDirectory = $true
                Message = "Ready"
            }
            ComputerProfile = [pscustomobject]@{
                Manufacturer = "Dell"
                Model = "Latitude"
                SystemFamily = "Laptop"
                DriverTargetOS = "Windows 11 x64"
            }
            SupportResources = @()
            Summary = [pscustomobject]@{}
            AllDevices = @()
            ProblemDevices = @()
        } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $oldSchemaPath -Encoding UTF8

        [pscustomobject]@{
            SchemaVersion = 4
            GeneratedAt = "2026-04-08T21:00:00"
            IsPreflight = $false
            Preflight = [pscustomobject]@{
                IsAdministrator = $true
                CanAccessCim = $true
                CanWriteReportDirectory = $true
                Message = "Ready"
            }
            ComputerProfile = [pscustomobject]@{
                Manufacturer = "Dell"
            }
            SupportResources = @()
            Summary = [pscustomobject]@{}
            AllDevices = @()
            ProblemDevices = @()
        } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $missingFieldsPath -Encoding UTF8
    }

    AfterEach {
        $script:BaseDirectory = $originalBaseDirectory
        if (Test-Path -LiteralPath $testReportDir) {
            Remove-Item -LiteralPath $testReportDir -Recurse -Force
        }
    }

    It "loads the preferred report path when valid" {
        $report = Load-ReportData -PreferredPath $validReportPath

        [int]$report.SchemaVersion | Should Be 4
        $script:LatestReport | Should Be $validReportPath
    }

    It "falls back to the latest report when preferred path is missing" {
        $report = Load-ReportData -PreferredPath (Join-Path $testReportDir "missing.json")

        $script:LatestReport | Should Be $validReportPath
        $report.GeneratedAt | Should Be "2026-04-11T21:00:00"
        $script:LatestReport | Should Be $validReportPath
    }

    It "throws when the report schema is older than expected" {
        { Load-ReportData -PreferredPath $oldSchemaPath } | Should Throw
    }

    It "throws when required report fields are missing" {
        { Load-ReportData -PreferredPath $missingFieldsPath } | Should Throw
    }

    It "throws when a newly generated preferred report is required but missing" {
        { Load-ReportData -PreferredPath (Join-Path $testReportDir "missing-new.json") -RequirePreferredPath } | Should Throw
    }
}

Describe "Assert-ReportSchema" {
    It "accepts a valid minimal report object" {
        $report = [pscustomobject]@{
            SchemaVersion = 4
            GeneratedAt = "2026-04-11T21:00:00"
            IsPreflight = $false
            Preflight = [pscustomobject]@{
                IsAdministrator = $true
                CanAccessCim = $true
                CanWriteReportDirectory = $true
                Message = "Ready"
            }
            ComputerProfile = [pscustomobject]@{
                Manufacturer = "Dell"
                Model = "Latitude"
                SystemFamily = "Laptop"
                DriverTargetOS = "Windows 11 x64"
            }
            SupportResources = @()
            AllDevices = @()
            ProblemDevices = @()
        }

        { Assert-ReportSchema -Report $report } | Should Not Throw
    }

    It "rejects device items missing required fields" {
        $report = [pscustomobject]@{
            SchemaVersion = 4
            GeneratedAt = "2026-04-11T21:00:00"
            IsPreflight = $false
            Preflight = [pscustomobject]@{
                IsAdministrator = $true
                CanAccessCim = $true
                CanWriteReportDirectory = $true
                Message = "Ready"
            }
            ComputerProfile = [pscustomobject]@{
                Manufacturer = "Dell"
                Model = "Latitude"
                SystemFamily = "Laptop"
                DriverTargetOS = "Windows 11 x64"
            }
            SupportResources = @()
            AllDevices = @(
                [pscustomobject]@{
                    Name = "Unknown device"
                }
            )
            ProblemDevices = @()
        }

        { Assert-ReportSchema -Report $report } | Should Throw
    }

    It "accepts the checked-in sample report" {
        $samplePath = Join-Path $projectRoot "examples\sample-report.json"
        $sampleReport = Get-Content -LiteralPath $samplePath -Encoding UTF8 -Raw | ConvertFrom-Json

        { Assert-ReportSchema -Report $sampleReport } | Should Not Throw
    }

    It "accepts the checked-in preflight sample report" {
        $samplePath = Join-Path $projectRoot "examples\sample-preflight-report.json"
        $sampleReport = Get-Content -LiteralPath $samplePath -Encoding UTF8 -Raw | ConvertFrom-Json

        { Assert-ReportSchema -Report $sampleReport } | Should Not Throw
        [bool]$sampleReport.IsPreflight | Should Be $true
        @($sampleReport.AllDevices).Count | Should Be 0
    }

    It "accepts the checked-in Huawei sample report" {
        $samplePath = Join-Path $projectRoot "examples\sample-huawei-report.json"
        $sampleReport = Get-Content -LiteralPath $samplePath -Encoding UTF8 -Raw | ConvertFrom-Json

        { Assert-ReportSchema -Report $sampleReport } | Should Not Throw
        $sampleReport.ComputerProfile.Manufacturer | Should Be "Huawei / HONOR"
    }

    It "accepts the checked-in LG sample report" {
        $samplePath = Join-Path $projectRoot "examples\sample-lg-report.json"
        $sampleReport = Get-Content -LiteralPath $samplePath -Encoding UTF8 -Raw | ConvertFrom-Json

        { Assert-ReportSchema -Report $sampleReport } | Should Not Throw
        $sampleReport.ComputerProfile.Manufacturer | Should Be "LG"
    }

    It "accepts the checked-in Razer sample report" {
        $samplePath = Join-Path $projectRoot "examples\sample-razer-report.json"
        $sampleReport = Get-Content -LiteralPath $samplePath -Encoding UTF8 -Raw | ConvertFrom-Json

        { Assert-ReportSchema -Report $sampleReport } | Should Not Throw
        $sampleReport.ComputerProfile.Manufacturer | Should Be "Razer"
    }

    It "accepts the checked-in Gigabyte sample report" {
        $samplePath = Join-Path $projectRoot "examples\sample-gigabyte-report.json"
        $sampleReport = Get-Content -LiteralPath $samplePath -Encoding UTF8 -Raw | ConvertFrom-Json

        { Assert-ReportSchema -Report $sampleReport } | Should Not Throw
        $sampleReport.ComputerProfile.Manufacturer | Should Be "Gigabyte / AORUS"
    }

    It "accepts the checked-in Dynabook sample report" {
        $samplePath = Join-Path $projectRoot "examples\sample-dynabook-report.json"
        $sampleReport = Get-Content -LiteralPath $samplePath -Encoding UTF8 -Raw | ConvertFrom-Json

        { Assert-ReportSchema -Report $sampleReport } | Should Not Throw
        $sampleReport.ComputerProfile.Manufacturer | Should Be "Dynabook / Toshiba"
    }

    It "accepts the checked-in VAIO sample report" {
        $samplePath = Join-Path $projectRoot "examples\sample-vaio-report.json"
        $sampleReport = Get-Content -LiteralPath $samplePath -Encoding UTF8 -Raw | ConvertFrom-Json

        { Assert-ReportSchema -Report $sampleReport } | Should Not Throw
        $sampleReport.ComputerProfile.Manufacturer | Should Be "VAIO"
    }

    It "accepts the checked-in Xiaomi sample report" {
        $samplePath = Join-Path $projectRoot "examples\sample-xiaomi-report.json"
        $sampleReport = Get-Content -LiteralPath $samplePath -Encoding UTF8 -Raw | ConvertFrom-Json

        { Assert-ReportSchema -Report $sampleReport } | Should Not Throw
        $sampleReport.ComputerProfile.Manufacturer | Should Be "Xiaomi / Redmi"
    }
}

Describe "Convert-DeviceToDetailSections" {
    It "matches the checked-in detail snapshots" {
        $device = [pscustomobject]@{
            Name = "Unknown device"
            InferredName = "Bluetooth Device"
            ProblemGroup = "Network Group"
            Category = "Bluetooth"
            PNPClass = "Bluetooth"
            Manufacturer = "Intel"
            ComponentVendor = "Intel"
            Status = "Error"
            ConfigManagerErrorCode = 28
            PriorityLevel = "High"
            PriorityScore = 83
            PriorityReason = "Connectivity is blocked."
            VendorInferenceSource = "USB Vendor ID 8087"
            DeviceInferenceSource = "Device name contained Bluetooth"
            NextAction = "Install the wireless package first."
            PrimaryHardwareId = "USB\VID_8087&PID_0A2A"
            IdAnalysis = [pscustomobject]@{
                BusType = "USB"
                VendorId = "8087"
                DeviceId = "0A2A"
                SubsystemId = ""
                Revision = ""
            }
            DriverPackageCandidates = @(
                [pscustomobject]@{ Priority = 1; Name = "Bluetooth Driver"; Query = "Intel Bluetooth Driver Bluetooth Device" },
                [pscustomobject]@{ Priority = 2; Name = "Wireless Combo Package"; Query = "Intel Wireless Bluetooth Combo Driver Bluetooth Device" }
            )
            Recommendations = @(
                [pscustomobject]@{ Priority = 1; Title = "Model support"; Detail = "Use the vendor support page."; Links = @() }
            )
        }

        $sections = Convert-DeviceToDetailSections -Device $device

        $expectedBasicInfo = Get-Content -LiteralPath (Join-Path $projectRoot "examples\snapshots\detail-basic-info.txt") -Encoding UTF8 -Raw
        $expectedHardwareInfo = Get-Content -LiteralPath (Join-Path $projectRoot "examples\snapshots\detail-hardware-info.txt") -Encoding UTF8 -Raw
        $expectedRecommendation = Get-Content -LiteralPath (Join-Path $projectRoot "examples\snapshots\detail-recommendation.txt") -Encoding UTF8 -Raw

        (Normalize-Newlines $sections.BasicInfo) | Should Be (Normalize-Newlines $expectedBasicInfo)
        (Normalize-Newlines $sections.HardwareInfo) | Should Be (Normalize-Newlines $expectedHardwareInfo)
        (Normalize-Newlines $sections.Recommendation) | Should Be (Normalize-Newlines $expectedRecommendation)
    }
}
