# InterPOS

Delphi 기반 음식점 Windows POS 프로젝트입니다. OKPOS와 유사한 현장 운영 흐름을 목표로 하며, Delphi 12 Athens와 Firebird 5.0을 기본 환경으로 합니다.

## 기술 스택
- Delphi 12 Athens / VCL
- FireDAC
- Firebird 5.0
- Windows 10/11

## 저장소 구성
- src/: Delphi 프로젝트 및 화면/데이터 모듈
- database/: Firebird 스키마 및 마이그레이션 스크립트
- config/: 설정 파일 예시
- docs/: 아키텍처, DB 설계 및 개발 문서

## 시작하기
1. Firebird 5.0 Server를 설치합니다.
2. 빈 데이터베이스에 database/01_schema.sql을 실행합니다.
3. database/02_employee_login_indexes.sql부터 database/07_sales_closing.sql까지 순서대로 실행합니다.
4. database/08_operational_foundation.sql을 실행합니다.
5. config/InterPOS.ini.example을 실행 파일 옆의 InterPOS.ini로 복사하고 DB 접속 정보와 [POS] StoreId, TerminalId를 입력합니다.
6. Delphi 12에서 src/InterPOS.dproj를 엽니다.
7. FireDAC Firebird 드라이버와 Firebird Client DLL(fbclient.dll) 설치 여부를 확인합니다.
8. 최초 실행 시 점주 계정을 등록하고 로그인합니다.

기존 데이터베이스에는 이미 적용한 스크립트를 다시 실행하지 말고, 미적용된 스크립트만 순서대로 실행합니다. 01_schema.sql은 빈 DB 최초 생성에만 사용합니다.

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
- 매니저는 일반 직원 계정만 관리 가능

## 문서
- [아키텍처](docs/ARCHITECTURE.md)
- [데이터베이스 설계](docs/DATABASE_DESIGN.md)
- [Delphi 12 구성 및 빌드](docs/DELPHI12_SETUP.md)
- [로그인 및 직원 권한](docs/AUTHENTICATION.md)
- [기초정보 관리](docs/MASTER_DATA.md)
- [POS 판매](docs/POS_SALES.md)

현재 단계는 기존 기능을 보존하면서 영업 세션/시재, 단말/프린터, 터치키, 감사 로그를 위한 DB 기반을 추가한 상태입니다. 실제 Delphi 컴파일, Firebird 마이그레이션 실행, 매장 장비 테스트는 개발 PC에서 검증해야 합니다.
