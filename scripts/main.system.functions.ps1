function Initialize-Logging {
    if (-not (Test-Path -LiteralPath $script:LogsDirectory)) {
        New-Item -ItemType Directory -Path $script:LogsDirectory | Out-Null
    }

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $script:LogPath = Join-Path $script:LogsDirectory "driver-scan-$timestamp.log"
    Write-RunLog -Level "INFO" -Message "드라이버 점검 시작"
}

function Write-RunLog {
    param(
        [string]$Level,
        [string]$Message
    )

    if (-not $script:LogPath) {
        return
    }

    $line = "[{0}] [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Message
    Add-Content -LiteralPath $script:LogPath -Value $line -Encoding UTF8
}

function New-EmptyComputerProfile {
    [PSCustomObject]@{
        Manufacturer    = ""
        Subline         = ""
        SublineSource   = ""
        Model           = ""
        SystemFamily    = ""
        BIOSVersion     = ""
        SerialNumber    = ""
        BoardProduct    = ""
        OperatingSystem = ""
        OSArchitecture  = ""
        DriverTargetOS  = ""
        ManufacturerIds = [PSCustomObject]@{
            ServiceTag     = ""
            MTM            = ""
            ProductNumber  = ""
            SystemSKU      = ""
            ProductVersion = ""
        }
    }
}

function Get-EnvironmentPreflight {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ReportDirectory
    )

    $resolvedReportDirectory = Join-Path $script:BaseDirectory $ReportDirectory
    $scriptsDirectory = Join-Path $script:BaseDirectory "scripts"
    $isAdministrator = Test-IsAdministrator

    $canWriteReportDirectory = $false
    $reportDirectoryMessage = ""
    try {
        if (-not (Test-Path -LiteralPath $resolvedReportDirectory)) {
            New-Item -ItemType Directory -Path $resolvedReportDirectory -Force | Out-Null
        }

        $probeFile = Join-Path $resolvedReportDirectory "preflight-write-test.tmp"
        "ok" | Set-Content -LiteralPath $probeFile -Encoding UTF8
        Remove-Item -LiteralPath $probeFile -Force
        $canWriteReportDirectory = $true
        $reportDirectoryMessage = "리포트 폴더에 쓸 수 있습니다."
    }
    catch {
        $reportDirectoryMessage = "리포트 폴더에 쓸 수 없습니다. 상세: $($_.Exception.Message)"
    }

    $cimAccess = $false
    $cimMessage = ""
    try {
        Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop | Out-Null
        $cimAccess = $true
        $cimMessage = "CIM/WMI 조회가 가능합니다."
    }
    catch {
        $cimMessage = "CIM/WMI 조회에 실패했습니다. 상세: $($_.Exception.Message)"
    }

    $overallMessage = if (-not $isAdministrator) {
        "관리자 권한이 없어 전체 장치 검사를 실행할 수 없습니다. 사전 점검 결과만 제공합니다."
    }
    elseif (-not $cimAccess) {
        "관리자 권한은 있지만 CIM/WMI 조회에 실패했습니다."
    }
    else {
        "전체 검사를 실행할 준비가 되었습니다."
    }

    [PSCustomObject]@{
        IsAdministrator         = $isAdministrator
        CanAccessCim            = $cimAccess
        CanWriteReportDirectory = $canWriteReportDirectory
        MainScriptExists        = (Test-Path -LiteralPath (Join-Path $script:BaseDirectory "main.ps1"))
        GuiScriptExists         = (Test-Path -LiteralPath (Join-Path $script:BaseDirectory "driver_gui.ps1"))
        ScriptsDirectoryExists  = (Test-Path -LiteralPath $scriptsDirectory)
        ReportDirectory         = $resolvedReportDirectory
        ScriptsDirectory        = $scriptsDirectory
        ReportDirectoryMessage  = $reportDirectoryMessage
        CimMessage              = $cimMessage
        Message                 = $overallMessage
    }
}

function Get-ComputerProfile {
    try {
        $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
        $computerSystemProduct = Get-CimInstance -ClassName Win32_ComputerSystemProduct -ErrorAction Stop
        $bios = Get-CimInstance -ClassName Win32_BIOS -ErrorAction Stop
        $baseBoard = Get-CimInstance -ClassName Win32_BaseBoard -ErrorAction Stop
        $operatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
    }
    catch {
        throw "컴퓨터 정보를 조회하지 못했습니다. 관리자 권한 PowerShell에서 다시 실행해 주세요. 상세: $($_.Exception.Message)"
    }

    $manufacturer = Resolve-ManufacturerCanonicalName -Manufacturer $computerSystem.Manufacturer -Model $computerSystem.Model -SystemFamily $computerSystem.SystemFamily
    $sublineInfo = Resolve-ManufacturerSublineInfo -Manufacturer $computerSystem.Manufacturer -Model $computerSystem.Model -SystemFamily $computerSystem.SystemFamily
    $serialNumber = Get-SafeText -Value ($bios.SerialNumber | Select-Object -First 1)
    $systemSku = Get-SafeText -Value $computerSystem.SystemSKUNumber
    $productVersion = Get-SafeText -Value $computerSystemProduct.Version
    $productNumber = Get-SafeText -Value $computerSystemProduct.IdentifyingNumber

    $manufacturerIds = [ordered]@{
        ServiceTag    = ""
        MTM           = ""
        ProductNumber = ""
        SystemSKU     = $systemSku
        ProductVersion= $productVersion
    }

    switch ($manufacturer) {
        "Dell" {
            $manufacturerIds.ServiceTag = $serialNumber
        }
        "Lenovo" {
            $manufacturerIds.MTM = $(if ($productVersion) { $productVersion } else { $systemSku })
        }
        "HP" {
            $manufacturerIds.ProductNumber = $(if ($systemSku) { $systemSku } else { $productNumber })
        }
    }

    $osCaption = Get-SafeText -Value $operatingSystem.Caption
    $osArchitecture = Get-SafeText -Value $operatingSystem.OSArchitecture
    $driverTargetOs = if ($osCaption -match "Windows 11") {
        "Windows 11 $osArchitecture"
    }
    elseif ($osCaption -match "Windows 10") {
        "Windows 10 $osArchitecture"
    }
    else {
        "Windows $osArchitecture"
    }

    [PSCustomObject]@{
        Manufacturer = $manufacturer
        Subline      = Get-SafeText -Value $sublineInfo.Name
        SublineSource = Get-SafeText -Value $sublineInfo.Source
        Model        = Get-SafeText -Value $computerSystem.Model
        SystemFamily = Get-SafeText -Value $computerSystem.SystemFamily
        BIOSVersion  = Get-SafeText -Value ($bios.SMBIOSBIOSVersion | Select-Object -First 1)
        SerialNumber = $serialNumber
        BoardProduct = Get-SafeText -Value ($baseBoard.Product | Select-Object -First 1)
        OperatingSystem = $osCaption
        OSArchitecture  = $osArchitecture
        DriverTargetOS  = $driverTargetOs
        ManufacturerIds = [PSCustomObject]$manufacturerIds
    }
}

function Resolve-SupportResources {
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$ComputerProfile
    )

    $canonicalManufacturer = Resolve-ManufacturerCanonicalName -Manufacturer $ComputerProfile.Manufacturer -Model $ComputerProfile.Model -SystemFamily $ComputerProfile.SystemFamily
    $model = Get-SafeText -Value $ComputerProfile.Model
    $systemFamily = Get-SafeText -Value $ComputerProfile.SystemFamily
    $supportKey = Get-ManufacturerMatchKey @($canonicalManufacturer, $model, $systemFamily)
    $serial = Get-SafeText -Value $ComputerProfile.SerialNumber
    $ids = $ComputerProfile.ManufacturerIds
    $modelEncoded = [uri]::EscapeDataString($model)
    $serialEncoded = [uri]::EscapeDataString($(if (Get-SafeText $ids.ServiceTag) { $ids.ServiceTag } elseif ($serial) { $serial } else { $model }))
    $mtmEncoded = [uri]::EscapeDataString($(if (Get-SafeText $ids.MTM) { $ids.MTM } else { $model }))
    $productEncoded = [uri]::EscapeDataString($(if (Get-SafeText $ids.ProductNumber) { $ids.ProductNumber } else { $model }))

    switch -Regex ($supportKey) {
        "dell" {
            return @(
                [PSCustomObject]@{ Label = "Dell 드라이버 지원 페이지"; Url = "https://www.dell.com/support/home/ko-kr?app=drivers"; Kind = "direct" },
                [PSCustomObject]@{ Label = "Dell 모델/서비스 태그 바로가기"; Url = "https://www.dell.com/support/home/ko-kr/product-support/servicetag/$serialEncoded/overview"; Kind = "direct" },
                [PSCustomObject]@{ Label = "Dell 설명서 페이지"; Url = "https://www.dell.com/support/home/ko-kr?app=manuals"; Kind = "manual" },
                [PSCustomObject]@{ Label = "Dell 모델 설명서 바로가기"; Url = "https://www.dell.com/support/home/ko-kr/product-support/servicetag/$serialEncoded/manuals"; Kind = "manual" },
                [PSCustomObject]@{ Label = "Dell 지원 페이지"; Url = "https://www.dell.com/support/home/"; Kind = "support" }
            )
        }
        "hp" {
            return @(
                [PSCustomObject]@{ Label = "HP 모델 검색"; Url = "https://support.hp.com/kr-ko/search?q=$modelEncoded"; Kind = "direct" },
                [PSCustomObject]@{ Label = "HP 제품번호 검색"; Url = "https://support.hp.com/kr-ko/search?q=$productEncoded"; Kind = "direct" },
                [PSCustomObject]@{ Label = "HP 설명서 검색"; Url = "https://support.hp.com/kr-ko/search?q=$modelEncoded%20user%20guide"; Kind = "manual-search" },
                [PSCustomObject]@{ Label = "HP 지원 페이지"; Url = "https://support.hp.com/kr-ko/drivers"; Kind = "support" }
            )
        }
        "lenovo" {
            return @(
                [PSCustomObject]@{ Label = "Lenovo 모델 검색"; Url = "https://pcsupport.lenovo.com/kr/ko/search?query=$modelEncoded"; Kind = "direct" },
                [PSCustomObject]@{ Label = "Lenovo MTM/모델 검색"; Url = "https://pcsupport.lenovo.com/kr/ko/search?query=$mtmEncoded"; Kind = "direct" },
                [PSCustomObject]@{ Label = "Lenovo 설명서 검색"; Url = "https://pcsupport.lenovo.com/kr/ko/search?query=$mtmEncoded%20user%20guide"; Kind = "manual-search" },
                [PSCustomObject]@{ Label = "Lenovo 지원 페이지"; Url = "https://pcsupport.lenovo.com/kr/ko/"; Kind = "support" }
            )
        }
        "asus" {
            return @(
                [PSCustomObject]@{ Label = "ASUS 모델 검색"; Url = "https://www.asus.com/kr/searchresult?searchType=products&searchKey=$modelEncoded"; Kind = "direct" },
                [PSCustomObject]@{ Label = "ASUS 설명서 검색"; Url = "https://www.asus.com/kr/searchresult?searchType=support&searchKey=$modelEncoded"; Kind = "manual-search" },
                [PSCustomObject]@{ Label = "ASUS 지원 페이지"; Url = "https://www.asus.com/kr/support/"; Kind = "support" }
            )
        }
        "acer" {
            return @(
                [PSCustomObject]@{ Label = "Acer 드라이버/매뉴얼"; Url = "https://www.acer.com/kr-ko/support/drivers-and-manuals"; Kind = "support" },
                [PSCustomObject]@{ Label = "Acer 설명서 페이지"; Url = "https://www.acer.com/kr-ko/support/drivers-and-manuals"; Kind = "manual" },
                [PSCustomObject]@{ Label = "Acer 모델 검색"; Url = "https://www.google.com/search?q=$modelEncoded"; Kind = "direct" }
            )
        }
        "msi" {
            return @(
                [PSCustomObject]@{ Label = "MSI 모델 검색"; Url = "https://www.msi.com/search/$modelEncoded"; Kind = "direct" },
                [PSCustomObject]@{ Label = "MSI 설명서 검색"; Url = "https://www.msi.com/search/$modelEncoded"; Kind = "manual-search" },
                [PSCustomObject]@{ Label = "MSI 지원 페이지"; Url = "https://www.msi.com/support"; Kind = "support" }
            )
        }
        "samsung" {
            return @(
                [PSCustomObject]@{ Label = "Samsung 모델 검색"; Url = "https://www.google.com/search?q=$modelEncoded"; Kind = "direct" },
                [PSCustomObject]@{ Label = "Samsung 설명서 검색"; Url = "https://www.google.com/search?q=site%3Asamsung.com%20$modelEncoded%20manual"; Kind = "manual-search" },
                [PSCustomObject]@{ Label = "Samsung 지원 페이지"; Url = "https://www.samsung.com/sec/support/"; Kind = "support" }
            )
        }
        "lg" {
            return @(
                [PSCustomObject]@{ Label = "LG 모델 검색"; Url = "https://www.google.com/search?q=$modelEncoded"; Kind = "direct" },
                [PSCustomObject]@{ Label = "LG 설명서 검색"; Url = "https://www.google.com/search?q=site%3Alge.co.kr%20$modelEncoded%20manual"; Kind = "manual-search" },
                [PSCustomObject]@{ Label = "LG 지원 페이지"; Url = "https://www.lge.co.kr/support"; Kind = "support" }
            )
        }
        "microsoft surface" {
            return @(
                [PSCustomObject]@{ Label = "Surface 드라이버 및 펌웨어"; Url = "https://support.microsoft.com/surface/download-drivers-and-firmware-for-surface-95d9f1f8-7d4e-8d0a-4f6c-d811ac5d9fba"; Kind = "direct" },
                [PSCustomObject]@{ Label = "Surface 도움말 및 설명서"; Url = "https://support.microsoft.com/surface"; Kind = "manual" }
            )
        }
        "huawei / honor" {
            return @(
                [PSCustomObject]@{ Label = "Huawei/HONOR 모델 검색"; Url = "https://www.google.com/search?q=$modelEncoded"; Kind = "direct" },
                [PSCustomObject]@{ Label = "Huawei PC 지원 페이지"; Url = "https://consumer.huawei.com/en/support/laptops/"; Kind = "support" },
                [PSCustomObject]@{ Label = "HONOR 지원 검색"; Url = "https://www.google.com/search?q=site%3Ahonor.com%20$modelEncoded%20driver"; Kind = "manual-search" }
            )
        }
        "gigabyte / aorus" {
            return @(
                [PSCustomObject]@{ Label = "GIGABYTE/AORUS 모델 검색"; Url = "https://www.google.com/search?q=site%3Agigabyte.com%20$modelEncoded%20support"; Kind = "direct" },
                [PSCustomObject]@{ Label = "GIGABYTE 지원 페이지"; Url = "https://www.gigabyte.com/Support"; Kind = "support" },
                [PSCustomObject]@{ Label = "AORUS 지원 검색"; Url = "https://www.google.com/search?q=site%3Aaorus.com%20$modelEncoded%20driver"; Kind = "manual-search" }
            )
        }
        "razer" {
            return @(
                [PSCustomObject]@{ Label = "Razer 모델 검색"; Url = "https://www.google.com/search?q=site%3Arazer.com%20$modelEncoded%20support"; Kind = "direct" },
                [PSCustomObject]@{ Label = "Razer 지원 페이지"; Url = "https://mysupport.razer.com/"; Kind = "support" },
                [PSCustomObject]@{ Label = "Razer 설명서 검색"; Url = "https://www.google.com/search?q=site%3Arazer.com%20$modelEncoded%20manual"; Kind = "manual-search" }
            )
        }
        "fujitsu" {
            return @(
                [PSCustomObject]@{ Label = "Fujitsu 모델 검색"; Url = "https://www.google.com/search?q=site%3Afujitsu.com%20$modelEncoded%20driver"; Kind = "direct" },
                [PSCustomObject]@{ Label = "Fujitsu 지원 페이지"; Url = "https://www.fujitsu.com/global/support/"; Kind = "support" }
            )
        }
        "dynabook / toshiba" {
            return @(
                [PSCustomObject]@{ Label = "Dynabook/Toshiba 모델 검색"; Url = "https://www.google.com/search?q=$modelEncoded"; Kind = "direct" },
                [PSCustomObject]@{ Label = "Dynabook 지원 페이지"; Url = "https://support.dynabook.com/"; Kind = "support" },
                [PSCustomObject]@{ Label = "Dynabook 설명서 검색"; Url = "https://www.google.com/search?q=site%3Asupport.dynabook.com%20$modelEncoded%20manual"; Kind = "manual-search" }
            )
        }
        "vaio" {
            return @(
                [PSCustomObject]@{ Label = "VAIO 모델 검색"; Url = "https://www.google.com/search?q=site%3Avaio.com%20$modelEncoded%20driver"; Kind = "direct" },
                [PSCustomObject]@{ Label = "VAIO 지원 페이지"; Url = "https://us.vaio.com/pages/support"; Kind = "support" }
            )
        }
        "xiaomi / redmi" {
            return @(
                [PSCustomObject]@{ Label = "Xiaomi/Redmi 모델 검색"; Url = "https://www.google.com/search?q=$modelEncoded"; Kind = "direct" },
                [PSCustomObject]@{ Label = "Xiaomi 지원 페이지"; Url = "https://www.mi.com/global/support/"; Kind = "support" }
            )
        }
        "clevo / tongfang oem" {
            return @(
                [PSCustomObject]@{ Label = "OEM 베어본 모델 검색"; Url = "https://www.google.com/search?q=$modelEncoded%20driver"; Kind = "direct" },
                [PSCustomObject]@{ Label = "장치 Hardware ID 검색 권장"; Url = "https://www.google.com/search?q=$modelEncoded%20hardware%20id%20driver"; Kind = "support" }
            )
        }
        default {
            return @(
                [PSCustomObject]@{ Label = "모델 검색"; Url = "https://www.google.com/search?q=$modelEncoded"; Kind = "support" },
                [PSCustomObject]@{ Label = "모델 설명서 검색"; Url = "https://www.google.com/search?q=$manufacturerText%20$modelEncoded%20manual"; Kind = "manual-search" }
            )
        }
    }
}

function Get-PrimarySupportLink {
    param(
        [AllowEmptyCollection()]
        [object[]]$SupportResources
    )

    if (-not $SupportResources -or $SupportResources.Count -eq 0) {
        return $null
    }

    $osDirect = $SupportResources | Where-Object { (Get-SafeText -Value $_.Kind) -eq "os_direct" } | Select-Object -First 1
    if ($osDirect) {
        return $osDirect
    }

    $direct = $SupportResources | Where-Object { (Get-SafeText -Value $_.Kind) -eq "direct" } | Select-Object -First 1
    if ($direct) {
        return $direct
    }

    return $SupportResources[0]
}

function Get-HardwareIdsForDevice {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Device
    )

    $directHardwareIds = @($Device.HardwareID | Where-Object { $_ })
    if ($directHardwareIds.Count -gt 0) {
        return $directHardwareIds
    }

    $deviceId = Get-SafeText -Value $Device.DeviceID
    if (-not $deviceId) {
        return @()
    }

    try {
        $escapedDeviceId = $deviceId.Replace('\', '\\').Replace("'", "''")
        $device = Get-CimInstance -ClassName Win32_PnPEntity -Filter "DeviceID = '$escapedDeviceId'" -ErrorAction Stop
        $hardwareIds = @($device.HardwareID | Where-Object { $_ })
        if ($hardwareIds.Count -gt 0) {
            return $hardwareIds
        }
    }
    catch {
        Write-RunLog -Level "WARN" -Message "Hardware ID 조회 실패: $deviceId"
    }

    return @()
}

function Convert-HardwareId {
    param(
        [string]$HardwareId
    )

    $upper = (Get-SafeText -Value $HardwareId).ToUpperInvariant()
    $result = [ordered]@{
        Raw         = $HardwareId
        BusType     = $null
        VendorId    = $null
        DeviceId    = $null
        SubsystemId = $null
        Revision    = $null
    }

    if ($upper.StartsWith("PCI\")) {
        $result.BusType = "PCI"
        $match = [regex]::Match($upper, "VEN_([0-9A-F]{4})&DEV_([0-9A-F]{4})")
        if ($match.Success) {
            $result.VendorId = $match.Groups[1].Value
            $result.DeviceId = $match.Groups[2].Value
        }
        $subsys = [regex]::Match($upper, "SUBSYS_([0-9A-F]{8})")
        $rev = [regex]::Match($upper, "REV_([0-9A-F]{2})")
        if ($subsys.Success) { $result.SubsystemId = $subsys.Groups[1].Value }
        if ($rev.Success) { $result.Revision = $rev.Groups[1].Value }
    }
    elseif ($upper.StartsWith("USB\")) {
        $result.BusType = "USB"
        $match = [regex]::Match($upper, "VID_([0-9A-F]{4})&PID_([0-9A-F]{4})")
        if ($match.Success) {
            $result.VendorId = $match.Groups[1].Value
            $result.DeviceId = $match.Groups[2].Value
        }
        $rev = [regex]::Match($upper, "REV_([0-9A-F]{4})")
        if ($rev.Success) { $result.Revision = $rev.Groups[1].Value }
    }
    elseif ($upper.StartsWith("HDAUDIO\")) {
        $result.BusType = "HDAUDIO"
    }
    elseif ($upper.StartsWith("ACPI\")) {
        $result.BusType = "ACPI"
    }

    return [PSCustomObject]$result
}


