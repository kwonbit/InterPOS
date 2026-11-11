unit uBackupForm;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.IOUtils,
  System.IniFiles, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Dialogs;

type
  TfrmBackup = class(TForm)
  private
    FBackupFolder: string;
    FGbakPath: string;
    FInfo: TLabel;
    FLog: TMemo;
    FBackupButton: TButton;
    FVerifyButton: TButton;
    FCloseButton: TButton;
    procedure BuildUI;
    procedure LoadSettings;
    function RunGbak(const AArguments: string; out AOutput: string): Boolean;
    function Quote(const S: string): string;
    function PasswordFile: string;
    function DatabaseName: string;
    function BackupFileName: string;
    procedure BackupClick(Sender: TObject);
    procedure VerifyClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

uses
  uDatabase;

constructor TfrmBackup.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  BuildUI;
  LoadSettings;
end;

procedure TfrmBackup.BuildUI;
var
  Header, Buttons: TPanel;
  L: TLabel;
begin
  Caption := '데이터 백업 및 복구 검증';
  Font.Name := '맑은 고딕';
  Width := 900;
  Height := 620;
  Position := poScreenCenter;

  Header := TPanel.Create(Self);
  Header.Parent := Self;
  Header.Align := alTop;
  Header.Height := 86;
  Header.BevelOuter := bvNone;

  L := TLabel.Create(Self);
  L.Parent := Header;
  L.Left := 16;
  L.Top := 12;
  L.Caption := 'Firebird 데이터베이스 보호';
  L.Font.Style := [fsBold];
  L.Font.Size := 13;

  FInfo := TLabel.Create(Self);
  FInfo.Parent := Header;
  FInfo.Left := 16;
  FInfo.Top := 43;
  FInfo.Caption := '설정 확인 중...';

  FLog := TMemo.Create(Self);
  FLog.Parent := Self;
  FLog.Align := alClient;
  FLog.ReadOnly := True;
  FLog.ScrollBars := ssVertical;
  FLog.WordWrap := False;

  Buttons := TPanel.Create(Self);
  Buttons.Parent := Self;
  Buttons.Align := alBottom;
  Buttons.Height := 68;
  Buttons.BevelOuter := bvNone;

  FBackupButton := TButton.Create(Self);
  FBackupButton.Parent := Buttons;
  FBackupButton.SetBounds(14, 12, 180, 42);
  FBackupButton.Caption := '지금 백업하기';
  FBackupButton.Font.Style := [fsBold];
  FBackupButton.OnClick := BackupClick;

  FVerifyButton := TButton.Create(Self);
  FVerifyButton.Parent := Buttons;
  FVerifyButton.SetBounds(204, 12, 210, 42);
  FVerifyButton.Caption := '백업 복구 검증';
  FVerifyButton.OnClick := VerifyClick;

  FCloseButton := TButton.Create(Self);
  FCloseButton.Parent := Buttons;
  FCloseButton.SetBounds(748, 12, 120, 42);
  FCloseButton.Caption := '닫기';
  FCloseButton.ModalResult := mrClose;
end;

procedure TfrmBackup.LoadSettings;
var
  Ini: TIniFile;
  IniPath: string;
begin
  IniPath := ChangeFileExt(ParamStr(0), '.ini');
  FGbakPath := 'C:\Program Files\Firebird\Firebird_5_0\gbak.exe';
  FBackupFolder := TPath.Combine(ExtractFilePath(ParamStr(0)), 'backup');
  if FileExists(IniPath) then
  begin
    Ini := TIniFile.Create(IniPath);
    try
      FGbakPath := Ini.ReadString('Backup', 'GbakPath', FGbakPath);
      FBackupFolder := Ini.ReadString('Backup', 'BackupFolder', FBackupFolder);
    finally
      Ini.Free;
    end;
  end;
  FInfo.Caption := 'DB: ' + dmDatabase.Connection.Params.Database +
    '   /   백업 폴더: ' + FBackupFolder;
  FLog.Lines.Add('gbak 경로: ' + FGbakPath);
  FLog.Lines.Add('백업 폴더: ' + FBackupFolder);
  FLog.Lines.Add('복구 검증은 운영 DB를 덮어쓰지 않고 별도 테스트 DB를 생성합니다.');
end;

function TfrmBackup.Quote(const S: string): string;
begin
  Result := '"' + StringReplace(S, '"', '""', [rfReplaceAll]) + '"';
end;

function TfrmBackup.PasswordFile: string;
var
  P: string;
begin
  P := TPath.GetTempFileName;
  TFile.WriteAllText(P, dmDatabase.Connection.Params.Values['Password'],
    TEncoding.ASCII);
  Result := P;
end;

function TfrmBackup.DatabaseName: string;
begin
  Result := dmDatabase.Connection.Params.Database;
end;

function TfrmBackup.BackupFileName: string;
begin
  Result := TPath.Combine(FBackupFolder,
    'INTERPOS_' + FormatDateTime('yyyymmdd_hhnnss', Now) + '.fbk');
end;

function TfrmBackup.RunGbak(const AArguments: string;
  out AOutput: string): Boolean;
var
  SI: TStartupInfo;
  PI: TProcessInformation;
  LogPath, PassPath, Cmd: string;
  LogHandle: THandle;
  ExitCode: DWORD;
begin
  Result := False;
  AOutput := '';
  if not FileExists(FGbakPath) then
    raise Exception.Create('gbak.exe를 찾을 수 없습니다. InterPOS.ini의 [Backup] GbakPath를 확인하세요.');
  PassPath := PasswordFile;
  LogPath := TPath.GetTempFileName;
  try
    LogHandle := CreateFile(PChar(LogPath), GENERIC_WRITE,
      FILE_SHARE_READ or FILE_SHARE_WRITE, nil, CREATE_ALWAYS,
      FILE_ATTRIBUTE_TEMPORARY, 0);
    if LogHandle = INVALID_HANDLE_VALUE then
      RaiseLastOSError;
    try
      ZeroMemory(@SI, SizeOf(SI));
      SI.cb := SizeOf(SI);
      SI.dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
      SI.wShowWindow := SW_HIDE;
      SI.hStdOutput := LogHandle;
      SI.hStdError := LogHandle;
      SI.hStdInput := GetStdHandle(STD_INPUT_HANDLE);

      Cmd := Quote(FGbakPath) + ' ' + AArguments +
        ' -user ' + Quote(dmDatabase.Connection.Params.UserName) +
        ' -fetch_password ' + Quote(PassPath);
      UniqueString(Cmd);
      if not CreateProcess(PChar(FGbakPath), PChar(Cmd), nil, nil, True,
        CREATE_NO_WINDOW, nil, PChar(ExtractFilePath(FGbakPath)), SI, PI) then
        RaiseLastOSError;
      try
        WaitForSingleObject(PI.hProcess, INFINITE);
        if not GetExitCodeProcess(PI.hProcess, ExitCode) then
          RaiseLastOSError;
        Result := ExitCode = 0;
      finally
        CloseHandle(PI.hThread);
        CloseHandle(PI.hProcess);
      end;
    finally
      CloseHandle(LogHandle);
    end;
    AOutput := TFile.ReadAllText(LogPath, TEncoding.Default);
  finally
    if FileExists(PassPath) then DeleteFile(PassPath);
    if FileExists(LogPath) then DeleteFile(LogPath);
  end;
end;

procedure TfrmBackup.BackupClick(Sender: TObject);
var
  Target, Output: string;
begin
  try
    ForceDirectories(FBackupFolder);
    Target := BackupFileName;
    if FileExists(Target) then
      raise Exception.Create('백업 파일이 이미 존재합니다. 다른 파일명을 선택하세요.');
    FBackupButton.Enabled := False;
    FVerifyButton.Enabled := False;
    try
      FLog.Lines.Add('');
      FLog.Lines.Add('백업 시작: ' + Target);
      Application.ProcessMessages;
      if not RunGbak('-b -g -v ' + Quote(DatabaseName) + ' ' +
        Quote(Target), Output) then
        raise Exception.Create('gbak 백업 실패.' + sLineBreak + Output);
      FLog.Lines.Add(Output);
      FLog.Lines.Add('백업 완료: ' + Target);
      MessageDlg('데이터 백업이 완료되었습니다.' + sLineBreak + Target,
        mtInformation, [mbOK], 0);
    finally
      FBackupButton.Enabled := True;
      FVerifyButton.Enabled := True;
    end;
  except
    on E: Exception do
    begin
      FLog.Lines.Add('오류: ' + E.Message);
      MessageDlg('백업 실패: ' + E.Message, mtError, [mbOK], 0);
    end;
  end;
end;

procedure TfrmBackup.VerifyClick(Sender: TObject);
var
  Dlg: TOpenDialog;
  BackupPath, DbName, DbPath, Prefix, Ext, Output: string;
  P, ServerPrefix: Integer;
begin
  Dlg := TOpenDialog.Create(Self);
  try
    Dlg.Title := '복구 검증에 사용할 백업 파일 선택';
    Dlg.Filter := 'Firebird 백업 (*.fbk)|*.fbk|모든 파일 (*.*)|*.*';
    Dlg.InitialDir := FBackupFolder;
    if not Dlg.Execute then Exit;
    BackupPath := Dlg.FileName;
  finally
    Dlg.Free;
  end;

  DbName := DatabaseName;
  P := Pos(':', DbName);
  if (P > 1) and (Pos('\', Copy(DbName, P + 1, MaxInt)) > 0) then
  begin
    ServerPrefix := P;
    Prefix := Copy(DbName, 1, ServerPrefix);
    DbPath := Copy(DbName, ServerPrefix + 1, MaxInt);
  end
  else
  begin
    Prefix := '';
    DbPath := DbName;
  end;

  Ext := ExtractFileExt(DbPath);
  DbName := Prefix + ChangeFileExt(DbPath, '') +
    '_RESTORE_TEST_' + FormatDateTime('yyyymmdd_hhnnss', Now) + Ext;

  if MessageDlg('선택한 백업을 별도 검증용 DB로 복구합니다.' + sLineBreak +
    '운영 DB는 변경하지 않습니다.' + sLineBreak + sLineBreak +
    '검증 DB: ' + DbName + sLineBreak +
    '복구 완료 후 검증 DB 파일은 Firebird 서버에서 직접 확인/정리해야 합니다.',
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  try
    FBackupButton.Enabled := False;
    FVerifyButton.Enabled := False;
    FLog.Lines.Add('');
    FLog.Lines.Add('복구 검증 시작: ' + BackupPath);
    FLog.Lines.Add('대상 DB: ' + DbName);
    Application.ProcessMessages;
    if not RunGbak('-c -v ' + Quote(BackupPath) + ' ' +
      Quote(DbName), Output) then
      raise Exception.Create('복구 검증 실패.' + sLineBreak + Output);
    FLog.Lines.Add(Output);
    FLog.Lines.Add('복구 검증용 DB 생성 완료: ' + DbName);
    MessageDlg('백업 파일의 복구가 완료되었습니다.' + sLineBreak +
      '운영 DB는 변경되지 않았습니다.' + sLineBreak +
      '검증 DB 파일: ' + DbName, mtInformation, [mbOK], 0);
  except
    on E: Exception do
    begin
      FLog.Lines.Add('오류: ' + E.Message);
      MessageDlg('복구 검증 실패: ' + E.Message, mtError, [mbOK], 0);
    end;
  end;
  FBackupButton.Enabled := True;
  FVerifyButton.Enabled := True;
end;

end.
