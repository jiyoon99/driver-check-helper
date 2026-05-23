function Get-LatestJsonReportPath {
    $candidateDirectories = New-Object System.Collections.Generic.List[string]
    if (Get-SafeText $script:ReportDirectory) {
        $candidateDirectories.Add($script:ReportDirectory)
    }

    if (Get-SafeText $script:BaseDirectory) {
        $candidateDirectories.Add((Join-Path $script:BaseDirectory "reports"))
    }

    $parentDirectory = if (Get-SafeText $script:BaseDirectory) { Split-Path -Parent $script:BaseDirectory } else { "" }
    if (Get-SafeText $parentDirectory) {
        $candidateDirectories.Add((Join-Path $parentDirectory "reports"))
    }

    $reports = foreach ($directory in ($candidateDirectories | Select-Object -Unique)) {
        if (-not (Test-Path -LiteralPath $directory)) {
            continue
        }

        Get-ChildItem -LiteralPath $directory -Filter "driver-report-*.json" | ForEach-Object {
            $timestamp = [datetime]::MinValue
            if ($_.BaseName -match '^driver-report-(\d{8})-(\d{6})$') {
                [void][datetime]::TryParseExact(
                    "$($matches[1])$($matches[2])",
                    "yyyyMMddHHmmss",
                    [System.Globalization.CultureInfo]::InvariantCulture,
                    [System.Globalization.DateTimeStyles]::None,
                    [ref]$timestamp
                )
            }

            [PSCustomObject]@{
                File          = $_
                ReportTime    = $timestamp
                LastWriteTime = $_.LastWriteTime
            }
        }
    }

    $report = @($reports) |
        Sort-Object @{ Expression = "ReportTime"; Descending = $true }, @{ Expression = "LastWriteTime"; Descending = $true } |
        Select-Object -First 1

    if ($report) {
        $script:ReportDirectory = $report.File.DirectoryName
        return $report.File.FullName
    }
    return $null
}

function Get-ReportDirectories {
    $candidateDirectories = New-Object System.Collections.Generic.List[string]
    if (Get-SafeText $script:ReportDirectory) {
        $candidateDirectories.Add($script:ReportDirectory)
    }

    if (Get-SafeText $script:BaseDirectory) {
        $candidateDirectories.Add((Join-Path $script:BaseDirectory "reports"))
    }

    $parentDirectory = if (Get-SafeText $script:BaseDirectory) { Split-Path -Parent $script:BaseDirectory } else { "" }
    if (Get-SafeText $parentDirectory) {
        $candidateDirectories.Add((Join-Path $parentDirectory "reports"))
    }

    return @($candidateDirectories | Select-Object -Unique)
}

function Ensure-ReportDirectories {
    foreach ($directory in Get-ReportDirectories) {
        if (-not (Get-SafeText $directory)) {
            continue
        }

        if (-not (Test-Path -LiteralPath $directory)) {
            try {
                $null = New-Item -ItemType Directory -Path $directory -Force -ErrorAction Stop
            }
            catch {
                continue
            }
        }
    }
}

function Clear-JsonReports {
    Ensure-ReportDirectories

    foreach ($directory in Get-ReportDirectories) {
        if (-not (Test-Path -LiteralPath $directory)) {
            continue
        }

        # Preserve completed reports so the GUI can reload recent results after a restart.
        Get-ChildItem -LiteralPath $directory -Filter "driver-report-*.json" |
            Where-Object { $_.Length -le 0 } |
            Remove-Item -Force
    }
}

function Remove-OldJsonReports {
    param(
        [Parameter(Mandatory = $true)]
        [string]$KeepPath,

        [int]$KeepCount = 10
    )

    if (-not (Get-SafeText $script:ReportDirectory)) {
        return
    }

    if (-not (Test-Path -LiteralPath $script:ReportDirectory)) {
        return
    }

    $resolvedKeepPath = (Resolve-Path -LiteralPath $KeepPath).Path
    Get-ChildItem -LiteralPath $script:ReportDirectory -Filter "driver-report-*.json" |
        Sort-Object LastWriteTime -Descending |
        Select-Object -Skip $KeepCount |
        Where-Object { $_.FullName -ne $resolvedKeepPath } |
        Remove-Item -Force
}

function Convert-RecommendationsToText {
    param(
        [AllowNull()]
        [object[]]$Recommendations
    )

    if (-not $Recommendations -or $Recommendations.Count -eq 0) {
        return "추천 정보가 없습니다."
    }

    $lines = New-Object System.Collections.Generic.List[string]
    foreach ($item in $Recommendations) {
        $lines.Add(("{0}. {1}" -f $item.Priority, (Get-SafeText $item.Title)))
        $lines.Add(("   {0}" -f (Get-SafeText $item.Detail)))
        foreach ($link in @($item.Links)) {
            $lines.Add(("   - {0}: {1}" -f (Get-SafeText $link.Label), (Get-SafeText $link.Url)))
        }
        $lines.Add("")
    }

    return ($lines -join [Environment]::NewLine).Trim()
}

function Convert-DeviceToDetailText {
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$Device
    )

    $parts = @(
        "장치 이름: $(Get-SafeText $Device.Name '없음')"
        "추정 장치명: $(Get-SafeText $Device.InferredName '없음')"
        "장치 분류: $(Get-SafeText $Device.Category '없음')"
        "장치 클래스: $(Get-SafeText $Device.PNPClass '없음')"
        "보고된 제조사: $(Get-SafeText $Device.Manufacturer '없음')"
        "서비스: $(Get-SafeText $Device.Service '없음')"
        "상태: $(Get-SafeText $Device.Status '없음')"
        "오류 코드: $(Get-SafeText $Device.ConfigManagerErrorCode '없음')"
        "대표 Hardware ID: $(Get-SafeText $Device.PrimaryHardwareId '없음')"
        "버스 종류: $(Get-SafeText $Device.IdAnalysis.BusType '없음')"
        "Vendor ID: $(Get-SafeText $Device.IdAnalysis.VendorId '없음')"
        "Device ID: $(Get-SafeText $Device.IdAnalysis.DeviceId '없음')"
        "Subsystem ID: $(Get-SafeText $Device.IdAnalysis.SubsystemId '없음')"
        "Revision: $(Get-SafeText $Device.IdAnalysis.Revision '없음')"
        "추정 칩셋 제조사: $(Get-SafeText $Device.ComponentVendor '없음')"
        "우선순위: $(Get-SafeText $Device.PriorityLevel '없음') / $(Get-SafeText $Device.PriorityScore '0')"
        "다음 행동: $(Get-SafeText $Device.NextAction '없음')"
        "추정 근거: $(Get-SafeText $Device.VendorInferenceSource '없음')"
        "장치 추정 근거: $(Get-SafeText $Device.DeviceInferenceSource '없음')"
        ""
        "[우선 다운로드 후보]"
        (@($Device.DriverPackageCandidates | Sort-Object Priority | ForEach-Object { "{0}. {1} - {2}" -f $_.Priority, $_.Name, $_.Query }) -join [Environment]::NewLine)
        ""
        "[추천 순서]"
        (Convert-RecommendationsToText -Recommendations @($Device.Recommendations))
    )

    return ($parts -join [Environment]::NewLine)
}

function Convert-DeviceToDetailSections {
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$Device
    )

    $priorityLevel = Get-SafeText $Device.PriorityLevel '없음'
    $priorityScore = Get-SafeText $Device.PriorityScore '0'
    $topPackage = @($Device.DriverPackageCandidates | Sort-Object Priority | Select-Object -First 1)
    $topPackageName = if ($topPackage.Count -gt 0) { Get-SafeText $topPackage[0].Name '없음' } else { '없음' }
    $topPackageQuery = if ($topPackage.Count -gt 0) { Get-SafeText $topPackage[0].Query '없음' } else { '없음' }

    $basicInfo = @(
        "장치 이름: $(Get-SafeText $Device.Name '없음')"
        "추정 장치명: $(Get-SafeText $Device.InferredName '없음')"
        "장치 묶음: $(Get-SafeText $Device.ProblemGroup '기타 계열')"
        "장치 분류: $(Get-SafeText $Device.Category '없음')"
        "장치 클래스: $(Get-SafeText $Device.PNPClass '없음')"
        "보고된 제조사: $(Get-SafeText $Device.Manufacturer '없음')"
        "추정 칩셋 제조사: $(Get-SafeText $Device.ComponentVendor '없음')"
        "상태: $(Get-SafeText $Device.Status '없음')"
        "오류 코드: $(Get-SafeText $Device.ConfigManagerErrorCode '없음')"
        "우선순위: $priorityLevel / $priorityScore"
        "우선 이유: $(Get-SafeText $Device.PriorityReason '없음')"
        "칩셋 추정 근거: $(Get-SafeText $Device.VendorInferenceSource '없음')"
        "장치 추정 근거: $(Get-SafeText $Device.DeviceInferenceSource '없음')"
    ) -join [Environment]::NewLine

    $hardwareInfo = @(
        "대표 Hardware ID"
        "$(Get-SafeText $Device.PrimaryHardwareId '없음')"
        ""
        "버스 종류: $(Get-SafeText $Device.IdAnalysis.BusType '없음')"
        "Vendor ID: $(Get-SafeText $Device.IdAnalysis.VendorId '없음')"
        "Device ID: $(Get-SafeText $Device.IdAnalysis.DeviceId '없음')"
        "Subsystem ID: $(Get-SafeText $Device.IdAnalysis.SubsystemId '없음')"
        "Revision: $(Get-SafeText $Device.IdAnalysis.Revision '없음')"
    ) -join [Environment]::NewLine

    $packageText = @($Device.DriverPackageCandidates | Sort-Object Priority | ForEach-Object {
        "{0}. {1}" -f $_.Priority, (Get-SafeText $_.Name '없음')
    }) -join [Environment]::NewLine
    if (-not (Get-SafeText $packageText)) {
        $packageText = "우선 다운로드 후보가 없습니다."
    }

    $recommendationText = Convert-RecommendationsToText -Recommendations @($Device.Recommendations)

    return [PSCustomObject]@{
        BasicInfo      = $basicInfo
        HardwareInfo   = $hardwareInfo
        Recommendation = @(
            "즉시 권장"
            "- 우선순위: $priorityLevel / $priorityScore"
            "- 먼저 할 일: $(Get-SafeText $Device.NextAction '없음')"
            "- 가장 유력한 다운로드 후보: $topPackageName"
            "- 권장 검색어: $topPackageQuery"
            ""
            "문제 장치 묶음"
            "- $(Get-SafeText $Device.ProblemGroup '기타 계열')"
            ""
            "우선 이유"
            "- $(Get-SafeText $Device.PriorityReason '없음')"
            ""
            "다음 행동"
            "- $(Get-SafeText $Device.NextAction '없음')"
            ""
            "우선 다운로드 후보"
            $packageText
            ""
            "추천 안내"
            $recommendationText
        ) -join [Environment]::NewLine
    }
}
function Set-UiBusyState {
    param([bool]$IsBusy)

    $btnScan.Enabled = -not $IsBusy
    $btnUtility.Enabled = $false
    $btnModelSupport.Enabled = $false
    $btnManualDocs.Enabled = $false
    $txtSearch.Enabled = -not $IsBusy
    $cmbCategory.Enabled = -not $IsBusy
    $chkProblemOnly.Enabled = -not $IsBusy

    $contentPanel.Refresh()
}

function Load-ReportData {
    param(
        [string]$PreferredPath,
        [switch]$RequirePreferredPath
    )

    $path = Get-SafeText $PreferredPath
    if ($path) {
        if (-not (Test-Path -LiteralPath $path)) {
            if ($RequirePreferredPath) {
                throw "이번 검사에서 생성된 JSON 리포트를 찾지 못했습니다."
            }
            $path = ""
        }
    }
    elseif ($RequirePreferredPath) {
        throw "이번 검사에서 생성된 JSON 리포트 경로를 확인하지 못했습니다."
    }

    if (-not $path) {
        $path = Get-LatestJsonReportPath
    }

    if (-not $path) {
        return $null
    }

    $script:LatestReport = $path
    Remove-OldJsonReports -KeepPath $path
    $report = Get-Content -LiteralPath $path -Encoding UTF8 -Raw | ConvertFrom-Json

    if ($null -eq $report.SchemaVersion -or [int]$report.SchemaVersion -lt $script:ExpectedSchemaVersion) {
        throw "리포트 형식이 오래되었습니다. GUI에서 다시 점검을 실행해 최신 리포트를 만들어 주세요."
    }

    Assert-ReportSchema -Report $report

    return $report
}

function Resolve-GeneratedJsonReportPath {
    param(
        [string]$ProcessOutput
    )

    $output = Get-SafeText $ProcessOutput
    if (-not $output) {
        return $null
    }

    $match = [regex]::Match($output, '(?m)^JSON_REPORT_PATH::(?<path>.+)$')
    if (-not $match.Success) {
        return $null
    }

    $path = Get-SafeText $match.Groups["path"].Value
    if (-not $path) {
        return $null
    }

    if (-not (Test-Path -LiteralPath $path)) {
        return $null
    }

    return $path
}

function Get-CategoryColor {
    param(
        [string]$Category,
        [bool]$IsProblem = $false
    )

    if ($IsProblem) {
        return [System.Drawing.Color]::FromArgb(255, 232, 232)
    }

    switch ($Category) {
        "네트워크" { return [System.Drawing.Color]::FromArgb(232, 244, 255) }
        "블루투스" { return [System.Drawing.Color]::FromArgb(232, 248, 255) }
        "그래픽" { return [System.Drawing.Color]::FromArgb(255, 243, 230) }
        "오디오" { return [System.Drawing.Color]::FromArgb(246, 238, 255) }
        "칩셋/시스템" { return [System.Drawing.Color]::FromArgb(239, 245, 233) }
        "입력장치" { return [System.Drawing.Color]::FromArgb(255, 246, 232) }
        default { return [System.Drawing.Color]::White }
    }
}



