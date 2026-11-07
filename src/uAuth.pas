unit uAuth;

interface

uses
  System.SysUtils, FireDAC.Comp.Client;

type
  TEmployeeSession = record
    EmployeeID: Integer;
    StoreID: Integer;
    EmployeeName: string;
    LoginID: string;
    RoleCode: string;
  end;

function ActiveEmployeeCount(AConnection: TFDConnection; AStoreID: Integer): Integer;
procedure CreateInitialOwner(AConnection: TFDConnection; AStoreID: Integer;
  const AStoreName, AEmployeeName, ALoginID, APassword: string);
function AuthenticateEmployee(AConnection: TFDConnection; AStoreID: Integer;
  const ALoginID, APassword: string; out ASession: TEmployeeSession): Boolean;
function RoleDisplayName(const ARoleCode: string): string;
function CanManageMenus(const ARoleCode: string): Boolean;
function CanManageEmployees(const ARoleCode: string): Boolean;

implementation

uses
  System.Classes, System.NetEncoding, Winapi.Windows;

type
  TBcryptAlgHandle = Pointer;

function BCryptOpenAlgorithmProvider(out phAlgorithm: TBcryptAlgHandle;
  pszAlgId, pszImplementation: PWideChar; dwFlags: ULONG): LongInt; stdcall;
  external 'bcrypt.dll' name 'BCryptOpenAlgorithmProvider';

function BCryptCloseAlgorithmProvider(hAlgorithm: TBcryptAlgHandle;
  dwFlags: ULONG): LongInt; stdcall;
  external 'bcrypt.dll' name 'BCryptCloseAlgorithmProvider';

function BCryptGenRandom(hAlgorithm: TBcryptAlgHandle; pbBuffer: PByte;
  cbBuffer, dwFlags: ULONG): LongInt; stdcall;
  external 'bcrypt.dll' name 'BCryptGenRandom';

function BCryptDeriveKeyPBKDF2(hPrf: TBcryptAlgHandle; pbPassword: PByte;
  cbPassword: ULONG; pbSalt: PByte; cbSalt: ULONG; cIterations: UInt64;
  pbDerivedKey: PByte; cbDerivedKey, dwFlags: ULONG): LongInt; stdcall;
  external 'bcrypt.dll' name 'BCryptDeriveKeyPBKDF2';

const
  BCRYPT_ALG_HANDLE_HMAC_FLAG = $00000008;
  BCRYPT_USE_SYSTEM_PREFERRED_RNG = $00000002;
  PBKDF2_ITERATIONS = 120000;
  SALT_LENGTH = 16;
  HASH_LENGTH = 32;

function DerivePasswordHash(const APassword: string; const ASalt: TBytes;
  AIterations: Integer): TBytes;
var
  Alg: TBcryptAlgHandle;
  PasswordBytes: TBytes;
  Status: LongInt;
begin
  Alg := nil;
  PasswordBytes := TEncoding.UTF8.GetBytes(APassword);
  SetLength(Result, HASH_LENGTH);

  Status := BCryptOpenAlgorithmProvider(Alg, 'SHA256', nil,
    BCRYPT_ALG_HANDLE_HMAC_FLAG);
  if Status <> 0 then
    raise Exception.CreateFmt('Windows 암호화 공급자를 열 수 없습니다. (0x%.8x)',
      [Cardinal(Status)]);
  try
    if Length(PasswordBytes) = 0 then
      raise Exception.Create('비밀번호를 입력해 주세요.');

    Status := BCryptDeriveKeyPBKDF2(Alg, @PasswordBytes[0],
      Length(PasswordBytes), @ASalt[0], Length(ASalt), AIterations,
      @Result[0], Length(Result), 0);
    if Status <> 0 then
      raise Exception.CreateFmt('비밀번호 해시 생성에 실패했습니다. (0x%.8x)',
        [Cardinal(Status)]);
  finally
    BCryptCloseAlgorithmProvider(Alg, 0);
  end;
end;

function HashPassword(const APassword: string): string;
var
  Salt, Hash: TBytes;
begin
  SetLength(Salt, SALT_LENGTH);
  if BCryptGenRandom(nil, @Salt[0], Length(Salt),
    BCRYPT_USE_SYSTEM_PREFERRED_RNG) <> 0 then
    raise Exception.Create('보안 난수 생성에 실패했습니다.');

  Hash := DerivePasswordHash(APassword, Salt, PBKDF2_ITERATIONS);
  Result := '$pbkdf2-sha256$' + IntToStr(PBKDF2_ITERATIONS) + '$' +
    TNetEncoding.Base64.EncodeBytesToString(Salt) + '$' +
    TNetEncoding.Base64.EncodeBytesToString(Hash);
end;

function VerifyPassword(const APassword, AStoredHash: string): Boolean;
var
  Parts: TArray<string>;
  Iterations: Integer;
  Salt, ExpectedHash, ActualHash: TBytes;
  I: Integer;
  Diff: Byte;
begin
  Result := False;
  Parts := AStoredHash.Split(['$']);
  if (Length(Parts) <> 5) or (Parts[1] <> 'pbkdf2-sha256') then
    Exit;
  if not TryStrToInt(Parts[2], Iterations) or (Iterations < 10000) then
    Exit;

  try
    Salt := TNetEncoding.Base64.DecodeStringToBytes(Parts[3]);
    ExpectedHash := TNetEncoding.Base64.DecodeStringToBytes(Parts[4]);
    if (Length(Salt) < 8) or (Length(ExpectedHash) <> HASH_LENGTH) then
      Exit;

    ActualHash := DerivePasswordHash(APassword, Salt, Iterations);
    Diff := 0;
    for I := 0 to HASH_LENGTH - 1 do
      Diff := Diff or (ActualHash[I] xor ExpectedHash[I]);
    Result := Diff = 0;
  except
    Result := False;
  end;
end;

function ActiveEmployeeCount(AConnection: TFDConnection;
  AStoreID: Integer): Integer;
var
  Q: TFDQuery;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := AConnection;
    Q.SQL.Text := 'SELECT COUNT(*) FROM EMPLOYEE ' +
      'WHERE STORE_ID = :STORE_ID AND ACTIVE_YN = ''Y''';
    Q.ParamByName('STORE_ID').AsInteger := AStoreID;
    Q.Open;
    Result := Q.Fields[0].AsInteger;
  finally
    Q.Free;
  end;
end;

procedure CreateInitialOwner(AConnection: TFDConnection; AStoreID: Integer;
  const AStoreName, AEmployeeName, ALoginID, APassword: string);
var
  Q: TFDQuery;
  EmployeeID: Integer;
begin
  if ActiveEmployeeCount(AConnection, AStoreID) > 0 then
    raise Exception.Create('이미 등록된 직원이 있습니다. 로그인해 주세요.');

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := AConnection;
    AConnection.StartTransaction;
    try
      Q.SQL.Text := 'SELECT COUNT(*) FROM STORE_INFO WHERE STORE_ID = :STORE_ID';
      Q.ParamByName('STORE_ID').AsInteger := AStoreID;
      Q.Open;
      if Q.Fields[0].AsInteger = 0 then
      begin
        Q.Close;
        Q.SQL.Text := 'INSERT INTO STORE_INFO (STORE_ID, STORE_NAME) ' +
          'VALUES (:STORE_ID, :STORE_NAME)';
        Q.ParamByName('STORE_ID').AsInteger := AStoreID;
        Q.ParamByName('STORE_NAME').AsString := AStoreName;
        Q.ExecSQL;
      end
      else
        Q.Close;

      Q.SQL.Text := 'SELECT COALESCE(MAX(EMPLOYEE_ID), 0) + 1 FROM EMPLOYEE';
      Q.Open;
      EmployeeID := Q.Fields[0].AsInteger;
      Q.Close;

      Q.SQL.Text :=
        'INSERT INTO EMPLOYEE (EMPLOYEE_ID, STORE_ID, EMPLOYEE_NAME, ' +
        'LOGIN_ID, PASSWORD_HASH, ROLE_CODE, ACTIVE_YN) ' +
        'VALUES (:EMPLOYEE_ID, :STORE_ID, :EMPLOYEE_NAME, :LOGIN_ID, ' +
        ':PASSWORD_HASH, ''OWNER'', ''Y'')';
      Q.ParamByName('EMPLOYEE_ID').AsInteger := EmployeeID;
      Q.ParamByName('STORE_ID').AsInteger := AStoreID;
      Q.ParamByName('EMPLOYEE_NAME').AsString := AEmployeeName;
      Q.ParamByName('LOGIN_ID').AsString := ALoginID;
      Q.ParamByName('PASSWORD_HASH').AsString := HashPassword(APassword);
      Q.ExecSQL;
      AConnection.Commit;
    except
      AConnection.Rollback;
      raise;
    end;
  finally
    Q.Free;
  end;
end;

function AuthenticateEmployee(AConnection: TFDConnection; AStoreID: Integer;
  const ALoginID, APassword: string; out ASession: TEmployeeSession): Boolean;
var
  Q: TFDQuery;
begin
  Result := False;
  ASession := Default(TEmployeeSession);
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := AConnection;
    Q.SQL.Text :=
      'SELECT FIRST 1 EMPLOYEE_ID, STORE_ID, EMPLOYEE_NAME, LOGIN_ID, ' +
      'PASSWORD_HASH, ROLE_CODE FROM EMPLOYEE ' +
      'WHERE STORE_ID = :STORE_ID AND LOGIN_ID = :LOGIN_ID ' +
      'AND ACTIVE_YN = ''Y''';
    Q.ParamByName('STORE_ID').AsInteger := AStoreID;
    Q.ParamByName('LOGIN_ID').AsString := Trim(ALoginID);
    Q.Open;
    if Q.IsEmpty then
      Exit;

    if not VerifyPassword(APassword, Q.FieldByName('PASSWORD_HASH').AsString) then
      Exit;

    ASession.EmployeeID := Q.FieldByName('EMPLOYEE_ID').AsInteger;
    ASession.StoreID := Q.FieldByName('STORE_ID').AsInteger;
    ASession.EmployeeName := Q.FieldByName('EMPLOYEE_NAME').AsString;
    ASession.LoginID := Q.FieldByName('LOGIN_ID').AsString;
    ASession.RoleCode := Q.FieldByName('ROLE_CODE').AsString;
    Result := True;
  finally
    Q.Free;
  end;
end;

function RoleDisplayName(const ARoleCode: string): string;
begin
  if SameText(ARoleCode, 'OWNER') then
    Exit('점주');
  if SameText(ARoleCode, 'MANAGER') then
    Exit('매니저');
  if SameText(ARoleCode, 'STAFF') then
    Exit('직원');
  Result := ARoleCode;
end;

function CanManageMenus(const ARoleCode: string): Boolean;
begin
  Result := SameText(ARoleCode, 'OWNER') or SameText(ARoleCode, 'MANAGER');
end;

function CanManageEmployees(const ARoleCode: string): Boolean;
begin
  Result := SameText(ARoleCode, 'OWNER') or SameText(ARoleCode, 'MANAGER');
end;

end.
