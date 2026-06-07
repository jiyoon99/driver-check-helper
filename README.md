# Driver Check Helper

Windows 장치 상태를 수집하고 문제 장치를 분류한 뒤, 제조사 지원 페이지와 Microsoft Update Catalog 검색 경로를 만들어 주는 PowerShell 기반 드라이버 점검 도구입니다.

![Driver Check Helper GUI preview](docs/assets/driver-check-helper-preview.svg)

## What I Built / 만든 것

장치 관리자에서 문제 장치를 하나씩 확인하고 Hardware ID를 다시 검색하던 작업을 하나의 점검 흐름으로 구성했습니다. 콘솔과 Windows Forms GUI를 모두 제공하며, 수집 결과는 JSON과 HTML 리포트로 저장할 수 있습니다.

## Main Features / 주요 기능

- Windows 장치 목록과 오류 상태 수집
- 문제 장치 우선 정렬과 장치 카테고리 추정
- Hardware ID, 제조사, 모델 정보 표시
- 제조사별 공식 지원 페이지 연결
- Microsoft Update Catalog 검색 URL 생성
- 기본 정보·하드웨어·권장 조치 탭으로 상세 정보 구성
- JSON/HTML 리포트 생성과 기존 리포트 다시 열기
- GUI 실행, 콘솔 스캔, Python wrapper 제공
- 실제 장비 정보 대신 익명화된 샘플 리포트 제공

## Development / 개발 방식

기능을 시스템 수집, 분석 규칙, 리포트 스키마, GUI 동작으로 분리했습니다.

```text
Windows device queries
        ↓
system collection functions
        ↓
vendor / device pattern rules
        ↓
analysis and recommendations
        ↓
GUI or console output
        ↓
JSON / HTML report
```

- `main.system.functions.ps1`: 장치와 시스템 정보 수집
- `main.analysis.functions.ps1`: 문제 장치 분석과 권장 조치 생성
- `rules/vendors.ps1`, `rules/patterns.ps1`: 제조사 및 장치 패턴 정의
- `report.schema.functions.ps1`: 저장 리포트 형식과 호환성 처리
- `gui.*.functions.ps1`: 화면, 검색, 리포트 열기, 사용자 동작 처리

드라이버를 자동 설치하지 않고 검색 경로와 판단 근거만 제공하도록 범위를 제한했습니다. 장비별 규칙은 코드에 섞지 않고 별도 규칙 파일로 관리하며, 리포트 스키마는 샘플과 테스트로 검증합니다.

## Tech Stack / 기술 스택

| 영역 | 기술 |
| --- | --- |
| Runtime | PowerShell |
| GUI | Windows Forms |
| Wrapper | Python |
| Data | JSON, HTML |
| Test | Pester |
| CI | GitHub Actions Windows runner |

## Run / 실행

```powershell
.\run_driver_gui.bat
.\run_driver_scan.bat
```

PowerShell 직접 실행:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\main.ps1
```

Python wrapper:

```powershell
python .\main.py
```

## Test / 검증

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1
```

테스트는 분석 규칙, 제조사 지원 URL, GUI 리포트 로딩, 리포트 스키마를 확인합니다.

## Repository Structure / 저장소 구조

```text
driver-check-helper/
├── driver_gui.ps1
├── main.ps1
├── main.py
├── scripts/
│   ├── main.*.functions.ps1
│   ├── gui.*.functions.ps1
│   └── rules/
├── tests/
├── examples/
└── docs/
```

## Documentation / 문서

- [Report schema](docs/report-schema.md)
- [Manufacturer support rules](docs/manufacturer-support.md)
- [Sample report](examples/sample-report.json)
- [Sample preflight report](examples/sample-preflight-report.json)

실제 장비의 이름, 시리얼, Hardware ID, 실행 로그는 저장소에 포함하지 않습니다.

## License

MIT License
