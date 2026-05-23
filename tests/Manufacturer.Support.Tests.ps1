$projectRoot = Split-Path -Parent $PSScriptRoot

. (Join-Path $projectRoot "scripts\common.functions.ps1")
. (Join-Path $projectRoot "scripts\main.system.functions.ps1")
. (Join-Path $projectRoot "scripts\gui.search.functions.ps1")

function New-Text {
    param([int[]]$Codes)

    return -join ($Codes | ForEach-Object { [char]$_ })
}

Describe "Resolve-ManufacturerCanonicalName" {
    It "normalizes major OEM aliases to a canonical name" {
        (Resolve-ManufacturerCanonicalName -Manufacturer "ASUSTeK COMPUTER INC." -Model "Zenbook 14" -SystemFamily "Laptop") | Should Be "ASUS"
        (Resolve-ManufacturerCanonicalName -Manufacturer "Hewlett-Packard" -Model "HP ProBook 450 G8" -SystemFamily "Notebook") | Should Be "HP"
        (Resolve-ManufacturerCanonicalName -Manufacturer "Micro-Star International Co., Ltd." -Model "Prestige 14" -SystemFamily "Notebook") | Should Be "MSI"
        (Resolve-ManufacturerCanonicalName -Manufacturer "SAMSUNG ELECTRONICS CO., LTD." -Model "Galaxy Book4 Pro" -SystemFamily "Notebook") | Should Be "Samsung"
        (Resolve-ManufacturerCanonicalName -Manufacturer "" -Model "NT950XGK-KC51G" -SystemFamily "Notebook") | Should Be "Samsung"
        (Resolve-ManufacturerCanonicalName -Manufacturer "LG Electronics" -Model "LG gram 16" -SystemFamily "Notebook") | Should Be "LG"
        (Resolve-ManufacturerCanonicalName -Manufacturer "" -Model "16U70R-GA56K" -SystemFamily "Notebook") | Should Be "LG"
        (Resolve-ManufacturerCanonicalName -Manufacturer "Microsoft Corporation" -Model "Surface Laptop 6" -SystemFamily "Laptop") | Should Be "Microsoft Surface"
        (Resolve-ManufacturerCanonicalName -Manufacturer "HUAWEI" -Model "MateBook X Pro" -SystemFamily "Notebook") | Should Be "Huawei / HONOR"
        (Resolve-ManufacturerCanonicalName -Manufacturer "HONOR" -Model "MagicBook 14" -SystemFamily "Notebook") | Should Be "Huawei / HONOR"
        (Resolve-ManufacturerCanonicalName -Manufacturer "GIGABYTE" -Model "AORUS 15" -SystemFamily "Notebook") | Should Be "Gigabyte / AORUS"
        (Resolve-ManufacturerCanonicalName -Manufacturer "Razer" -Model "Blade 15" -SystemFamily "Notebook") | Should Be "Razer"
        (Resolve-ManufacturerCanonicalName -Manufacturer "FUJITSU" -Model "LIFEBOOK U9311" -SystemFamily "Notebook") | Should Be "Fujitsu"
        (Resolve-ManufacturerCanonicalName -Manufacturer "TOSHIBA" -Model "Portégé X30" -SystemFamily "Notebook") | Should Be "Dynabook / Toshiba"
        (Resolve-ManufacturerCanonicalName -Manufacturer "VAIO Corporation" -Model "VAIO SX14" -SystemFamily "Notebook") | Should Be "VAIO"
        (Resolve-ManufacturerCanonicalName -Manufacturer "Xiaomi" -Model "RedmiBook Pro 14" -SystemFamily "Notebook") | Should Be "Xiaomi / Redmi"
        (Resolve-ManufacturerCanonicalName -Manufacturer "CLEVO" -Model "NH55" -SystemFamily "Notebook") | Should Be "Clevo / Tongfang OEM"
    }
}

Describe "Resolve-ManufacturerSublineInfo" {
    It "detects important notebook sublines from model context" {
        (Resolve-ManufacturerSublineInfo -Manufacturer "SAMSUNG ELECTRONICS CO., LTD." -Model "Galaxy Book4 Pro" -SystemFamily "Notebook").Name | Should Be "Galaxy Book"
        (Resolve-ManufacturerSublineInfo -Manufacturer "LG Electronics" -Model "LG gram 16" -SystemFamily "Notebook").Name | Should Be "gram"
        (Resolve-ManufacturerSublineInfo -Manufacturer "Lenovo" -Model "ThinkPad T14 Gen 5" -SystemFamily "Notebook").Name | Should Be "ThinkPad"
        (Resolve-ManufacturerSublineInfo -Manufacturer "ASUSTeK COMPUTER INC." -Model "ROG Zephyrus G14" -SystemFamily "Notebook").Name | Should Be "ROG"
        (Resolve-ManufacturerSublineInfo -Manufacturer "HP" -Model "EliteBook 840 G10" -SystemFamily "Notebook").Name | Should Be "EliteBook"
        (Resolve-ManufacturerSublineInfo -Manufacturer "Dell Inc." -Model "Latitude 7420" -SystemFamily "Notebook").Name | Should Be "Latitude"
    }
}

Describe "Resolve-SupportResources" {
    It "returns ASUS links even when the OEM string is ASUSTeK" {
        $profile = [pscustomobject]@{
            Manufacturer = "ASUSTeK COMPUTER INC."
            Model = "Zenbook UX3402"
            SystemFamily = "Notebook"
            SerialNumber = ""
            ManufacturerIds = [pscustomobject]@{
                ServiceTag = ""
                MTM = ""
                ProductNumber = ""
                SystemSKU = ""
                ProductVersion = ""
            }
        }

        $resources = @(Resolve-SupportResources -ComputerProfile $profile)

        @($resources).Count | Should BeGreaterThan 0
        $resources[0].Label | Should Match "ASUS"
    }

    It "returns Surface support resources for Surface-branded devices" {
        $profile = [pscustomobject]@{
            Manufacturer = "Microsoft Corporation"
            Model = "Surface Laptop 6"
            SystemFamily = "Laptop"
            SerialNumber = ""
            ManufacturerIds = [pscustomobject]@{
                ServiceTag = ""
                MTM = ""
                ProductNumber = ""
                SystemSKU = ""
                ProductVersion = ""
            }
        }

        $resources = @(Resolve-SupportResources -ComputerProfile $profile)

        @($resources).Count | Should BeGreaterThan 0
        $resources[0].Url | Should Match "support.microsoft.com"
    }

    It "returns Samsung support resources for Galaxy Book model names" {
        $profile = [pscustomobject]@{
            Manufacturer = "SAMSUNG ELECTRONICS CO., LTD."
            Model = "NT950XGK-KC51G"
            SystemFamily = "Notebook"
            SerialNumber = ""
            ManufacturerIds = [pscustomobject]@{
                ServiceTag = ""
                MTM = ""
                ProductNumber = ""
                SystemSKU = ""
                ProductVersion = ""
            }
        }

        $resources = @(Resolve-SupportResources -ComputerProfile $profile)

        @($resources).Count | Should BeGreaterThan 0
        ($resources | Where-Object { $_.Label -match "Samsung" }).Count | Should BeGreaterThan 0
    }

    It "returns LG support resources for gram and UltraPC model names" {
        $profile = [pscustomobject]@{
            Manufacturer = "LG Electronics"
            Model = "16U70R-GA56K"
            SystemFamily = "Notebook"
            SerialNumber = ""
            ManufacturerIds = [pscustomobject]@{
                ServiceTag = ""
                MTM = ""
                ProductNumber = ""
                SystemSKU = ""
                ProductVersion = ""
            }
        }

        $resources = @(Resolve-SupportResources -ComputerProfile $profile)

        @($resources).Count | Should BeGreaterThan 0
        ($resources | Where-Object { $_.Label -match "LG" }).Count | Should BeGreaterThan 0
    }

    It "returns support resources for expanded OEM families" {
        $profiles = @(
            [pscustomobject]@{ Manufacturer = "HUAWEI"; Model = "MateBook X Pro"; SystemFamily = "Notebook" },
            [pscustomobject]@{ Manufacturer = "GIGABYTE"; Model = "AORUS 15"; SystemFamily = "Notebook" },
            [pscustomobject]@{ Manufacturer = "Razer"; Model = "Blade 15"; SystemFamily = "Notebook" },
            [pscustomobject]@{ Manufacturer = "FUJITSU"; Model = "LIFEBOOK U9311"; SystemFamily = "Notebook" },
            [pscustomobject]@{ Manufacturer = "TOSHIBA"; Model = "Portégé X30"; SystemFamily = "Notebook" },
            [pscustomobject]@{ Manufacturer = "VAIO Corporation"; Model = "VAIO SX14"; SystemFamily = "Notebook" },
            [pscustomobject]@{ Manufacturer = "Xiaomi"; Model = "RedmiBook Pro 14"; SystemFamily = "Notebook" },
            [pscustomobject]@{ Manufacturer = "CLEVO"; Model = "NH55"; SystemFamily = "Notebook" }
        )

        foreach ($profileSeed in $profiles) {
            $profile = [pscustomobject]@{
                Manufacturer = $profileSeed.Manufacturer
                Model = $profileSeed.Model
                SystemFamily = $profileSeed.SystemFamily
                SerialNumber = ""
                ManufacturerIds = [pscustomobject]@{
                    ServiceTag = ""
                    MTM = ""
                    ProductNumber = ""
                    SystemSKU = ""
                    ProductVersion = ""
                }
            }

            $resources = @(Resolve-SupportResources -ComputerProfile $profile)
            @($resources).Count | Should BeGreaterThan 0
        }
    }
}

Describe "GUI manufacturer-aware support lookups" {
    BeforeEach {
        $script:CurrentReport = [pscustomobject]@{
            ComputerProfile = [pscustomobject]@{
                Manufacturer = "ASUSTeK COMPUTER INC."
                Model = "Zenbook UX3402"
                SystemFamily = "Notebook"
                DriverTargetOS = "Windows 11 x64"
            }
            SupportResources = @()
            PrimarySupportLink = [pscustomobject]@{
                Label = "ASUS Support"
                Url = "https://www.asus.com/kr/support/"
            }
        }
    }

    It "uses the ASUS support domain for site search" {
        (Get-ManufacturerSearchDomain) | Should Be "asus.com"
    }

    It "returns a manufacturer utility link for ASUS aliases" {
        $utility = Get-ManufacturerUtilityLink

        $utility.Label | Should Be "MyASUS"
    }
}

Describe "Samsung and LG search helpers" {
    It "uses Samsung support domain and keywords for Samsung aliases" {
        $script:CurrentReport = [pscustomobject]@{
            ComputerProfile = [pscustomobject]@{
                Manufacturer = "SAMSUNG ELECTRONICS CO., LTD."
                Model = "Galaxy Book4 Pro"
                SystemFamily = "Notebook"
                DriverTargetOS = "Windows 11 x64"
            }
            SupportResources = @()
            PrimarySupportLink = $null
        }

        $device = [pscustomobject]@{ Category = (New-Text @(0xB124, 0xD2B8, 0xC6CC, 0xD06C)); ComponentVendor = "Intel" }

        (Get-ManufacturerSearchDomain) | Should Be "samsung.com"
        (Get-ManufacturerCategoryKeywords -Device $device) | Should Match "galaxy book"
        (Get-ManufacturerCategoryDirectLink -Device $device).Label | Should Match "Samsung"
        (Get-ManufacturerUtilityLink).Label | Should Match "Samsung"
    }

    It "uses LG support domain and keywords for gram and UltraPC aliases" {
        $script:CurrentReport = [pscustomobject]@{
            ComputerProfile = [pscustomobject]@{
                Manufacturer = "LG Electronics"
                Model = "16U70R-GA56K"
                SystemFamily = "Notebook"
                DriverTargetOS = "Windows 11 x64"
            }
            SupportResources = @()
            PrimarySupportLink = $null
        }

        $device = [pscustomobject]@{ Category = (New-Text @(0xC785, 0xB825, 0xC7A5, 0xCE58)); ComponentVendor = "Synaptics" }

        (Get-ManufacturerSearchDomain) | Should Be "lge.co.kr"
        (Get-ManufacturerCategoryKeywords -Device $device) | Should Match "lg gram"
        (Get-ManufacturerCategoryDirectLink -Device $device).Label | Should Match "LG"
    }
}

Describe "Subline-aware search helpers" {
    It "adds ThinkPad-specific input keywords" {
        $script:CurrentReport = [pscustomobject]@{
            ComputerProfile = [pscustomobject]@{
                Manufacturer = "Lenovo"
                Subline = "ThinkPad"
                Model = "ThinkPad T14 Gen 5"
                SystemFamily = "Notebook"
                DriverTargetOS = "Windows 11 x64"
            }
            SupportResources = @()
            PrimarySupportLink = $null
        }

        $device = [pscustomobject]@{ Category = (New-Text @(0xC785, 0xB825, 0xC7A5, 0xCE58)); ComponentVendor = "Synaptics" }

        (Get-ManufacturerCategoryKeywords -Device $device) | Should Match "thinkpad"
        (@(Get-SystemSearchTerms -Device $device) -join " ") | Should Match "ThinkPad"
    }

    It "adds ROG-specific graphics keywords" {
        $script:CurrentReport = [pscustomobject]@{
            ComputerProfile = [pscustomobject]@{
                Manufacturer = "ASUSTeK COMPUTER INC."
                Subline = "ROG"
                Model = "ROG Zephyrus G14"
                SystemFamily = "Notebook"
                DriverTargetOS = "Windows 11 x64"
            }
            SupportResources = @()
            PrimarySupportLink = $null
        }

        $device = [pscustomobject]@{ Category = (New-Text @(0xADF8, 0xB798, 0xD53D)); ComponentVendor = "NVIDIA" }

        (Get-ManufacturerCategoryKeywords -Device $device) | Should Match "rog"
        (Test-PreferComponentVendorSearch -Device $device) | Should Be $true
    }
}

Describe "Expanded OEM search helpers" {
    It "returns branded support domains for newly added OEMs" {
        $cases = @(
            [pscustomobject]@{ Manufacturer = "HUAWEI"; Model = "MateBook X Pro"; Expected = "consumer.huawei.com" },
            [pscustomobject]@{ Manufacturer = "GIGABYTE"; Model = "AORUS 15"; Expected = "gigabyte.com" },
            [pscustomobject]@{ Manufacturer = "Razer"; Model = "Blade 15"; Expected = "razer.com" },
            [pscustomobject]@{ Manufacturer = "FUJITSU"; Model = "LIFEBOOK U9311"; Expected = "fujitsu.com" },
            [pscustomobject]@{ Manufacturer = "TOSHIBA"; Model = "Portégé X30"; Expected = "support.dynabook.com" },
            [pscustomobject]@{ Manufacturer = "VAIO Corporation"; Model = "VAIO SX14"; Expected = "vaio.com" },
            [pscustomobject]@{ Manufacturer = "Xiaomi"; Model = "RedmiBook Pro 14"; Expected = "mi.com" }
        )

        foreach ($case in $cases) {
            $script:CurrentReport = [pscustomobject]@{
                ComputerProfile = [pscustomobject]@{
                    Manufacturer = $case.Manufacturer
                    Model = $case.Model
                    SystemFamily = "Notebook"
                    DriverTargetOS = "Windows 11 x64"
                }
                SupportResources = @()
                PrimarySupportLink = $null
            }

            (Get-ManufacturerSearchDomain) | Should Be $case.Expected
            (Get-ManufacturerCategoryDirectLink -Device ([pscustomobject]@{ Category = "기타" })).Url | Should Match ".+"
            (Get-ManufacturerUtilityLink).Url | Should Match ".+"
        }
    }
}
