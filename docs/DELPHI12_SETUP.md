# Delphi 12 프로젝트 구성 및 빌드 기준

## 프로젝트
- 프로젝트: InterPOS
- IDE: Embarcadero Delphi 12 Athens (29.0.51961.7529)
- UI: VCL Windows Desktop
- 데이터 접근: FireDAC
- DBMS: Firebird 5.0
- 기본 빌드 대상: Win32 (매장 단말), 필요 시 Win64 추가

## 필수 Delphi 설정
1. src/InterPOS.dproj를 Delphi 12에서 엽니다.
2. Project Manager에서 Target Platform을 Windows 32-bit로 선택합니다.
3. Build Configuration은 Debug로 첫 빌드를 수행하고, 테스트 완료 후 Release로 전환합니다.
4. Project Search Path에 별도 경로가 필요하면 추가하되, Delphi 기본 FireDAC 유닛은 설치된 Delphi 경로를 사용합니다.
5. FireDAC Firebird Driver Link(FireDAC.Phys.FB, FireDAC.Phys.FBDef)를 포함합니다.
6. 실행 폴더에 Firebird Client DLL(fbclient.dll)이 있어야 합니다. 앱과 DLL의 비트수(Win32/Win64)를 일치시킵니다.
7. DB 파일은 Firebird Server가 접근할 수 있는 서버 경로에 두고, 클라이언트 설정은 INI의 Server/Port/Database로 지정합니다.

## 설정 파일
실행 파일과 같은 폴더의 InterPOS.ini를 사용합니다. 저장소에는 비밀번호를 넣지 않고 InterPOS.ini.example만 관리합니다.

- [Database] Server, Port, Database, UserName, Password, CharacterSet
- [POS] StoreId, TerminalId

실제 운영에서는 SYSDBA 대신 InterPOS 전용 DB 계정을 만들고 필요한 권한만 부여합니다. 예제 비밀번호는 운영 환경에서 반드시 변경합니다.

## 한글 처리
- Delphi 소스는 UTF-8 BOM으로 저장합니다.
- DFM 문자열의 한글은 Delphi 폼 디자이너가 저장한 인코딩을 유지합니다.
- 컴파일 지시문 {$CODEPAGE UTF8}을 임의로 추가하지 않습니다.
- DB 연결 문자셋은 UTF8로 고정합니다.

## 검증 체크리스트
- [ ] Delphi 12에서 InterPOS.dproj 열기
- [ ] Win32 Debug 빌드 성공
- [ ] Firebird 5.0 접속 성공
- [ ] 한글 매장명/메뉴명 입력 후 재조회 시 정상 표시
- [ ] 기존 로그인, 직원관리, 메뉴관리, POS 주문/결제, 주방 화면 회귀 테스트
- [ ] database/08_operational_foundation.sql 실행 및 신규 테이블 확인
