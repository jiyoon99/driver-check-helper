function Get-SafeText {
    param(
        [AllowNull()]
        [object]$Value,
        [string]$Default = ""
    )

    if ($null -eq $Value) {
        return $Default
    }

    $text = "$Value".Trim()
    if ([string]::IsNullOrWhiteSpace($text)) {
        return $Default
    }

    return $text
}

function Test-IsAdministrator {
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        return $false
    }
}

function ConvertTo-HtmlEncodedText {
    param(
        [AllowNull()]
        [object]$Value
    )

    $text = Get-SafeText -Value $Value
    return [System.Net.WebUtility]::HtmlEncode($text)
}

function Get-ManufacturerMatchKey {
    param(
        [AllowNull()]
        [object[]]$Values
    )

    $parts = @($Values | ForEach-Object { Get-SafeText -Value $_ } | Where-Object { $_ })
    if ($parts.Count -eq 0) {
        return ""
    }

    return (($parts -join " ").ToLowerInvariant())
}

function Resolve-ManufacturerCanonicalName {
    param(
        [AllowNull()]
        [object]$Manufacturer,
        [AllowNull()]
        [object]$Model,
        [AllowNull()]
        [object]$SystemFamily
    )

    $matchKey = Get-ManufacturerMatchKey @($Manufacturer, $Model, $SystemFamily)
    if (-not $matchKey) {
        return ""
    }

    switch -Regex ($matchKey) {
        "dell|alienware" { return "Dell" }
        "hewlett-packard|hp\b|omen|victus|probook|elitebook|zbook|pavilion" { return "HP" }
        "lenovo|thinkpad|thinkbook|ideapad|legion|yoga" { return "Lenovo" }
        "asus|asustek|rog|vivobook|zenbook|expertbook|tuf" { return "ASUS" }
        "acer|gateway|packard bell|travelmate|swift|aspire|nitro|predator" { return "Acer" }
        "msi|micro-star|modern |prestige|stealth|katana|thin gf|creator" { return "MSI" }
        "samsung|galaxy\s?book|book[1-9]|nt[0-9]|np[0-9]|notebook\s?9|pen\s?s|odyssey" { return "Samsung" }
        "^lg\b|lg electronics|gram|ultrapc|14z|15z|16z|17z|13u|14u|15u|16u|17u" { return "LG" }
        "microsoft|surface" { return "Microsoft Surface" }
        "huawei|matebook|honor magicbook|magicbook" { return "Huawei / HONOR" }
        "gigabyte|aorus" { return "Gigabyte / AORUS" }
        "razer|blade" { return "Razer" }
        "fujitsu|lifebook" { return "Fujitsu" }
        "dynabook|toshiba|portege|tecra|satellite" { return "Dynabook / Toshiba" }
        "vaio" { return "VAIO" }
        "xiaomi|redmibook|redmi book|mi notebook" { return "Xiaomi / Redmi" }
        "clevo|sager|tongfang|xmg|schenker" { return "Clevo / Tongfang OEM" }
        default { return (Get-SafeText -Value $Manufacturer) }
    }
}

function Resolve-ManufacturerSublineInfo {
    param(
        [AllowNull()]
        [object]$Manufacturer,
        [AllowNull()]
        [object]$Model,
        [AllowNull()]
        [object]$SystemFamily
    )

    $canonicalManufacturer = Resolve-ManufacturerCanonicalName -Manufacturer $Manufacturer -Model $Model -SystemFamily $SystemFamily
    $matchKey = Get-ManufacturerMatchKey @($canonicalManufacturer, $Model, $SystemFamily)

    $sublineName = ""
    $source = ""

    switch ($canonicalManufacturer) {
        "Samsung" {
            switch -Regex ($matchKey) {
                "galaxy\s?book" { $sublineName = "Galaxy Book"; $source = "Model keyword: Galaxy Book"; break }
                "book[1-9]" { $sublineName = "Galaxy Book"; $source = "Model keyword: Book generation"; break }
                "notebook\s?9" { $sublineName = "Notebook 9"; $source = "Model keyword: Notebook 9"; break }
                "odyssey" { $sublineName = "Odyssey"; $source = "Model keyword: Odyssey"; break }
                "pen\s?s" { $sublineName = "Pen S"; $source = "Model keyword: Pen S"; break }
            }
        }
        "LG" {
            switch -Regex ($matchKey) {
                "gram" { $sublineName = "gram"; $source = "Model keyword: gram"; break }
                "ultrapc" { $sublineName = "UltraPC"; $source = "Model keyword: UltraPC"; break }
            }
        }
        "Lenovo" {
            switch -Regex ($matchKey) {
                "thinkpad" { $sublineName = "ThinkPad"; $source = "Model keyword: ThinkPad"; break }
                "thinkbook" { $sublineName = "ThinkBook"; $source = "Model keyword: ThinkBook"; break }
                "ideapad" { $sublineName = "IdeaPad"; $source = "Model keyword: IdeaPad"; break }
                "legion" { $sublineName = "Legion"; $source = "Model keyword: Legion"; break }
                "yoga" { $sublineName = "Yoga"; $source = "Model keyword: Yoga"; break }
            }
        }
        "ASUS" {
            switch -Regex ($matchKey) {
                "\brog\b" { $sublineName = "ROG"; $source = "Model keyword: ROG"; break }
                "tuf" { $sublineName = "TUF"; $source = "Model keyword: TUF"; break }
                "zenbook" { $sublineName = "Zenbook"; $source = "Model keyword: Zenbook"; break }
                "vivobook" { $sublineName = "Vivobook"; $source = "Model keyword: Vivobook"; break }
                "expertbook" { $sublineName = "ExpertBook"; $source = "Model keyword: ExpertBook"; break }
            }
        }
        "HP" {
            switch -Regex ($matchKey) {
                "elitebook" { $sublineName = "EliteBook"; $source = "Model keyword: EliteBook"; break }
                "probook" { $sublineName = "ProBook"; $source = "Model keyword: ProBook"; break }
                "omen" { $sublineName = "OMEN"; $source = "Model keyword: OMEN"; break }
                "victus" { $sublineName = "Victus"; $source = "Model keyword: Victus"; break }
                "zbook" { $sublineName = "ZBook"; $source = "Model keyword: ZBook"; break }
                "pavilion" { $sublineName = "Pavilion"; $source = "Model keyword: Pavilion"; break }
            }
        }
        "Dell" {
            switch -Regex ($matchKey) {
                "latitude" { $sublineName = "Latitude"; $source = "Model keyword: Latitude"; break }
                "precision" { $sublineName = "Precision"; $source = "Model keyword: Precision"; break }
                "xps" { $sublineName = "XPS"; $source = "Model keyword: XPS"; break }
                "inspiron" { $sublineName = "Inspiron"; $source = "Model keyword: Inspiron"; break }
                "vostro" { $sublineName = "Vostro"; $source = "Model keyword: Vostro"; break }
                "alienware" { $sublineName = "Alienware"; $source = "Model keyword: Alienware"; break }
            }
        }
        "Acer" {
            switch -Regex ($matchKey) {
                "swift" { $sublineName = "Swift"; $source = "Model keyword: Swift"; break }
                "aspire" { $sublineName = "Aspire"; $source = "Model keyword: Aspire"; break }
                "nitro" { $sublineName = "Nitro"; $source = "Model keyword: Nitro"; break }
                "predator" { $sublineName = "Predator"; $source = "Model keyword: Predator"; break }
                "travelmate" { $sublineName = "TravelMate"; $source = "Model keyword: TravelMate"; break }
            }
        }
        "MSI" {
            switch -Regex ($matchKey) {
                "prestige" { $sublineName = "Prestige"; $source = "Model keyword: Prestige"; break }
                "modern" { $sublineName = "Modern"; $source = "Model keyword: Modern"; break }
                "stealth" { $sublineName = "Stealth"; $source = "Model keyword: Stealth"; break }
                "katana" { $sublineName = "Katana"; $source = "Model keyword: Katana"; break }
                "creator" { $sublineName = "Creator"; $source = "Model keyword: Creator"; break }
            }
        }
    }

    return [PSCustomObject]@{
        Manufacturer = $canonicalManufacturer
        Name         = $sublineName
        Source       = $source
    }
}
