# InterPOS 데이터베이스 설계 기준

## 기준 환경
- Delphi 12 Athens, VCL, Win32 우선(매장 POS 단말 기준)
- Firebird 5.0, 데이터베이스 문자셋 UTF8
- Delphi 데이터 접근은 FireDAC 사용
- 금액은 NUMERIC(15,2), 수량은 정수 또는 NUMERIC(12,3) 사용
- 모든 영업 데이터는 STORE_ID로 매장 범위를 구분

## 기존 스키마 재사용
기존 01_schema.sql~07_sales_closing.sql은 현재 InterPOS 기능의 기준 스키마입니다. 직원/로그인, 메뉴/옵션, 주문/품목, 결제, 주방 주문서, 일마감 테이블을 다시 만들지 않습니다. 신규 스크립트는 기존 데이터에 대한 비파괴 확장입니다.

## 핵심 엔터티
| 영역 | 기존/신규 테이블 | 역할 |
|---|---|---|
| 매장/단말 | STORE_INFO, POS_TERMINAL | 매장과 POS 단말 |
| 직원/권한 | EMPLOYEE | 로그인, 역할, 작업자 |
| 메뉴 | MENU_CATEGORY, MENU_ITEM, MENU_OPTION_GROUP, MENU_OPTION | 메뉴와 옵션 |
| 테이블 | POS_TABLE | 테이블 및 그룹 |
| 주문 | POS_ORDER, POS_ORDER_ITEM | 주문 헤더와 판매 시점 품목 스냅샷 |
| 결제 | POS_PAYMENT | 결제수단별 행을 저장해 복합결제를 표현 |
| 영업/시재 | POS_SHIFT, POS_CASH_MOVEMENT | 개점 준비금, 현금 입출금, 마감 시재 |
| 주방 | POS_KITCHEN_TICKET, POS_KITCHEN_ROUTE | 주방 주문서 및 분류/메뉴별 프린터 라우팅 |
| 터치키 | POS_TOUCH_LAYOUT, POS_TOUCH_KEY | 단말별 판매 화면 레이아웃 |
| 장치 | POS_PRINTER_CONFIG | 영수증/주방/돈통 등 장치 설정 |
| 설정/감사 | POS_SYSTEM_CONFIG, POS_AUDIT_LOG | 매장/단말 설정과 중요 변경 이력 |
| 마감 | POS_SALES_CLOSE, POS_SALES_CLOSE_MENU | 일마감 집계 스냅샷 |

## 주요 업무 규칙
1. POS_ORDER_ITEM에는 판매 당시 메뉴명/단가/옵션/금액을 보존합니다.
2. 한 주문의 복합결제는 POS_PAYMENT에 결제수단별로 여러 행을 저장합니다.
3. 결제 승인/취소 상태는 PAYMENT_STATUS와 CANCELED_AT으로 관리하며 원 결제 이력을 물리 삭제하지 않습니다.
4. 개점과 마감은 POS_SHIFT 단위로 관리합니다. 현금 시재 입출금은 POS_CASH_MOVEMENT에 기록합니다.
5. 할인/서비스 금액은 POS_ORDER의 별도 컬럼에 저장하고 기존 TOTAL_AMOUNT는 기존 코드와의 호환을 위해 유지합니다. 신규 결제 유스케이스에서 총액 계산 규칙을 한 곳에 모아 적용합니다.
6. 프린터 라우팅과 터치키 레이아웃은 데이터로 관리하되, 실제 프린터/VAN 통신은 장비별 어댑터로 분리합니다.
7. POS_AUDIT_LOG는 취소, 마감, 권한/설정 변경 등의 감사 추적에 사용합니다.

## 마이그레이션 순서
기존 DB에는 아래 순서대로 한 번만 적용합니다.

1. database/01_schema.sql (빈 DB 최초 생성에만 적용)
2. database/02_employee_login_indexes.sql
3. database/03_master_data.sql
4. database/04_pos_sales.sql
5. database/05_pos_payment.sql
6. database/06_kitchen_orders.sql
7. database/07_sales_closing.sql
8. database/08_operational_foundation.sql

기존 운영 DB에는 이미 실행한 스크립트를 다시 실행하지 말고, 아직 적용하지 않은 다음 스크립트만 실행합니다. 01 스크립트는 빈 DB에서만 실행합니다.

## 후속 구현 범위
- 영업 세션 개점/마감 UI 및 마감 정산 로직
- 현금 입금/출금 및 현금시재 대사
- 복합결제/더치페이/부분취소 및 VAN 승인 어댑터
- 터치키 편집기, 주방 프린터 분류 라우팅
- 단말 간 동기화 및 네트워크 장애 복구
