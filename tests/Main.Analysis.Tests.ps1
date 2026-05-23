$projectRoot = Split-Path -Parent $PSScriptRoot

. (Join-Path $projectRoot "scripts\common.functions.ps1")
. (Join-Path $projectRoot "scripts\main.analysis.functions.ps1")

function New-Text {
    param([int[]]$Codes)

    return -join ($Codes | ForEach-Object { [char]$_ })
}

$CategoryNetwork = New-Text @(0xB124, 0xD2B8, 0xC6CC, 0xD06C)
$CategoryBluetooth = New-Text @(0xBE14, 0xB8E8, 0xD22C, 0xC2A4)
$CategoryGraphics = New-Text @(0xADF8, 0xB798, 0xD53D)
$CategoryAudio = New-Text @(0xC624, 0xB514, 0xC624)
$CategoryChipset = New-Text @(0xCE69, 0xC14B, 0x002F, 0xC2DC, 0xC2A4, 0xD15C)
$CategoryFingerprint = New-Text @(0xC9C0, 0xBB38, 0xC778, 0xC2DD)
$CategoryInput = New-Text @(0xC785, 0xB825, 0xC7A5, 0xCE58)
$CategoryCardReader = New-Text @(0xCE74, 0xB4DC, 0xB9AC, 0xB354)
$GroupChipset = New-Text @(0xCE69, 0xC14B, 0x002F, 0xC2DC, 0xC2A4, 0xD15C, 0x0020, 0xACC4, 0xC5F4)
$GroupStorage = New-Text @(0xC2A4, 0xD1A0, 0xB9AC, 0xC9C0, 0x0020, 0xACC4, 0xC5F4)

$script:KnownComponentNames = @{
    "intel" = "Intel"
    "realtek" = "Realtek"
    "nvidia" = "NVIDIA"
    "amd" = "AMD"
    "qualcomm" = "Qualcomm"
    "atheros" = "Qualcomm Atheros"
    "broadcom" = "Broadcom"
    "mediatek" = "MediaTek"
    "renesas" = "Renesas"
    "asmedia" = "ASMedia"
    "synaptics" = "Synaptics"
    "elan" = "ELAN"
    "goodix" = "Goodix"
    "fresco logic" = "Fresco Logic"
    "genesys" = "Genesys Logic"
    "validity" = "Validity Sensors"
    "fingerprint" = "Fingerprint Vendor"
}

$script:PciVendorMap = @{
    "8086" = "Intel"
    "10EC" = "Realtek"
    "10DE" = "NVIDIA"
    "14E4" = "Broadcom"
    "1217" = "O2 Micro"
    "1C5C" = "Genesys Logic"
}

$script:UsbVendorMap = @{
    "8087" = "Intel"
    "0BDA" = "Realtek"
    "27C6" = "Goodix"
    "06CB" = "Synaptics"
}

$script:AcpiDeviceGuessMap = @{
    "ACPI\INT3400" = @{ Name = "Intel Dynamic Platform and Thermal Framework"; Category = $CategoryChipset; Vendor = "Intel"; Source = "ACPI ID INT3400" }
    "ACPI\ELAN" = @{ Name = "ELAN Input Device"; Category = $CategoryInput; Vendor = "ELAN"; Source = "ACPI ID ELAN" }
}

$script:PciDeviceGuessPatterns = @(
    @{ Pattern = "VEN_8086&DEV_9D3A"; Name = "Intel Management Engine Interface"; Category = $CategoryChipset; Vendor = "Intel"; Source = "PCI Device ID 9D3A" },
    @{ Pattern = "VEN_10EC&DEV_522A"; Name = "Realtek PCIe Card Reader"; Category = $CategoryCardReader; Vendor = "Realtek"; Source = "PCI Device ID 522A" }
)

$script:UsbDeviceGuessPatterns = @(
    @{ Pattern = "VID_8087&PID_0A2A"; Name = "Intel Wireless Bluetooth"; Category = $CategoryBluetooth; Vendor = "Intel"; Source = "USB Device ID 0A2A" },
    @{ Pattern = "VID_27C6"; Name = "Goodix Fingerprint Device"; Category = $CategoryFingerprint; Vendor = "Goodix"; Source = "USB Vendor ID 27C6" }
)

$script:HdAudioGuessPatterns = @(
    @{ Pattern = "VEN_10EC"; Name = "Realtek High Definition Audio"; Category = $CategoryAudio; Vendor = "Realtek"; Source = "HDAUDIO Vendor ID 10EC" }
)

Describe "Resolve-ComponentVendor" {
    It "prefers known component names from the device name" {
        $result = Resolve-ComponentVendor -Manufacturer "" -DeviceName "Realtek PCIe GbE Family Controller" -IdAnalysis ([pscustomobject]@{ VendorId = ""; BusType = "" })

        $result.Vendor | Should Be "Realtek"
    }

    It "falls back to PCI vendor ID mapping" {
        $result = Resolve-ComponentVendor -Manufacturer "" -DeviceName "Unknown device" -IdAnalysis ([pscustomobject]@{ VendorId = "8086"; BusType = "PCI" })

        $result.Vendor | Should Be "Intel"
        $result.Source | Should Be "PCI Vendor ID 8086"
    }
}

Describe "Resolve-UnknownDeviceGuess" {
    It "classifies multimedia audio controller as audio" {
        $result = Resolve-UnknownDeviceGuess -ClassName "" -DeviceName "Multimedia Audio Controller" -HardwareIds @() -IdAnalysis ([pscustomobject]@{}) -ComponentVendor "Realtek"

        $result.Name | Should Be "Multimedia Audio Controller"
        $result.Category | Should Be $CategoryAudio
    }

    It "uses hardware ID rules for ACPI devices" {
        $result = Resolve-UnknownDeviceGuess -ClassName "" -DeviceName "Unknown device" -HardwareIds @("ACPI\INT3400\0") -IdAnalysis ([pscustomobject]@{}) -ComponentVendor "Unknown"

        $result.Name | Should Be "Intel Dynamic Platform and Thermal Framework"
        $result.Category | Should Be $CategoryChipset
        $result.Vendor | Should Be "Intel"
    }

    It "classifies bluetooth peripheral devices" {
        $result = Resolve-UnknownDeviceGuess -ClassName "" -DeviceName "Bluetooth Peripheral Device" -HardwareIds @() -IdAnalysis ([pscustomobject]@{}) -ComponentVendor "Intel"

        $result.Category | Should Be $CategoryBluetooth
        $result.Name | Should Be "Bluetooth Device"
    }
}

Describe "Resolve-DeviceCategory" {
    It "returns graphics for video controller names" {
        $category = Resolve-DeviceCategory -ClassName "" -DeviceName "Video Controller" -IdAnalysis ([pscustomobject]@{ BusType = "" }) -UnknownGuess $null

        $category | Should Be $CategoryGraphics
    }

    It "returns audio for HDAUDIO bus types" {
        $category = Resolve-DeviceCategory -ClassName "" -DeviceName "Unknown device" -IdAnalysis ([pscustomobject]@{ BusType = "HDAUDIO" }) -UnknownGuess $null

        $category | Should Be $CategoryAudio
    }
}

Describe "Resolve-DriverPackageCandidates" {
    It "adds a combo package candidate for bluetooth devices" {
        $candidates = @(Resolve-DriverPackageCandidates -Category $CategoryBluetooth -ComponentVendor "Intel" -DeviceName "Bluetooth Device")

        $candidates.Count | Should Be 2
        $candidates[0].Name | Should Be (New-Text @(0xBE14, 0xB8E8, 0xD22C, 0xC2A4, 0x0020, 0xB4DC, 0xB77C, 0xC774, 0xBC84))
        $candidates[1].Name | Should Be (New-Text @(0xBB34, 0xC120, 0xB79C, 0x0020, 0x002B, 0x0020, 0xBE14, 0xB8E8, 0xD22C, 0xC2A4, 0x0020, 0xD1B5, 0xD569, 0x0020, 0xD328, 0xD0A4, 0xC9C0))
    }

    It "adds a DPTF candidate for chipset devices" {
        $candidates = @(Resolve-DriverPackageCandidates -Category $CategoryChipset -ComponentVendor "Intel" -DeviceName "Intel Dynamic Platform and Thermal Framework")

        $candidates.Count | Should Be 3
        $candidates[2].Name | Should Be "DPTF / Dynamic Tuning"
    }
}

Describe "Get-ProblemDeviceGroup" {
    It "groups card reader devices into storage" {
        $group = Get-ProblemDeviceGroup -Category $CategoryCardReader -DeviceName "Realtek PCIe Card Reader"

        $group | Should Be $GroupStorage
    }

    It "groups thunderbolt-like names into chipset/system when category is unknown" {
        $group = Get-ProblemDeviceGroup -Category "Other" -DeviceName "Thunderbolt Controller"

        $group | Should Be $GroupChipset
    }
}
