unit uReceiptPrinter;

interface

uses
  System.SysUtils, System.Classes, System.IniFiles, Data.DB,
  FireDAC.Comp.Client;

type
  TReceiptPrinterSettings = record
    PortName: string;
    BaudRate: Integer;
  end;

  TReceiptPrinter = class
  private
    class function SettingsFileName: string; static;
    class function EncodeKorean(const AText: string): TBytes; static;
    class procedure SendBytes(const ASettings: TReceiptPrinterSettings;
      const AData: TBytes); static;
    class procedure AddText(AStream: TMemoryStream; const AText: string); static;
    class procedure AddCommand(AStream: TMemoryStream;
      const ABytes: array of Byte); static;
  public
    class function LoadSettings: TReceiptPrinterSettings; static;
    class procedure SaveSettings(const ASettings: TReceiptPrinterSettings); static;
    class procedure TestPrint(const ASettings: TReceiptPrinterSettings); static;
    class procedure PrintReceipt(AConnection: TFDConnection;
      AStoreID: Integer; AOrderID: Int64); static;
  end;

implementation

uses
  Winapi.Windows;

class function TReceiptPrinter.SettingsFileName: string;
begin
  Result := ChangeFileExt(ParamStr(0), '.ini');
end;

class function TReceiptPrinter.LoadSettings: TReceiptPrinterSettings;
var
  Ini: TIniFile;
begin
  Result.PortName := 'COM1';
  Result.BaudRate := 9600;
  Ini := TIniFile.Create(SettingsFileName);
  try
    Result.PortName := Ini.ReadString('ReceiptPrinter', 'Port', Result.PortName);
    Result.BaudRate := Ini.ReadInteger('ReceiptPrinter', 'BaudRate', Result.BaudRate);
  finally
    Ini.Free;
  end;
end;

class procedure TReceiptPrinter.SaveSettings(
  const ASettings: TReceiptPrinterSettings);
var
  Ini: TIniFile;
begin
  if Trim(ASettings.PortName) = '' then
    raise Exception.Create('프린터 COM 포트를 입력해 주세요.');
  if not (ASettings.BaudRate in [2400, 4800, 9600, 19200, 38400, 57600, 115200]) then
    raise Exception.Create('지원하지 않는 통신 속도입니다.');
  Ini := TIniFile.Create(SettingsFileName);
  try
    Ini.WriteString('ReceiptPrinter', 'Port', UpperCase(Trim(ASettings.PortName)));
    Ini.WriteInteger('ReceiptPrinter', 'BaudRate', ASettings.BaudRate);
    Ini.UpdateFile;
  finally
    Ini.Free;
  end;
end;

class function TReceiptPrinter.EncodeKorean(const AText: string): TBytes;
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

class procedure TReceiptPrinter.AddText(AStream: TMemoryStream;
  const AText: string);
var
  B: TBytes;
begin
  B := EncodeKorean(AText);
  if Length(B) > 0 then
    AStream.WriteBuffer(B[0], Length(B));
end;

class procedure TReceiptPrinter.AddCommand(AStream: TMemoryStream;
  const ABytes: array of Byte);
begin
  if Length(ABytes) > 0 then
    AStream.WriteBuffer(ABytes[0], Length(ABytes));
end;

class procedure TReceiptPrinter.SendBytes(
  const ASettings: TReceiptPrinterSettings; const AData: TBytes);
var
  Handle: THandle;
  DCB: TDCB;
  Timeouts: TCommTimeouts;
  Written, Offset, Chunk: DWORD;
  DeviceName: string;
begin
  if Trim(ASettings.PortName) = '' then
    raise Exception.Create('프린터 COM 포트가 설정되지 않았습니다.');
  if not (ASettings.BaudRate in [2400, 4800, 9600, 19200, 38400, 57600, 115200]) then
    raise Exception.Create('지원하지 않는 프린터 통신 속도입니다.');

  DeviceName := '\\.' + '\' + UpperCase(Trim(ASettings.PortName));
  Handle := CreateFile(PChar(DeviceName), GENERIC_WRITE, 0, nil,
    OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if Handle = INVALID_HANDLE_VALUE then
    RaiseLastOSError;

  try
    FillChar(DCB, SizeOf(DCB), 0);
    DCB.DCBlength := SizeOf(DCB);
    if not GetCommState(Handle, DCB) then
      RaiseLastOSError;
    DCB.BaudRate := ASettings.BaudRate;
    DCB.ByteSize := 8;
    DCB.Parity := NOPARITY;
    DCB.StopBits := ONESTOPBIT;
    DCB.Flags := DCB.Flags or $00000001;
    if not SetCommState(Handle, DCB) then
      RaiseLastOSError;

    FillChar(Timeouts, SizeOf(Timeouts), 0);
    Timeouts.WriteTotalTimeoutConstant := 5000;
    Timeouts.WriteTotalTimeoutMultiplier := 10;
    if not SetCommTimeouts(Handle, Timeouts) then
      RaiseLastOSError;
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
        raise Exception.Create('영수증 프린터로 데이터를 전송하지 못했습니다.');
      Inc(Offset, Written);
    end;
  finally
    CloseHandle(Handle);
  end;
end;

class procedure TReceiptPrinter.TestPrint(
  const ASettings: TReceiptPrinterSettings);
var
  Stream: TMemoryStream;
  Data: TBytes;
begin
  Stream := TMemoryStream.Create;
  try
    AddCommand(Stream, [$1B, $40, $1B, $61, $01]);
    AddText(Stream, 'InterPOS 프린터 테스트' + sLineBreak);
    AddText(Stream, 'BIXOLON SRP-350PG' + sLineBreak);
    AddText(Stream, '통신 포트: ' + ASettings.PortName + sLineBreak);
    AddText(Stream, '통신 속도: ' + IntToStr(ASettings.BaudRate) + ' bps' + sLineBreak);
    AddCommand(Stream, [$1B, $61, $00]);
    AddText(Stream, '------------------------------------------' + sLineBreak);
    AddText(Stream, 'Serial communication test OK' + sLineBreak + sLineBreak);
    AddCommand(Stream, [$1B, $64, $03, $1B, $6D]);
    SetLength(Data, Stream.Size);
    Stream.Position := 0;
    if Stream.Size > 0 then Stream.ReadBuffer(Data[0], Stream.Size);
  finally
    Stream.Free;
  end;
  SendBytes(ASettings, Data);
end;

class procedure TReceiptPrinter.PrintReceipt(AConnection: TFDConnection;
  AStoreID: Integer; AOrderID: Int64);
var
  Q: TFDQuery;
  Stream: TMemoryStream;
  Data: TBytes;
  Settings: TReceiptPrinterSettings;
  StoreName, OrderNo, TableName, MethodName: string;
  TotalAmount, PaidAmount: Currency;
  ItemName, OptionText: string;
begin
  Settings := LoadSettings;
  Q := TFDQuery.Create(nil);
  Stream := TMemoryStream.Create;
  try
    Q.Connection := AConnection;
    Q.SQL.Text :=
      'SELECT S.STORE_NAME, O.ORDER_NO, O.TOTAL_AMOUNT, O.ORDERED_AT, ' +
      'T.TABLE_NAME FROM POS_ORDER O ' +
      'JOIN STORE_INFO S ON S.STORE_ID=O.STORE_ID ' +
      'LEFT JOIN POS_TABLE T ON T.TABLE_ID=O.TABLE_ID ' +
      'WHERE O.STORE_ID=:STORE_ID AND O.ORDER_ID=:ORDER_ID';
    Q.ParamByName('STORE_ID').AsInteger := AStoreID;
    Q.ParamByName('ORDER_ID').AsLargeInt := AOrderID;
    Q.Open;
    if Q.IsEmpty then
      raise Exception.Create('영수증을 출력할 주문을 찾을 수 없습니다.');
    StoreName := Q.FieldByName('STORE_NAME').AsString;
    OrderNo := Q.FieldByName('ORDER_NO').AsString;
    TotalAmount := Q.FieldByName('TOTAL_AMOUNT').AsCurrency;
    TableName := Q.FieldByName('TABLE_NAME').AsString;
    AddCommand(Stream, [$1B, $40, $1B, $61, $01]);
    AddText(Stream, StoreName + sLineBreak);
    AddText(Stream, '영 수 증' + sLineBreak);
    AddCommand(Stream, [$1B, $61, $00]);
    AddText(Stream, '------------------------------------------' + sLineBreak);
    AddText(Stream, '주문번호: ' + OrderNo + sLineBreak);
    AddText(Stream, '테이블: ' + TableName + sLineBreak);
    AddText(Stream, '주문일시: ' +
      FormatDateTime('yyyy-mm-dd hh:nn:ss', Q.FieldByName('ORDERED_AT').AsDateTime) +
      sLineBreak);
    AddText(Stream, '------------------------------------------' + sLineBreak);
    Q.Close;

    Q.SQL.Text :=
      'SELECT MENU_NAME, UNIT_PRICE, QUANTITY, LINE_AMOUNT, OPTION_TEXT ' +
      'FROM POS_ORDER_ITEM WHERE ORDER_ID=:ORDER_ID ORDER BY ORDER_ITEM_ID';
    Q.ParamByName('ORDER_ID').AsLargeInt := AOrderID;
    Q.Open;
    while not Q.Eof do
    begin
      ItemName := Q.FieldByName('MENU_NAME').AsString;
      OptionText := Q.FieldByName('OPTION_TEXT').AsString;
      AddText(Stream, ItemName + sLineBreak);
      if OptionText <> '' then AddText(Stream, '  ' + OptionText + sLineBreak);
      AddText(Stream, '  ' + FormatCurr('#,##0', Q.FieldByName('UNIT_PRICE').AsCurrency) +
        ' x ' + FormatCurr('#,##0.###', Q.FieldByName('QUANTITY').AsFloat) +
        ' = ' + FormatCurr('#,##0', Q.FieldByName('LINE_AMOUNT').AsCurrency) + '원' +
        sLineBreak);
      Q.Next;
    end;
    Q.Close;

    AddText(Stream, '------------------------------------------' + sLineBreak);
    AddCommand(Stream, [$1B, $45, $01]);
    AddText(Stream, '합계: ' + FormatCurr('#,##0', TotalAmount) + '원' + sLineBreak);
    AddCommand(Stream, [$1B, $45, $00]);
    Q.SQL.Text :=
      'SELECT PAYMENT_METHOD, PAYMENT_AMOUNT FROM POS_PAYMENT ' +
      'WHERE ORDER_ID=:ORDER_ID ORDER BY PAID_AT';
    Q.ParamByName('ORDER_ID').AsLargeInt := AOrderID;
    Q.Open;
    PaidAmount := 0;
    while not Q.Eof do
    begin
      if SameText(Q.FieldByName('PAYMENT_METHOD').AsString, 'CASH') then
        MethodName := '현금'
      else
        MethodName := '카드';
      PaidAmount := PaidAmount + Q.FieldByName('PAYMENT_AMOUNT').AsCurrency;
      AddText(Stream, MethodName + ': ' +
        FormatCurr('#,##0', Q.FieldByName('PAYMENT_AMOUNT').AsCurrency) + '원' +
        sLineBreak);
      Q.Next;
    end;
    AddText(Stream, '결제합계: ' + FormatCurr('#,##0', PaidAmount) + '원' + sLineBreak);
    AddText(Stream, '------------------------------------------' + sLineBreak);
    AddCommand(Stream, [$1B, $61, $01]);
    AddText(Stream, '감사합니다.' + sLineBreak + sLineBreak);
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
