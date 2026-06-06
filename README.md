# Driver Check Helper

Windows 장치 상태를 확인하고 문제 장치의 드라이버 검색 경로를 정리하는 PowerShell 기반 점검 도구입니다.

## Problem / 문제

- 여러 제조사 노트북을 점검할 때 장치 관리자, 제조사 지원 페이지, Microsoft Update Catalog를 반복해서 확인해야 합니다.
- 문제 장치가 있어도 Hardware ID, 제조사, 모델 정보를 기준으로 검색 경로를 정리하는 과정이 번거롭습니다.
- 점검 결과를 나중에 확인할 수 있는 리포트 형태로 남길 필요가 있습니다.

## Solution / 해결 방법

- Windows 장치 목록과 문제 장치를 수집합니다.
- 문제 장치를 우선 정렬하고 장치 카테고리를 추정합니다.
- 제조사/모델 기반 공식 지원 페이지와 Hardware ID 기반 Microsoft Update Catalog 검색 링크를 생성합니다.
- GUI와 콘솔 실행을 모두 제공하고 JSON/HTML 리포트를 저장합니다.

## Tech Stack / 기술 스택

| Area | Stack |
| --- | --- |
| Runtime | PowerShell |
| GUI | Windows Forms |
| Wrapper | Python |
| Report | JSON, HTML |
| Test | Pester |
| CI | GitHub Actions Windows runner |

## Skills / 구현 역량

- Windows 장치 정보 수집
- Hardware ID 기반 드라이버 검색 흐름 구성
- PowerShell 모듈형 스크립트 구조
- Windows Forms GUI 구성
- JSON/HTML 리포트 생성
- Pester 테스트와 GitHub Actions 구성
- 실제 장비 정보가 노출되지 않도록 샘플 데이터 분리

## Key Features / 주요 기능

- 전체 장치 목록 표시
- 문제 장치 우선 정렬
- 장치 상세 정보 확인
- 제조사 지원 페이지 링크 제공
- Microsoft Update Catalog 검색 링크 생성
- GUI 버전과 콘솔 버전 제공
- JSON/HTML 리포트 저장
- 샘플 리포트와 GUI 스냅샷 제공

## Preview / 미리보기

![Driver Check Helper GUI preview](docs/assets/driver-check-helper-preview.svg)

공개 저장소용 샘플 화면입니다. 실제 장비명, 시리얼, Hardware ID, 리포트 로그는 포함하지 않았습니다.

## Run / 실행

GUI 실행:

```powershell
.\run_driver_gui.bat
```

콘솔 실행:

```powershell
.\run_driver_scan.bat
```

PowerShell 직접 실행:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\main.ps1
```

Python 래퍼 실행:

```powershell
python .\main.py
```

## Test / 테스트

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1
```

## Output / 출력

```text
reports/
logs/
```

## Project Structure / 프로젝트 구조

```text
driver-check-helper/
├── driver_gui.ps1
├── main.ps1
├── main.py
├── run_driver_gui.bat
├── run_driver_scan.bat
├── scripts/
│   ├── main.analysis.functions.ps1
│   ├── main.report.functions.ps1
│   ├── main.system.functions.ps1
│   ├── gui.*.functions.ps1
│   └── rules/
├── docs/
├── examples/
└── tests/
```

## Documentation / 문서

- [Report schema](docs/report-schema.md)
- [Manufacturer support](docs/manufacturer-support.md)
- [Sample report](examples/sample-report.json)
- [Sample preflight report](examples/sample-preflight-report.json)
- [GUI detail snapshots](examples/snapshots)

## Safety / 안전 주의사항

- 드라이버를 자동 설치하지 않습니다.
- 공식 지원 페이지와 검색 링크를 안내하는 진단 보조 도구입니다.
- 공개 저장소에는 실제 실행 로그, 실제 장비 리포트, 복원 지점 백업을 포함하지 않습니다.
