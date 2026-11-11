unit uScheduledBackup;

interface

function RunScheduledBackup: Integer;
procedure ConfigureDailyBackupTask(const AEnabled: Boolean;
  const ATime: string);

implementation

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.IOUtils,
  System.IniFiles, System.DateUtils, uDatabase;

const
  CTaskName = 'InterPOS_DailyBackup';

function QuoteArg(const S: string): string;
begin
  Result := '"' + StringReplace(S, '"', '\"', [rfReplaceAll]) + '"';
end;

function IniPath: string;
begin
  Result := ChangeFileExt(ParamStr(0), '.ini');
end;

function ReadBackupSetting(const AName, ADefault: string): string;
var
  Ini: TIniFile;
begin
  Result := ADefault;
  if not FileExists(IniPath) then Exit;
  Ini := TIniFile.Create(IniPath);
  try
    Result := Ini.ReadString('Backup', AName, ADefault);
  finally
    Ini.Free;
  end;
end;

function BackupLogPath(const AFolder: string): string;
begin
  Result := TPath.Combine(AFolder, 'scheduled-backup.log');
end;

procedure WriteBackupLog(const AFolder, AMessage: string);
var
  Line: string;
begin
  Line := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + '  ' +
    AMessage + sLineBreak;
  ForceDirectories(AFolder);
  TFile.AppendAllText(BackupLogPath(AFolder), Line, TEncoding.UTF8);
end;

function PasswordFile: string;
var
  P: string;
begin
  P := TPath.GetTempFileName;
  TFile.WriteAllText(P, dmDatabase.Connection.Params.Values['Password'],
    TEncoding.ASCII);
  Result := P;
end;

function RunGbak(const ABackupFile, AGbakPath: string;
  out AOutput: string): Boolean;
var
  SI: TStartupInfo;
  PI: TProcessInformation;
  LogPath, PassPath, Cmd: string;
  LogHandle: THandle;
  SA: TSecurityAttributes;
  ExitCode: DWORD;
begin
  Result := False;
  AOutput := '';
  if not FileExists(AGbakPath) then
    raise Exception.Create('gbak.exe를 찾을 수 없습니다: ' + AGbakPath);

  PassPath := PasswordFile;
  LogPath := TPath.GetTempFileName;
  try
    ZeroMemory(@SA, SizeOf(SA));
    SA.nLength := SizeOf(SA);
    SA.bInheritHandle := True;
    LogHandle := CreateFile(PChar(LogPath), GENERIC_WRITE,
      FILE_SHARE_READ or FILE_SHARE_WRITE, @SA, CREATE_ALWAYS,
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

      Cmd := QuoteArg(AGbakPath) + ' -b -g -v ' +
        QuoteArg(dmDatabase.Connection.Params.Database) +
        ' ' + QuoteArg(ABackupFile) +
        ' -user ' + QuoteArg(dmDatabase.Connection.Params.UserName) +
        ' -fetch_password ' + QuoteArg(PassPath);
      UniqueString(Cmd);
      if not CreateProcess(PChar(AGbakPath), PChar(Cmd), nil, nil, True,
        CREATE_NO_WINDOW, nil, PChar(ExtractFilePath(AGbakPath)), SI, PI) then
        RaiseLastOSError;
      try
        if WaitForSingleObject(PI.hProcess, INFINITE) <> WAIT_OBJECT_0 then
          RaiseLastOSError;
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
    if FileExists(PassPath) then TFile.Delete(PassPath);
    if FileExists(LogPath) then TFile.Delete(LogPath);
  end;
end;

procedure CleanupOldBackups(const AFolder: string; const ARetentionDays: Integer);
var
  SR: TSearchRec;
  SearchResult: Integer;
  FilePath: string;
  Cutoff: TDateTime;
begin
  if ARetentionDays < 1 then
    raise Exception.Create('백업 보관 기간은 1일 이상이어야 합니다.');
  Cutoff := IncDay(Date, -ARetentionDays);
  SearchResult := FindFirst(TPath.Combine(AFolder, 'INTERPOS_*.fbk'),
    faAnyFile, SR);
  try
    while SearchResult = 0 do
    begin
      if (SR.Attr and faDirectory) = 0 then
      begin
        FilePath := TPath.Combine(AFolder, SR.Name);
        if FileDateToDateTime(SR.Time) < Cutoff then
        begin
          TFile.Delete(FilePath);
          WriteBackupLog(AFolder, '오래된 백업 삭제: ' + FilePath);
        end;
      end;
      SearchResult := FindNext(SR);
    end;
  finally
    FindClose(SR);
  end;
end;

function RunScheduledBackup: Integer;
var
  Folder, Gbak, Target, Output: string;
  RetentionDays: Integer;
  Ini: TIniFile;
  MutexHandle: THandle;
  WaitResult: DWORD;
begin
  Result := 1;
  Folder := ReadBackupSetting('BackupFolder',
    TPath.Combine(ExtractFilePath(ParamStr(0)), 'backup'));
  Gbak := ReadBackupSetting('GbakPath',
    'C:\Program Files\Firebird\Firebird_5_0\gbak.exe');
  RetentionDays := StrToIntDef(ReadBackupSetting('RetentionDays', '30'), 30);
  try
    if FileExists(IniPath) then
    begin
      Ini := TIniFile.Create(IniPath);
      try
        if not Ini.ReadBool('Backup', 'ScheduleEnabled', False) then
        begin
          WriteBackupLog(Folder, '예약 백업이 비활성화되어 작업을 건너뜁니다.');
          Exit(2);
        end;
      finally
        Ini.Free;
      end;
    end
    else
    begin
      WriteBackupLog(Folder, 'InterPOS.ini 파일을 찾을 수 없습니다.');
      Exit(2);
    end;

    ForceDirectories(Folder);
    MutexHandle := CreateMutex(nil, False, 'Global\InterPOS_ScheduledBackup');
    if MutexHandle = 0 then
      RaiseLastOSError;
    try
      WaitResult := WaitForSingleObject(MutexHandle, 0);
      if WaitResult = WAIT_TIMEOUT then
      begin
        WriteBackupLog(Folder, '이미 다른 예약 백업이 실행 중이므로 이번 작업을 건너뜁니다.');
        Exit(3);
      end;
      if (WaitResult <> WAIT_OBJECT_0) and
        (WaitResult <> WAIT_ABANDONED) then
        RaiseLastOSError;
      try
        if not dmDatabase.IsConnected then
          dmDatabase.Connect;
        Target := TPath.Combine(Folder,
          'INTERPOS_' + FormatDateTime('yyyymmdd_hhnnss_zzz', Now) + '.fbk');
        WriteBackupLog(Folder, '예약 백업 시작: ' + Target);
        if not RunGbak(Target, Gbak, Output) then
          raise Exception.Create('gbak 백업 실패.' + sLineBreak + Output);
        if (not FileExists(Target)) or (TFile.GetSize(Target) = 0) then
          raise Exception.Create('gbak 실행은 성공했지만 백업 파일이 생성되지 않았거나 비어 있습니다.');
        WriteBackupLog(Folder, '백업 성공: ' + Target);
        if Output <> '' then
          WriteBackupLog(Folder, Trim(Output));
        CleanupOldBackups(Folder, RetentionDays);
        WriteBackupLog(Folder, '보관 기간 정리 완료: 최근 ' +
          IntToStr(RetentionDays) + '일');
        Result := 0;
      finally
        ReleaseMutex(MutexHandle);
      end;
    finally
      CloseHandle(MutexHandle);
    end;
  except
    on E: Exception do
    begin
      try
        WriteBackupLog(Folder, '백업 실패: ' + E.Message);
      except
        // Keep the process exit code even if the log folder is unavailable.
      end;
      Result := 1;
    end;
  end;
end;

function RunSchtasks(const AArguments: string): DWORD;
var
  SI: TStartupInfo;
  PI: TProcessInformation;
  Cmd, ExePath: string;
  ExitCode: DWORD;
  Buffer: array[0..MAX_PATH] of Char;
begin
  if GetSystemDirectory(Buffer, MAX_PATH) = 0 then
    RaiseLastOSError;
  ExePath := IncludeTrailingPathDelimiter(string(PChar(@Buffer[0]))) + 'schtasks.exe';
  if not FileExists(ExePath) then
    raise Exception.Create('Windows schtasks.exe를 찾을 수 없습니다.');
  Cmd := QuoteArg(ExePath) + ' ' + AArguments;
  UniqueString(Cmd);
  ZeroMemory(@SI, SizeOf(SI));
  SI.cb := SizeOf(SI);
  SI.dwFlags := STARTF_USESHOWWINDOW;
  SI.wShowWindow := SW_HIDE;
  if not CreateProcess(PChar(ExePath), PChar(Cmd), nil, nil, False,
    CREATE_NO_WINDOW, nil, nil, SI, PI) then
    RaiseLastOSError;
  try
    if WaitForSingleObject(PI.hProcess, INFINITE) <> WAIT_OBJECT_0 then
      RaiseLastOSError;
    if not GetExitCodeProcess(PI.hProcess, ExitCode) then
      RaiseLastOSError;
    Result := ExitCode;
  finally
    CloseHandle(PI.hThread);
    CloseHandle(PI.hProcess);
  end;
end;

procedure ConfigureDailyBackupTask(const AEnabled: Boolean;
  const ATime: string);
var
  Ini: TIniFile;
  Args, ExeCommand: string;
  H, M: Integer;
begin
  if AEnabled then
  begin
    if (Length(ATime) <> 5) or (ATime[3] <> ':') or
      (not TryStrToInt(Copy(ATime, 1, 2), H)) or
      (not TryStrToInt(Copy(ATime, 4, 2), M)) or
      (H < 0) or (H > 23) or (M < 0) or (M > 59) then
      raise Exception.Create('예약 시간은 HH:MM 형식으로 입력해 주세요. 예: 02:00');

    ExeCommand := QuoteArg(ParamStr(0)) + ' /backup';
    Args := '/Create /SC DAILY /ST ' + ATime +
      ' /TN ' + QuoteArg(CTaskName) +
      ' /TR ' + QuoteArg(ExeCommand) +
      ' /RU SYSTEM /RL HIGHEST /F';
    if RunSchtasks(Args) <> 0 then
      raise Exception.Create('Windows 작업 스케줄러에 예약 작업을 등록하지 못했습니다. 관리자 권한으로 InterPOS를 실행했는지 확인해 주세요.');

    Ini := TIniFile.Create(IniPath);
    try
      Ini.WriteBool('Backup', 'ScheduleEnabled', True);
      Ini.WriteString('Backup', 'ScheduleTime', ATime);
    finally
      Ini.Free;
    end;
  end
  else
  begin
    RunSchtasks('/Delete /TN ' + QuoteArg(CTaskName) + ' /F');
    if FileExists(IniPath) then
    begin
      Ini := TIniFile.Create(IniPath);
      try
        Ini.WriteBool('Backup', 'ScheduleEnabled', False);
      finally
        Ini.Free;
      end;
    end;
  end;
end;

end.
