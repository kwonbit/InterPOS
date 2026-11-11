# InterPOS

Delphi 기반 음식점 Windows POS 프로젝트입니다. OKPOS와 유사한 현장 운영 흐름을 목표로 하며, 초기 저장소에는 애플리케이션 골격과 Firebird 데이터베이스 초안이 포함됩니다.

## 기술 스택
- Delphi 12 Athens / VCL
- FireDAC
- Firebird 5.0
- Windows 10/11

## 저장소 구성
- `src/`: Delphi 프로젝트 및 화면/데이터 모듈
- `database/`: Firebird 스키마 및 초기 데이터 스크립트
- `config/`: 설정 파일 예시
- `docs/`: 아키텍처 및 개발 문서

## 시작하기
1. Firebird 5.0 Server를 설치합니다.
2. 빈 데이터베이스에 `database/01_schema.sql`을 실행합니다.
3. `database/02_employee_login_indexes.sql`부터 `database/07_sales_closing.sql`까지 순서대로 실행합니다.
4. `database/08_operational_foundation.sql`, `database/09_inventory_management.sql`, `database/10_supplier_management.sql`, `database/11_purchase_management.sql`을 순서대로 한 번씩 실행합니다.
5. `config/InterPOS.ini.example`을 실행 파일 옆의 `InterPOS.ini`로 복사하고 DB 접속 정보와 `[POS] StoreId`, `[POS] TerminalId`를 입력합니다.
6. Delphi 12에서 `src/InterPOS.dpr`을 엽니다.
7. FireDAC Firebird 드라이버와 Firebird Client DLL 설치 여부를 확인합니다.
8. 최초 실행 시 점주 계정을 등록하고 로그인합니다.

기존 DB에는 이미 적용한 migration을 다시 실행하지 말고, 미적용된 다음 스크립트만 실행합니다. `01_schema.sql`은 빈 DB 최초 생성에만 사용합니다.

## 구현된 기능
- 최초 실행 시 매장 및 점주 계정 등록
- 직원 로그인 및 활성 계정 확인
- PBKDF2-HMAC-SHA256 비밀번호 해시 저장
- 점주/매니저/직원 역할에 따른 메뉴 접근 제어
- 직원 등록, 비밀번호 변경, 계정 사용 중지 및 재활성화
- 테이블 등록/수정/사용 상태 관리
- 음식 종류 등록/수정/사용 상태 관리
- 메뉴 등록/수정/가격/설명 및 사용 상태 관리
- POS 판매 화면에서 테이블/음식 종류/메뉴 선택
- 장바구니 수량 변경 및 주문 합계 계산
- 주문 헤더/품목을 Firebird 트랜잭션으로 저장
- 테이블 진행 주문의 현금/카드 전액 결제 처리
- 결제 금액 및 결제 수단을 POS_PAYMENT에 저장
- 현금 결제 시 받은 금액과 거스름돈 계산
- POS 단말별 영업 개점 및 준비금 등록
- 영업 중 현금 입금/출금 내역 관리
- 현금 결제액과 입출금을 반영한 예상 시재 계산
- 미결제 주문이 남아 있으면 영업마감 차단
- 실제 시재 입력, 차액 계산 및 단말별 마감 이력 조회
- 메뉴별 재고관리 사용 여부 및 안전재고 설정
- 메뉴 품절/판매 재개 처리 및 POS 판매 차단
- 재고 입고/출고/폐기/실사 조정과 변경 이력
- 기간/구분/메뉴명 조건별 전체 재고 이력 조회 및 CSV 내보내기
- 거래처 등록/수정/검색 및 사용/중지 관리
- 구매 등록, 거래처별 구매 내역 및 입고 확정/취소
- 입고 확정 시 재고 자동 증가와 재고 이력 연결
- 결제 완료 시 재고관리 메뉴 자동 차감 및 재고 부족 결제 차단
- 매니저는 일반 직원 계정만 관리 가능
- 다중 POS 단말에서 동일 테이블 중복 주문 방지
- 점주 전용 Firebird 데이터 백업 및 별도 DB 복구 검증
- 매일 예약 백업, 보관 기간 자동 정리 및 백업 실행 로그
- 현금 결제 시 설정된 ESC/POS 돈통 자동 열기

로그인 및 직원 권한은 [docs/AUTHENTICATION.md](docs/AUTHENTICATION.md), 기초정보 관리는 [docs/MASTER_DATA.md](docs/MASTER_DATA.md), POS 판매는 [docs/POS_SALES.md](docs/POS_SALES.md), 영업 개점/마감 및 현금시재는 [docs/SHIFT_MANAGEMENT.md](docs/SHIFT_MANAGEMENT.md), 재고관리는 [docs/INVENTORY_MANAGEMENT.md](docs/INVENTORY_MANAGEMENT.md) 및 [docs/INVENTORY_ALERT_EXPORT.md](docs/INVENTORY_ALERT_EXPORT.md) 및 [docs/INVENTORY_HISTORY_SEARCH.md](docs/INVENTORY_HISTORY_SEARCH.md), 거래처 관리는 [docs/SUPPLIER_MANAGEMENT.md](docs/SUPPLIER_MANAGEMENT.md), 구매관리는 [docs/PURCHASE_MANAGEMENT.md](docs/PURCHASE_MANAGEMENT.md), 다중 단말 구성은 [docs/MULTI_TERMINAL.md](docs/MULTI_TERMINAL.md), 데이터 백업/복구 및 예약 백업은 [docs/BACKUP_RECOVERY.md](docs/BACKUP_RECOVERY.md), 돈통 설정은 [docs/CASH_DRAWER.md](docs/CASH_DRAWER.md)를 참고하세요. 매출 보고서 CSV 내보내기는 [docs/SALES_REPORT_EXPORT.md](docs/SALES_REPORT_EXPORT.md)를 참고하세요.

현재 버전은 개발 초기 단계입니다. 이 단계는 Delphi 12에서 컴파일/실행 검증이 필요하며, 실제 매장 운영 전에는 POS 판매, 결제, 프린터, 백업/복구 및 전체 업무 흐름에 대한 추가 구현과 테스트가 필요합니다.
