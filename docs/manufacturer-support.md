# 제조사 대응 전략

이 도구는 "모든 노트북 완벽 자동 설치"를 목표로 하지 않습니다. 대신 주요 제조사의 노트북과 PC에서 다음 흐름을 안정적으로 제공하는 것을 목표로 합니다.

- 제조사/모델 식별
- 문제 장치 우선순위화
- 제조사 공식 지원 페이지 연결
- 장치 계열별 검색어와 부품 제조사 링크 제공

## 현재 직접 대응 제조사

| Canonical Name | 대표 인식 예시 | 지원 방식 |
| --- | --- | --- |
| `Dell` | `Dell`, `Alienware` | 서비스 태그, 드라이버 센터, 설명서, SupportAssist |
| `HP` | `HP`, `Hewlett-Packard`, `ProBook`, `EliteBook`, `Victus`, `Omen` | 제품 번호/모델 검색, 설명서, Support Assistant |
| `Lenovo` | `Lenovo`, `ThinkPad`, `ThinkBook`, `IdeaPad`, `Legion`, `Yoga` | MTM/모델 검색, 설명서, System Update |
| `ASUS` | `ASUS`, `ASUSTeK`, `ROG`, `Zenbook`, `Vivobook`, `TUF` | 모델 검색, 지원 페이지, MyASUS |
| `Acer` | `Acer`, `Gateway`, `Packard Bell`, `Swift`, `Aspire`, `Nitro`, `Predator` | Drivers and Manuals, Care Center 안내 |
| `MSI` | `MSI`, `Micro-Star`, `Prestige`, `Modern`, `Stealth`, `Katana` | 모델 검색, 지원 페이지, MSI Center |
| `Samsung` | `Samsung`, `Galaxy Book`, `Book4`, `NTxxxx`, `NPxxxx`, `Notebook 9`, `Odyssey` | 지원 페이지, Samsung Update 안내, Galaxy Book 계열 검색어 강화 |
| `LG` | `LG`, `LG Electronics`, `gram`, `UltraPC`, `14Z/15Z/16Z/17Z`, `13U/14U/15U/16U/17U` | 지원 페이지, 설명서 검색, gram/UltraPC 계열 검색어 강화 |
| `Microsoft Surface` | `Microsoft`, `Surface` | Surface 드라이버/펌웨어 문서, Surface 진단 도구 |
| `Huawei / HONOR` | `Huawei`, `MateBook`, `HONOR`, `MagicBook` | 지원 페이지, PC Manager 안내, 검색 보강 |
| `Gigabyte / AORUS` | `Gigabyte`, `AORUS` | 지원 페이지, 검색 보강, Control Center 안내 |
| `Razer` | `Razer`, `Blade` | 지원 포털, 검색 보강, Synapse 안내 |
| `Fujitsu` | `Fujitsu`, `LIFEBOOK` | 글로벌 지원 포털, 검색 보강 |
| `Dynabook / Toshiba` | `Dynabook`, `Toshiba`, `Portégé`, `Tecra`, `Satellite` | Dynabook 지원 포털, 검색 보강 |
| `VAIO` | `VAIO` | 지원 포털, 검색 보강 |
| `Xiaomi / Redmi` | `Xiaomi`, `RedmiBook`, `Mi Notebook` | 지원 포털, 검색 보강 |
| `Clevo / Tongfang OEM` | `CLEVO`, `Sager`, `Tongfang`, `XMG`, `Schenker` | OEM/베어본 계열 fallback 검색 중심 |

## 대응 원칙

1. 제조사 문자열은 원문 그대로 쓰지 않고 canonical name으로 정규화합니다.
2. 모델명과 시스템 패밀리도 함께 보고 제조사를 보정합니다.
3. OEM 제조사 링크가 있는 경우 부품 제조사 일반 링크보다 우선합니다.
4. 그래픽처럼 부품 제조사 드라이버가 더 현실적인 경우에는 예외적으로 부품 제조사 검색을 우선할 수 있습니다.

## 서브라인 예외 규칙

현재는 아래처럼 같은 제조사 안에서도 대표 서브라인을 따로 식별해 검색 품질을 보정합니다.

- Samsung: `Galaxy Book`, `Notebook 9`, `Odyssey`, `Pen S`
- LG: `gram`, `UltraPC`
- Lenovo: `ThinkPad`, `ThinkBook`, `IdeaPad`, `Legion`, `Yoga`
- ASUS: `ROG`, `TUF`, `Zenbook`, `Vivobook`, `ExpertBook`
- HP: `EliteBook`, `ProBook`, `OMEN`, `Victus`, `ZBook`, `Pavilion`
- Dell: `Latitude`, `Precision`, `XPS`, `Inspiron`, `Vostro`, `Alienware`
- Acer: `Swift`, `Aspire`, `Nitro`, `Predator`, `TravelMate`
- MSI: `Prestige`, `Modern`, `Stealth`, `Katana`, `Creator`

이 서브라인은 `ComputerProfile.Subline`으로 저장될 수 있고, GUI 검색어 생성 시 제조사 단독 키워드보다 더 구체적인 검색어를 만드는 데 사용됩니다.

## 한계

- 제조사 사이트 구조가 바뀌면 일부 링크는 약해질 수 있습니다.
- 같은 브랜드 안에서도 서브모델별 지원 규칙은 계속 보강이 필요합니다.
- 삼성/LG처럼 공개 검색 구조가 제한적인 제조사는 검색 유도 비중이 더 높습니다.
- Huawei/HONOR, Gigabyte/AORUS, Razer, Fujitsu, Dynabook/Toshiba, VAIO, Xiaomi/Redmi도 canonical name과 지원 포털 기준으로 묶어 둡니다.
- Clevo/Tongfang 계열은 브랜드보다 재판매사와 베어본 모델명이 더 중요한 경우가 많아 fallback 검색 비중이 큽니다.
- 삼성은 `Galaxy Book`, `NT`, `NP` 모델명만으로도 canonical name을 보정하도록 되어 있습니다.
- LG는 `gram`, `UltraPC`, `14Z/16U` 같은 대표 모델 패턴만으로도 canonical name을 보정하도록 되어 있습니다.

## 다음 확장 후보

- 제조사별 식별값 활용 강화
- 브랜드별 샘플 리포트 추가
- 실기기 테스트 매트릭스 확장
