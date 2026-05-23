function Write-ConsoleSummary {
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$ComputerProfile,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$SupportResources,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$ProblemDevices,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$AllDevices
    )

    Write-Host ""
    Write-Host "=== 컴퓨터 정보 ===" -ForegroundColor Cyan
    Write-Host ("제조사      : {0}" -f $ComputerProfile.Manufacturer)
    Write-Host ("모델        : {0}" -f $ComputerProfile.Model)
    Write-Host ("시스템 계열 : {0}" -f $ComputerProfile.SystemFamily)
    Write-Host ("BIOS 버전   : {0}" -f $ComputerProfile.BIOSVersion)
    Write-Host ("시리얼 번호 : {0}" -f $ComputerProfile.SerialNumber)
    Write-Host ("메인보드    : {0}" -f $ComputerProfile.BoardProduct)
    Write-Host ("식별 정보   : ServiceTag={0}, MTM={1}, ProductNumber={2}, SystemSKU={3}" -f (Get-SafeText $ComputerProfile.ManufacturerIds.ServiceTag "-"), (Get-SafeText $ComputerProfile.ManufacturerIds.MTM "-"), (Get-SafeText $ComputerProfile.ManufacturerIds.ProductNumber "-"), (Get-SafeText $ComputerProfile.ManufacturerIds.SystemSKU "-"))

    Write-Host ""
    Write-Host "=== 추천 지원 링크 ===" -ForegroundColor Cyan
    foreach ($resource in $SupportResources) {
        Write-Host ("[{0}] {1}" -f $resource.Label, $resource.Url)
    }

    Write-Host ""
    Write-Host ("전체 장치 수   : {0}" -f $AllDevices.Count)
    Write-Host ("문제 장치 수   : {0}" -f $ProblemDevices.Count)
    $topProblem = @($ProblemDevices | Sort-Object @{ Expression = { [int]$_.PriorityScore }; Descending = $true } | Select-Object -First 1)
    if ($topProblem.Count -gt 0) {
        Write-Host ("가장 먼저 볼 장치: {0} ({1})" -f (Get-SafeText $topProblem[0].InferredName $topProblem[0].Name), (Get-SafeText $topProblem[0].PriorityLevel)) -ForegroundColor Yellow
        Write-Host ("우선 이유       : {0}" -f (Get-SafeText $topProblem[0].PriorityReason))
    }
    Write-Host ""
    Write-Host "=== 문제 장치 ===" -ForegroundColor Cyan

    if (-not $ProblemDevices -or $ProblemDevices.Count -eq 0) {
        Write-Host "문제가 있는 장치가 감지되지 않았습니다." -ForegroundColor Green
        return
    }

    foreach ($device in $ProblemDevices) {
        Write-Host ""
        Write-Host ("장치 이름      : {0}" -f $device.Name) -ForegroundColor Yellow
        Write-Host ("장치 분류      : {0}" -f $device.Category)
        Write-Host ("장치 클래스    : {0}" -f $device.PNPClass)
        Write-Host ("보고된 제조사  : {0}" -f $device.Manufacturer)
        Write-Host ("서비스        : {0}" -f $device.Service)
        Write-Host ("상태          : {0}" -f $device.Status)
        Write-Host ("오류 코드     : {0}" -f $device.ConfigManagerErrorCode)
        Write-Host ("대표 HW ID    : {0}" -f (Get-SafeText -Value $device.PrimaryHardwareId -Default "없음"))
        Write-Host ("버스 종류     : {0}" -f (Get-SafeText -Value $device.IdAnalysis.BusType -Default "알 수 없음"))
        Write-Host ("Vendor ID     : {0}" -f (Get-SafeText -Value $device.IdAnalysis.VendorId -Default "없음"))
        Write-Host ("Device ID     : {0}" -f (Get-SafeText -Value $device.IdAnalysis.DeviceId -Default "없음"))
        Write-Host ("추정 칩셋 제조사: {0}" -f $device.ComponentVendor)
        Write-Host ("우선순위       : {0} ({1})" -f (Get-SafeText $device.PriorityLevel "없음"), (Get-SafeText $device.PriorityScore 0))
        Write-Host ("다음 행동       : {0}" -f (Get-SafeText $device.NextAction "없음"))
        Write-Host ("추정 근거     : {0}" -f $device.VendorInferenceSource)
        Write-Host ("우선 후보     : {0}" -f ((@($device.DriverPackageCandidates | Sort-Object Priority | Select-Object -ExpandProperty Name) -join ", ")))
        if ($device.Recommendations.Count -gt 0) {
            Write-Host "추천 순서      :" -ForegroundColor Cyan
            foreach ($recommendation in $device.Recommendations) {
                Write-Host ("  {0}. {1}" -f $recommendation.Priority, $recommendation.Title)
            }
        }
    }
}

function Write-PreflightSummary {
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Preflight
    )

    Write-Host ""
    Write-Host "=== 사전 점검 결과 ===" -ForegroundColor Cyan
    Write-Host ("관리자 권한        : {0}" -f $(if ($Preflight.IsAdministrator) { "예" } else { "아니오" }))
    Write-Host ("CIM/WMI 접근 가능  : {0}" -f $(if ($Preflight.CanAccessCim) { "예" } else { "아니오" }))
    Write-Host ("리포트 폴더 쓰기   : {0}" -f $(if ($Preflight.CanWriteReportDirectory) { "예" } else { "아니오" }))
    Write-Host ("main.ps1 존재       : {0}" -f $(if ($Preflight.MainScriptExists) { "예" } else { "아니오" }))
    Write-Host ("driver_gui.ps1 존재 : {0}" -f $(if ($Preflight.GuiScriptExists) { "예" } else { "아니오" }))
    Write-Host ("scripts 폴더 존재   : {0}" -f $(if ($Preflight.ScriptsDirectoryExists) { "예" } else { "아니오" }))
    Write-Host ("리포트 폴더        : {0}" -f $Preflight.ReportDirectory)
    Write-Host ("scripts 폴더       : {0}" -f $Preflight.ScriptsDirectory)
    Write-Host ("리포트 점검        : {0}" -f $Preflight.ReportDirectoryMessage)
    Write-Host ("CIM/WMI 점검       : {0}" -f $Preflight.CimMessage)
    Write-Host ("판정               : {0}" -f $Preflight.Message) -ForegroundColor Yellow
}

function Save-JsonReport {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ReportDirectory,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$ReportData,

        [Parameter(Mandatory = $true)]
        [string]$Timestamp
    )

    if (-not (Test-Path -LiteralPath $ReportDirectory)) {
        New-Item -ItemType Directory -Path $ReportDirectory | Out-Null
    }

    Assert-ReportSchema -Report $ReportData

    $reportPath = Join-Path -Path $ReportDirectory -ChildPath "driver-report-$Timestamp.json"
    $ReportData | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $reportPath -Encoding UTF8
    Remove-OldJsonReports -ReportDirectory $ReportDirectory -KeepPath $reportPath
    return $reportPath
}

function Remove-OldJsonReports {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ReportDirectory,

        [Parameter(Mandatory = $true)]
        [string]$KeepPath,

        [int]$KeepCount = 10
    )

    if (-not (Test-Path -LiteralPath $ReportDirectory)) {
        return
    }

    $resolvedKeepPath = (Resolve-Path -LiteralPath $KeepPath).Path
    Get-ChildItem -LiteralPath $ReportDirectory -Filter "driver-report-*.json" |
        Sort-Object LastWriteTime -Descending |
        Select-Object -Skip $KeepCount |
        Where-Object { $_.FullName -ne $resolvedKeepPath } |
        Remove-Item -Force
}

function Save-HtmlReport {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ReportDirectory,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$ReportData,

        [Parameter(Mandatory = $true)]
        [string]$Timestamp
    )

    $htmlPath = Join-Path -Path $ReportDirectory -ChildPath "driver-report-$Timestamp.html"
    $computerProfile = $ReportData.ComputerProfile
    $devices = @($ReportData.ProblemDevices)
    $supportLinks = @($ReportData.SupportResources)
    $primarySupportLink = $ReportData.PrimarySupportLink
    $summary = $ReportData.Summary
    $isPreflight = [bool]$ReportData.IsPreflight
    $preflight = $ReportData.Preflight

    $builder = New-Object System.Text.StringBuilder
    [void]$builder.AppendLine('<!DOCTYPE html>')
    [void]$builder.AppendLine('<html lang="ko">')
    [void]$builder.AppendLine('<head>')
    [void]$builder.AppendLine('<meta charset="utf-8">')
    [void]$builder.AppendLine('<meta name="viewport" content="width=device-width, initial-scale=1">')
    [void]$builder.AppendLine('<title>드라이버 점검 보고서</title>')
    [void]$builder.AppendLine('<style>')
    [void]$builder.AppendLine('body{font-family:"Malgun Gothic","Apple SD Gothic Neo",sans-serif;background:#f4f7fb;color:#162033;margin:0;padding:32px;}')
    [void]$builder.AppendLine('.wrap{max-width:1180px;margin:0 auto;}')
    [void]$builder.AppendLine('.hero{background:linear-gradient(135deg,#103c68,#1f6aa5);color:#fff;padding:28px;border-radius:20px;box-shadow:0 10px 30px rgba(16,60,104,.18);}')
    [void]$builder.AppendLine('.meta{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:14px;margin-top:20px;}')
    [void]$builder.AppendLine('.card{background:#fff;border-radius:18px;padding:20px;box-shadow:0 8px 24px rgba(20,33,61,.08);margin-top:22px;}')
    [void]$builder.AppendLine('.device{border:1px solid #dbe5f0;border-radius:16px;padding:18px;margin-top:16px;background:#fcfdff;}')
    [void]$builder.AppendLine('.pill{display:inline-block;padding:6px 10px;border-radius:999px;background:#e8f2ff;color:#0b4d88;font-size:13px;font-weight:700;margin-right:8px;}')
    [void]$builder.AppendLine('table{width:100%;border-collapse:collapse;margin-top:12px;}')
    [void]$builder.AppendLine('th,td{text-align:left;padding:10px;border-bottom:1px solid #e5edf5;vertical-align:top;}')
    [void]$builder.AppendLine('th{width:180px;color:#49617d;}')
    [void]$builder.AppendLine('a{color:#0b63b6;text-decoration:none;}')
    [void]$builder.AppendLine('a:hover{text-decoration:underline;}')
    [void]$builder.AppendLine('ol{margin:10px 0 0 20px;padding:0;}')
    [void]$builder.AppendLine('li{margin:8px 0;}')
    [void]$builder.AppendLine('.empty{padding:26px;border-radius:16px;background:#edf7ee;color:#25643b;font-weight:700;}')
    [void]$builder.AppendLine('.muted{color:#5b728c;font-size:14px;}')
    [void]$builder.AppendLine('</style>')
    [void]$builder.AppendLine('</head>')
    [void]$builder.AppendLine('<body><div class="wrap">')
    [void]$builder.AppendLine('<section class="hero">')
    [void]$builder.AppendLine('<h1>드라이버 점검 보고서</h1>')
    [void]$builder.AppendLine("<div class='muted'>생성 시각: $(ConvertTo-HtmlEncodedText $ReportData.GeneratedAt)</div>")
    [void]$builder.AppendLine('<div class="meta">')
    [void]$builder.AppendLine("<div><strong>제조사</strong><br>$(ConvertTo-HtmlEncodedText $computerProfile.Manufacturer)</div>")
    [void]$builder.AppendLine("<div><strong>모델</strong><br>$(ConvertTo-HtmlEncodedText $computerProfile.Model)</div>")
    [void]$builder.AppendLine("<div><strong>시스템 계열</strong><br>$(ConvertTo-HtmlEncodedText $computerProfile.SystemFamily)</div>")
    [void]$builder.AppendLine("<div><strong>BIOS 버전</strong><br>$(ConvertTo-HtmlEncodedText $computerProfile.BIOSVersion)</div>")
    [void]$builder.AppendLine('</div></section>')

    if (-not $isPreflight -and $summary) {
        [void]$builder.AppendLine('<section class="card"><h2>초보자용 빠른 안내</h2>')
        [void]$builder.AppendLine("<div><strong>문제 장치 수</strong>: $(ConvertTo-HtmlEncodedText $summary.ProblemCount)</div>")
        if ($summary.TopPriority) {
            [void]$builder.AppendLine("<div><strong>가장 먼저 볼 장치</strong>: $(ConvertTo-HtmlEncodedText (Get-SafeText $summary.TopPriority.InferredName $summary.TopPriority.Name))</div>")
            [void]$builder.AppendLine("<div><strong>우선 이유</strong>: $(ConvertTo-HtmlEncodedText $summary.TopPriority.PriorityReason)</div>")
            [void]$builder.AppendLine("<div><strong>다음 행동</strong>: $(ConvertTo-HtmlEncodedText $summary.TopPriority.NextAction)</div>")
        }
        if (@($summary.InstallOrder).Count -gt 0) {
            [void]$builder.AppendLine("<div><strong>권장 설치 순서</strong>: $(ConvertTo-HtmlEncodedText ((@($summary.InstallOrder) -join ' -> ')))</div>")
        }
        foreach ($tip in @($summary.BeginnerTips)) {
            [void]$builder.AppendLine("<div class='muted'>- $(ConvertTo-HtmlEncodedText $tip)</div>")
        }
        [void]$builder.AppendLine('</section>')
    }

    if ($isPreflight -and $preflight) {
        [void]$builder.AppendLine('<section class="card"><h2>사전 점검 결과</h2>')
        [void]$builder.AppendLine("<div><strong>판정</strong>: $(ConvertTo-HtmlEncodedText $preflight.Message)</div>")
        [void]$builder.AppendLine("<div><strong>관리자 권한</strong>: $(ConvertTo-HtmlEncodedText $(if ($preflight.IsAdministrator) { '예' } else { '아니오' }))</div>")
        [void]$builder.AppendLine("<div><strong>CIM/WMI 접근</strong>: $(ConvertTo-HtmlEncodedText $(if ($preflight.CanAccessCim) { '예' } else { '아니오' }))</div>")
        [void]$builder.AppendLine("<div><strong>리포트 폴더 쓰기</strong>: $(ConvertTo-HtmlEncodedText $(if ($preflight.CanWriteReportDirectory) { '예' } else { '아니오' }))</div>")
        [void]$builder.AppendLine("<div><strong>리포트 폴더 점검</strong>: $(ConvertTo-HtmlEncodedText $preflight.ReportDirectoryMessage)</div>")
        [void]$builder.AppendLine("<div><strong>CIM/WMI 점검</strong>: $(ConvertTo-HtmlEncodedText $preflight.CimMessage)</div>")
        [void]$builder.AppendLine('</section>')
    }

    [void]$builder.AppendLine('<section class="card"><h2>제조사 지원 링크</h2>')
    if ($primarySupportLink) {
        [void]$builder.AppendLine("<div><strong>바로 이동 링크</strong>: <a href='$(ConvertTo-HtmlEncodedText $primarySupportLink.Url)' target='_blank' rel='noreferrer'>$(ConvertTo-HtmlEncodedText $primarySupportLink.Label)</a></div>")
    }
    foreach ($resource in $supportLinks) {
        [void]$builder.AppendLine("<div><a href='$(ConvertTo-HtmlEncodedText $resource.Url)' target='_blank' rel='noreferrer'>$(ConvertTo-HtmlEncodedText $resource.Label)</a></div>")
    }
    [void]$builder.AppendLine('</section>')

    [void]$builder.AppendLine('<section class="card"><h2>문제 장치 분석</h2>')
    if ($isPreflight) {
        [void]$builder.AppendLine('<div class="empty">사전 점검 모드에서는 실제 장치 분석을 수행하지 않습니다.</div>')
    }
    elseif ($devices.Count -eq 0) {
        [void]$builder.AppendLine('<div class="empty">문제가 있는 장치가 감지되지 않았습니다.</div>')
    }
    else {
        foreach ($device in $devices) {
            [void]$builder.AppendLine('<article class="device">')
            [void]$builder.AppendLine("<h3>$(ConvertTo-HtmlEncodedText $device.Name)</h3>")
            [void]$builder.AppendLine("<span class='pill'>$(ConvertTo-HtmlEncodedText $device.Category)</span>")
            [void]$builder.AppendLine("<span class='pill'>$(ConvertTo-HtmlEncodedText $device.ComponentVendor)</span>")
            [void]$builder.AppendLine("<span class='pill'>$(ConvertTo-HtmlEncodedText $device.PriorityLevel)</span>")
            [void]$builder.AppendLine('<table>')
            [void]$builder.AppendLine("<tr><th>장치 클래스</th><td>$(ConvertTo-HtmlEncodedText $device.PNPClass)</td></tr>")
            [void]$builder.AppendLine("<tr><th>보고된 제조사</th><td>$(ConvertTo-HtmlEncodedText $device.Manufacturer)</td></tr>")
            [void]$builder.AppendLine("<tr><th>서비스</th><td>$(ConvertTo-HtmlEncodedText $device.Service)</td></tr>")
            [void]$builder.AppendLine("<tr><th>상태</th><td>$(ConvertTo-HtmlEncodedText $device.Status)</td></tr>")
            [void]$builder.AppendLine("<tr><th>오류 코드</th><td>$(ConvertTo-HtmlEncodedText $device.ConfigManagerErrorCode)</td></tr>")
            [void]$builder.AppendLine("<tr><th>우선순위</th><td>$(ConvertTo-HtmlEncodedText $device.PriorityLevel) / $(ConvertTo-HtmlEncodedText $device.PriorityScore)</td></tr>")
            [void]$builder.AppendLine("<tr><th>다음 행동</th><td>$(ConvertTo-HtmlEncodedText $device.NextAction)</td></tr>")
            [void]$builder.AppendLine("<tr><th>대표 Hardware ID</th><td>$(ConvertTo-HtmlEncodedText $device.PrimaryHardwareId)</td></tr>")
            [void]$builder.AppendLine("<tr><th>버스 종류</th><td>$(ConvertTo-HtmlEncodedText $device.IdAnalysis.BusType)</td></tr>")
            [void]$builder.AppendLine("<tr><th>Vendor ID / Device ID</th><td>$(ConvertTo-HtmlEncodedText $device.IdAnalysis.VendorId) / $(ConvertTo-HtmlEncodedText $device.IdAnalysis.DeviceId)</td></tr>")
            [void]$builder.AppendLine("<tr><th>추정 근거</th><td>$(ConvertTo-HtmlEncodedText $device.VendorInferenceSource)</td></tr>")
            [void]$builder.AppendLine('</table>')
            [void]$builder.AppendLine('<h4>추천 순서</h4><ol>')
            foreach ($recommendation in @($device.Recommendations | Sort-Object Priority)) {
                [void]$builder.AppendLine("<li><strong>$(ConvertTo-HtmlEncodedText $recommendation.Title)</strong><br>$(ConvertTo-HtmlEncodedText $recommendation.Detail)")
                foreach ($link in @($recommendation.Links)) {
                    [void]$builder.AppendLine("<div><a href='$(ConvertTo-HtmlEncodedText $link.Url)' target='_blank' rel='noreferrer'>$(ConvertTo-HtmlEncodedText $link.Label)</a></div>")
                }
                [void]$builder.AppendLine('</li>')
            }
            [void]$builder.AppendLine('</ol></article>')
        }
    }
    [void]$builder.AppendLine('</section></div></body></html>')

    $builder.ToString() | Set-Content -LiteralPath $htmlPath -Encoding UTF8
    return $htmlPath
}

function Open-RecommendationLinks {
    param(
        [object[]]$ProblemDevices,
        [PSCustomObject]$PrimarySupportLink
    )

    if (-not $ProblemDevices -or $ProblemDevices.Count -eq 0) {
        return
    }

    if ($AutoOpenSupport -and $PrimarySupportLink) {
        Write-RunLog -Level "INFO" -Message "모델 드라이버 센터 자동 열기"
        Start-Process $PrimarySupportLink.Url
    }

    if ($AutoOpenCatalog) {
        $catalogUrls = $ProblemDevices | ForEach-Object { Get-SafeText -Value $_.UpdateCatalogUrl } | Where-Object { $_ } | Select-Object -Unique | Select-Object -First 3
        foreach ($url in $catalogUrls) {
            Write-RunLog -Level "INFO" -Message "카탈로그 자동 열기: $url"
            Start-Process $url
        }
    }
}

