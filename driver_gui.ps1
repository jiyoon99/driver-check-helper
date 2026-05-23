[CmdletBinding()]
param()

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$script:ExpectedSchemaVersion = 4

$script:BaseDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:ReportDirectory = Join-Path $script:BaseDirectory "reports"
$script:LogsDirectory = Join-Path $script:BaseDirectory "logs"
$script:MainScriptPath = Join-Path $script:BaseDirectory "main.ps1"
$script:LatestReport = $null
$script:CurrentReport = $null
$script:CurrentProblemGroups = @()

. (Join-Path $script:BaseDirectory "scripts\gui.functions.ps1")

$form = New-Object System.Windows.Forms.Form
$form.Text = "드라이버 점검 도우미"
$form.StartPosition = "CenterScreen"
$form.ClientSize = New-Object System.Drawing.Size(1280, 720)
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$form.MaximizeBox = $false
$form.MinimumSize = New-Object System.Drawing.Size(1296, 759)
$form.MaximumSize = New-Object System.Drawing.Size(1296, 759)
$form.BackColor = [System.Drawing.Color]::FromArgb(239, 244, 250)

$colorInk = [System.Drawing.Color]::FromArgb(24, 36, 56)
$colorMuted = [System.Drawing.Color]::FromArgb(103, 116, 140)
$colorHero = [System.Drawing.Color]::FromArgb(21, 48, 82)
$colorHeroAccent = [System.Drawing.Color]::FromArgb(61, 126, 188)
$colorSurface = [System.Drawing.Color]::White
$colorSurfaceSoft = [System.Drawing.Color]::FromArgb(244, 247, 251)
$colorBorder = [System.Drawing.Color]::FromArgb(204, 214, 226)
$colorHeaderBg = [System.Drawing.Color]::FromArgb(236, 242, 248)
$colorHeaderText = [System.Drawing.Color]::FromArgb(54, 73, 98)
$colorSelectionBg = [System.Drawing.Color]::FromArgb(223, 235, 248)
$colorSelectionText = $colorInk
$colorHeroBadge = [System.Drawing.Color]::FromArgb(36, 78, 126)
$colorHeroMuted = [System.Drawing.Color]::FromArgb(188, 202, 220)
$colorTagBg = [System.Drawing.Color]::FromArgb(233, 240, 247)
$colorTagText = [System.Drawing.Color]::FromArgb(66, 91, 122)

$contentPanel = New-Object System.Windows.Forms.Panel
$contentPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$contentPanel.AutoScroll = $false
$contentPanel.BackColor = $form.BackColor
$form.Controls.Add($contentPanel)

$heroPanel = New-Object System.Windows.Forms.Panel
$heroPanel.Location = New-Object System.Drawing.Point(20, 18)
$heroPanel.Size = New-Object System.Drawing.Size(1120, 154)
$heroPanel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$heroPanel.BackColor = $colorHero
$heroPanel.BorderStyle = "FixedSingle"
$contentPanel.Controls.Add($heroPanel)

$heroAccent = New-Object System.Windows.Forms.Panel
$heroAccent.Location = New-Object System.Drawing.Point(0, 0)
$heroAccent.Size = New-Object System.Drawing.Size(1120, 6)
$heroAccent.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$heroAccent.BackColor = $colorHeroAccent
$heroPanel.Controls.Add($heroAccent)

$header = New-Object System.Windows.Forms.Label
$header.Text = "드라이버 점검 도우미"
$header.Font = New-Object System.Drawing.Font("Malgun Gothic", 15, [System.Drawing.FontStyle]::Bold)
$header.ForeColor = [System.Drawing.Color]::White
$header.Location = New-Object System.Drawing.Point(20, 16)
$header.AutoSize = $true
$heroPanel.Controls.Add($header)

$subHeader = New-Object System.Windows.Forms.Label
$subHeader.Text = ""
$subHeader.Font = New-Object System.Drawing.Font("Malgun Gothic", 8)
$subHeader.ForeColor = [System.Drawing.Color]::FromArgb(224, 233, 244)
$subHeader.Location = New-Object System.Drawing.Point(22, 50)
$subHeader.AutoSize = $true
$subHeader.Visible = $false
$heroPanel.Controls.Add($subHeader)

$actionBar = New-Object System.Windows.Forms.Panel
$actionBar.Location = New-Object System.Drawing.Point(20, 76)
$actionBar.Size = New-Object System.Drawing.Size(742, 50)
$actionBar.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
$actionBar.BackColor = [System.Drawing.Color]::FromArgb(17, 40, 68)
$actionBar.BorderStyle = "FixedSingle"
$heroPanel.Controls.Add($actionBar)

$actionBarTag = New-Object System.Windows.Forms.Label
$actionBarTag.Text = "OPERATIONS"
$actionBarTag.Font = New-Object System.Drawing.Font("Malgun Gothic", 7.5, [System.Drawing.FontStyle]::Bold)
$actionBarTag.ForeColor = $colorHeroMuted
$actionBarTag.Location = New-Object System.Drawing.Point(12, 6)
$actionBarTag.AutoSize = $true
$actionBar.Controls.Add($actionBarTag)

$btnScan = New-Object System.Windows.Forms.Button
$btnScan.Text = "점검 시작"
$btnScan.Font = New-Object System.Drawing.Font("Malgun Gothic", 8.5, [System.Drawing.FontStyle]::Bold)
$btnScan.Size = New-Object System.Drawing.Size(150, 32)
$btnScan.Location = New-Object System.Drawing.Point(10, 16)
$btnScan.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnScan.FlatAppearance.BorderSize = 0
$btnScan.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(85, 173, 132)
$btnScan.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::FromArgb(60, 142, 105)
$btnScan.BackColor = [System.Drawing.Color]::FromArgb(73, 160, 120)
$btnScan.ForeColor = [System.Drawing.Color]::White
$btnScan.Cursor = [System.Windows.Forms.Cursors]::Hand
$actionBar.Controls.Add($btnScan)

$btnUtility = New-Object System.Windows.Forms.Button
$btnUtility.Text = "공식 지원 도구"
$btnUtility.Font = New-Object System.Drawing.Font("Malgun Gothic", 8, [System.Drawing.FontStyle]::Bold)
$btnUtility.Size = New-Object System.Drawing.Size(180, 32)
$btnUtility.Location = New-Object System.Drawing.Point(162, 16)
$btnUtility.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnUtility.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(160, 184, 214)
$btnUtility.FlatAppearance.BorderSize = 1
$btnUtility.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(242, 246, 251)
$btnUtility.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::FromArgb(228, 236, 246)
$btnUtility.BackColor = [System.Drawing.Color]::White
$btnUtility.ForeColor = $colorHeaderText
$btnUtility.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnUtility.Enabled = $false
$actionBar.Controls.Add($btnUtility)

$btnModelSupport = New-Object System.Windows.Forms.Button
$btnModelSupport.Text = "모델 드라이버 센터"
$btnModelSupport.Font = New-Object System.Drawing.Font("Malgun Gothic", 8, [System.Drawing.FontStyle]::Bold)
$btnModelSupport.Size = New-Object System.Drawing.Size(170, 32)
$btnModelSupport.Location = New-Object System.Drawing.Point(344, 16)
$btnModelSupport.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnModelSupport.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(160, 184, 214)
$btnModelSupport.FlatAppearance.BorderSize = 1
$btnModelSupport.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(242, 246, 251)
$btnModelSupport.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::FromArgb(228, 236, 246)
$btnModelSupport.BackColor = [System.Drawing.Color]::White
$btnModelSupport.ForeColor = $colorHeaderText
$btnModelSupport.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnModelSupport.Enabled = $false
$actionBar.Controls.Add($btnModelSupport)

$btnManualDocs = New-Object System.Windows.Forms.Button
$btnManualDocs.Text = "공식 설명서"
$btnManualDocs.Font = New-Object System.Drawing.Font("Malgun Gothic", 8, [System.Drawing.FontStyle]::Bold)
$btnManualDocs.Size = New-Object System.Drawing.Size(170, 32)
$btnManualDocs.Location = New-Object System.Drawing.Point(516, 16)
$btnManualDocs.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnManualDocs.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(160, 184, 214)
$btnManualDocs.FlatAppearance.BorderSize = 1
$btnManualDocs.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(242, 246, 251)
$btnManualDocs.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::FromArgb(228, 236, 246)
$btnManualDocs.BackColor = [System.Drawing.Color]::White
$btnManualDocs.ForeColor = $colorHeaderText
$btnManualDocs.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnManualDocs.Enabled = $false
$actionBar.Controls.Add($btnManualDocs)

$statusBadge = New-Object System.Windows.Forms.Label
$statusBadge.Text = ""
$statusBadge.Font = New-Object System.Drawing.Font("Malgun Gothic", 7, [System.Drawing.FontStyle]::Bold)
$statusBadge.ForeColor = [System.Drawing.Color]::White
$statusBadge.BackColor = $colorHeroBadge
$statusBadge.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$statusBadge.Location = New-Object System.Drawing.Point(670, 18)
$statusBadge.Size = New-Object System.Drawing.Size(82, 24)
$statusBadge.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$statusBadge.Visible = $false
$heroPanel.Controls.Add($statusBadge)

$heroMetaLabel = New-Object System.Windows.Forms.Label
$heroMetaLabel.Text = "마지막 점검: 없음"
$heroMetaLabel.Font = New-Object System.Drawing.Font("Malgun Gothic", 7.5)
$heroMetaLabel.ForeColor = [System.Drawing.Color]::White
$heroMetaLabel.Location = New-Object System.Drawing.Point(766, 20)
$heroMetaLabel.Size = New-Object System.Drawing.Size(334, 17)
$heroMetaLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
$heroMetaLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$heroPanel.Controls.Add($heroMetaLabel)

$heroModeLabel = New-Object System.Windows.Forms.Label
$heroModeLabel.Text = "실행 모드: 대기"
$heroModeLabel.Font = New-Object System.Drawing.Font("Malgun Gothic", 7)
$heroModeLabel.ForeColor = $colorHeroMuted
$heroModeLabel.Location = New-Object System.Drawing.Point(670, 46)
$heroModeLabel.Size = New-Object System.Drawing.Size(210, 16)
$heroModeLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
$heroPanel.Controls.Add($heroModeLabel)

$heroSchemaLabel = New-Object System.Windows.Forms.Label
$heroSchemaLabel.Text = "리포트 스키마: v$($script:ExpectedSchemaVersion)"
$heroSchemaLabel.Font = New-Object System.Drawing.Font("Malgun Gothic", 7)
$heroSchemaLabel.ForeColor = $colorHeroMuted
$heroSchemaLabel.Location = New-Object System.Drawing.Point(890, 46)
$heroSchemaLabel.Size = New-Object System.Drawing.Size(210, 16)
$heroSchemaLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
$heroSchemaLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$heroPanel.Controls.Add($heroSchemaLabel)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "준비됨"
$statusLabel.Font = New-Object System.Drawing.Font("Malgun Gothic", 8, [System.Drawing.FontStyle]::Bold)
$statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(232, 240, 248)
$statusLabel.Location = New-Object System.Drawing.Point(670, 84)
$statusLabel.Size = New-Object System.Drawing.Size(430, 18)
$statusLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$heroPanel.Controls.Add($statusLabel)

$utilityHint = New-Object System.Windows.Forms.Label
$utilityHint.Text = "지원 도구, 드라이버 센터, 설명서가 준비되면 여기서 바로 열 수 있습니다."
$utilityHint.Font = New-Object System.Drawing.Font("Malgun Gothic", 7)
$utilityHint.ForeColor = [System.Drawing.Color]::FromArgb(214, 226, 240)
$utilityHint.Location = New-Object System.Drawing.Point(670, 104)
$utilityHint.Size = New-Object System.Drawing.Size(430, 24)
$utilityHint.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$heroPanel.Controls.Add($utilityHint)

$inspectionPanel = New-Object System.Windows.Forms.Panel
$inspectionPanel.Location = New-Object System.Drawing.Point(20, 188)
$inspectionPanel.Size = New-Object System.Drawing.Size(1120, 124)
$inspectionPanel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$inspectionPanel.BackColor = $colorSurface
$inspectionPanel.BorderStyle = "FixedSingle"
$contentPanel.Controls.Add($inspectionPanel)

$inspectionAccent = New-Object System.Windows.Forms.Panel
$inspectionAccent.Location = New-Object System.Drawing.Point(0, 0)
$inspectionAccent.Size = New-Object System.Drawing.Size(8, 124)
$inspectionAccent.BackColor = [System.Drawing.Color]::FromArgb(73, 160, 120)
$inspectionAccent.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left
$inspectionPanel.Controls.Add($inspectionAccent)

$inspectionTitle = New-Object System.Windows.Forms.Label
$inspectionTitle.Text = "점검 판정"
$inspectionTitle.Font = New-Object System.Drawing.Font("Malgun Gothic", 9.5, [System.Drawing.FontStyle]::Bold)
$inspectionTitle.ForeColor = $colorInk
$inspectionTitle.Location = New-Object System.Drawing.Point(20, 12)
$inspectionTitle.AutoSize = $true
$inspectionPanel.Controls.Add($inspectionTitle)

$inspectionVerdict = New-Object System.Windows.Forms.Label
$inspectionVerdict.Text = "발견된 문제 없음"
$inspectionVerdict.Font = New-Object System.Drawing.Font("Malgun Gothic", 14, [System.Drawing.FontStyle]::Bold)
$inspectionVerdict.Location = New-Object System.Drawing.Point(20, 34)
$inspectionVerdict.Size = New-Object System.Drawing.Size(340, 34)
$inspectionVerdict.AutoSize = $false
$inspectionVerdict.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$inspectionVerdict.ForeColor = [System.Drawing.Color]::FromArgb(90, 90, 90)
$inspectionPanel.Controls.Add($inspectionVerdict)

$inspectionHint = New-Object System.Windows.Forms.Label
$inspectionHint.Text = "점검 시작을 누르면 상태를 판정합니다."
$inspectionHint.Font = New-Object System.Drawing.Font("Malgun Gothic", 7.5)
$inspectionHint.ForeColor = $colorMuted
$inspectionHint.Location = New-Object System.Drawing.Point(220, 46)
$inspectionHint.Size = New-Object System.Drawing.Size(470, 18)
$inspectionHint.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$inspectionPanel.Controls.Add($inspectionHint)

$kpiCard1 = New-Object System.Windows.Forms.Panel
$kpiCard1.Location = New-Object System.Drawing.Point(20, 76)
$kpiCard1.Size = New-Object System.Drawing.Size(150, 34)
$kpiCard1.BackColor = $colorSurfaceSoft
$kpiCard1.BorderStyle = "FixedSingle"
$inspectionPanel.Controls.Add($kpiCard1)

$kpiLabel1 = New-Object System.Windows.Forms.Label
$kpiLabel1.Text = "문제 장치"
$kpiLabel1.Font = New-Object System.Drawing.Font("Malgun Gothic", 7, [System.Drawing.FontStyle]::Bold)
$kpiLabel1.ForeColor = $colorHeaderText
$kpiLabel1.Location = New-Object System.Drawing.Point(10, 5)
$kpiLabel1.AutoSize = $true
$kpiCard1.Controls.Add($kpiLabel1)

$kpiValue1 = New-Object System.Windows.Forms.Label
$kpiValue1.Text = "-"
$kpiValue1.Font = New-Object System.Drawing.Font("Malgun Gothic", 8, [System.Drawing.FontStyle]::Bold)
$kpiValue1.ForeColor = $colorInk
$kpiValue1.Location = New-Object System.Drawing.Point(10, 15)
$kpiValue1.Size = New-Object System.Drawing.Size(128, 16)
$kpiCard1.Controls.Add($kpiValue1)

$kpiCard2 = New-Object System.Windows.Forms.Panel
$kpiCard2.Location = New-Object System.Drawing.Point(180, 76)
$kpiCard2.Size = New-Object System.Drawing.Size(150, 34)
$kpiCard2.BackColor = $colorSurfaceSoft
$kpiCard2.BorderStyle = "FixedSingle"
$inspectionPanel.Controls.Add($kpiCard2)

$kpiLabel2 = New-Object System.Windows.Forms.Label
$kpiLabel2.Text = "점검 모드"
$kpiLabel2.Font = New-Object System.Drawing.Font("Malgun Gothic", 7, [System.Drawing.FontStyle]::Bold)
$kpiLabel2.ForeColor = $colorHeaderText
$kpiLabel2.Location = New-Object System.Drawing.Point(10, 5)
$kpiLabel2.AutoSize = $true
$kpiCard2.Controls.Add($kpiLabel2)

$kpiValue2 = New-Object System.Windows.Forms.Label
$kpiValue2.Text = "대기"
$kpiValue2.Font = New-Object System.Drawing.Font("Malgun Gothic", 8, [System.Drawing.FontStyle]::Bold)
$kpiValue2.ForeColor = $colorInk
$kpiValue2.Location = New-Object System.Drawing.Point(10, 15)
$kpiValue2.Size = New-Object System.Drawing.Size(128, 16)
$kpiCard2.Controls.Add($kpiValue2)

$kpiCard3 = New-Object System.Windows.Forms.Panel
$kpiCard3.Location = New-Object System.Drawing.Point(340, 76)
$kpiCard3.Size = New-Object System.Drawing.Size(350, 34)
$kpiCard3.BackColor = $colorSurfaceSoft
$kpiCard3.BorderStyle = "FixedSingle"
$inspectionPanel.Controls.Add($kpiCard3)

$kpiLabel3 = New-Object System.Windows.Forms.Label
$kpiLabel3.Text = "우선 대응"
$kpiLabel3.Font = New-Object System.Drawing.Font("Malgun Gothic", 7, [System.Drawing.FontStyle]::Bold)
$kpiLabel3.ForeColor = $colorHeaderText
$kpiLabel3.Location = New-Object System.Drawing.Point(10, 5)
$kpiLabel3.AutoSize = $true
$kpiCard3.Controls.Add($kpiLabel3)

$kpiValue3 = New-Object System.Windows.Forms.Label
$kpiValue3.Text = "-"
$kpiValue3.Font = New-Object System.Drawing.Font("Malgun Gothic", 8, [System.Drawing.FontStyle]::Bold)
$kpiValue3.ForeColor = $colorInk
$kpiValue3.Location = New-Object System.Drawing.Point(10, 15)
$kpiValue3.Size = New-Object System.Drawing.Size(328, 16)
$kpiCard3.Controls.Add($kpiValue3)

$inspectionDivider = New-Object System.Windows.Forms.Panel
$inspectionDivider.Location = New-Object System.Drawing.Point(710, 14)
$inspectionDivider.Size = New-Object System.Drawing.Size(1, 96)
$inspectionDivider.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$inspectionDivider.BackColor = $colorBorder
$inspectionPanel.Controls.Add($inspectionDivider)

$summaryInfoPanel = New-Object System.Windows.Forms.Panel
$summaryInfoPanel.Location = New-Object System.Drawing.Point(730, 12)
$summaryInfoPanel.Size = New-Object System.Drawing.Size(370, 72)
$summaryInfoPanel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$summaryInfoPanel.BackColor = $colorSurfaceSoft
$summaryInfoPanel.BorderStyle = "FixedSingle"
$inspectionPanel.Controls.Add($summaryInfoPanel)

$summaryLabel1 = New-Object System.Windows.Forms.Label
$summaryLabel1.Text = "제조사 / 모델"
$summaryLabel1.Font = New-Object System.Drawing.Font("Malgun Gothic", 8, [System.Drawing.FontStyle]::Bold)
$summaryLabel1.ForeColor = $colorHeaderText
$summaryLabel1.Location = New-Object System.Drawing.Point(12, 8)
$summaryLabel1.Size = New-Object System.Drawing.Size(140, 18)
$summaryInfoPanel.Controls.Add($summaryLabel1)

$summaryValue1 = New-Object System.Windows.Forms.Label
$summaryValue1.Text = "-"
$summaryValue1.Font = New-Object System.Drawing.Font("Malgun Gothic", 8)
$summaryValue1.ForeColor = $colorInk
$summaryValue1.Location = New-Object System.Drawing.Point(12, 28)
$summaryValue1.Size = New-Object System.Drawing.Size(344, 18)
$summaryValue1.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$summaryInfoPanel.Controls.Add($summaryValue1)

$summaryLabel2 = New-Object System.Windows.Forms.Label
$summaryLabel2.Text = "전체 장치 / 문제 장치"
$summaryLabel2.Font = New-Object System.Drawing.Font("Malgun Gothic", 8, [System.Drawing.FontStyle]::Bold)
$summaryLabel2.ForeColor = $colorHeaderText
$summaryLabel2.Location = New-Object System.Drawing.Point(12, 44)
$summaryLabel2.Size = New-Object System.Drawing.Size(150, 18)
$summaryLabel2.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$summaryInfoPanel.Controls.Add($summaryLabel2)

$summaryValue2 = New-Object System.Windows.Forms.Label
$summaryValue2.Text = "-"
$summaryValue2.Font = New-Object System.Drawing.Font("Malgun Gothic", 8)
$summaryValue2.ForeColor = $colorInk
$summaryValue2.Location = New-Object System.Drawing.Point(180, 44)
$summaryValue2.Size = New-Object System.Drawing.Size(176, 18)
$summaryValue2.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$summaryInfoPanel.Controls.Add($summaryValue2)

$summaryBox = New-Object System.Windows.Forms.TextBox
$summaryBox.Location = New-Object System.Drawing.Point(20, 274)
$summaryBox.Size = New-Object System.Drawing.Size(1120, 62)
$summaryBox.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$summaryBox.Multiline = $true
$summaryBox.ReadOnly = $true
$summaryBox.ScrollBars = "Vertical"
$summaryBox.Font = New-Object System.Drawing.Font("Malgun Gothic", 8.5)
$summaryBox.BorderStyle = "FixedSingle"
$summaryBox.ForeColor = $colorInk
$summaryBox.BackColor = $colorSurfaceSoft

$summaryPanel = New-Object System.Windows.Forms.Panel
$summaryPanel.Location = New-Object System.Drawing.Point(20, 320)
$summaryPanel.Size = New-Object System.Drawing.Size(1120, 122)
$summaryPanel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$summaryPanel.BackColor = $colorSurface
$summaryPanel.BorderStyle = "FixedSingle"
$contentPanel.Controls.Add($summaryPanel)

$summaryPanelLabel = New-Object System.Windows.Forms.Label
$summaryPanelLabel.Text = "운영 요약"
$summaryPanelLabel.Font = New-Object System.Drawing.Font("Malgun Gothic", 8, [System.Drawing.FontStyle]::Bold)
$summaryPanelLabel.ForeColor = $colorHeaderText
$summaryPanelLabel.Location = New-Object System.Drawing.Point(14, 10)
$summaryPanelLabel.AutoSize = $true
$summaryPanel.Controls.Add($summaryPanelLabel)

$summaryPanelTag = New-Object System.Windows.Forms.Label
$summaryPanelTag.Text = "SUMMARY"
$summaryPanelTag.Font = New-Object System.Drawing.Font("Malgun Gothic", 7, [System.Drawing.FontStyle]::Bold)
$summaryPanelTag.ForeColor = $colorTagText
$summaryPanelTag.BackColor = $colorTagBg
$summaryPanelTag.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$summaryPanelTag.Location = New-Object System.Drawing.Point(94, 8)
$summaryPanelTag.Size = New-Object System.Drawing.Size(76, 20)
$summaryPanel.Controls.Add($summaryPanelTag)

$summaryPanelLine = New-Object System.Windows.Forms.Panel
$summaryPanelLine.Location = New-Object System.Drawing.Point(12, 34)
$summaryPanelLine.Size = New-Object System.Drawing.Size(1094, 1)
$summaryPanelLine.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$summaryPanelLine.BackColor = $colorBorder
$summaryPanel.Controls.Add($summaryPanelLine)

$summaryCard1 = New-Object System.Windows.Forms.Panel
$summaryCard1.Location = New-Object System.Drawing.Point(12, 44)
$summaryCard1.Size = New-Object System.Drawing.Size(210, 46)
$summaryCard1.BackColor = $colorSurfaceSoft
$summaryCard1.BorderStyle = "FixedSingle"
$summaryPanel.Controls.Add($summaryCard1)

$summaryCardLabel1 = New-Object System.Windows.Forms.Label
$summaryCardLabel1.Text = "기준 OS"
$summaryCardLabel1.Font = New-Object System.Drawing.Font("Malgun Gothic", 7, [System.Drawing.FontStyle]::Bold)
$summaryCardLabel1.ForeColor = $colorHeaderText
$summaryCardLabel1.Location = New-Object System.Drawing.Point(10, 6)
$summaryCardLabel1.AutoSize = $true
$summaryCard1.Controls.Add($summaryCardLabel1)

$summaryCardValue1 = New-Object System.Windows.Forms.Label
$summaryCardValue1.Text = "-"
$summaryCardValue1.Font = New-Object System.Drawing.Font("Malgun Gothic", 8.5, [System.Drawing.FontStyle]::Bold)
$summaryCardValue1.ForeColor = $colorInk
$summaryCardValue1.Location = New-Object System.Drawing.Point(10, 21)
$summaryCardValue1.Size = New-Object System.Drawing.Size(188, 18)
$summaryCard1.Controls.Add($summaryCardValue1)

$summaryCard2 = New-Object System.Windows.Forms.Panel
$summaryCard2.Location = New-Object System.Drawing.Point(232, 44)
$summaryCard2.Size = New-Object System.Drawing.Size(280, 46)
$summaryCard2.BackColor = $colorSurfaceSoft
$summaryCard2.BorderStyle = "FixedSingle"
$summaryPanel.Controls.Add($summaryCard2)

$summaryCardLabel2 = New-Object System.Windows.Forms.Label
$summaryCardLabel2.Text = "모델 지원"
$summaryCardLabel2.Font = New-Object System.Drawing.Font("Malgun Gothic", 7, [System.Drawing.FontStyle]::Bold)
$summaryCardLabel2.ForeColor = $colorHeaderText
$summaryCardLabel2.Location = New-Object System.Drawing.Point(10, 6)
$summaryCardLabel2.AutoSize = $true
$summaryCard2.Controls.Add($summaryCardLabel2)

$summaryCardValue2 = New-Object System.Windows.Forms.Label
$summaryCardValue2.Text = "-"
$summaryCardValue2.Font = New-Object System.Drawing.Font("Malgun Gothic", 8.5, [System.Drawing.FontStyle]::Bold)
$summaryCardValue2.ForeColor = $colorInk
$summaryCardValue2.Location = New-Object System.Drawing.Point(10, 21)
$summaryCardValue2.Size = New-Object System.Drawing.Size(258, 18)
$summaryCard2.Controls.Add($summaryCardValue2)

$summaryCard3 = New-Object System.Windows.Forms.Panel
$summaryCard3.Location = New-Object System.Drawing.Point(522, 44)
$summaryCard3.Size = New-Object System.Drawing.Size(584, 46)
$summaryCard3.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$summaryCard3.BackColor = $colorSurfaceSoft
$summaryCard3.BorderStyle = "FixedSingle"
$summaryPanel.Controls.Add($summaryCard3)

$summaryCardLabel3 = New-Object System.Windows.Forms.Label
$summaryCardLabel3.Text = "즉시 확인"
$summaryCardLabel3.Font = New-Object System.Drawing.Font("Malgun Gothic", 7, [System.Drawing.FontStyle]::Bold)
$summaryCardLabel3.ForeColor = $colorHeaderText
$summaryCardLabel3.Location = New-Object System.Drawing.Point(10, 6)
$summaryCardLabel3.AutoSize = $true
$summaryCard3.Controls.Add($summaryCardLabel3)

$summaryCardValue3 = New-Object System.Windows.Forms.Label
$summaryCardValue3.Text = "-"
$summaryCardValue3.Font = New-Object System.Drawing.Font("Malgun Gothic", 8.5, [System.Drawing.FontStyle]::Bold)
$summaryCardValue3.ForeColor = $colorInk
$summaryCardValue3.Location = New-Object System.Drawing.Point(10, 21)
$summaryCardValue3.Size = New-Object System.Drawing.Size(562, 18)
$summaryCardValue3.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$summaryCard3.Controls.Add($summaryCardValue3)

$summaryBox.Location = New-Object System.Drawing.Point(12, 96)
$summaryBox.Size = New-Object System.Drawing.Size(1094, 20)
$summaryBox.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$summaryBox.BorderStyle = "None"
$summaryPanel.Controls.Add($summaryBox)

$listPanel = New-Object System.Windows.Forms.Panel
$listPanel.Location = New-Object System.Drawing.Point(20, 454)
$listPanel.Size = New-Object System.Drawing.Size(1120, 270)
$listPanel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$listPanel.BackColor = $colorSurface
$listPanel.BorderStyle = "FixedSingle"
$contentPanel.Controls.Add($listPanel)

$listLabel = New-Object System.Windows.Forms.Label
$listLabel.Text = "장치 목록"
$listLabel.Font = New-Object System.Drawing.Font("Malgun Gothic", 10, [System.Drawing.FontStyle]::Bold)
$listLabel.ForeColor = $colorInk
$listLabel.Location = New-Object System.Drawing.Point(14, 12)
$listLabel.AutoSize = $true
$listPanel.Controls.Add($listLabel)

$listPanelTag = New-Object System.Windows.Forms.Label
$listPanelTag.Text = "DEVICE"
$listPanelTag.Font = New-Object System.Drawing.Font("Malgun Gothic", 7.5, [System.Drawing.FontStyle]::Bold)
$listPanelTag.ForeColor = $colorTagText
$listPanelTag.BackColor = $colorTagBg
$listPanelTag.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$listPanelTag.Location = New-Object System.Drawing.Point(98, 10)
$listPanelTag.Size = New-Object System.Drawing.Size(64, 20)
$listPanel.Controls.Add($listPanelTag)

$listPanelLine = New-Object System.Windows.Forms.Panel
$listPanelLine.Location = New-Object System.Drawing.Point(14, 36)
$listPanelLine.Size = New-Object System.Drawing.Size(1092, 1)
$listPanelLine.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$listPanelLine.BackColor = $colorBorder
$listPanel.Controls.Add($listPanelLine)

$filterBar = New-Object System.Windows.Forms.Panel
$filterBar.Location = New-Object System.Drawing.Point(14, 46)
$filterBar.Size = New-Object System.Drawing.Size(1092, 38)
$filterBar.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$filterBar.BackColor = $colorSurfaceSoft
$filterBar.BorderStyle = "FixedSingle"
$listPanel.Controls.Add($filterBar)

$lblSearch = New-Object System.Windows.Forms.Label
$lblSearch.Text = "검색"
$lblSearch.Font = New-Object System.Drawing.Font("Malgun Gothic", 8)
$lblSearch.ForeColor = $colorHeaderText
$lblSearch.Location = New-Object System.Drawing.Point(12, 9)
$lblSearch.Size = New-Object System.Drawing.Size(40, 24)
$filterBar.Controls.Add($lblSearch)

$txtSearch = New-Object System.Windows.Forms.TextBox
$txtSearch.Font = New-Object System.Drawing.Font("Malgun Gothic", 8.5)
$txtSearch.Location = New-Object System.Drawing.Point(52, 7)
$txtSearch.Size = New-Object System.Drawing.Size(250, 24)
$txtSearch.BorderStyle = "FixedSingle"
$txtSearch.BackColor = $colorSurface
$filterBar.Controls.Add($txtSearch)

$lblCategory = New-Object System.Windows.Forms.Label
$lblCategory.Text = "분류"
$lblCategory.Font = New-Object System.Drawing.Font("Malgun Gothic", 8)
$lblCategory.ForeColor = $colorHeaderText
$lblCategory.Location = New-Object System.Drawing.Point(326, 9)
$lblCategory.Size = New-Object System.Drawing.Size(40, 24)
$filterBar.Controls.Add($lblCategory)

$cmbCategory = New-Object System.Windows.Forms.ComboBox
$cmbCategory.Font = New-Object System.Drawing.Font("Malgun Gothic", 8.5)
$cmbCategory.DropDownStyle = "DropDownList"
$cmbCategory.Location = New-Object System.Drawing.Point(366, 7)
$cmbCategory.Size = New-Object System.Drawing.Size(180, 24)
$cmbCategory.BackColor = $colorSurface
$cmbCategory.Items.AddRange(@("전체","네트워크","블루투스","그래픽","오디오","칩셋/시스템","카메라","지문인식","입력장치","USB/썬더볼트","스토리지","카드리더","기타"))
$cmbCategory.SelectedIndex = 0
$filterBar.Controls.Add($cmbCategory)

$lblProblemGroup = New-Object System.Windows.Forms.Label
$lblProblemGroup.Text = "묶음"
$lblProblemGroup.Font = New-Object System.Drawing.Font("Malgun Gothic", 8)
$lblProblemGroup.ForeColor = $colorHeaderText
$lblProblemGroup.Location = New-Object System.Drawing.Point(560, 9)
$lblProblemGroup.Size = New-Object System.Drawing.Size(40, 24)
$filterBar.Controls.Add($lblProblemGroup)

$cmbProblemGroup = New-Object System.Windows.Forms.ComboBox
$cmbProblemGroup.Font = New-Object System.Drawing.Font("Malgun Gothic", 8.5)
$cmbProblemGroup.DropDownStyle = "DropDownList"
$cmbProblemGroup.Location = New-Object System.Drawing.Point(600, 7)
$cmbProblemGroup.Size = New-Object System.Drawing.Size(170, 24)
$cmbProblemGroup.BackColor = $colorSurface
$null = $cmbProblemGroup.Items.Add("전체")
$cmbProblemGroup.SelectedIndex = 0
$filterBar.Controls.Add($cmbProblemGroup)

$chkProblemOnly = New-Object System.Windows.Forms.CheckBox
$chkProblemOnly.Text = "문제 장치만 표시"
$chkProblemOnly.Font = New-Object System.Drawing.Font("Malgun Gothic", 8)
$chkProblemOnly.Checked = $false
$chkProblemOnly.ForeColor = $colorInk
$chkProblemOnly.Location = New-Object System.Drawing.Point(792, 9)
$chkProblemOnly.AutoSize = $true
$filterBar.Controls.Add($chkProblemOnly)

$grid = New-Object System.Windows.Forms.DataGridView
$grid.Location = New-Object System.Drawing.Point(14, 94)
$grid.Size = New-Object System.Drawing.Size(1092, 160)
$grid.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$grid.ReadOnly = $true
$grid.AllowUserToAddRows = $false
$grid.AllowUserToDeleteRows = $false
$grid.AllowUserToResizeRows = $false
$grid.AllowUserToResizeColumns = $false
$grid.MultiSelect = $false
$grid.SelectionMode = "FullRowSelect"
$grid.AutoSizeColumnsMode = "None"
$grid.RowHeadersVisible = $false
$grid.BorderStyle = "FixedSingle"
$grid.CellBorderStyle = "SingleHorizontal"
$grid.EnableHeadersVisualStyles = $false
$grid.ScrollBars = "Vertical"
$grid.BackgroundColor = $colorSurface
$grid.Font = New-Object System.Drawing.Font("Malgun Gothic", 8.5)
$grid.RowTemplate.Height = 24
$grid.ColumnHeadersDefaultCellStyle.Font = New-Object System.Drawing.Font("Malgun Gothic", 8.5, [System.Drawing.FontStyle]::Bold)
$grid.ColumnHeadersDefaultCellStyle.BackColor = $colorHeaderBg
$grid.ColumnHeadersDefaultCellStyle.ForeColor = $colorHeaderText
$grid.ColumnHeadersDefaultCellStyle.SelectionBackColor = $colorHeaderBg
$grid.ColumnHeadersDefaultCellStyle.SelectionForeColor = $colorHeaderText
$grid.DefaultCellStyle.SelectionBackColor = $colorSelectionBg
$grid.DefaultCellStyle.SelectionForeColor = $colorSelectionText
$grid.DefaultCellStyle.BackColor = $colorSurface
$grid.DefaultCellStyle.ForeColor = $colorInk
$grid.AlternatingRowsDefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(249, 251, 254)
$grid.ColumnHeadersHeight = 26
$null = $grid.Columns.Add("Name", "장치 이름")
$null = $grid.Columns.Add("Category", "장치 분류")
$null = $grid.Columns.Add("Class", "장치 클래스")
$null = $grid.Columns.Add("Manufacturer", "보고된 제조사")
$null = $grid.Columns.Add("Vendor", "추정 칩셋 제조사")
$null = $grid.Columns.Add("Priority", "우선순위")
$null = $grid.Columns.Add("Package", "우선 다운로드 후보")
$null = $grid.Columns.Add("ErrorCode", "오류 코드")
$grid.Columns["Name"].Width = 235
$grid.Columns["Category"].Width = 100
$grid.Columns["Class"].Width = 110
$grid.Columns["Manufacturer"].Width = 135
$grid.Columns["Vendor"].Width = 135
$grid.Columns["Priority"].Width = 90
$grid.Columns["Package"].Width = 225
$grid.Columns["ErrorCode"].Width = 80
$grid.Columns["ErrorCode"].AutoSizeMode = [System.Windows.Forms.DataGridViewAutoSizeColumnMode]::Fill
$grid.Columns["Category"].DefaultCellStyle.Alignment = [System.Windows.Forms.DataGridViewContentAlignment]::MiddleCenter
$grid.Columns["Class"].DefaultCellStyle.Alignment = [System.Windows.Forms.DataGridViewContentAlignment]::MiddleCenter
$grid.Columns["Priority"].DefaultCellStyle.Alignment = [System.Windows.Forms.DataGridViewContentAlignment]::MiddleCenter
$grid.Columns["ErrorCode"].DefaultCellStyle.Alignment = [System.Windows.Forms.DataGridViewContentAlignment]::MiddleCenter
$grid.Columns["Category"].HeaderCell.Style.Alignment = [System.Windows.Forms.DataGridViewContentAlignment]::MiddleCenter
$grid.Columns["Class"].HeaderCell.Style.Alignment = [System.Windows.Forms.DataGridViewContentAlignment]::MiddleCenter
$grid.Columns["Priority"].HeaderCell.Style.Alignment = [System.Windows.Forms.DataGridViewContentAlignment]::MiddleCenter
$grid.Columns["ErrorCode"].HeaderCell.Style.Alignment = [System.Windows.Forms.DataGridViewContentAlignment]::MiddleCenter
$listPanel.Controls.Add($grid)

$detailPanel = New-Object System.Windows.Forms.Panel
$detailPanel.Location = New-Object System.Drawing.Point(20, 740)
$detailPanel.Size = New-Object System.Drawing.Size(1120, 248)
$detailPanel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$detailPanel.BackColor = $colorSurface
$detailPanel.BorderStyle = "FixedSingle"
$contentPanel.Controls.Add($detailPanel)

$detailLabel = New-Object System.Windows.Forms.Label
$detailLabel.Text = "선택 장치 상세"
$detailLabel.Font = New-Object System.Drawing.Font("Malgun Gothic", 10, [System.Drawing.FontStyle]::Bold)
$detailLabel.ForeColor = $colorInk
$detailLabel.Location = New-Object System.Drawing.Point(14, 12)
$detailLabel.AutoSize = $true
$detailPanel.Controls.Add($detailLabel)

$detailPanelTag = New-Object System.Windows.Forms.Label
$detailPanelTag.Text = "DETAIL"
$detailPanelTag.Font = New-Object System.Drawing.Font("Malgun Gothic", 7.5, [System.Drawing.FontStyle]::Bold)
$detailPanelTag.ForeColor = $colorTagText
$detailPanelTag.BackColor = $colorTagBg
$detailPanelTag.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$detailPanelTag.Location = New-Object System.Drawing.Point(128, 10)
$detailPanelTag.Size = New-Object System.Drawing.Size(64, 20)
$detailPanel.Controls.Add($detailPanelTag)

$btnDetailModelSupport = New-Object System.Windows.Forms.Button
$btnDetailModelSupport.Text = "모델 지원"
$btnDetailModelSupport.Font = New-Object System.Drawing.Font("Malgun Gothic", 7.5, [System.Drawing.FontStyle]::Bold)
$btnDetailModelSupport.Size = New-Object System.Drawing.Size(96, 24)
$btnDetailModelSupport.Location = New-Object System.Drawing.Point(802, 8)
$btnDetailModelSupport.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnDetailModelSupport.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(160, 184, 214)
$btnDetailModelSupport.FlatAppearance.BorderSize = 1
$btnDetailModelSupport.BackColor = [System.Drawing.Color]::White
$btnDetailModelSupport.ForeColor = $colorHeaderText
$btnDetailModelSupport.Enabled = $false
$detailPanel.Controls.Add($btnDetailModelSupport)

$btnDetailHardwareSearch = New-Object System.Windows.Forms.Button
$btnDetailHardwareSearch.Text = "HW ID 검색"
$btnDetailHardwareSearch.Font = New-Object System.Drawing.Font("Malgun Gothic", 7.5, [System.Drawing.FontStyle]::Bold)
$btnDetailHardwareSearch.Size = New-Object System.Drawing.Size(96, 24)
$btnDetailHardwareSearch.Location = New-Object System.Drawing.Point(904, 8)
$btnDetailHardwareSearch.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnDetailHardwareSearch.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(160, 184, 214)
$btnDetailHardwareSearch.FlatAppearance.BorderSize = 1
$btnDetailHardwareSearch.BackColor = [System.Drawing.Color]::White
$btnDetailHardwareSearch.ForeColor = $colorHeaderText
$btnDetailHardwareSearch.Enabled = $false
$detailPanel.Controls.Add($btnDetailHardwareSearch)

$btnDetailCatalog = New-Object System.Windows.Forms.Button
$btnDetailCatalog.Text = "카탈로그"
$btnDetailCatalog.Font = New-Object System.Drawing.Font("Malgun Gothic", 7.5, [System.Drawing.FontStyle]::Bold)
$btnDetailCatalog.Size = New-Object System.Drawing.Size(96, 24)
$btnDetailCatalog.Location = New-Object System.Drawing.Point(1006, 8)
$btnDetailCatalog.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnDetailCatalog.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(160, 184, 214)
$btnDetailCatalog.FlatAppearance.BorderSize = 1
$btnDetailCatalog.BackColor = [System.Drawing.Color]::White
$btnDetailCatalog.ForeColor = $colorHeaderText
$btnDetailCatalog.Enabled = $false
$detailPanel.Controls.Add($btnDetailCatalog)

$detailPanelLine = New-Object System.Windows.Forms.Panel
$detailPanelLine.Location = New-Object System.Drawing.Point(14, 36)
$detailPanelLine.Size = New-Object System.Drawing.Size(1092, 1)
$detailPanelLine.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$detailPanelLine.BackColor = $colorBorder
$detailPanel.Controls.Add($detailPanelLine)

$detailScrollPanel = New-Object System.Windows.Forms.Panel
$detailScrollPanel.Location = New-Object System.Drawing.Point(14, 48)
$detailScrollPanel.Size = New-Object System.Drawing.Size(1092, 184)
$detailScrollPanel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right -bor [System.Windows.Forms.AnchorStyles]::Bottom
$detailScrollPanel.AutoScroll = $true
$detailScrollPanel.BackColor = $colorSurface
$detailPanel.Controls.Add($detailScrollPanel)

$detailSection1 = New-Object System.Windows.Forms.Panel
$detailSection1.Location = New-Object System.Drawing.Point(0, 0)
$detailSection1.Size = New-Object System.Drawing.Size(320, 184)
$detailSection1.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
$detailSection1.BackColor = $colorSurfaceSoft
$detailSection1.BorderStyle = "FixedSingle"
$detailScrollPanel.Controls.Add($detailSection1)

$detailSectionLabel1 = New-Object System.Windows.Forms.Label
$detailSectionLabel1.Text = "기본 정보"
$detailSectionLabel1.Font = New-Object System.Drawing.Font("Malgun Gothic", 7.5, [System.Drawing.FontStyle]::Bold)
$detailSectionLabel1.ForeColor = $colorHeaderText
$detailSectionLabel1.Location = New-Object System.Drawing.Point(10, 8)
$detailSectionLabel1.AutoSize = $true
$detailSection1.Controls.Add($detailSectionLabel1)

$detailBasicBox = New-Object System.Windows.Forms.TextBox
$detailBasicBox.Location = New-Object System.Drawing.Point(10, 30)
$detailBasicBox.Size = New-Object System.Drawing.Size(298, 142)
$detailBasicBox.Multiline = $true
$detailBasicBox.ReadOnly = $true
$detailBasicBox.ScrollBars = "Vertical"
$detailBasicBox.Font = New-Object System.Drawing.Font("Malgun Gothic", 8.5)
$detailBasicBox.BorderStyle = "None"
$detailBasicBox.ForeColor = $colorInk
$detailBasicBox.BackColor = $colorSurfaceSoft
$detailSection1.Controls.Add($detailBasicBox)

$detailSection2 = New-Object System.Windows.Forms.Panel
$detailSection2.Location = New-Object System.Drawing.Point(354, 0)
$detailSection2.Size = New-Object System.Drawing.Size(250, 184)
$detailSection2.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
$detailSection2.BackColor = $colorSurfaceSoft
$detailSection2.BorderStyle = "FixedSingle"
$detailScrollPanel.Controls.Add($detailSection2)

$detailSectionLabel2 = New-Object System.Windows.Forms.Label
$detailSectionLabel2.Text = "Hardware ID"
$detailSectionLabel2.Font = New-Object System.Drawing.Font("Malgun Gothic", 7.5, [System.Drawing.FontStyle]::Bold)
$detailSectionLabel2.ForeColor = $colorHeaderText
$detailSectionLabel2.Location = New-Object System.Drawing.Point(10, 8)
$detailSectionLabel2.AutoSize = $true
$detailSection2.Controls.Add($detailSectionLabel2)

$detailHardwareBox = New-Object System.Windows.Forms.TextBox
$detailHardwareBox.Location = New-Object System.Drawing.Point(10, 30)
$detailHardwareBox.Size = New-Object System.Drawing.Size(228, 142)
$detailHardwareBox.Multiline = $true
$detailHardwareBox.ReadOnly = $true
$detailHardwareBox.ScrollBars = "Vertical"
$detailHardwareBox.Font = New-Object System.Drawing.Font("Malgun Gothic", 8.5)
$detailHardwareBox.BorderStyle = "None"
$detailHardwareBox.ForeColor = $colorInk
$detailHardwareBox.BackColor = $colorSurfaceSoft
$detailSection2.Controls.Add($detailHardwareBox)

$detailSection3 = New-Object System.Windows.Forms.Panel
$detailSection3.Location = New-Object System.Drawing.Point(624, 0)
$detailSection3.Size = New-Object System.Drawing.Size(482, 184)
$detailSection3.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
$detailSection3.BackColor = $colorSurfaceSoft
$detailSection3.BorderStyle = "FixedSingle"
$detailScrollPanel.Controls.Add($detailSection3)

$detailSectionLabel3 = New-Object System.Windows.Forms.Label
$detailSectionLabel3.Text = "추천 안내"
$detailSectionLabel3.Font = New-Object System.Drawing.Font("Malgun Gothic", 7.5, [System.Drawing.FontStyle]::Bold)
$detailSectionLabel3.ForeColor = $colorHeaderText
$detailSectionLabel3.Location = New-Object System.Drawing.Point(10, 8)
$detailSectionLabel3.AutoSize = $true
$detailSection3.Controls.Add($detailSectionLabel3)

$detailRecommendationBox = New-Object System.Windows.Forms.TextBox
$detailRecommendationBox.Location = New-Object System.Drawing.Point(10, 30)
$detailRecommendationBox.Size = New-Object System.Drawing.Size(460, 142)
$detailRecommendationBox.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$detailRecommendationBox.Multiline = $true
$detailRecommendationBox.ReadOnly = $true
$detailRecommendationBox.ScrollBars = "Vertical"
$detailRecommendationBox.Font = New-Object System.Drawing.Font("Malgun Gothic", 8.5)
$detailRecommendationBox.BorderStyle = "None"
$detailRecommendationBox.ForeColor = $colorInk
$detailRecommendationBox.BackColor = $colorSurfaceSoft
$detailSection3.Controls.Add($detailRecommendationBox)

$contentPanel.AutoScrollMinSize = New-Object System.Drawing.Size(0, 1014)

$script:CurrentDevices = @()
$script:FilteredDevices = @()
$script:ScanProcess = $null
$script:ScanStartTime = $null
$script:ScanPollTimer = New-Object System.Windows.Forms.Timer
$script:ScanPollTimer.Interval = 500

Register-DriverGuiEvents

Clear-JsonReports

[System.Windows.Forms.Application]::Run($form)













