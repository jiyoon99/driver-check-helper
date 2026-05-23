function New-RuleText {
    param([int[]]$Codes)

    -join ($Codes | ForEach-Object { [char]$_ })
}

$script:RuleCategoryNetwork = New-RuleText @(0xB124,0xD2B8,0xC6CC,0xD06C)
$script:RuleCategoryBluetooth = New-RuleText @(0xBE14,0xB8E8,0xD22C,0xC2A4)
$script:RuleCategoryGraphics = New-RuleText @(0xADF8,0xB798,0xD53D)
$script:RuleCategoryAudio = New-RuleText @(0xC624,0xB514,0xC624)
$script:RuleCategoryChipset = New-RuleText @(0xCE69,0xC14B,0x002F,0xC2DC,0xC2A4,0xD15C)
$script:RuleCategoryInput = New-RuleText @(0xC785,0xB825,0xC7A5,0xCE58)
$script:RuleCategoryCardReader = New-RuleText @(0xCE74,0xB4DC,0xB9AC,0xB354)
$script:RuleCategoryFingerprint = New-RuleText @(0xC9C0,0xBB38,0xC778,0xC2DD)
$script:RuleCategoryOther = New-RuleText @(0xAE30,0xD0C0)
$script:RuleUnknown = New-RuleText @(0xC54C,0x0020,0xC218,0x0020,0xC5C6,0xC74C)

$script:AcpiDeviceGuessMap = @{
    "ACPI\INT3400" = @{ Name = "Intel Dynamic Platform and Thermal Framework"; Category = $script:RuleCategoryChipset; Vendor = "Intel"; Source = "ACPI ID INT3400" }
    "ACPI\INT3401" = @{ Name = "Intel Dynamic Platform and Thermal Framework"; Category = $script:RuleCategoryChipset; Vendor = "Intel"; Source = "ACPI ID INT3401" }
    "ACPI\INT3402" = @{ Name = "Intel Dynamic Platform and Thermal Framework"; Category = $script:RuleCategoryChipset; Vendor = "Intel"; Source = "ACPI ID INT3402" }
    "ACPI\INT3403" = @{ Name = "Intel Dynamic Platform and Thermal Framework"; Category = $script:RuleCategoryChipset; Vendor = "Intel"; Source = "ACPI ID INT3403" }
    "ACPI\INT3442" = @{ Name = "Intel Serial IO GPIO Host Controller"; Category = $script:RuleCategoryChipset; Vendor = "Intel"; Source = "ACPI ID INT3442" }
    "ACPI\INT344B" = @{ Name = "Intel Serial IO GPIO Host Controller"; Category = $script:RuleCategoryChipset; Vendor = "Intel"; Source = "ACPI ID INT344B" }
    "ACPI\INT33D5" = @{ Name = "Intel Serial IO I2C Host Controller"; Category = $script:RuleCategoryChipset; Vendor = "Intel"; Source = "ACPI ID INT33D5" }
    "ACPI\INT33D6" = @{ Name = "Intel Serial IO I2C Host Controller"; Category = $script:RuleCategoryChipset; Vendor = "Intel"; Source = "ACPI ID INT33D6" }
    "ACPI\INT33D7" = @{ Name = "Intel Serial IO SPI Host Controller"; Category = $script:RuleCategoryChipset; Vendor = "Intel"; Source = "ACPI ID INT33D7" }
    "ACPI\INT33A0" = @{ Name = "Intel Smart Connect Technology"; Category = $script:RuleCategoryChipset; Vendor = "Intel"; Source = "ACPI ID INT33A0" }
    "ACPI\INT3F0D" = @{ Name = "Intel Smart Sound Technology OED"; Category = $script:RuleCategoryAudio; Vendor = "Intel"; Source = "ACPI ID INT3F0D" }
    "ACPI\INTC1040" = @{ Name = "Intel Dynamic Tuning Technology"; Category = $script:RuleCategoryChipset; Vendor = "Intel"; Source = "ACPI ID INTC1040" }
    "ACPI\PNP0C50" = @{ Name = "I2C HID Device"; Category = $script:RuleCategoryInput; Vendor = $script:RuleUnknown; Source = "ACPI ID PNP0C50" }
    "ACPI\ELAN" = @{ Name = "ELAN Input Device"; Category = $script:RuleCategoryInput; Vendor = "ELAN"; Source = "ACPI ID ELAN" }
    "ACPI\SYN" = @{ Name = "Synaptics Input Device"; Category = $script:RuleCategoryInput; Vendor = "Synaptics"; Source = "ACPI ID SYN" }
    "ACPI\VEN_ELAN" = @{ Name = "ELAN Input Device"; Category = $script:RuleCategoryInput; Vendor = "ELAN"; Source = "ACPI Vendor ELAN" }
    "ACPI\VEN_SYN" = @{ Name = "Synaptics Input Device"; Category = $script:RuleCategoryInput; Vendor = "Synaptics"; Source = "ACPI Vendor SYN" }
    "ACPI\HPQ6001" = @{ Name = "HP Wireless Button Driver"; Category = $script:RuleCategoryInput; Vendor = "HP"; Source = "ACPI ID HPQ6001" }
    "ACPI\HPQ6007" = @{ Name = "HP Hotkey Support"; Category = $script:RuleCategoryInput; Vendor = "HP"; Source = "ACPI ID HPQ6007" }
    "ACPI\MSFT0101" = @{ Name = "TPM 2.0 Device"; Category = $script:RuleCategoryChipset; Vendor = "Microsoft"; Source = "ACPI ID MSFT0101" }
    "ACPI\IFX0102" = @{ Name = "Infineon TPM Device"; Category = $script:RuleCategoryChipset; Vendor = "Infineon"; Source = "ACPI ID IFX0102" }
}

$script:PciDeviceGuessPatterns = @(
    @{ Pattern = "VEN_8086&DEV_9D3A"; Name = "Intel Management Engine Interface"; Category = $script:RuleCategoryChipset; Vendor = "Intel"; Source = "PCI Device ID 9D3A" },
    @{ Pattern = "VEN_8086&DEV_1C3A"; Name = "Intel Management Engine Interface"; Category = $script:RuleCategoryChipset; Vendor = "Intel"; Source = "PCI Device ID 1C3A" },
    @{ Pattern = "VEN_8086&DEV_9D60"; Name = "Intel Serial IO I2C Host Controller"; Category = $script:RuleCategoryChipset; Vendor = "Intel"; Source = "PCI Device ID 9D60" },
    @{ Pattern = "VEN_8086&DEV_9D61"; Name = "Intel Serial IO I2C Host Controller"; Category = $script:RuleCategoryChipset; Vendor = "Intel"; Source = "PCI Device ID 9D61" },
    @{ Pattern = "VEN_8086&DEV_9D62"; Name = "Intel Serial IO UART Host Controller"; Category = $script:RuleCategoryChipset; Vendor = "Intel"; Source = "PCI Device ID 9D62" },
    @{ Pattern = "VEN_8086&DEV_9D64"; Name = "Intel Serial IO SPI Host Controller"; Category = $script:RuleCategoryChipset; Vendor = "Intel"; Source = "PCI Device ID 9D64" },
    @{ Pattern = "VEN_10EC&DEV_522A"; Name = "Realtek PCIe Card Reader"; Category = $script:RuleCategoryCardReader; Vendor = "Realtek"; Source = "PCI Device ID 522A" },
    @{ Pattern = "VEN_10EC&DEV_5227"; Name = "Realtek PCIe Card Reader"; Category = $script:RuleCategoryCardReader; Vendor = "Realtek"; Source = "PCI Device ID 5227" },
    @{ Pattern = "VEN_10EC&DEV_8168"; Name = "Realtek PCIe GbE Family Controller"; Category = $script:RuleCategoryNetwork; Vendor = "Realtek"; Source = "PCI Device ID 8168" },
    @{ Pattern = "VEN_10EC&DEV_0280"; Name = "Realtek High Definition Audio"; Category = $script:RuleCategoryAudio; Vendor = "Realtek"; Source = "PCI/HDAUDIO Device ID 0280" },
    @{ Pattern = "VEN_168C"; Name = "Qualcomm Atheros Wireless Adapter"; Category = $script:RuleCategoryNetwork; Vendor = "Qualcomm Atheros"; Source = "PCI Vendor ID 168C" },
    @{ Pattern = "VEN_14E4"; Name = "Broadcom Network Adapter"; Category = $script:RuleCategoryNetwork; Vendor = "Broadcom"; Source = "PCI Vendor ID 14E4" }
)

$script:UsbDeviceGuessPatterns = @(
    @{ Pattern = "VID_8087&PID_0A2A"; Name = "Intel Wireless Bluetooth"; Category = $script:RuleCategoryBluetooth; Vendor = "Intel"; Source = "USB Device ID 0A2A" },
    @{ Pattern = "VID_8087&PID_0A2B"; Name = "Intel Wireless Bluetooth"; Category = $script:RuleCategoryBluetooth; Vendor = "Intel"; Source = "USB Device ID 0A2B" },
    @{ Pattern = "VID_0BDA"; Name = "Realtek USB Device"; Category = $script:RuleCategoryOther; Vendor = "Realtek"; Source = "USB Vendor ID 0BDA" },
    @{ Pattern = "VID_27C6"; Name = "Goodix Fingerprint Device"; Category = $script:RuleCategoryFingerprint; Vendor = "Goodix"; Source = "USB Vendor ID 27C6" }
)

$script:HdAudioGuessPatterns = @(
    @{ Pattern = "VEN_10EC"; Name = "Realtek High Definition Audio"; Category = $script:RuleCategoryAudio; Vendor = "Realtek"; Source = "HDAUDIO Vendor ID 10EC" },
    @{ Pattern = "VEN_8086"; Name = "Intel Display Audio"; Category = $script:RuleCategoryAudio; Vendor = "Intel"; Source = "HDAUDIO Vendor ID 8086" },
    @{ Pattern = "VEN_10DE"; Name = "NVIDIA HD Audio"; Category = $script:RuleCategoryAudio; Vendor = "NVIDIA"; Source = "HDAUDIO Vendor ID 10DE" },
    @{ Pattern = "VEN_1002"; Name = "AMD High Definition Audio"; Category = $script:RuleCategoryAudio; Vendor = "AMD"; Source = "HDAUDIO Vendor ID 1002" }
)
