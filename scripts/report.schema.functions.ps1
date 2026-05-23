function Test-ObjectHasProperty {
    param(
        [AllowNull()]
        [object]$InputObject,
        [Parameter(Mandatory = $true)]
        [string]$PropertyName
    )

    if ($null -eq $InputObject) {
        return $false
    }

    return $null -ne $InputObject.PSObject.Properties[$PropertyName]
}

function Assert-ReportSchema {
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$Report
    )

    $requiredRootProperties = @(
        "SchemaVersion",
        "GeneratedAt",
        "IsPreflight",
        "Preflight",
        "ComputerProfile",
        "SupportResources",
        "AllDevices",
        "ProblemDevices"
    )

    foreach ($propertyName in $requiredRootProperties) {
        if (-not (Test-ObjectHasProperty -InputObject $Report -PropertyName $propertyName)) {
            throw "리포트 필수 필드가 없습니다: $propertyName"
        }
    }

    $requiredPreflightProperties = @(
        "IsAdministrator",
        "CanAccessCim",
        "CanWriteReportDirectory",
        "Message"
    )

    foreach ($propertyName in $requiredPreflightProperties) {
        if (-not (Test-ObjectHasProperty -InputObject $Report.Preflight -PropertyName $propertyName)) {
            throw "Preflight 필수 필드가 없습니다: $propertyName"
        }
    }

    $requiredComputerProfileProperties = @(
        "Manufacturer",
        "Model",
        "SystemFamily",
        "DriverTargetOS"
    )

    foreach ($propertyName in $requiredComputerProfileProperties) {
        if (-not (Test-ObjectHasProperty -InputObject $Report.ComputerProfile -PropertyName $propertyName)) {
            throw "ComputerProfile 필수 필드가 없습니다: $propertyName"
        }
    }

    foreach ($device in @($Report.AllDevices)) {
        foreach ($propertyName in @(
            "Name",
            "InferredName",
            "Category",
            "Manufacturer",
            "ComponentVendor",
            "PriorityScore",
            "PriorityLevel",
            "PriorityReason",
            "NextAction",
            "ProblemGroup",
            "DriverPackageCandidates",
            "Recommendations"
        )) {
            if (-not (Test-ObjectHasProperty -InputObject $device -PropertyName $propertyName)) {
                throw "Device 필수 필드가 없습니다: $propertyName"
            }
        }
    }
}
