unit uFinancialSummaryForm;

interface

uses
  System.SysUtils, System.Classes, System.DateUtils, System.Math, Data.DB,
  FireDAC.Comp.Client,
  Vcl.Forms, Vcl.Controls, Vcl.Graphics, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Grids, Vcl.ComCtrls, Vcl.Dialogs;

type
  TfrmFinancialSummary = class(TForm)
  private
    FStoreID: Integer;
    FStartDate: TDateTimePicker;
    FEndDate: TDateTimePicker;
    FSalesLabel: TLabel;
    FExpenseLabel: TLabel;
    FSupplierPaidLabel: TLabel;
    FNetLabel: TLabel;
    FSalesMethodLabel: TLabel;
    FExpenseGrid: TStringGrid;
    FSupplierGrid: TStringGrid;
    FStatusLabel: TLabel;
    procedure BuildUI;
    procedure RefreshClick(Sender: TObject);
    procedure ExportClick(Sender: TObject);
    procedure RefreshReport;
    procedure SetStatus(const AText: string);
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetStoreID(AStoreID: Integer);
  end;

implementation

uses
  uDatabase;

constructor TfrmFinancialSummary.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  BuildUI;
end;

procedure TfrmFinancialSummary.SetStoreID(AStoreID: Integer);
begin
  FStoreID := AStoreID;
  if FStoreID <= 0 then
    raise Exception.Create('매장 정보를 확인할 수 없습니다.');
  RefreshReport;
end;

procedure TfrmFinancialSummary.BuildUI;
var
  Header, SummaryPanel, ButtonPanel, ExpensePanel, SupplierPanel: TPanel;
  L: TLabel;
  B: TButton;
begin
  Caption := '기간별 수입·지출 현황';
  Font.Name := '맑은 고딕';
  Width := 1180;
  Height := 780;
  Position := poScreenCenter;

  Header := TPanel.Create(Self);
  Header.Parent := Self;
  Header.Align := alTop;
  Header.Height := 64;
  Header.BevelOuter := bvNone;

  L := TLabel.Create(Self);
  L.Parent := Header;
  L.SetBounds(16, 20, 70, 22);
  L.Caption := '조회기간';
  FStartDate := TDateTimePicker.Create(Self);
  FStartDate.Parent := Header;
  FStartDate.SetBounds(88, 13, 140, 30);
  FStartDate.Format := 'yyyy-MM-dd';
  FStartDate.Date := StartOfTheMonth(Date);

  L := TLabel.Create(Self);
  L.Parent := Header;
  L.SetBounds(238, 20, 18, 22);
  L.Caption := '~';
  FEndDate := TDateTimePicker.Create(Self);
  FEndDate.Parent := Header;
  FEndDate.SetBounds(260, 13, 140, 30);
  FEndDate.Format := 'yyyy-MM-dd';
  FEndDate.Date := Date;

  B := TButton.Create(Self);
  B.Parent := Header;
  B.SetBounds(415, 11, 100, 34);
  B.Caption := '조회';
  B.OnClick := RefreshClick;

  B := TButton.Create(Self);
  B.Parent := Header;
  B.SetBounds(525, 11, 140, 34);
  B.Caption := 'CSV 내보내기';
  B.OnClick := ExportClick;

  SummaryPanel := TPanel.Create(Self);
  SummaryPanel.Parent := Self;
  SummaryPanel.Align := alTop;
  SummaryPanel.Height := 126;
  SummaryPanel.BevelOuter := bvLowered;

  FSalesLabel := TLabel.Create(Self);
  FSalesLabel.Parent := SummaryPanel;
  FSalesLabel.SetBounds(18, 16, 520, 30);
  FSalesLabel.Font.Size := 13;
  FSalesLabel.Font.Style := [fsBold];

  FExpenseLabel := TLabel.Create(Self);
  FExpenseLabel.Parent := SummaryPanel;
  FExpenseLabel.SetBounds(18, 52, 520, 26);
  FExpenseLabel.Font.Size := 11;

  FSupplierPaidLabel := TLabel.Create(Self);
  FSupplierPaidLabel.Parent := SummaryPanel;
  FSupplierPaidLabel.SetBounds(570, 16, 550, 30);
  FSupplierPaidLabel.Font.Size := 11;

  FNetLabel := TLabel.Create(Self);
  FNetLabel.Parent := SummaryPanel;
  FNetLabel.SetBounds(570, 52, 550, 30);
  FNetLabel.Font.Size := 14;
  FNetLabel.Font.Style := [fsBold];
  FNetLabel.Font.Color := clBlue;

  FSalesMethodLabel := TLabel.Create(Self);
  FSalesMethodLabel.Parent := SummaryPanel;
  FSalesMethodLabel.SetBounds(18, 88, 1080, 22);

  ExpensePanel := TPanel.Create(Self);
  ExpensePanel.Parent := Self;
  ExpensePanel.Align := alTop;
  ExpensePanel.Height := 250;
  ExpensePanel.BevelOuter := bvNone;

  L := TLabel.Create(Self);
  L.Parent := ExpensePanel;
  L.SetBounds(14, 8, 400, 24);
  L.Caption := '운영비용 분류별 집계';
  L.Font.Style := [fsBold];
  L.Font.Size := 12;

  FExpenseGrid := TStringGrid.Create(Self);
  FExpenseGrid.Parent := ExpensePanel;
  FExpenseGrid.SetBounds(12, 36, 1138, 205);
  FExpenseGrid.Anchors := [akLeft, akTop, akRight, akBottom];
  FExpenseGrid.FixedRows := 1;
  FExpenseGrid.FixedCols := 0;
  FExpenseGrid.ColCount := 3;
  FExpenseGrid.RowCount := 2;
  FExpenseGrid.DefaultRowHeight := 25;
  FExpenseGrid.Options := FExpenseGrid.Options + [goRowSelect, goColSizing];
  FExpenseGrid.Cells[0,0] := '지출 분류';
  FExpenseGrid.Cells[1,0] := '건수';
  FExpenseGrid.Cells[2,0] := '지출 합계';
  FExpenseGrid.ColWidths[0] := 600;
  FExpenseGrid.ColWidths[1] := 160;
  FExpenseGrid.ColWidths[2] := 300;

  SupplierPanel := TPanel.Create(Self);
  SupplierPanel.Parent := Self;
  SupplierPanel.Align := alClient;
  SupplierPanel.BevelOuter := bvNone;

  L := TLabel.Create(Self);
  L.Parent := SupplierPanel;
  L.SetBounds(14, 8, 500, 24);
  L.Caption := '거래처 지급수단별 집계';
  L.Font.Style := [fsBold];
  L.Font.Size := 12;

  FSupplierGrid := TStringGrid.Create(Self);
  FSupplierGrid.Parent := SupplierPanel;
  FSupplierGrid.Align := alNone;
  FSupplierGrid.SetBounds(12, 36, 1138, 120);
  FSupplierGrid.Anchors := [akLeft, akTop, akRight, akBottom];
  FSupplierGrid.FixedRows := 1;
  FSupplierGrid.FixedCols := 0;
  FSupplierGrid.ColCount := 3;
  FSupplierGrid.RowCount := 2;
  FSupplierGrid.DefaultRowHeight := 25;
  FSupplierGrid.Options := FSupplierGrid.Options + [goRowSelect, goColSizing];
  FSupplierGrid.Cells[0,0] := '지급수단';
  FSupplierGrid.Cells[1,0] := '건수';
  FSupplierGrid.Cells[2,0] := '지급 합계';
  FSupplierGrid.ColWidths[0] := 600;
  FSupplierGrid.ColWidths[1] := 160;
  FSupplierGrid.ColWidths[2] := 300;

  ButtonPanel := TPanel.Create(Self);
  ButtonPanel.Parent := Self;
  ButtonPanel.Align := alBottom;
  ButtonPanel.Height := 42;
  ButtonPanel.BevelOuter := bvNone;
  FStatusLabel := TLabel.Create(Self);
  FStatusLabel.Parent := ButtonPanel;
  FStatusLabel.SetBounds(16, 12, 1100, 22);
  FStatusLabel.Caption := '조회 기간을 선택하고 조회를 눌러주세요.';
end;

procedure TfrmFinancialSummary.SetStatus(const AText: string);
begin
  FStatusLabel.Caption := AText;
end;

procedure TfrmFinancialSummary.RefreshClick(Sender: TObject);
begin
  try
    RefreshReport;
  except
    on E: Exception do
      MessageDlg('수입·지출 현황 조회 실패: ' + E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TfrmFinancialSummary.RefreshReport;
var
  Q: TFDQuery;
  StartAt, EndAt: TDateTime;
  SalesTotal, CashTotal, CardTotal, ExpenseTotal, SupplierPaid, NetAmount: Currency;
  Row, CountRows: Integer;
  MethodName: string;
begin
  if FEndDate.Date < FStartDate.Date then
    raise Exception.Create('종료일은 시작일보다 빠를 수 없습니다.');

  StartAt := DateOf(FStartDate.Date);
  EndAt := IncDay(DateOf(FEndDate.Date), 1);
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmDatabase.Connection;

    Q.SQL.Text :=
      'SELECT COALESCE(SUM(P.PAYMENT_AMOUNT),0) AS SALES_TOTAL, ' +
      'COALESCE(SUM(IIF(P.PAYMENT_METHOD=''CASH'',P.PAYMENT_AMOUNT,0)),0) AS CASH_TOTAL, ' +
      'COALESCE(SUM(IIF(P.PAYMENT_METHOD=''CARD'',P.PAYMENT_AMOUNT,0)),0) AS CARD_TOTAL ' +
      'FROM POS_PAYMENT P JOIN POS_ORDER O ON O.ORDER_ID=P.ORDER_ID ' +
      'WHERE O.STORE_ID=:STORE_ID AND O.ORDER_STATUS=''PAID'' ' +
      'AND P.PAYMENT_STATUS=''APPROVED'' AND P.PAID_AT>=:START_AT AND P.PAID_AT<:END_AT';
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.ParamByName('START_AT').AsDateTime := StartAt;
    Q.ParamByName('END_AT').AsDateTime := EndAt;
    Q.Open;
    SalesTotal := Q.FieldByName('SALES_TOTAL').AsCurrency;
    CashTotal := Q.FieldByName('CASH_TOTAL').AsCurrency;
    CardTotal := Q.FieldByName('CARD_TOTAL').AsCurrency;
    Q.Close;

    Q.SQL.Text :=
      'SELECT COALESCE(SUM(AMOUNT),0) AS EXPENSE_TOTAL ' +
      'FROM POS_OPERATING_EXPENSE WHERE STORE_ID=:STORE_ID ' +
      'AND EXPENSE_STATUS=''ACTIVE'' AND EXPENSE_DATE>=:START_DATE AND EXPENSE_DATE<:END_DATE';
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.ParamByName('START_DATE').AsDate := StartAt;
    Q.ParamByName('END_DATE').AsDate := EndAt;
    Q.Open;
    ExpenseTotal := Q.FieldByName('EXPENSE_TOTAL').AsCurrency;
    Q.Close;

    Q.SQL.Text :=
      'SELECT COALESCE(SUM(PAYMENT_AMOUNT),0) AS SUPPLIER_PAID ' +
      'FROM POS_PURCHASE_PAYMENT WHERE STORE_ID=:STORE_ID ' +
      'AND PAYMENT_DATE>=:START_DATE AND PAYMENT_DATE<:END_DATE';
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.ParamByName('START_DATE').AsDate := StartAt;
    Q.ParamByName('END_DATE').AsDate := EndAt;
    Q.Open;
    SupplierPaid := Q.FieldByName('SUPPLIER_PAID').AsCurrency;
    Q.Close;

    NetAmount := SalesTotal - ExpenseTotal - SupplierPaid;
    FSalesLabel.Caption := '결제 완료 매출: ' + FormatCurr('#,##0', SalesTotal) + '원';
    FExpenseLabel.Caption := '운영비용: ' + FormatCurr('#,##0', ExpenseTotal) + '원';
    FSupplierPaidLabel.Caption := '거래처 지급액: ' + FormatCurr('#,##0', SupplierPaid) + '원';
    FNetLabel.Caption := '수입·지출 차액: ' + FormatCurr('#,##0', NetAmount) + '원';
    FSalesMethodLabel.Caption := '매출 결제수단  |  현금: ' +
      FormatCurr('#,##0', CashTotal) + '원   /   카드: ' +
      FormatCurr('#,##0', CardTotal) + '원';
    
    Q.SQL.Text :=
      'SELECT CATEGORY, COUNT(*) AS EXPENSE_COUNT, SUM(AMOUNT) AS TOTAL_AMOUNT ' +
      'FROM POS_OPERATING_EXPENSE WHERE STORE_ID=:STORE_ID ' +
      'AND EXPENSE_STATUS=''ACTIVE'' AND EXPENSE_DATE>=:START_DATE AND EXPENSE_DATE<:END_DATE ' +
      'GROUP BY CATEGORY ORDER BY SUM(AMOUNT) DESC';
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.ParamByName('START_DATE').AsDate := StartAt;
    Q.ParamByName('END_DATE').AsDate := EndAt;
    Q.Open;
    CountRows := Q.RecordCount;
    if CountRows < 1 then CountRows := 1;
    FExpenseGrid.RowCount := CountRows + 1;
    Row := 1;
    while not Q.Eof do
    begin
      FExpenseGrid.Cells[0,Row] := Q.FieldByName('CATEGORY').AsString;
      FExpenseGrid.Cells[1,Row] := Q.FieldByName('EXPENSE_COUNT').AsString;
      FExpenseGrid.Cells[2,Row] := FormatCurr('#,##0', Q.FieldByName('TOTAL_AMOUNT').AsCurrency);
      Inc(Row);
      Q.Next;
    end;
    if Row = 1 then FExpenseGrid.Cells[0,1] := '조회된 지출이 없습니다.';
    Q.Close;

    Q.SQL.Text :=
      'SELECT PAYMENT_METHOD, COUNT(*) AS PAYMENT_COUNT, SUM(PAYMENT_AMOUNT) AS TOTAL_AMOUNT ' +
      'FROM POS_PURCHASE_PAYMENT WHERE STORE_ID=:STORE_ID ' +
      'AND PAYMENT_DATE>=:START_DATE AND PAYMENT_DATE<:END_DATE ' +
      'GROUP BY PAYMENT_METHOD ORDER BY SUM(PAYMENT_AMOUNT) DESC';
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.ParamByName('START_DATE').AsDate := StartAt;
    Q.ParamByName('END_DATE').AsDate := EndAt;
    Q.Open;
    CountRows := Q.RecordCount;
    if CountRows < 1 then CountRows := 1;
    FSupplierGrid.RowCount := CountRows + 1;
    Row := 1;
    while not Q.Eof do
    begin
      MethodName := Q.FieldByName('PAYMENT_METHOD').AsString;
      if MethodName = 'CASH' then MethodName := '현금'
      else if MethodName = 'BANK' then MethodName := '계좌이체'
      else if MethodName = 'CARD' then MethodName := '카드'
      else MethodName := '기타';
      FSupplierGrid.Cells[0,Row] := MethodName;
      FSupplierGrid.Cells[1,Row] := Q.FieldByName('PAYMENT_COUNT').AsString;
      FSupplierGrid.Cells[2,Row] := FormatCurr('#,##0', Q.FieldByName('TOTAL_AMOUNT').AsCurrency);
      Inc(Row);
      Q.Next;
    end;
    if Row = 1 then FSupplierGrid.Cells[0,1] := '조회된 거래처 지급 내역이 없습니다.';
  finally
    Q.Free;
  end;

  SetStatus('조회 완료: ' + FormatDateTime('yyyy-mm-dd', StartAt) +
    ' ~ ' + FormatDateTime('yyyy-mm-dd', FEndDate.Date) +
    '  |  수입·지출 차액은 매출에서 운영비용과 거래처 지급액을 뺀 관리용 참고 금액입니다.');
end;

procedure TfrmFinancialSummary.ExportClick(Sender: TObject);
var
  SaveDialog: TSaveDialog;
  Lines: TStringList;
  I: Integer;
  FileName: string;
  function CsvField(const AValue: string): string;
  begin
    Result := '"' + StringReplace(AValue, '"', '""', [rfReplaceAll]) + '"';
  end;
begin
  SaveDialog := TSaveDialog.Create(Self);
  try
    SaveDialog.Title := '수입·지출 보고서 CSV 저장';
    SaveDialog.Filter := 'CSV 파일 (*.csv)|*.csv';
    SaveDialog.DefaultExt := 'csv';
    SaveDialog.FileName := 'InterPOS_Financial_' +
      FormatDateTime('yyyymmdd', FStartDate.Date) + '_' +
      FormatDateTime('yyyymmdd', FEndDate.Date) + '.csv';
    SaveDialog.Options := SaveDialog.Options + [ofPathMustExist, ofOverwritePrompt];
    if not SaveDialog.Execute then Exit;
    FileName := SaveDialog.FileName;
    if ExtractFileExt(FileName) = '' then FileName := FileName + '.csv';

    Lines := TStringList.Create;
    try
      Lines.Add(CsvField('InterPOS 기간별 수입·지출 보고서'));
      Lines.Add(CsvField('조회 시작일') + ',' + CsvField(FormatDateTime('yyyy-mm-dd', FStartDate.Date)));
      Lines.Add(CsvField('조회 종료일') + ',' + CsvField(FormatDateTime('yyyy-mm-dd', FEndDate.Date)));
      Lines.Add(CsvField(FSalesLabel.Caption));
      Lines.Add(CsvField(FExpenseLabel.Caption));
      Lines.Add(CsvField(FSupplierPaidLabel.Caption));
      Lines.Add(CsvField(FNetLabel.Caption));
      Lines.Add(CsvField(FSalesMethodLabel.Caption));
      Lines.Add('');
      Lines.Add(CsvField('운영비용 분류') + ',' + CsvField('건수') + ',' + CsvField('금액'));
      for I := 1 to FExpenseGrid.RowCount - 1 do
        if Trim(FExpenseGrid.Cells[0,I]) <> '' then
          Lines.Add(CsvField(FExpenseGrid.Cells[0,I]) + ',' +
            CsvField(FExpenseGrid.Cells[1,I]) + ',' + CsvField(FExpenseGrid.Cells[2,I]));
      Lines.Add('');
      Lines.Add(CsvField('거래처 지급수단') + ',' + CsvField('건수') + ',' + CsvField('금액'));
      for I := 1 to FSupplierGrid.RowCount - 1 do
        if Trim(FSupplierGrid.Cells[0,I]) <> '' then
          Lines.Add(CsvField(FSupplierGrid.Cells[0,I]) + ',' +
            CsvField(FSupplierGrid.Cells[1,I]) + ',' + CsvField(FSupplierGrid.Cells[2,I]));
      Lines.SaveToFile(FileName, TEncoding.UTF8);
    finally
      Lines.Free;
    end;
    MessageDlg('수입·지출 보고서를 저장했습니다.' + sLineBreak + FileName,
      mtInformation, [mbOK], 0);
  finally
    SaveDialog.Free;
  end;
end;

end.
