unit uSalesReportForm;

interface

uses
  System.SysUtils, System.Classes, System.DateUtils, System.Math, Data.DB,
  FireDAC.Comp.Client, FireDAC.Stan.Param,
  Vcl.Forms, Vcl.Controls, Vcl.Graphics, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Grids, Vcl.ComCtrls, Vcl.Dialogs;

type
  TfrmSalesReport = class(TForm)
  private
    FStoreID: Integer;
    FEmployeeID: Integer;
    FStartDate: TDateTimePicker;
    FEndDate: TDateTimePicker;
    FOrderLabel: TLabel;
    FTotalLabel: TLabel;
    FCashLabel: TLabel;
    FCardLabel: TLabel;
    FMenuGrid: TStringGrid;
    FRefreshButton: TButton;
    FCloseButton: TButton;
    FHistoryButton: TButton;
    FStatusLabel: TLabel;
    procedure BuildUI;
    procedure RefreshClick(Sender: TObject);
    procedure CloseDayClick(Sender: TObject);
    procedure ExecuteCloseDay;
    procedure HistoryClick(Sender: TObject);
    procedure ShowCloseHistory;
    procedure RefreshReport;
    procedure SetStatus(const AText: string);
    function NextSequenceValue(const ASequenceName: string): Int64;
    function ExistingCloseID(ABusinessDate: TDateTime): Int64;
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetContext(AStoreID, AEmployeeID: Integer);
  end;

implementation

uses
  uDatabase;

constructor TfrmSalesReport.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  BuildUI;
end;

procedure TfrmSalesReport.SetContext(AStoreID, AEmployeeID: Integer);
begin
  FStoreID := AStoreID;
  FEmployeeID := AEmployeeID;
  RefreshReport;
end;

procedure TfrmSalesReport.BuildUI;
var
  Header, SummaryPanel, ButtonPanel: TPanel;
  L: TLabel;
begin
  Caption := '매출관리 및 영업마감';
  Font.Name := '맑은 고딕';
  Width := 1050;
  Height := 720;
  Position := poScreenCenter;

  Header := TPanel.Create(Self);
  Header.Parent := Self;
  Header.Align := alTop;
  Header.Height := 76;
  Header.BevelOuter := bvNone;

  L := TLabel.Create(Self);
  L.Parent := Header;
  L.Left := 16;
  L.Top := 15;
  L.Caption := '조회 기간';
  L.Font.Name := Font.Name;

  FStartDate := TDateTimePicker.Create(Self);
  FStartDate.Parent := Header;
  FStartDate.Left := 100;
  FStartDate.Top := 10;
  FStartDate.Width := 140;
  FStartDate.Date := Date;
  FStartDate.Format := 'yyyy-MM-dd';

  L := TLabel.Create(Self);
  L.Parent := Header;
  L.Left := 252;
  L.Top := 15;
  L.Caption := '~';
  L.Font.Name := Font.Name;

  FEndDate := TDateTimePicker.Create(Self);
  FEndDate.Parent := Header;
  FEndDate.Left := 275;
  FEndDate.Top := 10;
  FEndDate.Width := 140;
  FEndDate.Date := Date;
  FEndDate.Format := 'yyyy-MM-dd';

  FRefreshButton := TButton.Create(Self);
  FRefreshButton.Parent := Header;
  FRefreshButton.Left := 435;
  FRefreshButton.Top := 8;
  FRefreshButton.Width := 110;
  FRefreshButton.Height := 34;
  FRefreshButton.Caption := '매출 조회';
  FRefreshButton.OnClick := RefreshClick;

  FCloseButton := TButton.Create(Self);
  FCloseButton.Parent := Header;
  FCloseButton.Left := 560;
  FCloseButton.Top := 8;
  FCloseButton.Width := 150;
  FCloseButton.Height := 34;
  FCloseButton.Caption := '선택일 영업마감';
  FCloseButton.OnClick := CloseDayClick;

  FHistoryButton := TButton.Create(Self);
  FHistoryButton.Parent := Header;
  FHistoryButton.Left := 730;
  FHistoryButton.Top := 8;
  FHistoryButton.Width := 130;
  FHistoryButton.Height := 34;
  FHistoryButton.Caption := '마감내역 조회';
  FHistoryButton.OnClick := HistoryClick;

  SummaryPanel := TPanel.Create(Self);
  SummaryPanel.Parent := Self;
  SummaryPanel.Align := alTop;
  SummaryPanel.Height := 105;
  SummaryPanel.BevelOuter := bvLowered;

  FOrderLabel := TLabel.Create(Self);
  FOrderLabel.Parent := SummaryPanel;
  FOrderLabel.Left := 20;
  FOrderLabel.Top := 18;
  FOrderLabel.Font.Size := 12;
  FOrderLabel.Font.Style := [fsBold];

  FTotalLabel := TLabel.Create(Self);
  FTotalLabel.Parent := SummaryPanel;
  FTotalLabel.Left := 260;
  FTotalLabel.Top := 18;
  FTotalLabel.Font.Size := 14;
  FTotalLabel.Font.Style := [fsBold];
  FTotalLabel.Font.Color := clBlue;

  FCashLabel := TLabel.Create(Self);
  FCashLabel.Parent := SummaryPanel;
  FCashLabel.Left := 20;
  FCashLabel.Top := 60;

  FCardLabel := TLabel.Create(Self);
  FCardLabel.Parent := SummaryPanel;
  FCardLabel.Left := 260;
  FCardLabel.Top := 60;

  FMenuGrid := TStringGrid.Create(Self);
  FMenuGrid.Parent := Self;
  FMenuGrid.Align := alClient;
  FMenuGrid.FixedRows := 1;
  FMenuGrid.FixedCols := 0;
  FMenuGrid.ColCount := 3;
  FMenuGrid.RowCount := 2;
  FMenuGrid.DefaultRowHeight := 28;
  FMenuGrid.Options := FMenuGrid.Options + [goRowSelect, goColSizing];
  FMenuGrid.Cells[0, 0] := '메뉴명';
  FMenuGrid.Cells[1, 0] := '판매수량';
  FMenuGrid.Cells[2, 0] := '매출금액';
  FMenuGrid.ColWidths[0] := 480;
  FMenuGrid.ColWidths[1] := 160;
  FMenuGrid.ColWidths[2] := 220;

  ButtonPanel := TPanel.Create(Self);
  ButtonPanel.Parent := Self;
  ButtonPanel.Align := alBottom;
  ButtonPanel.Height := 42;
  ButtonPanel.BevelOuter := bvNone;

  FStatusLabel := TLabel.Create(Self);
  FStatusLabel.Parent := ButtonPanel;
  FStatusLabel.Left := 16;
  FStatusLabel.Top := 12;
  FStatusLabel.Caption := '조회 기간을 선택하고 매출 조회를 눌러주세요.';
end;

procedure TfrmSalesReport.SetStatus(const AText: string);
begin
  FStatusLabel.Caption := AText;
end;

function TfrmSalesReport.NextSequenceValue(const ASequenceName: string): Int64;
var
  Q: TFDQuery;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmDatabase.Connection;
    Q.SQL.Text := 'SELECT GEN_ID(' + ASequenceName + ', 1) FROM RDB$DATABASE';
    Q.Open;
    Result := Q.Fields[0].AsLargeInt;
  finally
    Q.Free;
  end;
end;

function TfrmSalesReport.ExistingCloseID(ABusinessDate: TDateTime): Int64;
var
  Q: TFDQuery;
begin
  Result := 0;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmDatabase.Connection;
    Q.SQL.Text := 'SELECT CLOSE_ID FROM POS_SALES_CLOSE ' +
      'WHERE STORE_ID=:STORE_ID AND BUSINESS_DATE=:BUSINESS_DATE';
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.ParamByName('BUSINESS_DATE').AsDateTime := DateOf(ABusinessDate);
    Q.Open;
    if not Q.IsEmpty then
      Result := Q.Fields[0].AsLargeInt;
  finally
    Q.Free;
  end;
end;

procedure TfrmSalesReport.RefreshClick(Sender: TObject);
begin
  try
    RefreshReport;
  except
    on E: Exception do
      MessageDlg('매출 조회에 실패했습니다: ' + E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TfrmSalesReport.RefreshReport;
var
  Q: TFDQuery;
  StartAt, EndAt: TDateTime;
  Row: Integer;
  CloseID: Int64;
begin
  if FEndDate.Date < FStartDate.Date then
    raise Exception.Create('종료일은 시작일보다 빠를 수 없습니다.');

  StartAt := DateOf(FStartDate.Date);
  EndAt := IncDay(DateOf(FEndDate.Date), 1);

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmDatabase.Connection;
    Q.SQL.Text :=
      'SELECT COUNT(DISTINCT O.ORDER_ID) AS ORDER_COUNT, ' +
      'COALESCE(SUM(P.PAYMENT_AMOUNT), 0) AS TOTAL_AMOUNT, ' +
      'COALESCE(SUM(IIF(P.PAYMENT_METHOD=''CASH'', P.PAYMENT_AMOUNT, 0)), 0) AS CASH_AMOUNT, ' +
      'COALESCE(SUM(IIF(P.PAYMENT_METHOD=''CARD'', P.PAYMENT_AMOUNT, 0)), 0) AS CARD_AMOUNT ' +
      'FROM POS_PAYMENT P JOIN POS_ORDER O ON O.ORDER_ID=P.ORDER_ID ' +
      'WHERE O.STORE_ID=:STORE_ID AND O.ORDER_STATUS=''PAID'' ' +
      'AND P.PAID_AT>=:START_AT AND P.PAID_AT<:END_AT';
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.ParamByName('START_AT').AsDateTime := StartAt;
    Q.ParamByName('END_AT').AsDateTime := EndAt;
    Q.Open;
    FOrderLabel.Caption := '결제 완료 주문: ' +
      FormatFloat('#,##0', Q.FieldByName('ORDER_COUNT').AsInteger) + '건';
    FTotalLabel.Caption := '총 매출: ' +
      FormatCurr('#,##0', Q.FieldByName('TOTAL_AMOUNT').AsCurrency) + '원';
    FCashLabel.Caption := '현금 매출: ' +
      FormatCurr('#,##0', Q.FieldByName('CASH_AMOUNT').AsCurrency) + '원';
    FCardLabel.Caption := '카드 매출: ' +
      FormatCurr('#,##0', Q.FieldByName('CARD_AMOUNT').AsCurrency) + '원';
    Q.Close;

    Q.SQL.Text :=
      'SELECT I.MENU_NAME, SUM(I.QUANTITY) AS SOLD_QUANTITY, ' +
      'SUM(I.LINE_AMOUNT) AS SALES_AMOUNT ' +
      'FROM POS_ORDER_ITEM I JOIN POS_ORDER O ON O.ORDER_ID=I.ORDER_ID ' +
      'WHERE O.STORE_ID=:STORE_ID AND O.ORDER_STATUS=''PAID'' ' +
      'AND EXISTS (SELECT 1 FROM POS_PAYMENT P WHERE P.ORDER_ID=O.ORDER_ID ' +
      'AND P.PAID_AT>=:START_AT AND P.PAID_AT<:END_AT) ' +
      'GROUP BY I.MENU_NAME ORDER BY SUM(I.LINE_AMOUNT) DESC';
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.ParamByName('START_AT').AsDateTime := StartAt;
    Q.ParamByName('END_AT').AsDateTime := EndAt;
    Q.Open;

    FMenuGrid.RowCount := Max(2, Q.RecordCount + 1);
    Row := 1;
    while not Q.Eof do
    begin
      FMenuGrid.Cells[0, Row] := Q.FieldByName('MENU_NAME').AsString;
      FMenuGrid.Cells[1, Row] := FormatFloat('#,##0.###',
        Q.FieldByName('SOLD_QUANTITY').AsFloat);
      FMenuGrid.Cells[2, Row] := FormatCurr('#,##0',
        Q.FieldByName('SALES_AMOUNT').AsCurrency);
      Inc(Row);
      Q.Next;
    end;
    if Row = 1 then
    begin
      FMenuGrid.Cells[0, 1] := '조회된 판매 내역이 없습니다.';
      FMenuGrid.Cells[1, 1] := '';
      FMenuGrid.Cells[2, 1] := '';
    end;
    Q.Close;
  finally
    Q.Free;
  end;

  CloseID := ExistingCloseID(FStartDate.Date);
  if (FStartDate.Date = FEndDate.Date) and (CloseID > 0) then
    SetStatus('선택한 날짜는 영업마감이 완료되었습니다. 마감번호: ' +
      IntToStr(CloseID))
  else
    SetStatus('매출 조회 완료: ' + FormatDateTime('yyyy-mm-dd', StartAt) +
      ' ~ ' + FormatDateTime('yyyy-mm-dd', FEndDate.Date));
end;

procedure TfrmSalesReport.HistoryClick(Sender: TObject);
begin
  try
    ShowCloseHistory;
  except
    on E: Exception do
      MessageDlg('마감내역 조회에 실패했습니다: ' + E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TfrmSalesReport.ShowCloseHistory;
var
  HistoryForm: TForm;
  Grid: TStringGrid;
  Q: TFDQuery;
  Row: Integer;
  StartAt, EndAt: TDateTime;
begin
  StartAt := DateOf(FStartDate.Date);
  EndAt := IncDay(DateOf(FEndDate.Date), 1);

  HistoryForm := TForm.Create(Self);
  try
    HistoryForm.Caption := '영업마감 내역';
    HistoryForm.Font.Name := Font.Name;
    HistoryForm.Position := poScreenCenter;
    HistoryForm.Width := 850;
    HistoryForm.Height := 500;

    Grid := TStringGrid.Create(HistoryForm);
    Grid.Parent := HistoryForm;
    Grid.Align := alClient;
    Grid.FixedRows := 1;
    Grid.FixedCols := 0;
    Grid.ColCount := 6;
    Grid.RowCount := 2;
    Grid.DefaultRowHeight := 28;
    Grid.Options := Grid.Options + [goRowSelect, goColSizing];
    Grid.Cells[0, 0] := '마감번호';
    Grid.Cells[1, 0] := '영업일자';
    Grid.Cells[2, 0] := '주문건수';
    Grid.Cells[3, 0] := '총 매출';
    Grid.Cells[4, 0] := '현금';
    Grid.Cells[5, 0] := '카드';
    Grid.ColWidths[0] := 90;
    Grid.ColWidths[1] := 120;
    Grid.ColWidths[2] := 90;
    Grid.ColWidths[3] := 150;
    Grid.ColWidths[4] := 130;
    Grid.ColWidths[5] := 130;

    Q := TFDQuery.Create(nil);
    try
      Q.Connection := dmDatabase.Connection;
      Q.SQL.Text :=
        'SELECT CLOSE_ID, BUSINESS_DATE, ORDER_COUNT, TOTAL_AMOUNT, ' +
        'CASH_AMOUNT, CARD_AMOUNT FROM POS_SALES_CLOSE ' +
        'WHERE STORE_ID=:STORE_ID AND BUSINESS_DATE>=:START_DATE ' +
        'AND BUSINESS_DATE<:END_DATE ORDER BY BUSINESS_DATE DESC';
      Q.ParamByName('STORE_ID').AsInteger := FStoreID;
      Q.ParamByName('START_DATE').AsDateTime := StartAt;
      Q.ParamByName('END_DATE').AsDateTime := EndAt;
      Q.Open;
      Grid.RowCount := Max(2, Q.RecordCount + 1);
      Row := 1;
      while not Q.Eof do
      begin
        Grid.Cells[0, Row] := Q.FieldByName('CLOSE_ID').AsString;
        Grid.Cells[1, Row] := FormatDateTime('yyyy-mm-dd',
          Q.FieldByName('BUSINESS_DATE').AsDateTime);
        Grid.Cells[2, Row] := Q.FieldByName('ORDER_COUNT').AsString;
        Grid.Cells[3, Row] := FormatCurr('#,##0',
          Q.FieldByName('TOTAL_AMOUNT').AsCurrency);
        Grid.Cells[4, Row] := FormatCurr('#,##0',
          Q.FieldByName('CASH_AMOUNT').AsCurrency);
        Grid.Cells[5, Row] := FormatCurr('#,##0',
          Q.FieldByName('CARD_AMOUNT').AsCurrency);
        Inc(Row);
        Q.Next;
      end;
      if Row = 1 then
        Grid.Cells[0, 1] := '조회된 마감내역이 없습니다.';
    finally
      Q.Free;
    end;
    HistoryForm.ShowModal;
  finally
    HistoryForm.Free;
  end;
end;

procedure TfrmSalesReport.CloseDayClick(Sender: TObject);
begin
  try
    ExecuteCloseDay;
  except
    on E: Exception do
      MessageDlg('영업마감에 실패했습니다: ' + E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TfrmSalesReport.ExecuteCloseDay;
var
  Q, DetailQ: TFDQuery;
  CloseID, CloseMenuID: Int64;
  BusinessDate: TDateTime;
  OrderCount: Integer;
  TotalAmount, CashAmount, CardAmount: Currency;
  StartAt, EndAt: TDateTime;
begin
  if FStartDate.Date <> FEndDate.Date then
    raise Exception.Create('영업마감은 하루 단위로만 실행할 수 있습니다.');

  BusinessDate := DateOf(FStartDate.Date);
  if ExistingCloseID(BusinessDate) > 0 then
    raise Exception.Create('선택한 날짜는 이미 영업마감이 완료되었습니다.');

  if MessageDlg(FormatDateTime('yyyy-mm-dd', BusinessDate) +
    ' 영업을 마감하시겠습니까?' + sLineBreak +
    '마감 후에는 동일 날짜로 중복 마감할 수 없습니다.',
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  StartAt := BusinessDate;
  EndAt := IncDay(BusinessDate, 1);
  Q := TFDQuery.Create(nil);
  DetailQ := TFDQuery.Create(nil);
  try
    Q.Connection := dmDatabase.Connection;
    Q.SQL.Text :=
      'SELECT COUNT(DISTINCT O.ORDER_ID) AS ORDER_COUNT, ' +
      'COALESCE(SUM(P.PAYMENT_AMOUNT), 0) AS TOTAL_AMOUNT, ' +
      'COALESCE(SUM(IIF(P.PAYMENT_METHOD=''CASH'', P.PAYMENT_AMOUNT, 0)), 0) AS CASH_AMOUNT, ' +
      'COALESCE(SUM(IIF(P.PAYMENT_METHOD=''CARD'', P.PAYMENT_AMOUNT, 0)), 0) AS CARD_AMOUNT ' +
      'FROM POS_PAYMENT P JOIN POS_ORDER O ON O.ORDER_ID=P.ORDER_ID ' +
      'WHERE O.STORE_ID=:STORE_ID AND O.ORDER_STATUS=''PAID'' ' +
      'AND P.PAID_AT>=:START_AT AND P.PAID_AT<:END_AT';
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.ParamByName('START_AT').AsDateTime := StartAt;
    Q.ParamByName('END_AT').AsDateTime := EndAt;
    Q.Open;
    OrderCount := Q.FieldByName('ORDER_COUNT').AsInteger;
    TotalAmount := Q.FieldByName('TOTAL_AMOUNT').AsCurrency;
    CashAmount := Q.FieldByName('CASH_AMOUNT').AsCurrency;
    CardAmount := Q.FieldByName('CARD_AMOUNT').AsCurrency;
    Q.Close;

    if OrderCount = 0 then
      raise Exception.Create('해당 날짜에 결제 완료된 매출이 없어 마감할 수 없습니다.');

    dmDatabase.Connection.StartTransaction;
    try
      CloseID := NextSequenceValue('GEN_POS_SALES_CLOSE_ID');
      Q.SQL.Text :=
        'INSERT INTO POS_SALES_CLOSE ' +
        '(CLOSE_ID, STORE_ID, BUSINESS_DATE, ORDER_COUNT, TOTAL_AMOUNT, CASH_AMOUNT, CARD_AMOUNT, CLOSED_BY) ' +
        'VALUES (:ID, :STORE_ID, :BUSINESS_DATE, :ORDER_COUNT, :TOTAL, :CASH, :CARD, :EMPLOYEE_ID)';
      Q.ParamByName('ID').AsLargeInt := CloseID;
      Q.ParamByName('STORE_ID').AsInteger := FStoreID;
      Q.ParamByName('BUSINESS_DATE').AsDateTime := BusinessDate;
      Q.ParamByName('ORDER_COUNT').AsInteger := OrderCount;
      Q.ParamByName('TOTAL').AsCurrency := TotalAmount;
      Q.ParamByName('CASH').AsCurrency := CashAmount;
      Q.ParamByName('CARD').AsCurrency := CardAmount;
      if FEmployeeID > 0 then
        Q.ParamByName('EMPLOYEE_ID').AsInteger := FEmployeeID
      else
        Q.ParamByName('EMPLOYEE_ID').Clear;
      Q.ExecSQL;

      DetailQ.Connection := dmDatabase.Connection;
      DetailQ.SQL.Text :=
        'SELECT I.MENU_NAME, SUM(I.QUANTITY) AS SOLD_QUANTITY, ' +
        'SUM(I.LINE_AMOUNT) AS SALES_AMOUNT ' +
        'FROM POS_ORDER_ITEM I JOIN POS_ORDER O ON O.ORDER_ID=I.ORDER_ID ' +
        'WHERE O.STORE_ID=:STORE_ID AND O.ORDER_STATUS=''PAID'' ' +
        'AND EXISTS (SELECT 1 FROM POS_PAYMENT P WHERE P.ORDER_ID=O.ORDER_ID ' +
        'AND P.PAID_AT>=:START_AT AND P.PAID_AT<:END_AT) ' +
        'GROUP BY I.MENU_NAME ORDER BY I.MENU_NAME';
      DetailQ.ParamByName('STORE_ID').AsInteger := FStoreID;
      DetailQ.ParamByName('START_AT').AsDateTime := StartAt;
      DetailQ.ParamByName('END_AT').AsDateTime := EndAt;
      DetailQ.Open;

      while not DetailQ.Eof do
      begin
        CloseMenuID := NextSequenceValue('GEN_POS_SALES_CLOSE_MENU_ID');
        Q.SQL.Text :=
          'INSERT INTO POS_SALES_CLOSE_MENU ' +
          '(CLOSE_MENU_ID, CLOSE_ID, MENU_NAME, SOLD_QUANTITY, SALES_AMOUNT) ' +
          'VALUES (:MENU_ID, :CLOSE_ID, :MENU_NAME, :QUANTITY, :AMOUNT)';
        Q.ParamByName('MENU_ID').AsLargeInt := CloseMenuID;
        Q.ParamByName('CLOSE_ID').AsLargeInt := CloseID;
        Q.ParamByName('MENU_NAME').AsString := DetailQ.FieldByName('MENU_NAME').AsString;
        Q.ParamByName('QUANTITY').AsFloat := DetailQ.FieldByName('SOLD_QUANTITY').AsFloat;
        Q.ParamByName('AMOUNT').AsCurrency := DetailQ.FieldByName('SALES_AMOUNT').AsCurrency;
        Q.ExecSQL;
        DetailQ.Next;
      end;
      DetailQ.Close;
      dmDatabase.Connection.Commit;
    except
      dmDatabase.Connection.Rollback;
      raise;
    end;
    MessageDlg('영업마감이 완료되었습니다.' + sLineBreak +
      '마감번호: ' + IntToStr(CloseID) + sLineBreak +
      '총 매출: ' + FormatCurr('#,##0', TotalAmount) + '원',
      mtInformation, [mbOK], 0);
    RefreshReport;
  finally
    DetailQ.Free;
    Q.Free;
  end;
end;

end.
