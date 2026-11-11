unit uCashDrawer;

interface

type
  TCashDrawer = class
  public
    class function IsEnabled: Boolean; static;
    class procedure OpenIfEnabled; static;
  end;

implementation

uses
  System.SysUtils, System.IniFiles, Winapi.Windows;

class function TCashDrawer.IsEnabled: Boolean;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(ChangeFileExt(ParamStr(0), '.ini'));
  try
    Result := Ini.ReadBool('CashDrawer', 'Enabled', False);
  finally
    Ini.Free;
  end;
end;

class procedure TCashDrawer.OpenIfEnabled;
var
  Ini: TIniFile;
  PortName, DeviceName: string;
  BaudRate, Pin, PulseOn, PulseOff: Integer;
  Handle: THandle;
  DCB: TDCB;
  Timeouts: TCommTimeouts;
  Data: array[0..4] of Byte;
  Written: DWORD;
begin
  Ini := TIniFile.Create(ChangeFileExt(ParamStr(0), '.ini'));
  try
    if not Ini.ReadBool('CashDrawer', 'Enabled', False) then
      Exit;
    PortName := UpperCase(Trim(Ini.ReadString('CashDrawer', 'Port', 'COM1')));
    BaudRate := Ini.ReadInteger('CashDrawer', 'BaudRate', 9600);
    Pin := Ini.ReadInteger('CashDrawer', 'Pin', 0);
    PulseOn := Ini.ReadInteger('CashDrawer', 'PulseOn', 25);
    PulseOff := Ini.ReadInteger('CashDrawer', 'PulseOff', 250);
  finally
    Ini.Free;
  end;

  if PortName = '' then
    raise Exception.Create('돈통 프린터 COM 포트가 설정되지 않았습니다.');
  if not ((BaudRate = 2400) or (BaudRate = 4800) or
    (BaudRate = 9600) or (BaudRate = 19200) or
    (BaudRate = 38400) or (BaudRate = 57600) or (BaudRate = 115200)) then
    raise Exception.Create('돈통 통신 속도가 올바르지 않습니다.');
  if not ((Pin = 0) or (Pin = 1)) then
    raise Exception.Create('돈통 신호 핀은 0 또는 1이어야 합니다.');
  if (PulseOn < 1) or (PulseOn > 255) or
     (PulseOff < 1) or (PulseOff > 255) then
    raise Exception.Create('돈통 펄스 시간은 1~255 범위여야 합니다.');

  DeviceName := '\\.' + '\' + PortName;
  Handle := CreateFile(PChar(DeviceName), GENERIC_WRITE, 0, nil,
    OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if Handle = INVALID_HANDLE_VALUE then
    RaiseLastOSError;
  try
    FillChar(DCB, SizeOf(DCB), 0);
    DCB.DCBlength := SizeOf(DCB);
    if not GetCommState(Handle, DCB) then
      RaiseLastOSError;
    DCB.BaudRate := BaudRate;
    DCB.ByteSize := 8;
    DCB.Parity := NOPARITY;
    DCB.StopBits := ONESTOPBIT;
    DCB.Flags := DCB.Flags or $00000001;
    if not SetCommState(Handle, DCB) then
      RaiseLastOSError;

    FillChar(Timeouts, SizeOf(Timeouts), 0);
    Timeouts.WriteTotalTimeoutConstant := 3000;
    Timeouts.WriteTotalTimeoutMultiplier := 10;
    if not SetCommTimeouts(Handle, Timeouts) then
      RaiseLastOSError;

    Data[0] := $1B; // ESC
    Data[1] := $70; // Drawer kick
    Data[2] := Byte(Pin);
    Data[3] := Byte(PulseOn);
    Data[4] := Byte(PulseOff);
    Written := 0;
    if not WriteFile(Handle, Data[0], SizeOf(Data), Written, nil) then
      RaiseLastOSError;
    if Written <> SizeOf(Data) then
      raise Exception.Create('돈통 열림 신호를 프린터에 모두 전송하지 못했습니다.');
  finally
    CloseHandle(Handle);
  end;
end;

end.
