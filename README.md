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
2. `database/01_schema.sql`을 실행해 데이터베이스 스키마를 생성합니다.
3. `config/InterPOS.ini.example`을 `InterPOS.ini`로 복사하고 DB 접속 정보를 입력합니다.
4. Delphi 12에서 `src/InterPOS.dpr`을 엽니다.
5. FireDAC Firebird 드라이버와 Firebird Client DLL 설치 여부를 확인합니다.

현재 버전은 개발 시작용 골격이며, 실제 매장 운영 전에는 결제/프린터/권한/복구 시나리오와 전체 업무 흐름에 대한 구현 및 테스트가 필요합니다.
