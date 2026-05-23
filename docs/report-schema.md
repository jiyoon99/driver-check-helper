# Report Schema

이 문서는 `main.ps1`가 생성하고 GUI가 읽는 JSON 리포트 계약을 정리합니다.

## Root Object

최상위 객체는 아래 필드를 가집니다.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `SchemaVersion` | number | yes | 현재 GUI 기준 최소 버전은 `4` |
| `GeneratedAt` | string | yes | ISO 유사 시각 문자열, 예: `2026-04-11T21:00:00` |
| `LogPath` | string\|null | no | 실행 로그 파일 경로 |
| `AutoOpenSupport` | boolean | yes | 자동 열기 옵션 |
| `AutoOpenCatalog` | boolean | yes | 자동 열기 옵션 |
| `IsPreflight` | boolean | yes | 사전 점검 모드 여부 |
| `Preflight` | object | yes | 사전 점검 결과 |
| `ComputerProfile` | object | yes | 시스템 정보 |
| `SupportResources` | array | yes | 제조사 지원 링크 목록 |
| `PrimarySupportLink` | object\|null | no | 가장 우선인 지원 링크 |
| `Summary` | object\|null | no | 전체 요약 |
| `AllDevices` | array | yes | 전체 장치 분석 결과 |
| `ProblemDevices` | array | yes | 문제 장치만 필터링한 결과 |

## Preflight

`Preflight` 객체는 아래 필드를 가집니다.

| Field | Type | Required |
| --- | --- | --- |
| `IsAdministrator` | boolean | yes |
| `CanAccessCim` | boolean | yes |
| `CanWriteReportDirectory` | boolean | yes |
| `MainScriptExists` | boolean | yes |
| `GuiScriptExists` | boolean | yes |
| `ScriptsDirectoryExists` | boolean | yes |
| `ReportDirectory` | string | yes |
| `ScriptsDirectory` | string | yes |
| `ReportDirectoryMessage` | string | yes |
| `CimMessage` | string | yes |
| `Message` | string | yes |

## ComputerProfile

`ComputerProfile` 객체는 아래 필드를 가집니다.

| Field | Type | Required |
| --- | --- | --- |
| `Manufacturer` | string | yes |
| `Subline` | string | no |
| `SublineSource` | string | no |
| `Model` | string | yes |
| `SystemFamily` | string | yes |
| `BIOSVersion` | string | yes |
| `SerialNumber` | string | yes |
| `BoardProduct` | string | yes |
| `OperatingSystem` | string | yes |
| `OSArchitecture` | string | yes |
| `DriverTargetOS` | string | yes |
| `ManufacturerIds` | object | yes |

`ManufacturerIds` 하위 필드:

| Field | Type | Required |
| --- | --- | --- |
| `ServiceTag` | string | yes |
| `MTM` | string | yes |
| `ProductNumber` | string | yes |
| `SystemSKU` | string | yes |
| `ProductVersion` | string | yes |

## Link Object

지원 링크, 추천 링크 등은 대체로 같은 형태를 씁니다.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `Label` | string | yes | 표시명 |
| `Url` | string | yes | 이동 URL |
| `Kind` | string | no | 지원 리소스에서 주로 사용 |

## Summary

`Summary` 객체는 아래 필드를 가집니다.

| Field | Type | Required |
| --- | --- | --- |
| `ProblemCount` | number | yes |
| `TopPriority` | object\|null | no |
| `TopProblems` | array | yes |
| `ProblemGroups` | array | yes |
| `InstallOrder` | array | yes |
| `BeginnerTips` | array | yes |
| `HealthyDevices` | number | yes |

### ProblemGroups Item

| Field | Type | Required |
| --- | --- | --- |
| `Name` | string | yes |
| `Count` | number | yes |
| `TopDeviceName` | string | yes |
| `PriorityLevel` | string | yes |
| `Reason` | string | yes |
| `NextAction` | string | yes |

## Device Object

`AllDevices` 와 `ProblemDevices` 의 각 항목은 아래 구조를 가집니다.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `Name` | string | yes | 원본 장치명 |
| `InferredName` | string | yes | 추정 후 장치명 |
| `PNPClass` | string | yes | PnP 클래스 |
| `Category` | string | yes | GUI 필터와 요약에서 사용 |
| `Manufacturer` | string | yes | 보고된 제조사 |
| `Service` | string | yes | PnP 서비스명 |
| `DeviceID` | string | yes | 장치 식별자 |
| `Status` | string | yes | 장치 상태 |
| `ConfigManagerErrorCode` | number | yes | 오류 코드 |
| `IsProblemDevice` | boolean | yes | 문제 장치 여부 |
| `HardwareIds` | array | yes | 전체 Hardware ID |
| `PrimaryHardwareId` | string\|null | no | 대표 Hardware ID |
| `IdAnalysis` | object | yes | Hardware ID 파싱 결과 |
| `ComponentVendor` | string | yes | 추정 칩셋 제조사 |
| `VendorInferenceSource` | string | yes | 제조사 추정 근거 |
| `DeviceInferenceSource` | string | yes | 장치 추정 근거 |
| `PriorityScore` | number | yes | 정렬과 요약에 사용 |
| `PriorityLevel` | string | yes | 예: `최우선`, `높음`, `보통`, `낮음` |
| `PriorityReason` | string | yes | 우선 이유 |
| `NextAction` | string | yes | 다음 행동 |
| `ProblemGroup` | string | yes | GUI 묶음 필터에 사용 |
| `DriverPackageCandidates` | array | yes | 검색 후보 |
| `UpdateCatalogUrl` | string\|null | no | Microsoft Update Catalog URL |
| `ComponentLinks` | array | yes | 칩셋 제조사 링크 |
| `Recommendations` | array | yes | 사용자 안내 순서 |

### IdAnalysis

| Field | Type | Required |
| --- | --- | --- |
| `BusType` | string\|null | no |
| `VendorId` | string\|null | no |
| `DeviceId` | string\|null | no |
| `SubsystemId` | string\|null | no |
| `Revision` | string\|null | no |

### DriverPackageCandidates Item

| Field | Type | Required |
| --- | --- | --- |
| `Name` | string | yes |
| `Priority` | number | yes |
| `Query` | string | yes |

### Recommendations Item

| Field | Type | Required |
| --- | --- | --- |
| `Priority` | number | yes |
| `Title` | string | yes |
| `Detail` | string | yes |
| `Links` | array | yes |

## Compatibility Notes

- GUI는 `SchemaVersion >= 4` 를 기대합니다.
- `Summary`, `ComputerProfile`, `ProblemDevices`, `AllDevices` 는 GUI 표시와 정렬에 직접 사용됩니다.
- `ProblemGroup`, `PriorityScore`, `PriorityLevel`, `DriverPackageCandidates`, `Recommendations` 가 빠지면 GUI 사용성이 크게 떨어집니다.
- `JSON_REPORT_PATH::<absolute path>` 출력 규약은 GUI가 새 리포트를 즉시 찾는 데 사용합니다.

## Example

- 샘플 리포트 파일: `examples/sample-report.json`
- 샘플 사전 점검 리포트 파일: `examples/sample-preflight-report.json`
- GUI 상세 패널 텍스트 스냅샷: `examples/snapshots/detail-*.txt`
- 이 파일들은 문서 예시이면서 테스트에서 스키마 검증 대상으로도 사용됩니다.
