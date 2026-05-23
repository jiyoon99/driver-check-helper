function Resolve-ComponentVendor {
    param(
        [string]$Manufacturer,
        [string]$DeviceName,
        [PSCustomObject]$IdAnalysis
    )

    $manufacturerText = (Get-SafeText -Value $Manufacturer).ToLowerInvariant()
    $deviceNameText = (Get-SafeText -Value $DeviceName).ToLowerInvariant()

    foreach ($key in $script:KnownComponentNames.Keys) {
        if ($manufacturerText.Contains($key) -or $deviceNameText.Contains($key)) {
            return [PSCustomObject]@{
                Vendor = $script:KnownComponentNames[$key]
                Source = "제조사 또는 장치명 일치"
            }
        }
    }

    $vendorId = Get-SafeText -Value $IdAnalysis.VendorId
    $busType = Get-SafeText -Value $IdAnalysis.BusType

    if ($vendorId) {
        if ($busType -eq "PCI" -and $script:PciVendorMap -and $script:PciVendorMap.ContainsKey($vendorId)) {
            return [PSCustomObject]@{
                Vendor = $script:PciVendorMap[$vendorId]
                Source = "PCI Vendor ID $vendorId"
            }
        }
        if ($busType -eq "USB" -and $script:UsbVendorMap -and $script:UsbVendorMap.ContainsKey($vendorId)) {
            return [PSCustomObject]@{
                Vendor = $script:UsbVendorMap[$vendorId]
                Source = "USB Vendor ID $vendorId"
            }
        }
    }

    return [PSCustomObject]@{
        Vendor = "알 수 없음"
        Source = "일치하는 벤더 정보를 찾지 못함"
    }
}

function Resolve-UnknownDeviceGuess {
    param(
        [string]$ClassName,
        [string]$DeviceName,
        [string[]]$HardwareIds,
        [PSCustomObject]$IdAnalysis,
        [string]$ComponentVendor
    )

    $nameText = (Get-SafeText -Value $DeviceName).ToLowerInvariant()
    $classText = (Get-SafeText -Value $ClassName).ToLowerInvariant()
    $hardwareList = @($HardwareIds | Where-Object { $_ })

    if ($nameText -match "sm bus") {
        return [PSCustomObject]@{
            Name     = "SM Bus Controller"
            Category = "칩셋/시스템"
            Vendor   = $(if ($ComponentVendor -and $ComponentVendor -ne "알 수 없음") { $ComponentVendor } else { $null })
            Source   = "장치명에 SM Bus 포함"
        }
    }

    if ($nameText -match "pci simple communications") {
        return [PSCustomObject]@{
            Name     = "PCI Simple Communications Controller"
            Category = "칩셋/시스템"
            Vendor   = $(if ($ComponentVendor -and $ComponentVendor -ne "알 수 없음") { $ComponentVendor } else { $null })
            Source   = "장치명에 PCI Simple Communications 포함"
        }
    }

    if ($nameText -match "network controller") {
        return [PSCustomObject]@{
            Name     = "Wireless Network Controller"
            Category = "네트워크"
            Vendor   = $(if ($ComponentVendor -and $ComponentVendor -ne "알 수 없음") { $ComponentVendor } else { $null })
            Source   = "장치명에 Network Controller 포함"
        }
    }

    if ($nameText -match "bluetooth peripheral device|bluetooth adapter|bluetooth radio") {
        return [PSCustomObject]@{
            Name     = "Bluetooth Device"
            Category = "블루투스"
            Vendor   = $(if ($ComponentVendor -and $ComponentVendor -ne "알 수 없음") { $ComponentVendor } else { $null })
            Source   = "장치명에 Bluetooth 포함"
        }
    }

    if ($nameText -match "base system device") {
        return [PSCustomObject]@{
            Name     = "Base System Device"
            Category = "칩셋/시스템"
            Vendor   = $(if ($ComponentVendor -and $ComponentVendor -ne "알 수 없음") { $ComponentVendor } else { $null })
            Source   = "장치명에 Base System Device 포함"
        }
    }

    if ($nameText -match "usb controller|universal serial bus") {
        return [PSCustomObject]@{
            Name     = "USB Controller"
            Category = "USB/썬더볼트"
            Vendor   = $(if ($ComponentVendor -and $ComponentVendor -ne "알 수 없음") { $ComponentVendor } else { $null })
            Source   = "장치명에 USB Controller 포함"
        }
    }

    if ($nameText -match "multimedia audio controller") {
        return [PSCustomObject]@{
            Name     = "Multimedia Audio Controller"
            Category = "오디오"
            Vendor   = $(if ($ComponentVendor -and $ComponentVendor -ne "알 수 없음") { $ComponentVendor } else { $null })
            Source   = "장치명에 Multimedia Audio Controller 포함"
        }
    }

    if ($nameText -match "video controller|vga compatible") {
        return [PSCustomObject]@{
            Name     = "Video Controller"
            Category = "그래픽"
            Vendor   = $(if ($ComponentVendor -and $ComponentVendor -ne "알 수 없음") { $ComponentVendor } else { $null })
            Source   = "장치명에 Video Controller 포함"
        }
    }

    if ($nameText -match "fingerprint|biometric") {
        return [PSCustomObject]@{
            Name     = "Fingerprint Device"
            Category = "지문인식"
            Vendor   = $(if ($ComponentVendor -and $ComponentVendor -ne "알 수 없음") { $ComponentVendor } else { $null })
            Source   = "장치명에 Fingerprint 포함"
        }
    }

    if ($nameText -match "sd host|card reader|memory card|flash media") {
        return [PSCustomObject]@{
            Name     = "Card Reader"
            Category = "카드리더"
            Vendor   = $(if ($ComponentVendor -and $ComponentVendor -ne "알 수 없음") { $ComponentVendor } else { $null })
            Source   = "장치명에 카드리더 계열 키워드 포함"
        }
    }

    if ($nameText -match "thunderbolt") {
        return [PSCustomObject]@{
            Name     = "Thunderbolt Controller"
            Category = "USB/썬더볼트"
            Vendor   = $(if ($ComponentVendor -and $ComponentVendor -ne "알 수 없음") { $ComponentVendor } else { $null })
            Source   = "장치명에 Thunderbolt 포함"
        }
    }

    if ($nameText -match "management engine|serial io|dynamic platform|thermal framework") {
        return [PSCustomObject]@{
            Name     = (Get-SafeText -Value $DeviceName)
            Category = "칩셋/시스템"
            Vendor   = $(if ($ComponentVendor -and $ComponentVendor -ne "알 수 없음") { $ComponentVendor } else { $null })
            Source   = "장치명에 칩셋/시스템 계열 키워드 포함"
        }
    }

    if ($nameText -and $nameText -notmatch "unknown|기본 시스템|base system|generic|pci device|sm bus|simple communications") {
        return [PSCustomObject]@{
            Name     = (Get-SafeText -Value $DeviceName)
            Category = $null
            Vendor   = $null
            Source   = "기존 장치명 사용"
        }
    }

    foreach ($hardwareId in $hardwareList) {
        $upper = (Get-SafeText -Value $hardwareId).ToUpperInvariant()

        foreach ($prefix in $script:AcpiDeviceGuessMap.Keys) {
            if ($upper.StartsWith($prefix)) {
                $hit = $script:AcpiDeviceGuessMap[$prefix]
                return [PSCustomObject]@{
                    Name     = $hit.Name
                    Category = $hit.Category
                    Vendor   = $hit.Vendor
                    Source   = $hit.Source
                }
            }
        }

        foreach ($rule in $script:PciDeviceGuessPatterns) {
            if ($upper -like "*$($rule.Pattern)*") {
                return [PSCustomObject]@{
                    Name     = $rule.Name
                    Category = $rule.Category
                    Vendor   = $rule.Vendor
                    Source   = $rule.Source
                }
            }
        }

        foreach ($rule in $script:UsbDeviceGuessPatterns) {
            if ($upper -like "*$($rule.Pattern)*") {
                return [PSCustomObject]@{
                    Name     = $rule.Name
                    Category = $rule.Category
                    Vendor   = $rule.Vendor
                    Source   = $rule.Source
                }
            }
        }

        foreach ($rule in $script:HdAudioGuessPatterns) {
            if ($upper -like "*$($rule.Pattern)*") {
                return [PSCustomObject]@{
                    Name     = $rule.Name
                    Category = $rule.Category
                    Vendor   = $rule.Vendor
                    Source   = $rule.Source
                }
            }
        }
    }

    if ($classText -match "system" -and $ComponentVendor -eq "Intel") {
        return [PSCustomObject]@{
            Name     = "Intel 칩셋/시스템 장치"
            Category = "칩셋/시스템"
            Vendor   = "Intel"
            Source   = "시스템 클래스 + Intel 벤더 추정"
        }
    }

    if ($classText -match "media" -and $ComponentVendor -eq "Realtek") {
        return [PSCustomObject]@{
            Name     = "Realtek 오디오 장치"
            Category = "오디오"
            Vendor   = "Realtek"
            Source   = "미디어 클래스 + Realtek 벤더 추정"
        }
    }

    return [PSCustomObject]@{
        Name     = ""
        Category = $null
        Vendor   = $null
        Source   = "장치 추정 실패"
    }
}

function Resolve-DeviceCategory {
    param(
        [string]$ClassName,
        [string]$DeviceName,
        [PSCustomObject]$IdAnalysis,
        [AllowNull()]
        [psobject]$UnknownGuess = $null
    )

    if ($UnknownGuess -and (Get-SafeText -Value $UnknownGuess.Category)) {
        return (Get-SafeText -Value $UnknownGuess.Category)
    }

    $classText = (Get-SafeText -Value $ClassName).ToLowerInvariant()
    $nameText = (Get-SafeText -Value $DeviceName).ToLowerInvariant()

    if ($classText -match "net|bluetooth" -or $nameText -match "wifi|wireless|wlan|lan|ethernet|network|bluetooth") {
        if ($nameText -match "bluetooth") { return "블루투스" }
        return "네트워크"
    }
    if ($classText -match "display|video" -or $nameText -match "graphics|display|video|vga|nvidia|radeon|geforce|uhd|iris") {
        return "그래픽"
    }
    if ($classText -match "media|audio|sound" -or $nameText -match "audio|sound|realtek high definition|hd audio") {
        return "오디오"
    }
    if ($classText -match "system" -or $nameText -match "chipset|sm bus|pci simple communications|management engine|serial io") {
        return "칩셋/시스템"
    }
    if ($classText -match "image|camera" -or $nameText -match "camera|webcam|imaging") {
        return "카메라"
    }
    if ($classText -match "biometric" -or $nameText -match "fingerprint|biometric") {
        return "지문인식"
    }
    if ($classText -match "mouse|keyboard|hid" -or $nameText -match "touchpad|elan|synaptics|goodix|hid") {
        return "입력장치"
    }
    if ($classText -match "usb" -or $nameText -match "usb|type-c|thunderbolt") {
        return "USB/썬더볼트"
    }
    if ($classText -match "scsiadapter|hdc|storage" -or $nameText -match "nvme|sata|storage|raid") {
        return "스토리지"
    }
    if ($nameText -match "card reader|sd host|o2micro|genesys") {
        return "카드리더"
    }
    if ($IdAnalysis.BusType -eq "HDAUDIO") {
        return "오디오"
    }
    if ($IdAnalysis.BusType -eq "ACPI") {
        return "ACPI/기타 시스템"
    }

    return "기타"
}

function Resolve-ComponentSupportLinks {
    param(
        [string]$ComponentVendor
    )

    switch ($ComponentVendor) {
        "Intel" {
            return @(
                [PSCustomObject]@{ Label = "Intel 다운로드 센터"; Url = "https://www.intel.com/content/www/us/en/download-center/home.html" },
                [PSCustomObject]@{ Label = "Intel 드라이버 지원 도우미"; Url = "https://www.intel.com/content/www/us/en/support/detect.html" }
            )
        }
        "Realtek" {
            return @(
                [PSCustomObject]@{ Label = "Realtek 다운로드"; Url = "https://www.realtek.com/Download/List?cate_id=593" }
            )
        }
        "NVIDIA" {
            return @(
                [PSCustomObject]@{ Label = "NVIDIA 드라이버 다운로드"; Url = "https://www.nvidia.com/Download/index.aspx" }
            )
        }
        "AMD" {
            return @(
                [PSCustomObject]@{ Label = "AMD 드라이버 및 지원"; Url = "https://www.amd.com/en/support" },
                [PSCustomObject]@{ Label = "AMD 자동 감지 도구"; Url = "https://www.amd.com/en/support/download/drivers.html" }
            )
        }
        "Qualcomm" {
            return @(
                [PSCustomObject]@{ Label = "Qualcomm 지원 페이지"; Url = "https://www.qualcomm.com/support" }
            )
        }
        "Qualcomm Atheros" {
            return @(
                [PSCustomObject]@{ Label = "Qualcomm Atheros 드라이버 검색"; Url = "https://www.google.com/search?q=Qualcomm+Atheros+driver" }
            )
        }
        "Broadcom" {
            return @(
                [PSCustomObject]@{ Label = "Broadcom 지원 페이지"; Url = "https://www.broadcom.com/support" }
            )
        }
        "MediaTek" {
            return @(
                [PSCustomObject]@{ Label = "MediaTek 지원 페이지"; Url = "https://www.mediatek.com/products" }
            )
        }
        "Renesas" {
            return @(
                [PSCustomObject]@{ Label = "Renesas 지원 페이지"; Url = "https://www.renesas.com/us/en/support" }
            )
        }
        "ASMedia" {
            return @(
                [PSCustomObject]@{ Label = "ASMedia 드라이버 검색"; Url = "https://www.google.com/search?q=ASMedia+driver" }
            )
        }
        "Synaptics" {
            return @(
                [PSCustomObject]@{ Label = "Synaptics 드라이버 검색"; Url = "https://www.google.com/search?q=Synaptics+touchpad+driver" }
            )
        }
        "Goodix" {
            return @(
                [PSCustomObject]@{ Label = "Goodix 드라이버 검색"; Url = "https://www.google.com/search?q=Goodix+driver" }
            )
        }
        "ELAN" {
            return @(
                [PSCustomObject]@{ Label = "ELAN 터치패드 드라이버 검색"; Url = "https://www.google.com/search?q=ELAN+touchpad+driver" }
            )
        }
        "Genesys Logic" {
            return @(
                [PSCustomObject]@{ Label = "Genesys Logic 카드리더 드라이버 검색"; Url = "https://www.google.com/search?q=Genesys+Logic+card+reader+driver" }
            )
        }
        "O2 Micro" {
            return @(
                [PSCustomObject]@{ Label = "O2Micro 카드리더 드라이버 검색"; Url = "https://www.google.com/search?q=O2Micro+card+reader+driver" }
            )
        }
        "Fresco Logic" {
            return @(
                [PSCustomObject]@{ Label = "Fresco Logic USB 드라이버 검색"; Url = "https://www.google.com/search?q=Fresco+Logic+USB+driver" }
            )
        }
        "Validity Sensors" {
            return @(
                [PSCustomObject]@{ Label = "Validity Sensors 지문 드라이버 검색"; Url = "https://www.google.com/search?q=Validity+Sensors+fingerprint+driver" }
            )
        }
        default {
            return @()
        }
    }
}

function Resolve-DriverPackageCandidates {
    param(
        [string]$Category,
        [string]$ComponentVendor,
        [string]$DeviceName
    )

    $deviceText = Get-SafeText -Value $DeviceName
    $vendorText = Get-SafeText -Value $ComponentVendor
    $deviceTextLower = $deviceText.ToLowerInvariant()

    switch ($Category) {
        "네트워크" {
            if ($deviceTextLower -match "ethernet|gbe|lan") {
                return @([PSCustomObject]@{ Name = "유선랜 드라이버"; Priority = 1; Query = "$vendorText Ethernet LAN Driver $deviceText" })
            }

            return @(
                [PSCustomObject]@{ Name = "무선랜 드라이버"; Priority = 1; Query = "$vendorText Wi-Fi WLAN Driver $deviceText" },
                [PSCustomObject]@{ Name = "유선랜 드라이버"; Priority = 2; Query = "$vendorText Ethernet LAN Driver $deviceText" }
            )
        }
        "블루투스" {
            return @(
                [PSCustomObject]@{ Name = "블루투스 드라이버"; Priority = 1; Query = "$vendorText Bluetooth Driver $deviceText" },
                [PSCustomObject]@{ Name = "무선랜 + 블루투스 통합 패키지"; Priority = 2; Query = "$vendorText Wireless Bluetooth Combo Driver $deviceText" }
            )
        }
        "그래픽" {
            return @([PSCustomObject]@{ Name = "그래픽 드라이버"; Priority = 1; Query = "$vendorText Graphics VGA Driver $deviceText" })
        }
        "오디오" {
            return @(
                [PSCustomObject]@{ Name = "오디오 드라이버"; Priority = 1; Query = "$vendorText Audio Driver $deviceText" },
                [PSCustomObject]@{ Name = "오디오 콘솔/코덱 패키지"; Priority = 2; Query = "$vendorText Audio Console Codec Driver $deviceText" }
            )
        }
        "칩셋/시스템" {
            return @(
                [PSCustomObject]@{ Name = "칩셋 드라이버"; Priority = 1; Query = "$vendorText Chipset Driver $deviceText" },
                [PSCustomObject]@{ Name = "Serial IO / Management Engine"; Priority = 2; Query = "$vendorText Serial IO Management Engine Driver $deviceText" },
                [PSCustomObject]@{ Name = "DPTF / Dynamic Tuning"; Priority = 3; Query = "$vendorText Dynamic Platform Thermal Framework Driver $deviceText" }
            )
        }
        "카메라" {
            return @(
                [PSCustomObject]@{ Name = "카메라 드라이버"; Priority = 1; Query = "$vendorText Camera Driver $deviceText" },
                [PSCustomObject]@{ Name = "IR 카메라 / 이미지 장치"; Priority = 2; Query = "$vendorText IR Camera Imaging Driver $deviceText" }
            )
        }
        "지문인식" {
            return @(
                [PSCustomObject]@{ Name = "지문인식 드라이버"; Priority = 1; Query = "$vendorText Fingerprint Driver $deviceText" },
                [PSCustomObject]@{ Name = "생체 인식 센서 패키지"; Priority = 2; Query = "$vendorText Biometric Sensor Driver $deviceText" }
            )
        }
        "입력장치" {
            return @(
                [PSCustomObject]@{ Name = "터치패드 드라이버"; Priority = 1; Query = "$vendorText Touchpad Driver $deviceText" },
                [PSCustomObject]@{ Name = "핫키/입력 제어 유틸리티"; Priority = 2; Query = "Hotkey Utility Input Driver $deviceText" }
            )
        }
        "USB/썬더볼트" {
            return @(
                [PSCustomObject]@{ Name = "USB / Thunderbolt 드라이버"; Priority = 1; Query = "$vendorText USB Thunderbolt Driver $deviceText" },
                [PSCustomObject]@{ Name = "USB 컨트롤러 드라이버"; Priority = 2; Query = "$vendorText USB Controller Driver $deviceText" }
            )
        }
        "스토리지" {
            return @([PSCustomObject]@{ Name = "스토리지 컨트롤러 드라이버"; Priority = 1; Query = "$vendorText NVMe SATA RAID Storage Driver $deviceText" })
        }
        "카드리더" {
            return @(
                [PSCustomObject]@{ Name = "카드리더 드라이버"; Priority = 1; Query = "$vendorText Card Reader Driver $deviceText" },
                [PSCustomObject]@{ Name = "SD Host Controller 드라이버"; Priority = 2; Query = "$vendorText SD Host Controller Driver $deviceText" }
            )
        }
        default {
            return @([PSCustomObject]@{ Name = "기본 장치 드라이버"; Priority = 1; Query = "$vendorText Driver $deviceText" })
        }
    }
}

function Get-CategoryGuidance {
    param(
        [string]$Category
    )

    switch ($Category) {
        "네트워크" { return "무선랜/유선랜이 안 잡히면 인터넷 연결이 어려우므로 가장 먼저 설치하는 것이 좋습니다." }
        "블루투스" { return "블루투스는 무선랜 드라이버와 함께 제공되는 경우가 많아 무선랜 패키지를 우선 확인해 보세요." }
        "그래픽" { return "그래픽 드라이버는 해상도, 듀얼 모니터, 영상 재생 성능에 직접 영향을 줍니다." }
        "오디오" { return "오디오 드라이버는 스피커, 마이크, 이어폰 단자 인식 문제와 연결됩니다." }
        "칩셋/시스템" { return "칩셋, Serial IO, Management Engine 계열은 다른 드라이버보다 먼저 설치하면 안정적입니다." }
        "카메라" { return "웹캠 장치는 제조사 번들 드라이버나 Windows Update에서 같이 잡히는 경우도 많습니다." }
        "입력장치" { return "터치패드, 제스처, 단축키 문제는 입력장치 드라이버와 제조사 유틸리티를 함께 확인하세요." }
        "지문인식" { return "지문인식은 센서 드라이버와 제조사 보안 앱이 함께 필요한 경우가 있습니다." }
        "USB/썬더볼트" { return "USB/썬더볼트 문제는 칩셋 또는 컨트롤러 드라이버와 묶여 있는 경우가 많습니다." }
        "스토리지" { return "스토리지 컨트롤러 드라이버는 SSD 인식, NVMe 성능, 설치 프로그램 인식에 영향을 줍니다." }
        "카드리더" { return "카드리더는 O2Micro, Realtek, Genesys Logic 계열 드라이버인지 먼저 확인해 보세요." }
        default { return "제조사 공식 지원 페이지와 Hardware ID 검색을 함께 확인하는 것이 가장 안전합니다." }
    }
}

function Get-DevicePriorityProfile {
    param(
        [string]$Category,
        [bool]$IsProblemDevice,
        [int]$ErrorCode,
        [string]$Status
    )

    $safeCategory = Get-SafeText $Category "기타"
    $safeStatus = (Get-SafeText $Status).ToLowerInvariant()
    $score = 20
    $level = "낮음"
    $reason = "나중에 확인해도 되는 장치입니다."
    $nextAction = "모델 지원 페이지에서 해당 장치 분류를 찾은 뒤 여유 있을 때 설치해도 됩니다."

    switch ($safeCategory) {
        "네트워크" {
            $score = 100
            $level = "최우선"
            $reason = "네트워크 드라이버가 없으면 인터넷 연결과 후속 드라이버 설치가 막힐 수 있습니다."
            $nextAction = "무선랜 또는 유선랜 드라이버를 가장 먼저 설치해 인터넷 연결부터 복구하세요."
        }
        "칩셋/시스템" {
            $score = 90
            $level = "높음"
            $reason = "칩셋과 시스템 장치는 다른 장치 인식과 안정성에 영향을 줍니다."
            $nextAction = "칩셋, Serial IO, Management Engine 계열 드라이버를 그래픽보다 먼저 설치하세요."
        }
        "스토리지" {
            $score = 85
            $level = "높음"
            $reason = "스토리지 컨트롤러 문제는 성능과 장치 인식에 직접 영향을 줍니다."
            $nextAction = "NVMe, SATA, RAID 같은 스토리지 컨트롤러 드라이버를 우선 확인하세요."
        }
        "그래픽" {
            $score = 75
            $level = "보통"
            $reason = "해상도와 그래픽 가속, 외부 디스플레이 사용성에 영향을 줍니다."
            $nextAction = "칩셋 설치 후 그래픽 드라이버를 적용하면 안정적인 경우가 많습니다."
        }
        "오디오" {
            $score = 65
            $level = "보통"
            $reason = "스피커, 마이크, 이어폰 단자 기능과 관련됩니다."
            $nextAction = "그래픽이나 칩셋보다 급하진 않지만 사용성에 영향을 주므로 이어서 설치하세요."
        }
        "USB/썬더볼트" {
            $score = 60
            $level = "보통"
            $reason = "외부 장치 연결과 도킹, Type-C 기능에 영향을 줄 수 있습니다."
            $nextAction = "칩셋 설치 후 USB 또는 Thunderbolt 패키지를 함께 확인하세요."
        }
        "입력장치" {
            $score = 55
            $level = "보통"
            $reason = "터치패드, 제스처, 핫키 같은 입력 기능과 관련됩니다."
            $nextAction = "터치패드 드라이버와 제조사 핫키 유틸리티를 같이 확인하면 좋습니다."
        }
        "블루투스" {
            $score = 45
            $level = "보통"
            $reason = "블루투스는 네트워크 드라이버 패키지와 함께 제공되는 경우가 많습니다."
            $nextAction = "무선랜 드라이버 설치 후 블루투스 기능이 같이 복구되는지 먼저 확인하세요."
        }
        "카메라" {
            $score = 35
            $level = "낮음"
            $reason = "웹캠 사용에만 직접 영향을 주는 경우가 많습니다."
            $nextAction = "기본 장치들이 정상화된 뒤 카메라 드라이버를 설치해도 됩니다."
        }
        "지문인식" {
            $score = 35
            $level = "낮음"
            $reason = "로그인 편의 기능과 연결되며 필수 부팅 요소는 아닙니다."
            $nextAction = "센서 드라이버와 제조사 보안 앱을 나중에 같이 확인하세요."
        }
        "카드리더" {
            $score = 30
            $level = "낮음"
            $reason = "카드리더는 필수 기능이 아닌 경우가 많습니다."
            $nextAction = "다른 핵심 드라이버를 설치한 뒤 마지막에 처리해도 됩니다."
        }
    }

    if ($IsProblemDevice) {
        $score += 10
    }
    if ($ErrorCode -gt 0) {
        $score += [Math]::Min($ErrorCode, 15)
    }
    if ($safeStatus -match "error|unknown|degraded") {
        $score += 5
    }

    return [PSCustomObject]@{
        Score      = $score
        Level      = $level
        Reason     = $reason
        NextAction = $nextAction
    }
}

function Get-ProblemDeviceGroup {
    param(
        [string]$Category,
        [string]$DeviceName
    )

    $safeCategory = Get-SafeText $Category "기타"
    $safeName = (Get-SafeText $DeviceName).ToLowerInvariant()

    switch ($safeCategory) {
        "네트워크" { return "네트워크 계열" }
        "블루투스" { return "네트워크 계열" }
        "칩셋/시스템" { return "칩셋/시스템 계열" }
        "USB/썬더볼트" { return "칩셋/시스템 계열" }
        "입력장치" { return "입력장치 계열" }
        "지문인식" { return "입력장치 계열" }
        "그래픽" { return "그래픽 계열" }
        "오디오" { return "오디오 계열" }
        "카메라" { return "카메라 계열" }
        "스토리지" { return "스토리지 계열" }
        "카드리더" { return "스토리지 계열" }
        default {
            if ($safeName -match "wifi|wireless|bluetooth|ethernet|lan") { return "네트워크 계열" }
            if ($safeName -match "touchpad|keyboard|mouse|hotkey|fingerprint") { return "입력장치 계열" }
            if ($safeName -match "audio|sound|codec") { return "오디오 계열" }
            if ($safeName -match "display|graphics|video") { return "그래픽 계열" }
            if ($safeName -match "card reader|sd host|flash media") { return "스토리지 계열" }
            if ($safeName -match "usb|thunderbolt|type-c|serial io|management engine") { return "칩셋/시스템 계열" }
            return "기타 계열"
        }
    }
}

function Get-BeginnerSummary {
    param(
        [object[]]$AllDevices,
        [object[]]$ProblemDevices
    )

    $orderedProblems = @($ProblemDevices | Sort-Object @{ Expression = { [int]$_.PriorityScore }; Descending = $true }, @{ Expression = { Get-SafeText $_.InferredName } })
    $topProblems = @($orderedProblems | Select-Object -First 3)
    $installOrder = @($orderedProblems | Group-Object Category | Sort-Object { ($_.Group | Select-Object -First 1).PriorityScore } -Descending | ForEach-Object { $_.Name })
    $problemGroups = @(
        $orderedProblems |
            Group-Object ProblemGroup |
            Sort-Object { ($_.Group | Select-Object -First 1).PriorityScore } -Descending |
            ForEach-Object {
                $topDevice = $_.Group | Sort-Object @{ Expression = { [int]$_.PriorityScore }; Descending = $true } | Select-Object -First 1
                [PSCustomObject]@{
                    Name          = $_.Name
                    Count         = @($_.Group).Count
                    TopDeviceName = Get-SafeText $topDevice.InferredName $topDevice.Name
                    PriorityLevel = Get-SafeText $topDevice.PriorityLevel "없음"
                    Reason        = Get-SafeText $topDevice.PriorityReason "없음"
                    NextAction    = Get-SafeText $topDevice.NextAction "없음"
                }
            }
    )
    $tips = @(
        "네트워크가 없으면 가장 먼저 해결해 인터넷 연결을 확보하세요."
        "칩셋/시스템 장치는 다른 드라이버보다 먼저 설치하는 편이 안전합니다."
        "그래픽, 오디오, 입력장치는 핵심 장치가 정상화된 뒤 이어서 설치하세요."
    )

    [PSCustomObject]@{
        ProblemCount   = @($ProblemDevices).Count
        TopPriority    = $(if ($topProblems.Count -gt 0) { $topProblems[0] } else { $null })
        TopProblems    = $topProblems
        ProblemGroups  = $problemGroups
        InstallOrder   = @($installOrder | Select-Object -Unique)
        BeginnerTips   = $tips
        HealthyDevices = @($AllDevices | Where-Object { -not [bool]$_.IsProblemDevice }).Count
    }
}

function Get-DriverRecommendations {
    param(
        [PSCustomObject]$Device,
        [string]$Category,
        [string]$ComponentVendor,
        [object[]]$ManufacturerResources,
        [object[]]$ComponentLinks,
        [object[]]$PackageCandidates,
        [string]$CatalogUrl
    )

    $list = New-Object System.Collections.Generic.List[object]

    $list.Add([PSCustomObject]@{
        Priority = 1
        Title    = "모델 드라이버 센터 확인"
        Detail   = "$(Get-CategoryGuidance -Category $Category)"
        Links    = @($ManufacturerResources)
    })

    if ($PackageCandidates.Count -gt 0) {
        $packageText = ($PackageCandidates | Sort-Object Priority | ForEach-Object { "{0} ({1})" -f $_.Name, $_.Query }) -join "; "
        $list.Add([PSCustomObject]@{
            Priority = 2
            Title    = "우선 다운로드 후보"
            Detail   = $packageText
            Links    = @()
        })
    }

    if ($ComponentLinks.Count -gt 0) {
        $list.Add([PSCustomObject]@{
            Priority = 3
            Title    = "칩셋 제조사 페이지 확인"
            Detail   = "이 장치는 '$ComponentVendor' 계열로 추정됩니다. 해당 제조사 다운로드 페이지도 함께 확인하세요."
            Links    = @($ComponentLinks)
        })
    }

    if ($CatalogUrl) {
        $list.Add([PSCustomObject]@{
            Priority = 4
            Title    = "Hardware ID로 Microsoft Update Catalog 검색"
            Detail   = "공식 페이지에 없을 때는 대표 Hardware ID로 카탈로그 검색을 해보는 것이 좋습니다."
            Links    = @([PSCustomObject]@{ Label = "Microsoft Update Catalog 검색"; Url = $CatalogUrl })
        })
    }

    return $list.ToArray()
}

function Get-AnalyzedDevices {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$ManufacturerResources
    )

    Write-RunLog -Level "INFO" -Message "전체 장치 조회 시작"
    try {
        $devices = Get-CimInstance -ClassName Win32_PnPEntity -ErrorAction Stop
    }
    catch {
        throw "장치 목록을 조회하지 못했습니다. 관리자 권한 PowerShell에서 다시 실행해 주세요. 상세: $($_.Exception.Message)"
    }
    Write-RunLog -Level "INFO" -Message ("전체 장치 조회 완료: {0}개" -f @($devices).Count)

    foreach ($device in $devices) {
        $hardwareIds = @(Get-HardwareIdsForDevice -Device $device)
        $primaryHardwareId = if ($hardwareIds.Count -gt 0) { $hardwareIds[0] } else { $null }
        $idAnalysis = Convert-HardwareId -HardwareId $primaryHardwareId
        $vendorResult = Resolve-ComponentVendor -Manufacturer $device.Manufacturer -DeviceName $device.Name -IdAnalysis $idAnalysis
        $unknownGuess = Resolve-UnknownDeviceGuess -ClassName $device.PNPClass -DeviceName $device.Name -HardwareIds $hardwareIds -IdAnalysis $idAnalysis -ComponentVendor $vendorResult.Vendor
        $effectiveDeviceName = $(if (Get-SafeText -Value $unknownGuess.Name) { $unknownGuess.Name } else { Get-SafeText -Value $device.Name })
        $effectiveVendor = $(if (Get-SafeText -Value $unknownGuess.Vendor) { Get-SafeText -Value $unknownGuess.Vendor } else { $vendorResult.Vendor })
        $vendorSource = $(if ((Get-SafeText -Value $unknownGuess.Vendor) -and $vendorResult.Vendor -eq "알 수 없음") { Get-SafeText -Value $unknownGuess.Source } else { $vendorResult.Source })
        $category = Resolve-DeviceCategory -ClassName $device.PNPClass -DeviceName $effectiveDeviceName -IdAnalysis $idAnalysis -UnknownGuess $unknownGuess
        $catalogUrl = if ($primaryHardwareId) {
            "https://www.catalog.update.microsoft.com/Search.aspx?q=$([uri]::EscapeDataString($primaryHardwareId))"
        }
        else {
            $null
        }
        $componentLinks = @(Resolve-ComponentSupportLinks -ComponentVendor $effectiveVendor)
        $packageCandidates = @(Resolve-DriverPackageCandidates -Category $category -ComponentVendor $effectiveVendor -DeviceName $effectiveDeviceName)
        $recommendations = @(Get-DriverRecommendations -Device $device -Category $category -ComponentVendor $effectiveVendor -ManufacturerResources $ManufacturerResources -ComponentLinks $componentLinks -PackageCandidates $packageCandidates -CatalogUrl $catalogUrl)
        $priorityProfile = Get-DevicePriorityProfile -Category $category -IsProblemDevice:([bool]([int]$device.ConfigManagerErrorCode -ne 0)) -ErrorCode ([int]$device.ConfigManagerErrorCode) -Status (Get-SafeText -Value $device.Status)

        Write-RunLog -Level "INFO" -Message ("장치 분석 완료: {0} / {1} / {2}" -f $effectiveDeviceName, $category, $effectiveVendor)

        [PSCustomObject]@{
            Name                   = Get-SafeText -Value $device.Name
            InferredName           = Get-SafeText -Value $effectiveDeviceName
            PNPClass               = Get-SafeText -Value $device.PNPClass
            Category               = $category
            Manufacturer           = Get-SafeText -Value $device.Manufacturer
            Service                = Get-SafeText -Value $device.Service
            DeviceID               = Get-SafeText -Value $device.DeviceID
            Status                 = Get-SafeText -Value $device.Status
            ConfigManagerErrorCode = $device.ConfigManagerErrorCode
            IsProblemDevice        = ([int]$device.ConfigManagerErrorCode -ne 0)
            HardwareIds            = $hardwareIds
            PrimaryHardwareId      = $primaryHardwareId
            IdAnalysis             = $idAnalysis
            ComponentVendor        = $effectiveVendor
            VendorInferenceSource  = $vendorSource
            DeviceInferenceSource  = Get-SafeText -Value $unknownGuess.Source
            PriorityScore          = [int]$priorityProfile.Score
            PriorityLevel          = Get-SafeText $priorityProfile.Level
            PriorityReason         = Get-SafeText $priorityProfile.Reason
            NextAction             = Get-SafeText $priorityProfile.NextAction
            ProblemGroup           = Get-ProblemDeviceGroup -Category $category -DeviceName $effectiveDeviceName
            DriverPackageCandidates = $packageCandidates
            UpdateCatalogUrl       = $catalogUrl
            ComponentLinks         = $componentLinks
            Recommendations        = $recommendations
        }
    }
}





