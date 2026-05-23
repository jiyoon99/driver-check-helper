function Update-DetailActionButtons {
    param([AllowNull()][psobject]$Device)

    $links = Get-DetailActionLinks -Device $Device

    $btnDetailModelSupport.Tag = $links.ModelSupportUrl
    $btnDetailModelSupport.Enabled = [bool](Get-SafeText $links.ModelSupportUrl)
    $btnDetailHardwareSearch.Tag = $links.HardwareSearchUrl
    $btnDetailHardwareSearch.Enabled = [bool](Get-SafeText $links.HardwareSearchUrl)
    $btnDetailCatalog.Tag = $links.CatalogUrl
    $btnDetailCatalog.Enabled = [bool](Get-SafeText $links.CatalogUrl)
}

function Populate-Grid {
    $grid.Rows.Clear()
    foreach ($device in $script:FilteredDevices) {
        $rowIndex = $grid.Rows.Add()
        $row = $grid.Rows[$rowIndex]
        $row.Tag = $device
        $displayName = Get-SafeText $device.InferredName
        if (-not $displayName) {
            $displayName = Get-SafeText $device.Name "없음"
        }
        $row.Cells["Name"].Value = $displayName
        $row.Cells["Category"].Value = Get-SafeText $device.Category "없음"
        $row.Cells["Class"].Value = Get-SafeText $device.PNPClass "없음"
        $row.Cells["Manufacturer"].Value = Get-SafeText $device.Manufacturer "없음"
        $row.Cells["Vendor"].Value = Get-SafeText $device.ComponentVendor "없음"
        $priorityLevel = Get-SafeText $device.PriorityLevel "없음"
        $priorityScore = Get-SafeText $device.PriorityScore "0"
        $row.Cells["Priority"].Value = "{0} ({1})" -f $priorityLevel, $priorityScore
        $packageCandidates = @($device.DriverPackageCandidates | Sort-Object Priority | Select-Object -ExpandProperty Name)
        $primaryPackage = if ($packageCandidates.Count -gt 0) { $packageCandidates[0] } else { "없음" }
        if ($packageCandidates.Count -gt 1) {
            $row.Cells["Package"].Value = "{0} 외 {1}" -f $primaryPackage, ($packageCandidates.Count - 1)
        }
        else {
            $row.Cells["Package"].Value = $primaryPackage
        }
        $row.Cells["ErrorCode"].Value = Get-SafeText $device.ConfigManagerErrorCode "없음"
        $row.DefaultCellStyle.BackColor = Get-CategoryColor -Category (Get-SafeText $device.Category) -IsProblem:([bool]$device.IsProblemDevice)
        if ([bool]$device.IsProblemDevice) {
            $row.DefaultCellStyle.Font = New-Object System.Drawing.Font("Malgun Gothic", 8.5, [System.Drawing.FontStyle]::Bold)
            $row.Cells["Priority"].Style.ForeColor = [System.Drawing.Color]::FromArgb(178, 34, 34)
            $row.Cells["ErrorCode"].Style.ForeColor = [System.Drawing.Color]::FromArgb(178, 34, 34)
        }
        elseif ((Get-SafeText $device.PriorityLevel) -eq "높음") {
            $row.Cells["Priority"].Style.ForeColor = [System.Drawing.Color]::FromArgb(163, 90, 20)
        }
        else {
            $row.Cells["Priority"].Style.ForeColor = [System.Drawing.Color]::FromArgb(54, 73, 98)
            $row.Cells["ErrorCode"].Style.ForeColor = [System.Drawing.Color]::FromArgb(54, 73, 98)
        }
    }

    if ($grid.Rows.Count -gt 0) {
        $grid.Rows[0].Selected = $true
        $sections = Convert-DeviceToDetailSections -Device $grid.Rows[0].Tag
        $detailBasicBox.Text = $sections.BasicInfo
        $detailHardwareBox.Text = $sections.HardwareInfo
        $detailRecommendationBox.Text = ($sections.Recommendation + [Environment]::NewLine + [Environment]::NewLine + '공식 링크 우선순위' + [Environment]::NewLine + (Get-OfficialPriorityTextForDevice -Device $grid.Rows[0].Tag))
        Update-DetailActionButtons -Device $grid.Rows[0].Tag
    }
    else {
        $detailBasicBox.Text = "표시할 장치가 없습니다."
        $detailHardwareBox.Text = ""
        $detailRecommendationBox.Text = ""
        Update-DetailActionButtons -Device $null
    }
}

function Start-DriverScanProcess {
    param(
        [switch]$Preflight
    )

    $arguments = '-NoProfile -ExecutionPolicy Bypass -File "{0}"' -f $script:MainScriptPath
    if ($Preflight) {
        $arguments += ' -Preflight'
    }

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $psi.Arguments = $arguments
    $psi.WorkingDirectory = $script:BaseDirectory
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
    $psi.StandardErrorEncoding = [System.Text.Encoding]::UTF8

    return [System.Diagnostics.Process]::Start($psi)
}

function Show-ReportData {
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$Report,
        [string]$StatusText = "최신 리포트를 불러왔습니다."
    )

    $deviceList = if ($Report.AllDevices) { @($Report.AllDevices) } else { @($Report.ProblemDevices) }
    $deviceList = @($deviceList | Sort-Object @{ Expression = { [int]$_.PriorityScore }; Descending = $true }, @{ Expression = { [bool]$_.IsProblemDevice }; Descending = $true }, @{ Expression = { Get-SafeText $_.InferredName $_.Name } })
    $problemCount = @($deviceList | Where-Object { [bool]$_.IsProblemDevice }).Count
    $generatedAtText = Get-SafeText $Report.GeneratedAt "없음"
    $sublineText = Get-SafeText $Report.ComputerProfile.Subline
    if (-not $sublineText) {
        $sublineText = Get-SafeText (Resolve-ManufacturerSublineInfo -Manufacturer $Report.ComputerProfile.Manufacturer -Model $Report.ComputerProfile.Model -SystemFamily $Report.ComputerProfile.SystemFamily).Name
    }

    $script:CurrentReport = $Report
    $script:CurrentDevices = $deviceList

    $verdictText = "발견된 문제 없음"
    $verdictColor = [System.Drawing.Color]::FromArgb(40, 125, 60)
    $hintText = "문제 장치가 감지되지 않았습니다."
    $badgeText = "NORMAL"
    $badgeColor = [System.Drawing.Color]::FromArgb(44, 122, 78)
    $modeText = "실행 모드: 전체 점검"
    $modeValueText = "전체 점검"
    $priorityText = "대응 불필요"
    if ([bool]$Report.IsPreflight) {
        $verdictText = "사전 점검 모드"
        $verdictColor = [System.Drawing.Color]::FromArgb(180, 120, 20)
        $hintText = Get-SafeText $Report.Preflight.Message "관리자 권한이 없어 사전 점검 결과만 표시합니다."
        $badgeText = "PREFLIGHT"
        $badgeColor = [System.Drawing.Color]::FromArgb(180, 120, 20)
        $modeText = "실행 모드: 사전 점검"
        $modeValueText = "사전 점검"
        $priorityText = "관리자 권한으로 재실행"
    }
    elseif ($problemCount -gt 0) {
        $verdictText = "드라이버 설치 필요"
        $verdictColor = [System.Drawing.Color]::FromArgb(178, 34, 34)
        $hintText = "문제 장치가 감지되었습니다. 우선순위가 높은 항목부터 확인하고 더블클릭으로 검색을 열어 주세요."
        $badgeText = "ACTION"
        $badgeColor = [System.Drawing.Color]::FromArgb(178, 34, 34)
        $priorityText = Get-SafeText $Report.Summary.TopPriority.InferredName $Report.Summary.TopPriority.Name
    }

    $inspectionVerdict.Text = $verdictText
    $inspectionVerdict.ForeColor = $verdictColor
    $inspectionHint.Text = $hintText
    $statusBadge.Text = $badgeText
    $statusBadge.BackColor = $badgeColor
    $heroMetaLabel.Text = "마지막 점검: {0}" -f $generatedAtText
    $heroModeLabel.Text = $modeText
    $heroSchemaLabel.Text = "리포트 스키마: v{0}" -f (Get-SafeText $Report.SchemaVersion $script:ExpectedSchemaVersion)
    $systemLabel = if (Get-SafeText $sublineText) {
        "{0} / {1} / {2}" -f (Get-SafeText $Report.ComputerProfile.Manufacturer '-'), $sublineText, (Get-SafeText $Report.ComputerProfile.Model '-')
    }
    else {
        "{0} / {1}" -f (Get-SafeText $Report.ComputerProfile.Manufacturer '-'), (Get-SafeText $Report.ComputerProfile.Model '-')
    }
    $summaryValue1.Text = $systemLabel
    $summaryValue2.Text = "{0}개 / {1}개" -f $deviceList.Count, $problemCount
    $kpiValue1.Text = "{0}개" -f $problemCount
    $kpiValue2.Text = $modeValueText
    $kpiValue3.Text = Get-SafeText $priorityText "-"

    if ([bool]$Report.IsPreflight) {
        $summaryCardValue1.Text = "권한 점검"
        $summaryCardValue2.Text = if ($Report.Preflight.CanAccessCim) { "CIM 접근 가능" } else { "CIM 접근 제한" }
        $summaryCardValue3.Text = Get-SafeText $Report.Preflight.Message "관리자 권한 점검 필요"
        $summaryBox.Text = "환경 메모: 관리자 권한 {0}, 리포트 폴더 쓰기 {1}" -f ($(if ($Report.Preflight.IsAdministrator) { '예' } else { '아니오' })), ($(if ($Report.Preflight.CanWriteReportDirectory) { '가능' } else { '제한' }))
    }
    else {
        $utility = Get-ManufacturerUtilityLink
        $manualLink = Get-ManualSupportLink
        $utilityLabel = if ($utility) { Get-SafeText $utility.Label "없음" } else { "없음" }
        $manualLabel = if ($manualLink) { Get-SafeText $manualLink.Label "없음" } else { "없음" }
        $topPriority = $Report.Summary.TopPriority
        $topPriorityText = if ($topPriority) { Get-SafeText $topPriority.InferredName $topPriority.Name } else { "없음" }

        $summaryCardValue1.Text = Get-SafeText $Report.ComputerProfile.DriverTargetOS "없음"
        $summaryCardValue2.Text = Get-SafeText $Report.PrimarySupportLink.Label "없음"
        $topProblemGroup = @($Report.Summary.ProblemGroups | Select-Object -First 1)
        $summaryCardValue3.Text = if ($topProblemGroup.Count -gt 0) { ('{0} ({1}개)' -f (Get-SafeText $topProblemGroup[0].Name '없음'), [int]$topProblemGroup[0].Count) } else { $topPriorityText }
        $topReason = if ($topPriority) { Get-SafeText $topPriority.PriorityReason "없음" } else { "없음" }
        $summaryBox.Text = "추가 안내: 가장 먼저 볼 이유 - {0} / 공식 링크 1순위 모델 지원 / 장치를 더블클릭하면 드라이버 검색이 열립니다." -f $topReason
    }

    $problemGroups = @($Report.Summary.ProblemGroups | ForEach-Object { Get-SafeText $_.Name } | Where-Object { Get-SafeText $_ })
    $cmbProblemGroup.Items.Clear()
    $null = $cmbProblemGroup.Items.Add("전체")
    foreach ($groupName in ($problemGroups | Select-Object -Unique)) {
        $null = $cmbProblemGroup.Items.Add($groupName)
    }
    $cmbProblemGroup.SelectedIndex = 0

    Update-UtilityButtons
    Apply-Filters
    $statusLabel.Text = $StatusText
}

function Complete-DriverScan {
    if (-not $script:ScanProcess) {
        return
    }

    $process = $script:ScanProcess
    $script:ScanProcess = $null
    $script:ScanPollTimer.Stop()
    Set-UiBusyState -IsBusy $false

    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    $exitCode = $process.ExitCode
    $process.Dispose()
    $generatedReportPath = Resolve-GeneratedJsonReportPath -ProcessOutput $stdout

    if ($exitCode -ne 0) {
        $message = Get-SafeText -Value $stderr
        if (-not $message) {
            $message = Get-SafeText -Value $stdout -Default "점검 실행 중 오류가 발생했습니다."
        }

        $statusBadge.Text = "FAILED"
        $statusBadge.BackColor = [System.Drawing.Color]::FromArgb(178, 34, 34)
        $heroModeLabel.Text = "실행 모드: 오류"
        $statusLabel.Text = "점검 실패"
        [System.Windows.Forms.MessageBox]::Show($message, "오류")
        return
    }

    try {
        if (-not (Get-SafeText $generatedReportPath)) {
            throw "이번 검사에서 생성된 JSON 리포트 경로를 확인하지 못했습니다."
        }

        $report = Load-ReportData -PreferredPath $generatedReportPath -RequirePreferredPath
        if (-not $report) {
            $statusBadge.Text = "FAILED"
            $statusBadge.BackColor = [System.Drawing.Color]::FromArgb(178, 34, 34)
            $heroModeLabel.Text = "실행 모드: 오류"
            $statusLabel.Text = "점검 실패"
            [System.Windows.Forms.MessageBox]::Show("이번 검사에서 생성된 JSON 리포트를 불러오지 못했습니다.", "오류")
            return
        }

        $statusText = if ([bool]$report.IsPreflight) {
            "사전 점검이 완료되었습니다."
        }
        else {
            "점검이 완료되었습니다."
        }

        Show-ReportData -Report $report -StatusText $statusText
    }
    catch {
        $statusBadge.Text = "FAILED"
        $statusBadge.BackColor = [System.Drawing.Color]::FromArgb(178, 34, 34)
        $heroModeLabel.Text = "실행 모드: 오류"
        $statusLabel.Text = "점검 실패"
        $message = Get-SafeText $_.Exception.Message "리포트 처리 중 오류가 발생했습니다."
        if (-not $message -and $stderr) {
            $message = Get-SafeText $stderr
        }
        [System.Windows.Forms.MessageBox]::Show($message, "오류")
    }
}

function Apply-Filters {
    $searchText = (Get-SafeText $txtSearch.Text).ToLowerInvariant()
    $selectedCategory = Get-SafeText $cmbCategory.SelectedItem "전체"
    $selectedProblemGroup = Get-SafeText $cmbProblemGroup.SelectedItem "전체"
    $devices = @($script:CurrentDevices)

    if ($chkProblemOnly.Checked) {
        $devices = @($devices | Where-Object { [bool]$_.IsProblemDevice })
    }

    if ($selectedCategory -ne "전체") {
        $devices = @($devices | Where-Object { (Get-SafeText $_.Category) -eq $selectedCategory })
    }

    if ($selectedProblemGroup -ne "전체") {
        $devices = @($devices | Where-Object { (Get-SafeText $_.ProblemGroup) -eq $selectedProblemGroup })
    }

    if ($searchText) {
        $devices = @($devices | Where-Object {
            ((Get-SafeText $_.Name).ToLowerInvariant().Contains($searchText)) -or
            ((Get-SafeText $_.Manufacturer).ToLowerInvariant().Contains($searchText)) -or
            ((Get-SafeText $_.ComponentVendor).ToLowerInvariant().Contains($searchText)) -or
            ((Get-SafeText $_.PrimaryHardwareId).ToLowerInvariant().Contains($searchText))
        })
    }

    $script:FilteredDevices = $devices
    Populate-Grid
}

function Update-ResponsiveLayout {
    $heroPanel.Location = New-Object System.Drawing.Point(20, 10)
    $heroPanel.Size = New-Object System.Drawing.Size(1240, 108)
    $heroAccent.Size = New-Object System.Drawing.Size(1240, 6)
    $header.Location = New-Object System.Drawing.Point(28, 14)
    $subHeader.Location = New-Object System.Drawing.Point(30, 40)
    $subHeader.MaximumSize = New-Object System.Drawing.Size(710, 18)
    $subHeader.Visible = $false

    $actionBar.Location = New-Object System.Drawing.Point(22, 60)
    $actionBar.Size = New-Object System.Drawing.Size(742, 38)
    $actionBarTag.Location = New-Object System.Drawing.Point(10, 3)
    $btnScan.Location = New-Object System.Drawing.Point(10, 10)
    $btnScan.Size = New-Object System.Drawing.Size(150, 24)
    $btnUtility.Location = New-Object System.Drawing.Point(162, 10)
    $btnUtility.Size = New-Object System.Drawing.Size(180, 24)
    $btnModelSupport.Location = New-Object System.Drawing.Point(344, 10)
    $btnModelSupport.Size = New-Object System.Drawing.Size(170, 24)
    $btnManualDocs.Location = New-Object System.Drawing.Point(516, 10)
    $btnManualDocs.Size = New-Object System.Drawing.Size(170, 24)

    $statusBadge.Location = New-Object System.Drawing.Point(820, 14)
    $statusBadge.Visible = $false
    $heroMetaLabel.Location = New-Object System.Drawing.Point(920, 16)
    $heroMetaLabel.Size = New-Object System.Drawing.Size(316, 17)
    $heroMetaLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
    $heroModeLabel.Location = New-Object System.Drawing.Point(820, 38)
    $heroModeLabel.Size = New-Object System.Drawing.Size(190, 16)
    $heroSchemaLabel.Location = New-Object System.Drawing.Point(1020, 38)
    $heroSchemaLabel.Size = New-Object System.Drawing.Size(200, 16)
    $heroSchemaLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
    $statusLabel.Location = New-Object System.Drawing.Point(820, 60)
    $statusLabel.Size = New-Object System.Drawing.Size(400, 18)
    $utilityHint.Location = New-Object System.Drawing.Point(820, 80)
    $utilityHint.Size = New-Object System.Drawing.Size(400, 20)
    $utilityHint.Visible = $true

    $inspectionPanel.Location = New-Object System.Drawing.Point(20, 126)
    $inspectionPanel.Size = New-Object System.Drawing.Size(1240, 112)
    $inspectionAccent.Height = 112
    $inspectionTitle.Location = New-Object System.Drawing.Point(20, 12)
    $inspectionVerdict.Location = New-Object System.Drawing.Point(20, 30)
    $inspectionVerdict.Size = New-Object System.Drawing.Size(420, 34)
    $inspectionHint.Location = New-Object System.Drawing.Point(24, 64)
    $inspectionHint.Size = New-Object System.Drawing.Size(430, 16)
    $kpiCard1.Location = New-Object System.Drawing.Point(20, 84)
    $kpiCard1.Size = New-Object System.Drawing.Size(156, 22)
    $kpiCard2.Location = New-Object System.Drawing.Point(184, 84)
    $kpiCard2.Size = New-Object System.Drawing.Size(156, 22)
    $kpiCard3.Location = New-Object System.Drawing.Point(348, 84)
    $kpiCard3.Size = New-Object System.Drawing.Size(404, 22)
    $kpiLabel1.Location = New-Object System.Drawing.Point(8, 3)
    $kpiLabel2.Location = New-Object System.Drawing.Point(8, 3)
    $kpiLabel3.Location = New-Object System.Drawing.Point(8, 3)
    $kpiValue1.Location = New-Object System.Drawing.Point(76, 3)
    $kpiValue2.Location = New-Object System.Drawing.Point(76, 3)
    $kpiValue3.Location = New-Object System.Drawing.Point(76, 3)
    $kpiValue1.Size = New-Object System.Drawing.Size(68, 18)
    $kpiValue2.Size = New-Object System.Drawing.Size(68, 18)
    $kpiValue3.Size = New-Object System.Drawing.Size(316, 18)

    $inspectionDivider.Visible = $true
    $inspectionDivider.Location = New-Object System.Drawing.Point(776, 12)
    $inspectionDivider.Size = New-Object System.Drawing.Size(1, 88)
    $summaryInfoPanel.Location = New-Object System.Drawing.Point(796, 12)
    $summaryInfoPanel.Size = New-Object System.Drawing.Size(424, 88)
    $summaryLabel1.Location = New-Object System.Drawing.Point(12, 8)
    $summaryValue1.Location = New-Object System.Drawing.Point(12, 26)
    $summaryValue1.Size = New-Object System.Drawing.Size(396, 24)
    $summaryLabel2.Location = New-Object System.Drawing.Point(12, 58)
    $summaryValue2.Location = New-Object System.Drawing.Point(188, 58)
    $summaryValue2.Size = New-Object System.Drawing.Size(208, 18)

    $summaryPanel.Location = New-Object System.Drawing.Point(20, 242)
    $summaryPanel.Size = New-Object System.Drawing.Size(1240, 88)
    $summaryPanelLine.Location = New-Object System.Drawing.Point(12, 30)
    $summaryPanelLine.Size = New-Object System.Drawing.Size(1214, 1)
    $summaryPanelLabel.Location = New-Object System.Drawing.Point(14, 8)
    $summaryPanelTag.Location = New-Object System.Drawing.Point(96, 6)
    $summaryCard1.Location = New-Object System.Drawing.Point(12, 40)
    $summaryCard1.Size = New-Object System.Drawing.Size(260, 36)
    $summaryCardLabel1.Location = New-Object System.Drawing.Point(10, 4)
    $summaryCardValue1.Location = New-Object System.Drawing.Point(10, 16)
    $summaryCardValue1.Size = New-Object System.Drawing.Size(238, 20)
    $summaryCard2.Location = New-Object System.Drawing.Point(286, 40)
    $summaryCard2.Size = New-Object System.Drawing.Size(330, 36)
    $summaryCardLabel2.Location = New-Object System.Drawing.Point(10, 4)
    $summaryCardValue2.Location = New-Object System.Drawing.Point(10, 16)
    $summaryCardValue2.Size = New-Object System.Drawing.Size(308, 20)
    $summaryCard3.Location = New-Object System.Drawing.Point(630, 40)
    $summaryCard3.Size = New-Object System.Drawing.Size(590, 36)
    $summaryCardLabel3.Location = New-Object System.Drawing.Point(10, 4)
    $summaryCardValue3.Location = New-Object System.Drawing.Point(10, 16)
    $summaryCardValue3.Size = New-Object System.Drawing.Size(568, 20)
    $summaryBox.Location = New-Object System.Drawing.Point(12, 0)
    $summaryBox.Size = New-Object System.Drawing.Size(1, 1)
    $summaryBox.Visible = $false

    $listPanel.Location = New-Object System.Drawing.Point(20, 338)
    $listPanel.Size = New-Object System.Drawing.Size(1240, 216)
    $listPanelLine.Location = New-Object System.Drawing.Point(14, 36)
    $listPanelLine.Size = New-Object System.Drawing.Size(1212, 1)
    $listLabel.Location = New-Object System.Drawing.Point(14, 10)
    $listPanelTag.Location = New-Object System.Drawing.Point(100, 8)
    $filterBar.Location = New-Object System.Drawing.Point(14, 42)
    $filterBar.Size = New-Object System.Drawing.Size(1212, 34)
    $lblSearch.Location = New-Object System.Drawing.Point(12, 7)
    $txtSearch.Location = New-Object System.Drawing.Point(52, 5)
    $txtSearch.Size = New-Object System.Drawing.Size(272, 24)
    $lblCategory.Location = New-Object System.Drawing.Point(348, 7)
    $cmbCategory.Location = New-Object System.Drawing.Point(388, 5)
    $cmbCategory.Size = New-Object System.Drawing.Size(150, 24)
    $lblProblemGroup.Location = New-Object System.Drawing.Point(550, 7)
    $cmbProblemGroup.Location = New-Object System.Drawing.Point(590, 5)
    $cmbProblemGroup.Size = New-Object System.Drawing.Size(170, 24)
    $chkProblemOnly.Location = New-Object System.Drawing.Point(780, 7)
    $chkProblemOnly.MaximumSize = New-Object System.Drawing.Size(240, 24)
    $grid.Location = New-Object System.Drawing.Point(14, 82)
    $grid.Size = New-Object System.Drawing.Size(1212, 120)

    $detailPanel.Location = New-Object System.Drawing.Point(20, 562)
    $detailPanel.Size = New-Object System.Drawing.Size(1240, 146)
    $detailPanelLine.Location = New-Object System.Drawing.Point(14, 36)
    $detailPanelLine.Size = New-Object System.Drawing.Size(1212, 1)
    $detailLabel.Location = New-Object System.Drawing.Point(14, 10)
    $detailPanelTag.Location = New-Object System.Drawing.Point(130, 8)
    $btnDetailModelSupport.Location = New-Object System.Drawing.Point(922, 8)
    $btnDetailHardwareSearch.Location = New-Object System.Drawing.Point(1020, 8)
    $btnDetailCatalog.Location = New-Object System.Drawing.Point(1118, 8)
    $detailScrollPanel.Location = New-Object System.Drawing.Point(14, 42)
    $detailScrollPanel.Size = New-Object System.Drawing.Size(1212, 94)
    $detailSection1.Location = New-Object System.Drawing.Point(0, 0)
    $detailSection1.Size = New-Object System.Drawing.Size(294, 94)
    $detailSectionLabel1.Location = New-Object System.Drawing.Point(10, 6)
    $detailBasicBox.Location = New-Object System.Drawing.Point(10, 22)
    $detailBasicBox.Size = New-Object System.Drawing.Size(272, 64)
    $detailSection2.Location = New-Object System.Drawing.Point(308, 0)
    $detailSection2.Size = New-Object System.Drawing.Size(224, 94)
    $detailSectionLabel2.Location = New-Object System.Drawing.Point(10, 6)
    $detailHardwareBox.Location = New-Object System.Drawing.Point(10, 22)
    $detailHardwareBox.Size = New-Object System.Drawing.Size(202, 64)
    $detailSection3.Location = New-Object System.Drawing.Point(546, 0)
    $detailSection3.Size = New-Object System.Drawing.Size(666, 94)
    $detailSectionLabel3.Location = New-Object System.Drawing.Point(10, 6)
    $detailRecommendationBox.Location = New-Object System.Drawing.Point(10, 22)
    $detailRecommendationBox.Size = New-Object System.Drawing.Size(644, 64)
    $detailScrollPanel.AutoScrollMinSize = New-Object System.Drawing.Size(1212, 94)

    $contentPanel.AutoScrollMinSize = New-Object System.Drawing.Size(0, 712)
}

function Register-DriverGuiEvents {
    $form.Add_Shown({ Update-ResponsiveLayout })
    $form.Add_Resize({ Update-ResponsiveLayout })

    $grid.add_SelectionChanged({
        if ($grid.SelectedRows.Count -eq 0) {
            return
        }

        $device = $grid.SelectedRows[0].Tag
        if ($device) {
            $sections = Convert-DeviceToDetailSections -Device $device
            $detailBasicBox.Text = $sections.BasicInfo
            $detailHardwareBox.Text = $sections.HardwareInfo
            $detailRecommendationBox.Text = ($sections.Recommendation + [Environment]::NewLine + [Environment]::NewLine + "공식 링크 우선순위" + [Environment]::NewLine + (Get-OfficialPriorityTextForDevice -Device $device))
            Update-DetailActionButtons -Device $device
        }
    })

    $grid.add_CellDoubleClick({
        if ($grid.SelectedRows.Count -eq 0) {
            return
        }

        $device = $grid.SelectedRows[0].Tag
        if (-not $device) {
            return
        }

        Open-PreferredDeviceLink -Device $device
    })

    $btnUtility.Add_Click({
        $url = Get-SafeText $btnUtility.Tag
        if ($url) {
            Open-ExternalUrl -Url $url
        }
    })

    $btnModelSupport.Add_Click({
        $url = Get-SafeText $btnModelSupport.Tag
        if ($url) {
            Open-ExternalUrl -Url $url
        }
    })

    $btnManualDocs.Add_Click({
        $url = Get-SafeText $btnManualDocs.Tag
        if ($url) {
            Open-ExternalUrl -Url $url
        }
    })

    $btnDetailModelSupport.Add_Click({
        $url = Get-SafeText $btnDetailModelSupport.Tag
        if ($url) {
            Open-ExternalUrl -Url $url
        }
    })

    $btnDetailHardwareSearch.Add_Click({
        $url = Get-SafeText $btnDetailHardwareSearch.Tag
        if ($url) {
            Open-ExternalUrl -Url $url
        }
    })

    $btnDetailCatalog.Add_Click({
        $url = Get-SafeText $btnDetailCatalog.Tag
        if ($url) {
            Open-ExternalUrl -Url $url
        }
    })

    $txtSearch.Add_TextChanged({ Apply-Filters })
    $cmbCategory.Add_SelectedIndexChanged({ Apply-Filters })
    $cmbProblemGroup.Add_SelectedIndexChanged({ Apply-Filters })
    $chkProblemOnly.Add_CheckedChanged({ Apply-Filters })

    $script:ScanPollTimer.Add_Tick({
        if (-not $script:ScanProcess) {
            $script:ScanPollTimer.Stop()
            return
        }

        if (-not $script:ScanProcess.HasExited) {
            $elapsedText = ""
            if ($script:ScanStartTime) {
                $elapsed = (New-TimeSpan -Start $script:ScanStartTime -End (Get-Date)).TotalSeconds
                $elapsedText = " ({0:N0}초)" -f [math]::Max([int][math]::Floor($elapsed), 0)
            }
            $statusLabel.Text = "점검을 실행하는 중입니다$elapsedText"
            return
        }

        Complete-DriverScan
    })

    $btnScan.Add_Click({
        if ($script:ScanProcess -and -not $script:ScanProcess.HasExited) {
            return
        }

        Clear-JsonReports
        Set-UiBusyState -IsBusy $true
        $statusBadge.Text = "SCANNING"
        $statusBadge.BackColor = [System.Drawing.Color]::FromArgb(34, 101, 173)
        $heroModeLabel.Text = "실행 모드: 점검 진행 중"
        $heroMetaLabel.Text = "마지막 점검: 실행 중"
        $kpiValue1.Text = "-"
        $kpiValue2.Text = "점검 중"
        $kpiValue3.Text = "장치 상태 수집 중"
        $statusLabel.Text = "점검을 실행하는 중입니다..."
        $inspectionVerdict.Text = "점검 중"
        $inspectionVerdict.ForeColor = [System.Drawing.Color]::FromArgb(160, 120, 30)
        $inspectionHint.Text = "장치 상태를 확인하고 있습니다."
        $summaryValue1.Text = "-"
        $summaryValue2.Text = "-"
        $summaryCardValue1.Text = "-"
        $summaryCardValue2.Text = "-"
        $summaryCardValue3.Text = "-"
        $summaryBox.Text = ""
        $utilityHint.Text = "지원 도구, 드라이버 센터, 설명서가 준비되면 여기서 바로 열 수 있습니다."
        $detailBasicBox.Text = ""
        $detailHardwareBox.Text = ""
        $detailRecommendationBox.Text = ""
        Update-DetailActionButtons -Device $null
        $grid.Rows.Clear()
        $cmbProblemGroup.Items.Clear()
        $null = $cmbProblemGroup.Items.Add("전체")
        $cmbProblemGroup.SelectedIndex = 0
        $script:CurrentDevices = @()
        $script:FilteredDevices = @()
        $script:CurrentReport = $null
        $script:LatestReport = $null
        $btnManualDocs.Tag = $null
        $btnManualDocs.Text = "공식 설명서"

        try {
            $runPreflight = -not (Test-IsAdministrator)
            $script:ScanStartTime = Get-Date
            $script:ScanProcess = Start-DriverScanProcess -Preflight:$runPreflight
            if (-not $script:ScanProcess) {
                throw "점검 프로세스를 시작하지 못했습니다."
            }

            if ($runPreflight) {
                $statusLabel.Text = "사전 점검을 실행하는 중입니다..."
                $inspectionHint.Text = "관리자 권한이 없어 사전 점검 결과를 생성합니다."
                $statusBadge.Text = "PREFLIGHT"
                $statusBadge.BackColor = [System.Drawing.Color]::FromArgb(180, 120, 20)
                $heroModeLabel.Text = "실행 모드: 사전 점검 준비"
                $kpiValue2.Text = "사전 점검"
                $kpiValue3.Text = "권한 및 환경 확인"
            }

            $script:ScanPollTimer.Start()
        }
        catch {
            $script:ScanProcess = $null
            $script:ScanPollTimer.Stop()
            Set-UiBusyState -IsBusy $false
            $statusBadge.Text = "FAILED"
            $statusBadge.BackColor = [System.Drawing.Color]::FromArgb(178, 34, 34)
            $heroModeLabel.Text = "실행 모드: 오류"
            $kpiValue2.Text = "오류"
            $kpiValue3.Text = "실행을 다시 시도"
            $statusLabel.Text = "점검 실패"
            [System.Windows.Forms.MessageBox]::Show((Get-SafeText $_.Exception.Message "점검을 시작하지 못했습니다."), "오류")
        }
    })
}




