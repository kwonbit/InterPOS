unit uKitchenPrinter;

interface

uses
  System.SysUtils, System.Classes, System.IniFiles, FireDAC.Comp.Client;

type
  TKitchenPrinterSettings = record
    PortName: string;
    BaudRate: Integer;
  end;

  TKitchenPrinter = class
  private
    class function SettingsFileName: string; static;
    class function EncodeKorean(const AText: string): TBytes; static;
    class procedure AddText(AStream: TMemoryStream; const AText: string); static;
    class procedure AddCommand(AStream: TMemoryStream; const ABytes: array of Byte); static;
    class procedure SendBytes(const ASettings: TKitchenPrinterSettings;
      const AData: TBytes); static;
  public
    class function LoadSettings: TKitchenPrinterSettings; static;
    class procedure SaveSettings(const ASettings: TKitchenPrinterSettings); static;
    class procedure TestPrint(const ASettings: TKitchenPrinterSettings); static;
    class procedure PrintTicket(AConnection: TFDConnection; AStoreID: Integer;
      ATicketID: Int64); static;
  end;

implementation

uses
  Winapi.Windows;

class function TKitchenPrinter.SettingsFileName: string;
begin
  Result := ChangeFileExt(ParamStr(0), '.ini');
end;

class function TKitchenPrinter.LoadSettings: TKitchenPrinterSettings;
var
  Ini: TIniFile;
begin
  Result.PortName := 'COM2';
  Result.BaudRate := 9600;
  Ini := TIniFile.Create(SettingsFileName);
  try
    Result.PortName := Ini.ReadString('KitchenPrinter', 'Port', Result.PortName);
    Result.BaudRate := Ini.ReadInteger('KitchenPrinter', 'BaudRate', Result.BaudRate);
  finally
    Ini.Free;
  end;
end;

class procedure TKitchenPrinter.SaveSettings(
  const ASettings: TKitchenPrinterSettings);
var
  Ini: TIniFile;
begin
  if Trim(ASettings.PortName) = '' then
    raise Exception.Create('주방 프린터 COM 포트를 입력해 주세요.');
  if not ((ASettings.BaudRate = 2400) or (ASettings.BaudRate = 4800) or
    (ASettings.BaudRate = 9600) or (ASettings.BaudRate = 19200) or
    (ASettings.BaudRate = 38400) or (ASettings.BaudRate = 57600) or
    (ASettings.BaudRate = 115200)) then
    raise Exception.Create('지원하지 않는 통신 속도입니다.');
  Ini := TIniFile.Create(SettingsFileName);
  try
    Ini.WriteString('KitchenPrinter', 'Port', UpperCase(Trim(ASettings.PortName)));
    Ini.WriteInteger('KitchenPrinter', 'BaudRate', ASettings.BaudRate);
    Ini.UpdateFile;
  finally
    Ini.Free;
  end;
end;

class function TKitchenPrinter.EncodeKorean(const AText: string): TBytes;
var
  Encoding: TEncoding;
begin
  Encoding := TEncoding.GetEncoding(949);
  try
    Result := Encoding.GetBytes(AText);
  finally
    Encoding.Free;
  end;
end;

class procedure TKitchenPrinter.AddText(AStream: TMemoryStream;
  const AText: string);
var
  B: TBytes;
begin
  B := EncodeKorean(AText);
  if Length(B) > 0 then
    AStream.WriteBuffer(B[0], Length(B));
end;

class procedure TKitchenPrinter.AddCommand(AStream: TMemoryStream;
  const ABytes: array of Byte);
begin
  if Length(ABytes) > 0 then
    AStream.WriteBuffer(ABytes[0], Length(ABytes));
end;

class procedure TKitchenPrinter.SendBytes(
  const ASettings: TKitchenPrinterSettings; const AData: TBytes);
var
  Handle: THandle;
  DCB: TDCB;
  Timeouts: TCommTimeouts;
  Written, Offset, Chunk: DWORD;
  DeviceName: string;
begin
  if Trim(ASettings.PortName) = '' then
    raise Exception.Create('주방 프린터 COM 포트가 설정되지 않았습니다.');
  DeviceName := '\\.' + '\' + UpperCase(Trim(ASettings.PortName));
  Handle := CreateFile(PChar(DeviceName), GENERIC_WRITE, 0, nil,
    OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if Handle = INVALID_HANDLE_VALUE then
    RaiseLastOSError;
  try
    FillChar(DCB, SizeOf(DCB), 0);
    DCB.DCBlength := SizeOf(DCB);
    if not GetCommState(Handle, DCB) then RaiseLastOSError;
    DCB.BaudRate := ASettings.BaudRate;
    DCB.ByteSize := 8;
    DCB.Parity := NOPARITY;
    DCB.StopBits := ONESTOPBIT;
    DCB.Flags := DCB.Flags or $00000001;
    if not SetCommState(Handle, DCB) then RaiseLastOSError;
    FillChar(Timeouts, SizeOf(Timeouts), 0);
    Timeouts.WriteTotalTimeoutConstant := 5000;
    Timeouts.WriteTotalTimeoutMultiplier := 10;
    if not SetCommTimeouts(Handle, Timeouts) then RaiseLastOSError;
    PurgeComm(Handle, PURGE_TXABORT or PURGE_TXCLEAR);
    Offset := 0;
    while Offset < DWORD(Length(AData)) do
    begin
      Chunk := DWORD(Length(AData)) - Offset;
      if Chunk > 4096 then Chunk := 4096;
      Written := 0;
      if not WriteFile(Handle, AData[Offset], Chunk, Written, nil) then
        RaiseLastOSError;
      if Written = 0 then
        raise Exception.Create('주방 프린터로 데이터를 전송하지 못했습니다.');
      Inc(Offset, Written);
    end;
  finally
    CloseHandle(Handle);
  end;
end;

class procedure TKitchenPrinter.TestPrint(
  const ASettings: TKitchenPrinterSettings);
var
  Stream: TMemoryStream;
  Data: TBytes;
begin
  Stream := TMemoryStream.Create;
  try
    AddCommand(Stream, [$1B, $40, $1B, $61, $01, $1B, $45, $01]);
    AddText(Stream, 'InterPOS 주방 프린터 테스트' + sLineBreak);
    AddCommand(Stream, [$1B, $45, $00, $1B, $61, $00]);
    AddText(Stream, '포트: ' + ASettings.PortName + ' / ' +
      IntToStr(ASettings.BaudRate) + ' bps' + sLineBreak);
    AddText(Stream, '주방 주문서 출력 준비 완료' + sLineBreak + sLineBreak);
    AddCommand(Stream, [$1B, $64, $03, $1B, $6D]);
    SetLength(Data, Stream.Size);
    Stream.Position := 0;
    if Stream.Size > 0 then Stream.ReadBuffer(Data[0], Stream.Size);
  finally
    Stream.Free;
  end;
  SendBytes(ASettings, Data);
end;

class procedure TKitchenPrinter.PrintTicket(AConnection: TFDConnection;
  AStoreID: Integer; ATicketID: Int64);
var
  Q: TFDQuery;
  Stream: TMemoryStream;
  Data: TBytes;
  Settings: TKitchenPrinterSettings;
  TicketNo, OrderNo, TableName, StoreName, ItemName, OptionText: string;
  ItemQty: Double;
begin
  Settings := LoadSettings;
  Q := TFDQuery.Create(nil);
  Stream := TMemoryStream.Create;
  try
    Q.Connection := AConnection;
    Q.SQL.Text :=
      'SELECT K.TICKET_NO, K.CREATED_AT, O.ORDER_NO, S.STORE_NAME, ' +
      'COALESCE(T.TABLE_NAME, ''포장/기타'') AS TABLE_NAME ' +
      'FROM POS_KITCHEN_TICKET K JOIN POS_ORDER O ON O.ORDER_ID=K.ORDER_ID ' +
      'JOIN STORE_INFO S ON S.STORE_ID=O.STORE_ID ' +
      'LEFT JOIN POS_TABLE T ON T.TABLE_ID=O.TABLE_ID ' +
      'WHERE O.STORE_ID=:STORE_ID AND K.KITCHEN_TICKET_ID=:TICKET_ID';
    Q.ParamByName('STORE_ID').AsInteger := AStoreID;
    Q.ParamByName('TICKET_ID').AsLargeInt := ATicketID;
    Q.Open;
    if Q.IsEmpty then
      raise Exception.Create('출력할 주방 주문서를 찾을 수 없습니다.');
    TicketNo := Q.FieldByName('TICKET_NO').AsString;
    OrderNo := Q.FieldByName('ORDER_NO').AsString;
    StoreName := Q.FieldByName('STORE_NAME').AsString;
    TableName := Q.FieldByName('TABLE_NAME').AsString;

    AddCommand(Stream, [$1B, $40, $1B, $61, $01, $1B, $45, $01]);
    AddText(Stream, '주 방 주 문 서' + sLineBreak);
    AddCommand(Stream, [$1B, $45, $00]);
    AddText(Stream, StoreName + sLineBreak);
    AddCommand(Stream, [$1B, $61, $00]);
    AddText(Stream, '------------------------------------------' + sLineBreak);
    AddText(Stream, '티켓: ' + TicketNo + sLineBreak);
    AddText(Stream, '주문: ' + OrderNo + sLineBreak);
    AddText(Stream, '테이블: ' + TableName + sLineBreak);
    AddText(Stream, '접수: ' +
      FormatDateTime('yyyy-mm-dd hh:nn:ss', Q.FieldByName('CREATED_AT').AsDateTime) +
      sLineBreak);
    AddText(Stream, '------------------------------------------' + sLineBreak);
    Q.Close;

    Q.SQL.Text :=
      'SELECT MENU_NAME, QUANTITY, OPTION_TEXT FROM POS_ORDER_ITEM ' +
      'WHERE KITCHEN_TICKET_ID=:TICKET_ID ORDER BY ORDER_ITEM_ID';
    Q.ParamByName('TICKET_ID').AsLargeInt := ATicketID;
    Q.Open;
    while not Q.Eof do
    begin
      ItemName := Q.FieldByName('MENU_NAME').AsString;
      OptionText := Q.FieldByName('OPTION_TEXT').AsString;
      ItemQty := Q.FieldByName('QUANTITY').AsFloat;
      AddCommand(Stream, [$1B, $45, $01]);
      AddText(Stream, ItemName + '  x ' + FormatFloat('#,##0.###', ItemQty) +
        sLineBreak);
      AddCommand(Stream, [$1B, $45, $00]);
      if OptionText <> '' then
        AddText(Stream, '  옵션: ' + OptionText + sLineBreak);
      Q.Next;
    end;
    AddText(Stream, '------------------------------------------' + sLineBreak);
    AddCommand(Stream, [$1B, $61, $01]);
    AddText(Stream, '조리 요청 확인' + sLineBreak + sLineBreak);
    AddCommand(Stream, [$1B, $64, $04, $1B, $6D]);
    SetLength(Data, Stream.Size);
    Stream.Position := 0;
    if Stream.Size > 0 then Stream.ReadBuffer(Data[0], Stream.Size);
  finally
    Stream.Free;
    Q.Free;
  end;
  SendBytes(Settings, Data);
end;

end.
