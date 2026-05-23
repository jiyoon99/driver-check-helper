function Test-IsGenericSystemValue {
    param([string]$Value)

    $text = (Get-SafeText $Value).ToLowerInvariant()
    if (-not $text) {
        return $true
    }

    return (
        $text -match "^to be filled by o\.e\.m\.$" -or
        $text -match "^system product name$" -or
        $text -match "^system manufacturer$" -or
        $text -match "^default string$" -or
        $text -match "^default$" -or
        $text -match "^oem$" -or
        $text -match "^not applicable$"
    )
}

function Test-PreferComponentVendorSearch {
    param([psobject]$Device)

    if (-not $Device -or -not $script:CurrentReport) {
        return $false
    }

    $category = Get-SafeText $Device.Category
    $componentVendor = (Get-SafeText $Device.ComponentVendor).ToLowerInvariant()
    $manufacturer = Resolve-ManufacturerCanonicalName -Manufacturer $script:CurrentReport.ComputerProfile.Manufacturer -Model $script:CurrentReport.ComputerProfile.Model -SystemFamily $script:CurrentReport.ComputerProfile.SystemFamily

    if ($category -eq "그래픽" -and $componentVendor -in @("nvidia", "amd", "intel")) {
        return $true
    }

    if (Test-IsGenericSystemValue -Value $manufacturer) {
        return $true
    }

    return $false
}

function Get-SystemSearchTerms {
    param([psobject]$Device)

    if (-not $script:CurrentReport) {
        return @()
    }

    if (Test-PreferComponentVendorSearch -Device $Device) {
        return @()
    }

    $manufacturer = Resolve-ManufacturerCanonicalName -Manufacturer $script:CurrentReport.ComputerProfile.Manufacturer -Model $script:CurrentReport.ComputerProfile.Model -SystemFamily $script:CurrentReport.ComputerProfile.SystemFamily
    $subline = Get-SafeText $script:CurrentReport.ComputerProfile.Subline
    if (-not $subline) {
        $subline = Get-SafeText (Resolve-ManufacturerSublineInfo -Manufacturer $script:CurrentReport.ComputerProfile.Manufacturer -Model $script:CurrentReport.ComputerProfile.Model -SystemFamily $script:CurrentReport.ComputerProfile.SystemFamily).Name
    }
    $model = Get-SafeText $script:CurrentReport.ComputerProfile.Model
    $terms = New-Object System.Collections.Generic.List[string]

    if (-not (Test-IsGenericSystemValue -Value $manufacturer)) {
        $terms.Add($manufacturer)
    }
    if ((Get-SafeText $subline) -and -not (Test-IsGenericSystemValue -Value $subline)) {
        $terms.Add($subline)
    }
    if (-not (Test-IsGenericSystemValue -Value $model)) {
        $terms.Add($model)
    }

    return $terms.ToArray()
}

function Get-DeviceSearchQuery {
    param([psobject]$Device)

    if (-not $Device) {
        return $null
    }

    $firstCandidate = @($Device.DriverPackageCandidates | Sort-Object Priority | Select-Object -First 1)
    if ($firstCandidate.Count -gt 0) {
        $query = Get-SafeText $firstCandidate[0].Query
        if ($query) {
            return $query
        }
    }

    $vendor = Get-SafeText $Device.ComponentVendor
    $name = Get-SafeText $Device.Name
    $category = Get-SafeText $Device.Category
    $driverTargetOs = Get-SafeText $script:CurrentReport.ComputerProfile.DriverTargetOS
    $systemTerms = @(Get-SystemSearchTerms -Device $Device)
    $queryText = (@($systemTerms + @($driverTargetOs, $vendor, $category, "드라이버", $name)) | Where-Object { Get-SafeText $_ }) -join " "
    if ($queryText) {
        return $queryText
    }

    return $name
}

function Get-CategorySearchKeywords {
    param([psobject]$Device)

    $category = Get-SafeText $Device.Category

    switch ($category) {
        "네트워크" { return "wifi wlan lan ethernet network" }
        "블루투스" { return "bluetooth bt wireless" }
        "그래픽" { return "graphics vga display gpu" }
        "오디오" { return "audio sound codec" }
        "칩셋/시스템" { return "chipset serial io management engine system" }
        "카메라" { return "camera webcam imaging" }
        "지문인식" { return "fingerprint biometric" }
        "입력장치" { return "touchpad input hotkey keyboard mouse" }
        "USB/썬더볼트" { return "usb thunderbolt controller" }
        "스토리지" { return "storage sata nvme raid ahci" }
        "카드리더" { return "card reader sd reader" }
        default { return "driver download" }
    }
}

function Get-ManufacturerCategoryKeywords {
    param([psobject]$Device)

    $manufacturer = (Resolve-ManufacturerCanonicalName -Manufacturer $script:CurrentReport.ComputerProfile.Manufacturer -Model $script:CurrentReport.ComputerProfile.Model -SystemFamily $script:CurrentReport.ComputerProfile.SystemFamily).ToLowerInvariant()
    $subline = Get-SafeText $script:CurrentReport.ComputerProfile.Subline
    if (-not $subline) {
        $subline = Get-SafeText (Resolve-ManufacturerSublineInfo -Manufacturer $script:CurrentReport.ComputerProfile.Manufacturer -Model $script:CurrentReport.ComputerProfile.Model -SystemFamily $script:CurrentReport.ComputerProfile.SystemFamily).Name
    }
    $category = Get-SafeText $Device.Category

    switch -Regex ($manufacturer) {
        "dell" {
            switch ($category) {
                "네트워크" { return "wireless wlan wifi ethernet network driver" }
                "블루투스" { return "bluetooth wireless driver" }
                "그래픽" { return "video graphics display driver" }
                "오디오" { return "audio sound driver" }
                "칩셋/시스템" { return "chipset serial io management engine driver" }
                "입력장치" { return "touchpad dell touchpad input driver" }
                default { return "driver" }
            }
        }
        "hp" {
            switch ($category) {
                "네트워크" { return "wireless lan wlan wifi ethernet driver" }
                "블루투스" { return "bluetooth driver" }
                "그래픽" { return "graphics driver" }
                "오디오" { return "audio driver" }
                "칩셋/시스템" { return "chipset driver" }
                "입력장치" { return "synaptics elan touchpad hotkey driver" }
                default { return "driver" }
            }
        }
        "lenovo" {
            if ($subline -eq "ThinkPad" -and $category -eq "입력장치") { return "thinkpad hotkey touchpad ultraNav driver" }
            if ($subline -eq "Legion" -and $category -eq "그래픽") { return "legion graphics vga gpu driver" }
            switch ($category) {
                "네트워크" { return "wireless lan wifi ethernet driver" }
                "블루투스" { return "bluetooth driver" }
                "그래픽" { return "display vga graphics driver" }
                "오디오" { return "audio sound driver" }
                "칩셋/시스템" { return "chipset serial io management engine driver" }
                "입력장치" { return "touchpad hotkey utility driver" }
                default { return "driver" }
            }
        }
        "asus" {
            if ($subline -eq "ROG" -and $category -eq "그래픽") { return "rog graphics vga gpu driver" }
            if ($subline -eq "ROG" -and $category -eq "칩셋/시스템") { return "rog chipset system driver" }
            if ($subline -eq "TUF" -and $category -eq "그래픽") { return "tuf gaming graphics driver" }
            switch ($category) {
                "네트워크" { return "wireless lan wifi ethernet driver" }
                "블루투스" { return "bluetooth driver" }
                "그래픽" { return "vga graphics display driver" }
                "오디오" { return "audio driver" }
                "칩셋/시스템" { return "chipset serial io driver" }
                "입력장치" { return "touchpad atk hotkey driver" }
                default { return "driver" }
            }
        }
        "samsung" {
            if ($subline -eq "Galaxy Book") {
                switch ($category) {
                    "네트워크" { return "samsung galaxy book wireless lan wifi ethernet driver" }
                    "블루투스" { return "samsung galaxy book bluetooth driver" }
                    "입력장치" { return "samsung galaxy book touchpad hotkey driver" }
                }
            }
            switch ($category) {
                "네트워크" { return "samsung galaxy book wireless lan wifi ethernet driver" }
                "블루투스" { return "samsung galaxy book bluetooth driver" }
                "그래픽" { return "samsung galaxy book graphics driver" }
                "오디오" { return "samsung galaxy book audio sound driver" }
                "칩셋/시스템" { return "samsung galaxy book chipset system driver" }
                "입력장치" { return "samsung settings hotkey touchpad driver" }
                default { return "samsung driver" }
            }
        }
        "lg" {
            if ($subline -eq "gram") {
                switch ($category) {
                    "네트워크" { return "lg gram wireless lan wifi ethernet driver" }
                    "입력장치" { return "lg gram touchpad hotkey driver" }
                }
            }
            if ($subline -eq "UltraPC") {
                switch ($category) {
                    "네트워크" { return "lg ultrapc wireless lan wifi ethernet driver" }
                    "칩셋/시스템" { return "lg ultrapc chipset driver" }
                }
            }
            switch ($category) {
                "네트워크" { return "lg gram ultrapc wireless lan wifi ethernet driver" }
                "블루투스" { return "lg gram bluetooth driver" }
                "그래픽" { return "lg gram graphics driver" }
                "오디오" { return "lg gram audio sound driver" }
                "칩셋/시스템" { return "lg gram chipset system driver" }
                "입력장치" { return "lg gram touchpad hotkey driver" }
                default { return "lg gram driver" }
            }
        }
        "huawei / honor" {
            switch ($category) {
                "네트워크" { return "huawei matebook honor magicbook wifi ethernet driver" }
                "블루투스" { return "huawei matebook bluetooth driver" }
                "그래픽" { return "huawei matebook graphics driver" }
                "오디오" { return "huawei matebook audio driver" }
                "칩셋/시스템" { return "huawei matebook chipset system driver" }
                "입력장치" { return "huawei pc manager touchpad hotkey driver" }
                default { return "huawei matebook driver" }
            }
        }
        "gigabyte / aorus" {
            switch ($category) {
                "네트워크" { return "gigabyte aorus wifi ethernet driver" }
                "그래픽" { return "gigabyte aorus graphics driver" }
                "칩셋/시스템" { return "gigabyte aorus chipset driver" }
                default { return "gigabyte aorus driver" }
            }
        }
        "razer" {
            switch ($category) {
                "네트워크" { return "razer blade wifi ethernet driver" }
                "그래픽" { return "razer blade graphics driver" }
                "오디오" { return "razer blade audio driver" }
                default { return "razer blade driver" }
            }
        }
        "fujitsu" {
            return "fujitsu lifebook driver"
        }
        "dynabook / toshiba" {
            return "dynabook toshiba notebook driver"
        }
        "vaio" {
            return "vaio notebook driver"
        }
        "xiaomi / redmi" {
            return "xiaomi redmibook notebook driver"
        }
        "clevo / tongfang oem" {
            return "oem barebone notebook driver"
        }
        default {
            return (Get-CategorySearchKeywords -Device $Device)
        }
    }
}

function Get-ComponentVendorKeywords {
    param([psobject]$Device)

    $vendor = (Get-SafeText $Device.ComponentVendor).ToLowerInvariant()
    $category = Get-SafeText $Device.Category

    switch ($vendor) {
        "intel" {
            switch ($category) {
                "네트워크" { return "intel wireless wifi wlan ethernet" }
                "블루투스" { return "intel bluetooth" }
                "그래픽" { return "intel graphics" }
                "칩셋/시스템" { return "intel chipset serial io management engine" }
                default { return "intel driver" }
            }
        }
        "realtek" {
            switch ($category) {
                "네트워크" { return "realtek lan ethernet wifi" }
                "오디오" { return "realtek audio hd audio codec" }
                "카드리더" { return "realtek card reader" }
                default { return "realtek driver" }
            }
        }
        "nvidia" {
            switch ($category) {
                "그래픽" { return "nvidia geforce graphics display gpu" }
                "오디오" { return "nvidia hd audio" }
                default { return "nvidia driver" }
            }
        }
        "amd" {
            switch ($category) {
                "그래픽" { return "amd radeon graphics display gpu" }
                "칩셋/시스템" { return "amd chipset ryzen system" }
                "오디오" { return "amd hd audio" }
                default { return "amd driver" }
            }
        }
        "synaptics" {
            if ($category -eq "입력장치") { return "synaptics touchpad pointing driver" }
            return "synaptics driver"
        }
        "goodix" {
            if ($category -eq "지문인식") { return "goodix fingerprint biometric driver" }
            return "goodix driver"
        }
        default {
            return (Get-SafeText $Device.ComponentVendor)
        }
    }
}

function Get-ManufacturerCategoryDirectLink {
    param([psobject]$Device)

    if (-not $Device -or -not $script:CurrentReport) {
        return $null
    }

    $manufacturer = (Resolve-ManufacturerCanonicalName -Manufacturer $script:CurrentReport.ComputerProfile.Manufacturer -Model $script:CurrentReport.ComputerProfile.Model -SystemFamily $script:CurrentReport.ComputerProfile.SystemFamily).ToLowerInvariant()
    $category = Get-SafeText $Device.Category

    switch -Regex ($manufacturer) {
        "dell" {
            return [PSCustomObject]@{
                Label = "Dell 드라이버 카테고리"
                Url   = "https://www.dell.com/support/home/ko-kr?app=drivers"
                Kind  = "category-direct"
            }
        }
        "hp" {
            return [PSCustomObject]@{
                Label = "HP 드라이버 페이지"
                Url   = "https://support.hp.com/kr-ko/drivers"
                Kind  = "category-direct"
            }
        }
        "lenovo" {
            return [PSCustomObject]@{
                Label = "Lenovo 드라이버 및 소프트웨어"
                Url   = "https://pcsupport.lenovo.com/kr/ko/products/laptops-and-netbooks/downloads/driver-list/"
                Kind  = "category-direct"
            }
        }
        "asus" {
            if ($category -eq "입력장치") {
                return [PSCustomObject]@{
                    Label = "ASUS 터치패드/ATK 지원"
                    Url   = "https://www.asus.com/kr/support/"
                    Kind  = "category-direct"
                }
            }

            return [PSCustomObject]@{
                Label = "ASUS 드라이버 지원"
                Url   = "https://www.asus.com/kr/support/"
                Kind  = "category-direct"
            }
        }
        "samsung" {
            return [PSCustomObject]@{
                Label = "Samsung 지원 페이지"
                Url   = "https://www.samsung.com/sec/support/"
                Kind  = "category-direct"
            }
        }
        "lg" {
            return [PSCustomObject]@{
                Label = "LG 지원 페이지"
                Url   = "https://www.lge.co.kr/support"
                Kind  = "category-direct"
            }
        }
        "huawei / honor" {
            return [PSCustomObject]@{
                Label = "Huawei/HONOR 지원 페이지"
                Url   = "https://consumer.huawei.com/en/support/laptops/"
                Kind  = "category-direct"
            }
        }
        "gigabyte / aorus" {
            return [PSCustomObject]@{
                Label = "GIGABYTE/AORUS 지원 페이지"
                Url   = "https://www.gigabyte.com/Support"
                Kind  = "category-direct"
            }
        }
        "razer" {
            return [PSCustomObject]@{
                Label = "Razer 지원 페이지"
                Url   = "https://mysupport.razer.com/"
                Kind  = "category-direct"
            }
        }
        "fujitsu" {
            return [PSCustomObject]@{
                Label = "Fujitsu 지원 페이지"
                Url   = "https://www.fujitsu.com/global/support/"
                Kind  = "category-direct"
            }
        }
        "dynabook / toshiba" {
            return [PSCustomObject]@{
                Label = "Dynabook 지원 페이지"
                Url   = "https://support.dynabook.com/"
                Kind  = "category-direct"
            }
        }
        "vaio" {
            return [PSCustomObject]@{
                Label = "VAIO 지원 페이지"
                Url   = "https://us.vaio.com/pages/support"
                Kind  = "category-direct"
            }
        }
        "xiaomi / redmi" {
            return [PSCustomObject]@{
                Label = "Xiaomi 지원 페이지"
                Url   = "https://www.mi.com/global/support/"
                Kind  = "category-direct"
            }
        }
        default {
            return $null
        }
    }
}

function Get-OfficialDriverSearchQuery {
    param([psobject]$Device)

    if (-not $Device) {
        return $null
    }

    $driverTargetOs = Get-SafeText $script:CurrentReport.ComputerProfile.DriverTargetOS
    $packageName = Get-SafeText (@($Device.DriverPackageCandidates | Sort-Object Priority | Select-Object -First 1 | Select-Object -ExpandProperty Name) | Select-Object -First 1)
    $deviceName = Get-SafeText $Device.Name
    $componentVendor = Get-SafeText $Device.ComponentVendor
    $category = Get-SafeText $Device.Category
    $categoryKeywords = Get-CategorySearchKeywords -Device $Device
    $manufacturerKeywords = Get-ManufacturerCategoryKeywords -Device $Device
    $componentVendorKeywords = Get-ComponentVendorKeywords -Device $Device
    $systemTerms = @(Get-SystemSearchTerms -Device $Device)

    $parts = @($systemTerms + @($driverTargetOs, $packageName, $componentVendor, $componentVendorKeywords, $category, $manufacturerKeywords, $categoryKeywords, $deviceName, "driver download support"))
    $query = ($parts | Where-Object { Get-SafeText $_ }) -join " "
    return (Get-SafeText $query)
}

function Get-ManufacturerSearchDomain {
    $supportKey = Get-ManufacturerMatchKey @(
        (Resolve-ManufacturerCanonicalName -Manufacturer $script:CurrentReport.ComputerProfile.Manufacturer -Model $script:CurrentReport.ComputerProfile.Model -SystemFamily $script:CurrentReport.ComputerProfile.SystemFamily),
        $script:CurrentReport.ComputerProfile.Model,
        $script:CurrentReport.ComputerProfile.SystemFamily
    )

    switch -Regex ($supportKey) {
        "dell" { return "dell.com" }
        "hp" { return "support.hp.com" }
        "lenovo" { return "pcsupport.lenovo.com" }
        "asus" { return "asus.com" }
        "acer" { return "acer.com" }
        "msi|micro-star" { return "msi.com" }
        "samsung" { return "samsung.com" }
        "lg" { return "lge.co.kr" }
        "microsoft surface" { return "support.microsoft.com" }
        "huawei / honor" { return "consumer.huawei.com" }
        "gigabyte / aorus" { return "gigabyte.com" }
        "razer" { return "razer.com" }
        "fujitsu" { return "fujitsu.com" }
        "dynabook / toshiba" { return "support.dynabook.com" }
        "vaio" { return "vaio.com" }
        "xiaomi / redmi" { return "mi.com" }
        default { return $null }
    }
}

function Get-ManufacturerSiteSearchQuery {
    param([psobject]$Device)

    if (-not $Device) {
        return $null
    }

    $domain = Get-ManufacturerSearchDomain
    $baseQuery = Get-OfficialDriverSearchQuery -Device $Device
    if (-not $domain -or -not $baseQuery) {
        return $baseQuery
    }

    return "site:$domain $baseQuery"
}

function Get-SupportCenterSearchQuery {
    param([psobject]$Device)

    if (-not $Device) {
        return $null
    }

    $driverTargetOs = Get-SafeText $script:CurrentReport.ComputerProfile.DriverTargetOS
    $packageName = Get-SafeText (@($Device.DriverPackageCandidates | Sort-Object Priority | Select-Object -First 1 | Select-Object -ExpandProperty Name) | Select-Object -First 1)
    $categoryKeywords = Get-CategorySearchKeywords -Device $Device
    $manufacturerKeywords = Get-ManufacturerCategoryKeywords -Device $Device
    $componentVendorKeywords = Get-ComponentVendorKeywords -Device $Device
    $systemTerms = @(Get-SystemSearchTerms -Device $Device)

    $parts = @($systemTerms + @($driverTargetOs, $packageName, $componentVendorKeywords, $manufacturerKeywords, $categoryKeywords, "support driver")) |
        Where-Object { Get-SafeText $_ } |
        ForEach-Object { Get-SafeText $_ }

    return (Get-SafeText ($parts -join " "))
}

function Get-HardwareIdSearchQuery {
    param([psobject]$Device)

    if (-not $Device) {
        return $null
    }

    $hardwareId = Get-SafeText $Device.PrimaryHardwareId
    if (-not $hardwareId) {
        return $null
    }

    return "$hardwareId driver"
}

function Get-PackageSpecificSearchLinks {
    param([psobject]$Device)

    if (-not $Device) {
        return @()
    }

    $driverTargetOs = Get-SafeText $script:CurrentReport.ComputerProfile.DriverTargetOS
    $domain = Get-ManufacturerSearchDomain
    $links = New-Object System.Collections.Generic.List[object]
    $manufacturerKeywords = Get-ManufacturerCategoryKeywords -Device $Device
    $componentVendorKeywords = Get-ComponentVendorKeywords -Device $Device
    $systemTerms = @(Get-SystemSearchTerms -Device $Device)

    foreach ($candidate in @($Device.DriverPackageCandidates | Sort-Object Priority | Select-Object -First 2)) {
        $name = Get-SafeText $candidate.Name
        $query = @($systemTerms + @($driverTargetOs, $name, $componentVendorKeywords, $manufacturerKeywords, "driver download")) |
            Where-Object { Get-SafeText $_ } |
            ForEach-Object { Get-SafeText $_ }

        $queryText = $query -join " "
        if ($domain) {
            $queryText = "site:$domain $queryText"
        }

        $url = Get-WebSearchUrl -Query $queryText
        if ($url) {
            $links.Add([PSCustomObject]@{
                Label = "{0} 직접 검색" -f $name
                Url   = $url
                Kind  = "package-search"
            })
        }
    }

    return $links.ToArray()
}

function Get-WebSearchUrl {
    param([string]$Query)

    $safeQuery = Get-SafeText $Query
    if (-not $safeQuery) {
        return $null
    }

    return "https://www.google.com/search?q=$([uri]::EscapeDataString($safeQuery))"
}

function Open-ExternalUrl {
    param([string]$Url)

    $safeUrl = Get-SafeText $Url
    if (-not $safeUrl) {
        return
    }

    Start-Process $safeUrl
}

function Get-OfficialPriorityLinksForDevice {
    param([psobject]$Device)

    $links = New-Object System.Collections.Generic.List[object]
    $report = $script:CurrentReport

    $primarySupportUrl = Get-SafeText $report.PrimarySupportLink.Url
    if ($primarySupportUrl) {
        $links.Add([PSCustomObject]@{ Label = "1순위 공식 링크: 모델 지원"; Url = $primarySupportUrl; Kind = "support-primary"; Rank = 1 })
    }

    $utility = Get-ManufacturerUtilityLink
    if ($utility -and (Get-SafeText $utility.Url)) {
        $links.Add([PSCustomObject]@{ Label = "2순위 공식 링크: 제조사 도구"; Url = (Get-SafeText $utility.Url); Kind = "utility"; Rank = 2 })
    }

    $manual = Get-ManualSupportLink
    if ($manual -and (Get-SafeText $manual.Url)) {
        $links.Add([PSCustomObject]@{ Label = "3순위 공식 링크: 설명서"; Url = (Get-SafeText $manual.Url); Kind = "manual"; Rank = 3 })
    }

    if ($Device) {
        $categoryDirectLink = Get-ManufacturerCategoryDirectLink -Device $Device
        if ($categoryDirectLink -and (Get-SafeText $categoryDirectLink.Url)) {
            $links.Add([PSCustomObject]@{ Label = "4순위 공식 링크: 장치 계열 지원"; Url = (Get-SafeText $categoryDirectLink.Url); Kind = "category-direct"; Rank = 4 })
        }
    }

    return @($links | Sort-Object Rank)
}

function Get-OfficialPriorityTextForDevice {
    param([psobject]$Device)

    $lines = @()
    foreach ($link in @(Get-OfficialPriorityLinksForDevice -Device $Device)) {
        $lines += ("- {0}" -f (Get-SafeText $link.Label))
    }

    if ($lines.Count -eq 0) {
        return "공식 링크가 준비되지 않았습니다."
    }

    return ($lines -join [Environment]::NewLine)
}

function Get-DetailActionLinks {
    param([psobject]$Device)

    $modelSupportUrl = Get-SafeText $script:CurrentReport.PrimarySupportLink.Url
    $hardwareSearchUrl = if ($Device) { Get-WebSearchUrl -Query (Get-HardwareIdSearchQuery -Device $Device) } else { $null }
    $catalogUrl = if ($Device) { Get-SafeText $Device.UpdateCatalogUrl } else { $null }

    return [PSCustomObject]@{
        ModelSupportUrl   = $modelSupportUrl
        HardwareSearchUrl = $hardwareSearchUrl
        CatalogUrl        = $catalogUrl
    }
}

function Get-QuickLinksForDevice {
    param([psobject]$Device)

    $links = @()
    $links += @(Get-OfficialPriorityLinksForDevice -Device $Device)

    if ($Device) {
        foreach ($packageLink in @(Get-PackageSpecificSearchLinks -Device $Device)) {
            $links += $packageLink
        }

        $officialQuery = Get-ManufacturerSiteSearchQuery -Device $Device
        $officialSearchUrl = Get-WebSearchUrl -Query $officialQuery
        if ($officialSearchUrl) {
            $links += [PSCustomObject]@{
                Label = "공식 도메인 드라이버 검색"
                Url   = $officialSearchUrl
                Kind  = "official-search"
            }
        }

        $supportCenterQuery = Get-SupportCenterSearchQuery -Device $Device
        $supportCenterSearchUrl = Get-WebSearchUrl -Query $supportCenterQuery
        if ($supportCenterSearchUrl) {
            $links += [PSCustomObject]@{
                Label = "지원센터 기준 검색"
                Url   = $supportCenterSearchUrl
                Kind  = "support-search"
            }
        }

        $searchQuery = Get-DeviceSearchQuery -Device $Device
        $searchUrl = Get-WebSearchUrl -Query $searchQuery
        if ($searchUrl) {
            $links += [PSCustomObject]@{
                Label = "이 장치 드라이버 검색"
                Url   = $searchUrl
                Kind  = "search"
            }
        }

        $hardwareSearchQuery = Get-HardwareIdSearchQuery -Device $Device
        $hardwareSearchUrl = Get-WebSearchUrl -Query $hardwareSearchQuery
        if ($hardwareSearchUrl) {
            $links += [PSCustomObject]@{
                Label = "Hardware ID 검색"
                Url   = $hardwareSearchUrl
                Kind  = "hardware-search"
            }
        }

        if (Get-SafeText $Device.UpdateCatalogUrl) {
            $links += [PSCustomObject]@{
                Label = "Microsoft Update Catalog"
                Url   = (Get-SafeText $Device.UpdateCatalogUrl)
                Kind  = "catalog"
            }
        }

        $componentLink = @($Device.ComponentLinks | Select-Object -First 1)
        if ($componentLink.Count -gt 0 -and (Get-SafeText $componentLink[0].Url)) {
            $links += [PSCustomObject]@{
                Label = "부품 제조사 페이지"
                Url   = (Get-SafeText $componentLink[0].Url)
                Kind  = $(if (Test-PreferComponentVendorSearch -Device $Device) { "vendor-priority" } else { "vendor" })
            }
        }
    }

    return @($links | Where-Object { Get-SafeText $_.Url })
}
function Get-ManufacturerUtilityLink {
    $supportKey = Get-ManufacturerMatchKey @(
        (Resolve-ManufacturerCanonicalName -Manufacturer $script:CurrentReport.ComputerProfile.Manufacturer -Model $script:CurrentReport.ComputerProfile.Model -SystemFamily $script:CurrentReport.ComputerProfile.SystemFamily),
        $script:CurrentReport.ComputerProfile.Model,
        $script:CurrentReport.ComputerProfile.SystemFamily
    )

    switch -Regex ($supportKey) {
        "dell" {
            return [PSCustomObject]@{
                Label = "Dell SupportAssist"
                Url   = "https://www.dell.com/support/contents/en-us/article/product-support/self-support-knowledgebase/software-and-downloads/support-assist/supportassist-for-home"
                Detail = "Dell은 SupportAssist로 드라이버 점검과 업데이트를 지원합니다."
            }
        }
        "hp" {
            return [PSCustomObject]@{
                Label = "HP Support Assistant"
                Url   = "https://support.hp.com/us-en/help/hp-support-assistant"
                Detail = "HP는 HP Support Assistant에서 모델별 드라이버 다운로드를 지원합니다."
            }
        }
        "lenovo" {
            return [PSCustomObject]@{
                Label = "Lenovo System Update"
                Url   = "https://support.lenovo.com/us/en/downloads/ds012808-lenovo-system-update-for-windows-10-7-32-bit-64-bit-desktop-notebook-workstation"
                Detail = "Lenovo는 System Update 또는 Lenovo Vantage로 드라이버 업데이트를 지원합니다."
            }
        }
        "asus" {
            return [PSCustomObject]@{
                Label = "MyASUS"
                Url   = "https://www.asus.com/support/myasus-deeplink"
                Detail = "ASUS는 MyASUS에서 드라이버와 진단 기능을 제공합니다."
            }
        }
        "acer" {
            return [PSCustomObject]@{
                Label = "Acer Care Center 안내"
                Url   = "https://www.acer.com/us-en/support/drivers-and-manuals"
                Detail = "Acer는 Drivers and Manuals 페이지의 Application 항목에서 Acer Care Center를 제공합니다."
            }
        }
        "msi" {
            return [PSCustomObject]@{
                Label = "MSI Center"
                Url   = "https://www.msi.com/Landing/msi-center/download"
                Detail = "MSI는 MSI Center에서 Live Update와 진단 기능을 제공합니다."
            }
        }
        "samsung" {
            return [PSCustomObject]@{
                Label = "Samsung Update 안내"
                Url   = "https://www.samsung.com/us/support/answer/ANS10001472/"
                Detail = "Samsung PC는 Samsung Update 앱으로 드라이버 다운로드를 지원합니다."
            }
        }
        "lg" {
            return [PSCustomObject]@{
                Label = "LG Update / 지원 안내"
                Url   = "https://www.lge.co.kr/support"
                Detail = "LG는 지원 페이지와 LG Update 계열 도구를 통해 드라이버를 제공하는 경우가 많습니다."
            }
        }
        "microsoft surface" {
            return [PSCustomObject]@{
                Label = "Surface 앱 / 진단 도구"
                Url   = "https://support.microsoft.com/en-us/surface/fix-common-problems-using-the-surface-app-and-surface-diagnostic-toolkit-f61d8d18-37a9-863d-f8d0-1982eb16f7b5"
                Detail = "Surface는 Surface 앱과 Surface Diagnostic Toolkit을 사용할 수 있습니다."
            }
        }
        "huawei / honor" {
            return [PSCustomObject]@{
                Label = "Huawei PC Manager 안내"
                Url   = "https://consumer.huawei.com/en/support/pc-manager/"
                Detail = "Huawei 노트북은 PC Manager로 드라이버와 진단 기능을 지원하는 경우가 있습니다."
            }
        }
        "gigabyte / aorus" {
            return [PSCustomObject]@{
                Label = "GIGABYTE Control Center 안내"
                Url   = "https://www.gigabyte.com/Support"
                Detail = "GIGABYTE/AORUS는 지원 페이지와 Control Center 계열 도구를 사용하는 경우가 많습니다."
            }
        }
        "razer" {
            return [PSCustomObject]@{
                Label = "Razer Synapse / 지원 안내"
                Url   = "https://mysupport.razer.com/"
                Detail = "Razer는 지원 포털과 Synapse를 통해 일부 장치 업데이트를 제공합니다."
            }
        }
        "fujitsu" {
            return [PSCustomObject]@{
                Label = "Fujitsu 지원 안내"
                Url   = "https://www.fujitsu.com/global/support/"
                Detail = "Fujitsu는 글로벌 또는 지역 지원 포털에서 드라이버를 제공합니다."
            }
        }
        "dynabook / toshiba" {
            return [PSCustomObject]@{
                Label = "Dynabook 지원 안내"
                Url   = "https://support.dynabook.com/"
                Detail = "Dynabook/Toshiba는 모델 검색 기반 지원 페이지를 사용하는 경우가 많습니다."
            }
        }
        "vaio" {
            return [PSCustomObject]@{
                Label = "VAIO 지원 안내"
                Url   = "https://us.vaio.com/pages/support"
                Detail = "VAIO는 지역별 지원 페이지에서 드라이버와 문서를 제공합니다."
            }
        }
        "xiaomi / redmi" {
            return [PSCustomObject]@{
                Label = "Xiaomi 지원 안내"
                Url   = "https://www.mi.com/global/support/"
                Detail = "Xiaomi/Redmi 계열은 모델 검색과 Hardware ID 검색을 병행하는 편이 안전합니다."
            }
        }
        default {
            return $null
        }
    }
}

function Get-ManualSupportLink {
    if (-not $script:CurrentReport) {
        return $null
    }

    $resources = @($script:CurrentReport.SupportResources)
    if (-not $resources -or $resources.Count -eq 0) {
        return $null
    }

    $manual = $resources | Where-Object { (Get-SafeText $_.Kind) -eq "manual" } | Select-Object -First 1
    if ($manual -and (Get-SafeText $manual.Url)) {
        return $manual
    }

    $manualSearch = $resources | Where-Object { (Get-SafeText $_.Kind) -eq "manual-search" } | Select-Object -First 1
    if ($manualSearch -and (Get-SafeText $manualSearch.Url)) {
        return $manualSearch
    }

    return $null
}

function Update-UtilityButtons {
    $utility = $null
    $manualLink = $null
    if ($script:CurrentReport) {
        $utility = Get-ManufacturerUtilityLink
        $manualLink = Get-ManualSupportLink
    }

    if ($utility -and (Get-SafeText $utility.Url)) {
        $btnUtility.Enabled = $true
        $btnUtility.Tag = $utility.Url
        $btnUtility.Text = ((Get-SafeText $utility.Label "공식 지원 도구") -replace '\s*다운로드$', '')
    }
    else {
        $btnUtility.Enabled = $false
        $btnUtility.Tag = $null
        $btnUtility.Text = "공식 지원 도구"
    }

    $primarySupportUrl = ""
    if ($script:CurrentReport) {
        $primarySupportUrl = Get-SafeText $script:CurrentReport.PrimarySupportLink.Url
    }

    if ($primarySupportUrl) {
        $btnModelSupport.Enabled = $true
        $btnModelSupport.Tag = $primarySupportUrl
    }
    else {
        $btnModelSupport.Enabled = $false
        $btnModelSupport.Tag = $null
    }

    if ($manualLink -and (Get-SafeText $manualLink.Url)) {
        $btnManualDocs.Enabled = $true
        $btnManualDocs.Tag = $manualLink.Url
        $btnManualDocs.Text = ((Get-SafeText $manualLink.Label "공식 설명서") -replace '\s*다운로드$', '')
    }
    else {
        $btnManualDocs.Enabled = $false
        $btnManualDocs.Tag = $null
        $btnManualDocs.Text = "공식 설명서"
    }

    $hintParts = New-Object System.Collections.Generic.List[string]
    if ($primarySupportUrl) {
        $hintParts.Add("모델 지원 페이지")
    }
    if ($manualLink -and (Get-SafeText $manualLink.Url)) {
        $hintParts.Add("공식 설명서")
    }
    if ($utility -and (Get-SafeText $utility.Url)) {
        $hintParts.Add("지원 도구")
    }

    if ($hintParts.Count -gt 0) {
        $utilityHint.Text = ("바로 열기 가능: {0}" -f ($hintParts -join ", "))
    }
    elseif ($utility) {
        $utilityHint.Text = (Get-SafeText $utility.Detail "지원 도구, 드라이버 센터, 설명서가 준비되면 여기서 바로 열 수 있습니다.")
    }
    else {
        $utilityHint.Text = "지원 도구, 드라이버 센터, 설명서가 준비되면 여기서 바로 열 수 있습니다."
    }
}

function Open-PreferredDeviceLink {
    param([psobject]$Device)

    $quickLinks = @(Get-QuickLinksForDevice -Device $Device)
    $sortedLinks = $quickLinks |
        Sort-Object @{ Expression = {
            switch ($_.Kind) {
                "vendor-priority" { 1 }
                "category-direct" { 1 }
                "package-search" { 2 }
                "official-search" { 3 }
                "support" { 4 }
                "support-search" { 5 }
                "search" { 6 }
                "hardware-search" { 7 }
                "catalog" { 8 }
                "vendor" { 9 }
                default { 10 }
            }
        } }

    $preferred = @($sortedLinks | Select-Object -First 1)
    if ($preferred.Count -gt 0 -and (Get-SafeText $preferred[0].Url)) {
        Open-ExternalUrl -Url $preferred[0].Url
    }
}





