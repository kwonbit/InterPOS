unit uKitchenDisplayForm;

interface

uses
  System.SysUtils, System.Classes, System.UITypes, Data.DB,
  FireDAC.Comp.Client, Vcl.Forms, Vcl.Controls, Vcl.Graphics, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Grids, Vcl.Dialogs;

type
  TfrmKitchenDisplay = class(TForm)
  private
    FStoreID: Integer;
    FTicketGrid: TStringGrid;
    FItemGrid: TStringGrid;
    FStatusLabel: TLabel;
    FRefreshTimer: TTimer;
    FRefreshing: Boolean;
    procedure BuildUI;
    procedure RefreshTickets;
    procedure RefreshItems;
    procedure GridClick(Sender: TObject);
    procedure TimerTick(Sender: TObject);
    procedure StatusClick(Sender: TObject);
    procedure ConfigurePrinterClick(Sender: TObject);
    procedure ReprintClick(Sender: TObject);
    function SelectedTicketID: Int64;
    procedure SetTicketStatus(const AStatus: string);
  public
    constructor CreateKitchen(AOwner: TComponent; AStoreID: Integer);
  end;

implementation

uses
  uDatabase, uKitchenPrinter;

function KitchenStatusCaption(const AStatus: string): string;
begin
  if SameText(AStatus, 'NEW') then Result := '접수대기'
  else if SameText(AStatus, 'PREPARING') then Result := '조리시작'
  else if SameText(AStatus, 'READY') then Result := '조리완료'
  else if SameText(AStatus, 'CANCELLED') then Result := '주문취소'
  else Result := AStatus;
end;

constructor TfrmKitchenDisplay.CreateKitchen(AOwner: TComponent;
  AStoreID: Integer);
begin
  inherited CreateNew(AOwner);
  FStoreID := AStoreID;
  BuildUI;
  RefreshTickets;
  FRefreshTimer.Enabled := True;
end;

procedure TfrmKitchenDisplay.BuildUI;
var
  Header, LeftPanel, RightPanel, ButtonPanel: TPanel;
  L: TLabel;
  B: TButton;
begin
  Caption := 'InterPOS - 주방 주문현황';
  Font.Name := '맑은 고딕';
  Position := poScreenCenter;
  Width := 1180;
  Height := 760;

  Header := TPanel.Create(Self);
  Header.Parent := Self;
  Header.Align := alTop;
  Header.Height := 58;
  Header.BevelOuter := bvNone;

  L := TLabel.Create(Self);
  L.Parent := Header;
  L.Left := 16;
  L.Top := 18;
  L.Caption := '주방 주문현황';
  L.Font.Size := 16;
  L.Font.Style := [fsBold];

  FStatusLabel := TLabel.Create(Self);
  FStatusLabel.Parent := Header;
  FStatusLabel.Left := 230;
  FStatusLabel.Top := 22;
  FStatusLabel.Caption := '5초마다 자동 새로고침';

  B := TButton.Create(Self);
  B.Parent := Header;
  B.Align := alRight;
  B.Width := 130;
  B.Caption := '주방 프린터 설정';
  B.OnClick := ConfigurePrinterClick;

  B := TButton.Create(Self);
  B.Parent := Header;
  B.Align := alRight;
  B.Width := 100;
  B.Caption := '새로고침';
  B.OnClick := TimerTick;

  LeftPanel := TPanel.Create(Self);
  LeftPanel.Parent := Self;
  LeftPanel.Align := alLeft;
  LeftPanel.Width := 520;
  LeftPanel.Caption := '';

  FTicketGrid := TStringGrid.Create(Self);
  FTicketGrid.Parent := LeftPanel;
  FTicketGrid.Align := alClient;
  FTicketGrid.FixedRows := 1;
  FTicketGrid.FixedCols := 0;
  FTicketGrid.ColCount := 5;
  FTicketGrid.RowCount := 2;
  FTicketGrid.Options := FTicketGrid.Options + [goRowSelect, goColSizing];
  FTicketGrid.Cells[0, 0] := '티켓ID';
  FTicketGrid.Cells[1, 0] := '주문번호';
  FTicketGrid.Cells[2, 0] := '테이블';
  FTicketGrid.Cells[3, 0] := '접수시간';
  FTicketGrid.Cells[4, 0] := '상태';
  FTicketGrid.ColWidths[0] := 0;
  FTicketGrid.ColWidths[1] := 145;
  FTicketGrid.ColWidths[2] := 90;
  FTicketGrid.ColWidths[3] := 115;
  FTicketGrid.ColWidths[4] := 90;
  FTicketGrid.OnClick := GridClick;

  RightPanel := TPanel.Create(Self);
  RightPanel.Parent := Self;
  RightPanel.Align := alClient;
  RightPanel.Caption := '';

  L := TLabel.Create(Self);
  L.Parent := RightPanel;
  L.Align := alTop;
  L.Height := 34;
  L.Caption := '선택한 주문의 조리 항목';
  L.Layout := tlCenter;
  L.Font.Style := [fsBold];

  FItemGrid := TStringGrid.Create(Self);
  FItemGrid.Parent := RightPanel;
  FItemGrid.Align := alClient;
  FItemGrid.FixedRows := 1;
  FItemGrid.FixedCols := 0;
  FItemGrid.ColCount := 3;
  FItemGrid.RowCount := 2;
  FItemGrid.Options := FItemGrid.Options + [goRowSelect, goColSizing];
  FItemGrid.Cells[0, 0] := '음식명 / 옵션';
  FItemGrid.Cells[1, 0] := '수량';
  FItemGrid.Cells[2, 0] := '주문상태';
  FItemGrid.ColWidths[0] := 330;
  FItemGrid.ColWidths[1] := 70;
  FItemGrid.ColWidths[2] := 90;

  ButtonPanel := TPanel.Create(Self);
  ButtonPanel.Parent := RightPanel;
  ButtonPanel.Align := alBottom;
  ButtonPanel.Height := 58;
  ButtonPanel.BevelOuter := bvNone;

  B := TButton.Create(Self);
  B.Parent := ButtonPanel;
  B.Left := 8;
  B.Top := 9;
  B.Width := 92;
  B.Height := 38;
  B.Caption := '접수대기';
  B.Tag := 0;
  B.OnClick := StatusClick;

  B := TButton.Create(Self);
  B.Parent := ButtonPanel;
  B.Left := 106;
  B.Top := 9;
  B.Width := 92;
  B.Height := 38;
  B.Caption := '조리시작';
  B.Tag := 1;
  B.OnClick := StatusClick;

  B := TButton.Create(Self);
  B.Parent := ButtonPanel;
  B.Left := 204;
  B.Top := 9;
  B.Width := 92;
  B.Height := 38;
  B.Caption := '조리완료';
  B.Tag := 2;
  B.OnClick := StatusClick;

  B := TButton.Create(Self);
  B.Parent := ButtonPanel;
  B.Left := 302;
  B.Top := 9;
  B.Width := 92;
  B.Height := 38;
  B.Caption := '주문취소';
  B.Tag := 3;
  B.OnClick := StatusClick;

  B := TButton.Create(Self);
  B.Parent := ButtonPanel;
  B.Left := 400;
  B.Top := 9;
  B.Width := 100;
  B.Height := 38;
  B.Caption := '주문서 재출력';
  B.OnClick := ReprintClick;

  FRefreshTimer := TTimer.Create(Self);
  FRefreshTimer.Interval := 5000;
  FRefreshTimer.Enabled := False;
  FRefreshTimer.OnTimer := TimerTick;
end;

function TfrmKitchenDisplay.SelectedTicketID: Int64;
begin
  Result := 0;
  if Assigned(FTicketGrid) and (FTicketGrid.Row > 0) and
    (FTicketGrid.Row < FTicketGrid.RowCount) then
    Result := StrToInt64Def(FTicketGrid.Cells[0, FTicketGrid.Row], 0);
end;

procedure TfrmKitchenDisplay.RefreshTickets;
var
  Q: TFDQuery;
  Row: Integer;
  SelectedID: Int64;
begin
  if FRefreshing then Exit;
  FRefreshing := True;
  SelectedID := SelectedTicketID;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmDatabase.Connection;
    Q.SQL.Text :=
      'SELECT FIRST 100 K.KITCHEN_TICKET_ID, K.TICKET_NO, K.CREATED_AT, ' +
      'K.STATUS, O.ORDER_NO, COALESCE(T.TABLE_NAME, ''포장/기타'') AS TABLE_NAME ' +
      'FROM POS_KITCHEN_TICKET K JOIN POS_ORDER O ON O.ORDER_ID=K.ORDER_ID ' +
      'LEFT JOIN POS_TABLE T ON T.TABLE_ID=O.TABLE_ID ' +
      'WHERE O.STORE_ID=:STORE_ID ' +
      'ORDER BY CASE K.STATUS WHEN ''NEW'' THEN 0 WHEN ''PREPARING'' THEN 1 ' +
      'WHEN ''READY'' THEN 2 ELSE 3 END, K.CREATED_AT DESC';
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.Open;
    FTicketGrid.RowCount := 2;
    Row := 1;
    while not Q.Eof do
    begin
      if Row >= FTicketGrid.RowCount then
        FTicketGrid.RowCount := Row + 1;
      FTicketGrid.Cells[0, Row] := Q.FieldByName('KITCHEN_TICKET_ID').AsString;
      FTicketGrid.Cells[1, Row] := Q.FieldByName('ORDER_NO').AsString;
      FTicketGrid.Cells[2, Row] := Q.FieldByName('TABLE_NAME').AsString;
      FTicketGrid.Cells[3, Row] :=
        FormatDateTime('hh:nn:ss', Q.FieldByName('CREATED_AT').AsDateTime);
      FTicketGrid.Cells[4, Row] := KitchenStatusCaption(Q.FieldByName('STATUS').AsString);
      if Q.FieldByName('KITCHEN_TICKET_ID').AsLargeInt = SelectedID then
        FTicketGrid.Row := Row;
      Inc(Row);
      Q.Next;
    end;
    if Row = 1 then
    begin
      FTicketGrid.RowCount := 2;
      FTicketGrid.Cells[0, 1] := '';
      FTicketGrid.Cells[1, 1] := '';
      FTicketGrid.Cells[2, 1] := '';
      FTicketGrid.Cells[3, 1] := '';
      FTicketGrid.Cells[4, 1] := '';
    end
    else if SelectedID = 0 then
      FTicketGrid.Row := 1;
    FStatusLabel.Caption := '표시 주문서 ' + IntToStr(Row - 1) +
      '건 / 5초마다 자동 새로고침';
  finally
    Q.Free;
    FRefreshing := False;
  end;
  RefreshItems;
end;

procedure TfrmKitchenDisplay.RefreshItems;
var
  Q: TFDQuery;
  Row: Integer;
begin
  FItemGrid.RowCount := 2;
  if SelectedTicketID = 0 then
  begin
    FItemGrid.Cells[0, 1] := '';
    FItemGrid.Cells[1, 1] := '';
    FItemGrid.Cells[2, 1] := '';
    Exit;
  end;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmDatabase.Connection;
    Q.SQL.Text :=
      'SELECT MENU_NAME, QUANTITY, COALESCE(OPTION_TEXT, '''') AS OPTION_TEXT ' +
      'FROM POS_ORDER_ITEM WHERE KITCHEN_TICKET_ID=:TICKET_ID ' +
      'ORDER BY ORDER_ITEM_ID';
    Q.ParamByName('TICKET_ID').AsLargeInt := SelectedTicketID;
    Q.Open;
    Row := 1;
    while not Q.Eof do
    begin
      if Row >= FItemGrid.RowCount then
        FItemGrid.RowCount := Row + 1;
      FItemGrid.Cells[0, Row] := Q.FieldByName('MENU_NAME').AsString;
      if Q.FieldByName('OPTION_TEXT').AsString <> '' then
        FItemGrid.Cells[0, Row] := FItemGrid.Cells[0, Row] + sLineBreak +
          Q.FieldByName('OPTION_TEXT').AsString;
      FItemGrid.Cells[1, Row] := FormatFloat('#,##0.###',
        Q.FieldByName('QUANTITY').AsFloat);
      FItemGrid.Cells[2, Row] := FTicketGrid.Cells[4, FTicketGrid.Row];
      Inc(Row);
      Q.Next;
    end;
    if Row = 1 then
    begin
      FItemGrid.Cells[0, 1] := '';
      FItemGrid.Cells[1, 1] := '';
      FItemGrid.Cells[2, 1] := '';
    end;
  finally
    Q.Free;
  end;
end;

procedure TfrmKitchenDisplay.GridClick(Sender: TObject);
begin
  if not FRefreshing then
    RefreshItems;
end;

procedure TfrmKitchenDisplay.TimerTick(Sender: TObject);
begin
  try
    RefreshTickets;
  except
    on E: Exception do
      FStatusLabel.Caption := '새로고침 실패: ' + E.Message;
  end;
end;

procedure TfrmKitchenDisplay.SetTicketStatus(const AStatus: string);
var
  Q: TFDQuery;
  TicketID: Int64;
begin
  TicketID := SelectedTicketID;
  if TicketID = 0 then
    raise Exception.Create('먼저 주방 주문서를 선택해 주세요.');
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmDatabase.Connection;
    Q.SQL.Text :=
      'UPDATE POS_KITCHEN_TICKET SET STATUS=:STATUS, ' +
      'UPDATED_AT=CURRENT_TIMESTAMP WHERE KITCHEN_TICKET_ID=:TICKET_ID';
    Q.ParamByName('STATUS').AsString := AStatus;
    Q.ParamByName('TICKET_ID').AsLargeInt := TicketID;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
  RefreshTickets;
end;

procedure TfrmKitchenDisplay.StatusClick(Sender: TObject);
begin
  try
    case TButton(Sender).Tag of
      0: SetTicketStatus('NEW');
      1: SetTicketStatus('PREPARING');
      2: SetTicketStatus('READY');
      3: SetTicketStatus('CANCELLED');
    end;
  except
    on E: Exception do
      MessageDlg('주방 주문상태 변경에 실패했습니다: ' + E.Message,
        mtError, [mbOK], 0);
  end;
end;

procedure TfrmKitchenDisplay.ConfigurePrinterClick(Sender: TObject);
var
  Settings: TKitchenPrinterSettings;
  PortText, BaudText: string;
begin
  try
    Settings := TKitchenPrinter.LoadSettings;
    PortText := Settings.PortName;
    BaudText := IntToStr(Settings.BaudRate);
    if not InputQuery('주방 프린터 설정', '시리얼 포트 (예: COM2)', PortText) then Exit;
    if not InputQuery('주방 프린터 설정', '통신 속도', BaudText) then Exit;
    Settings.PortName := UpperCase(Trim(PortText));
    if not TryStrToInt(Trim(BaudText), Settings.BaudRate) then
      raise Exception.Create('통신 속도는 숫자로 입력해 주세요.');
    TKitchenPrinter.SaveSettings(Settings);
    if MessageDlg('주방 프린터 설정이 저장되었습니다.' + sLineBreak +
      '테스트 인쇄를 실행하시겠습니까?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      TKitchenPrinter.TestPrint(Settings);
    MessageDlg('주방 프린터 설정이 저장되었습니다.', mtInformation, [mbOK], 0);
  except
    on E: Exception do
      MessageDlg('주방 프린터 설정/테스트에 실패했습니다: ' + E.Message,
        mtError, [mbOK], 0);
  end;
end;

procedure TfrmKitchenDisplay.ReprintClick(Sender: TObject);
begin
  try
    if SelectedTicketID = 0 then
      raise Exception.Create('먼저 주방 주문서를 선택해 주세요.');
    TKitchenPrinter.PrintTicket(dmDatabase.Connection, FStoreID,
      SelectedTicketID);
    MessageDlg('주방 주문서를 다시 출력했습니다.', mtInformation, [mbOK], 0);
  except
    on E: Exception do
      MessageDlg('주방 주문서 재출력에 실패했습니다: ' + E.Message,
        mtError, [mbOK], 0);
  end;
end;

end.
