[CmdletBinding()]
param(
    [string]$ReportDirectory = ".\reports",
    [switch]$AutoOpenSupport,
    [switch]$AutoOpenCatalog,
    [switch]$Preflight
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:ReportSchemaVersion = 4
$script:BaseDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:LogsDirectory = Join-Path $script:BaseDirectory "logs"
$script:LogPath = $null

. (Join-Path $script:BaseDirectory "scripts\main.functions.ps1")

try {
    Initialize-Logging

    $preflightStatus = Get-EnvironmentPreflight -ReportDirectory $ReportDirectory

    if ($Preflight) {
        $report = [PSCustomObject]@{
            SchemaVersion      = $script:ReportSchemaVersion
            GeneratedAt        = (Get-Date).ToString("s")
            LogPath            = $script:LogPath
            AutoOpenSupport    = $false
            AutoOpenCatalog    = $false
            IsPreflight        = $true
            Preflight          = $preflightStatus
            ComputerProfile    = New-EmptyComputerProfile
            SupportResources   = @()
            PrimarySupportLink = $null
            Summary            = $null
            AllDevices         = @()
            ProblemDevices     = @()
        }

        $reportTimestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        Write-PreflightSummary -Preflight $preflightStatus
        $jsonReportPath = Save-JsonReport -ReportDirectory $ReportDirectory -ReportData $report -Timestamp $reportTimestamp
        $htmlReportPath = Save-HtmlReport -ReportDirectory $ReportDirectory -ReportData $report -Timestamp $reportTimestamp

        Write-Host ""
        Write-Host ("JSON 리포트 저장 위치: {0}" -f (Resolve-Path -LiteralPath $jsonReportPath)) -ForegroundColor Green
        Write-Host ("HTML 리포트 저장 위치: {0}" -f (Resolve-Path -LiteralPath $htmlReportPath)) -ForegroundColor Green
        Write-Host ("JSON_REPORT_PATH::{0}" -f ((Resolve-Path -LiteralPath $jsonReportPath).Path))
        Write-RunLog -Level "INFO" -Message "사전 점검 완료"
        exit 0
    }

    if (-not $preflightStatus.IsAdministrator) {
        throw "이 스크립트는 관리자 권한으로 실행하는 것이 좋습니다. run_driver_scan.bat를 사용하거나 PowerShell을 관리자 권한으로 다시 실행해 주세요."
    }

    $computerProfile = Get-ComputerProfile
    $supportResources = @(Resolve-SupportResources -ComputerProfile $computerProfile)
    $primarySupportLink = Get-PrimarySupportLink -SupportResources $supportResources
    $allDevices = @(Get-AnalyzedDevices -ManufacturerResources $supportResources)
    $problemDevices = @($allDevices | Where-Object { $_.IsProblemDevice })
    $summary = Get-BeginnerSummary -AllDevices $allDevices -ProblemDevices $problemDevices

    $report = [PSCustomObject]@{
        SchemaVersion      = $script:ReportSchemaVersion
        GeneratedAt        = (Get-Date).ToString("s")
        LogPath            = $script:LogPath
        AutoOpenSupport    = [bool]$AutoOpenSupport
        AutoOpenCatalog    = [bool]$AutoOpenCatalog
        IsPreflight        = $false
        Preflight          = $preflightStatus
        ComputerProfile    = $computerProfile
        SupportResources   = $supportResources
        PrimarySupportLink = $primarySupportLink
        Summary            = $summary
        AllDevices         = $allDevices
        ProblemDevices     = $problemDevices
    }

    $reportTimestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    Write-ConsoleSummary -ComputerProfile $computerProfile -SupportResources $supportResources -ProblemDevices $problemDevices -AllDevices $allDevices
    $jsonReportPath = Save-JsonReport -ReportDirectory $ReportDirectory -ReportData $report -Timestamp $reportTimestamp
    $htmlReportPath = Save-HtmlReport -ReportDirectory $ReportDirectory -ReportData $report -Timestamp $reportTimestamp
    Open-RecommendationLinks -ProblemDevices $problemDevices -PrimarySupportLink $primarySupportLink

    Write-Host ""
    if ($primarySupportLink) {
        Write-Host ("바로 이동 링크: [{0}] {1}" -f $primarySupportLink.Label, $primarySupportLink.Url) -ForegroundColor Cyan
    }
    Write-Host ""
    Write-Host ("로그 저장 위치      : {0}" -f (Resolve-Path -LiteralPath $script:LogPath)) -ForegroundColor DarkGray
    Write-Host ("JSON 리포트 저장 위치: {0}" -f (Resolve-Path -LiteralPath $jsonReportPath)) -ForegroundColor Green
    Write-Host ("HTML 리포트 저장 위치: {0}" -f (Resolve-Path -LiteralPath $htmlReportPath)) -ForegroundColor Green
    Write-Host ("JSON_REPORT_PATH::{0}" -f ((Resolve-Path -LiteralPath $jsonReportPath).Path))
    Write-RunLog -Level "INFO" -Message "드라이버 점검 완료"
}
catch {
    Write-RunLog -Level "ERROR" -Message $_.Exception.Message
    Write-Host ""
    Write-Host "실행 중 문제가 발생했습니다." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Yellow
    if ($script:LogPath) {
        Write-Host ("로그 파일: {0}" -f $script:LogPath) -ForegroundColor DarkGray
    }
    exit 1
}




