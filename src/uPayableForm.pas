unit uPayableForm;

interface

uses
  System.SysUtils, System.Classes, System.UITypes, System.Math,
  Data.DB, FireDAC.Comp.Client,
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.DBGrids,
  Vcl.Dialogs, Vcl.Graphics, Vcl.Grids;

type
  TfrmPayables = class(TForm)
  private
    FStoreID: Integer;
    FEmployeeID: Integer;
    FQuery: TFDQuery;
    FSource: TDataSource;
    FGrid: TDBGrid;
    FHistory: TStringGrid;
    FSearch: TEdit;
    FSummary: TLabel;
    procedure BuildUI;
    procedure RefreshData;
    procedure LoadHistory;
    procedure SearchClick(Sender: TObject);
    procedure PaymentClick(Sender: TObject);
    procedure GridCellClick(Column: TColumn);
    function SelectedPurchaseID: Int64;
    procedure RegisterPayment(APurchaseID: Int64; AAmount: Currency;
      const AMethod, ANote: string);
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetContext(AStoreID, AEmployeeID: Integer);
  end;

implementation

uses
  uDatabase;

function NewPayableQuery: TFDQuery;
begin
  Result := TFDQuery.Create(nil);
  Result.Connection := dmDatabase.Connection;
end;

constructor TfrmPayables.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  BuildUI;
end;

procedure TfrmPayables.BuildUI;
var
  Header, FilterPanel, BottomPanel: TPanel;
  L: TLabel;
  B: TButton;
begin
  Caption := '거래처 매입현황 / 미지급금 관리';
  Font.Name := '맑은 고딕';
  Position := poScreenCenter;
  Width := 1180;
  Height := 760;

  Header := TPanel.Create(Self);
  Header.Parent := Self;
  Header.Align := alTop;
  Header.Height := 76;
  Header.BevelOuter := bvNone;
  L := TLabel.Create(Self);
  L.Parent := Header;
  L.SetBounds(16, 8, 600, 26);
  L.Caption := '거래처별 입고 구매금액과 지급 잔액 관리';
  L.Font.Name := Font.Name;
  L.Font.Size := 14;
  L.Font.Style := [fsBold];
  FSummary := TLabel.Create(Self);
  FSummary.Parent := Header;
  FSummary.SetBounds(16, 40, 1100, 24);
  FSummary.Font.Style := [fsBold];
  FSummary.Caption := '매입 합계 0  |  지급 합계 0  |  미지급 잔액 0';

  FilterPanel := TPanel.Create(Self);
  FilterPanel.Parent := Self;
  FilterPanel.Align := alTop;
  FilterPanel.Height := 48;
  FilterPanel.BevelOuter := bvNone;
  L := TLabel.Create(Self);
  L.Parent := FilterPanel;
  L.SetBounds(16, 13, 80, 22);
  L.Caption := '거래처 검색';
  FSearch := TEdit.Create(Self);
  FSearch.Parent := FilterPanel;
  FSearch.SetBounds(100, 8, 260, 28);
  FSearch.TextHint := '거래처명';
  B := TButton.Create(Self);
  B.Parent := FilterPanel;
  B.SetBounds(370, 7, 90, 32);
  B.Caption := '검색';
  B.OnClick := SearchClick;

  FQuery := TFDQuery.Create(Self);
  FSource := TDataSource.Create(Self);
  FSource.DataSet := FQuery;
  FGrid := TDBGrid.Create(Self);
  FGrid.Parent := Self;
  FGrid.Align := alClient;
  FGrid.DataSource := FSource;
  FGrid.ReadOnly := True;
  FGrid.Options := FGrid.Options + [dgRowSelect, dgTitles, dgIndicator];
  FGrid.OnCellClick := GridCellClick;

  FHistory := TStringGrid.Create(Self);
  FHistory.Parent := Self;
  FHistory.Align := alBottom;
  FHistory.Height := 170;
  FHistory.FixedRows := 1;
  FHistory.FixedCols := 0;
  FHistory.ColCount := 5;
  FHistory.RowCount := 2;
  FHistory.DefaultRowHeight := 25;
  FHistory.Options := FHistory.Options + [goRowSelect, goColSizing];
  FHistory.Cells[0,0] := '지급일';
  FHistory.Cells[1,0] := '지급금액';
  FHistory.Cells[2,0] := '지급수단';
  FHistory.Cells[3,0] := '비고';
  FHistory.Cells[4,0] := '처리 직원';
  FHistory.ColWidths[0] := 130;
  FHistory.ColWidths[1] := 150;
  FHistory.ColWidths[2] := 120;
  FHistory.ColWidths[3] := 480;
  FHistory.ColWidths[4] := 150;

  BottomPanel := TPanel.Create(Self);
  BottomPanel.Parent := Self;
  BottomPanel.Align := alBottom;
  BottomPanel.Height := 58;
  BottomPanel.BevelOuter := bvNone;
  B := TButton.Create(Self);
  B.Parent := BottomPanel;
  B.SetBounds(12, 9, 150, 40);
  B.Caption := '지급 등록';
  B.OnClick := PaymentClick;
  B := TButton.Create(Self);
  B.Parent := BottomPanel;
  B.SetBounds(1030, 9, 120, 40);
  B.Caption := '닫기';
  B.ModalResult := mrClose;
end;

procedure TfrmPayables.SetContext(AStoreID, AEmployeeID: Integer);
begin
  FStoreID := AStoreID;
  FEmployeeID := AEmployeeID;
  if (FStoreID <= 0) or (FEmployeeID <= 0) then
    raise Exception.Create('매장 및 로그인 직원 정보를 확인해 주세요.');
  FQuery.Connection := dmDatabase.Connection;
  RefreshData;
end;

function TfrmPayables.SelectedPurchaseID: Int64;
begin
  Result := 0;
  if not FQuery.IsEmpty then
    Result := FQuery.FieldByName('PURCHASE_ID').AsLargeInt;
end;

procedure TfrmPayables.RefreshData;
var
  Q: TFDQuery;
  PurchaseTotal, PaidTotal, BalanceTotal: Currency;
begin
  FQuery.Close;
  FQuery.SQL.Text :=
    'SELECT P.PURCHASE_ID, P.PURCHASE_DATE, S.SUPPLIER_NAME, ' +
    'P.TOTAL_AMOUNT, COALESCE(X.PAID_AMOUNT, 0) AS PAID_AMOUNT, ' +
    'P.TOTAL_AMOUNT-COALESCE(X.PAID_AMOUNT, 0) AS BALANCE_AMOUNT ' +
    'FROM POS_PURCHASE P JOIN POS_SUPPLIER S ON S.SUPPLIER_ID=P.SUPPLIER_ID ' +
    'LEFT JOIN (SELECT PURCHASE_ID, SUM(PAYMENT_AMOUNT) AS PAID_AMOUNT ' +
    'FROM POS_PURCHASE_PAYMENT WHERE STORE_ID=:STORE_ID GROUP BY PURCHASE_ID) X ' +
    'ON X.PURCHASE_ID=P.PURCHASE_ID ' +
    'WHERE P.STORE_ID=:STORE_ID AND P.PURCHASE_STATUS=''RECEIVED'' ' +
    'AND P.TOTAL_AMOUNT>COALESCE(X.PAID_AMOUNT, 0) ';
  if Trim(FSearch.Text) <> '' then
    FQuery.SQL.Add('AND S.SUPPLIER_NAME CONTAINING :SUPPLIER_KEY ');
  FQuery.SQL.Add('ORDER BY P.PURCHASE_DATE, S.SUPPLIER_NAME, P.PURCHASE_ID');
  FQuery.ParamByName('STORE_ID').AsInteger := FStoreID;
  if Trim(FSearch.Text) <> '' then
    FQuery.ParamByName('SUPPLIER_KEY').AsString := Trim(FSearch.Text);
  FQuery.Open;
  FQuery.FieldByName('PURCHASE_ID').Visible := False;
  FQuery.FieldByName('PURCHASE_DATE').DisplayLabel := '구매일자';
  FQuery.FieldByName('SUPPLIER_NAME').DisplayLabel := '거래처';
  FQuery.FieldByName('TOTAL_AMOUNT').DisplayLabel := '매입금액';
  FQuery.FieldByName('PAID_AMOUNT').DisplayLabel := '누적 지급액';
  FQuery.FieldByName('BALANCE_AMOUNT').DisplayLabel := '미지급 잔액';

  PurchaseTotal := 0;
  PaidTotal := 0;
  BalanceTotal := 0;
  Q := NewPayableQuery;
  try
    Q.SQL.Text :=
      'SELECT COALESCE(SUM(P.TOTAL_AMOUNT),0) AS PURCHASE_TOTAL, ' +
      'COALESCE(SUM(COALESCE(X.PAID_AMOUNT,0)),0) AS PAID_TOTAL, ' +
      'COALESCE(SUM(P.TOTAL_AMOUNT-COALESCE(X.PAID_AMOUNT,0)),0) AS BALANCE_TOTAL ' +
      'FROM POS_PURCHASE P LEFT JOIN ' +
      '(SELECT PURCHASE_ID, SUM(PAYMENT_AMOUNT) AS PAID_AMOUNT ' +
      'FROM POS_PURCHASE_PAYMENT WHERE STORE_ID=:STORE_ID GROUP BY PURCHASE_ID) X ' +
      'ON X.PURCHASE_ID=P.PURCHASE_ID ' +
      'WHERE P.STORE_ID=:STORE_ID AND P.PURCHASE_STATUS=''RECEIVED''';
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.Open;
    PurchaseTotal := Q.FieldByName('PURCHASE_TOTAL').AsCurrency;
    PaidTotal := Q.FieldByName('PAID_TOTAL').AsCurrency;
    BalanceTotal := Q.FieldByName('BALANCE_TOTAL').AsCurrency;
  finally
    Q.Free;
  end;
  FSummary.Caption :=
    '입고 매입 합계 ' + FormatCurr('#,##0.00', PurchaseTotal) +
    ' 원   |   지급 합계 ' + FormatCurr('#,##0.00', PaidTotal) +
    ' 원   |   미지급 잔액 ' + FormatCurr('#,##0.00', BalanceTotal) + ' 원';
  LoadHistory;
end;

procedure TfrmPayables.LoadHistory;
var
  Q: TFDQuery;
  R, HistoryCount: Integer;
begin
  FHistory.RowCount := 2;
  FHistory.Cells[0,1] := '';
  if SelectedPurchaseID = 0 then Exit;
  Q := NewPayableQuery;
  try
    Q.SQL.Text :=
      'SELECT D.PAYMENT_DATE, D.PAYMENT_AMOUNT, D.PAYMENT_METHOD, ' +
      'D.NOTE, E.EMPLOYEE_NAME FROM POS_PURCHASE_PAYMENT D ' +
      'JOIN EMPLOYEE E ON E.EMPLOYEE_ID=D.EMPLOYEE_ID ' +
      'WHERE D.STORE_ID=:STORE_ID AND D.PURCHASE_ID=:PURCHASE_ID ' +
      'ORDER BY D.PAYMENT_DATE DESC, D.PAYMENT_ID DESC';
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.ParamByName('PURCHASE_ID').AsLargeInt := SelectedPurchaseID;
    Q.Open;
    HistoryCount := Q.RecordCount + 1;
    if HistoryCount < 2 then HistoryCount := 2;
    FHistory.RowCount := HistoryCount;
    R := 1;
    while not Q.Eof do
    begin
      FHistory.Cells[0,R] := DateToStr(Q.FieldByName('PAYMENT_DATE').AsDateTime);
      FHistory.Cells[1,R] := FormatCurr('#,##0.00', Q.FieldByName('PAYMENT_AMOUNT').AsCurrency);
      FHistory.Cells[2,R] := Q.FieldByName('PAYMENT_METHOD').AsString;
      FHistory.Cells[3,R] := Q.FieldByName('NOTE').AsString;
      FHistory.Cells[4,R] := Q.FieldByName('EMPLOYEE_NAME').AsString;
      Inc(R);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

procedure TfrmPayables.GridCellClick(Column: TColumn);
begin
  LoadHistory;
end;

procedure TfrmPayables.SearchClick(Sender: TObject);
begin
  try
    RefreshData;
  except
    on E: Exception do
      MessageDlg('매입현황 조회 실패: ' + E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TfrmPayables.RegisterPayment(APurchaseID: Int64; AAmount: Currency;
  const AMethod, ANote: string);
var
  Q: TFDQuery;
  PurchaseAmount, PaidAmount, BalanceAmount: Currency;
  PaymentID: Int64;
begin
  dmDatabase.Connection.StartTransaction;
  try
    Q := NewPayableQuery;
    try
      Q.SQL.Text :=
        'SELECT TOTAL_AMOUNT, PURCHASE_STATUS FROM POS_PURCHASE ' +
        'WHERE STORE_ID=:STORE_ID AND PURCHASE_ID=:PURCHASE_ID WITH LOCK';
      Q.ParamByName('STORE_ID').AsInteger := FStoreID;
      Q.ParamByName('PURCHASE_ID').AsLargeInt := APurchaseID;
      Q.Open;
      if Q.IsEmpty then raise Exception.Create('구매 내역을 찾을 수 없습니다.');
      if Q.FieldByName('PURCHASE_STATUS').AsString <> 'RECEIVED' then
        raise Exception.Create('입고 완료된 구매에 대해서만 지급 등록할 수 있습니다.');
      PurchaseAmount := Q.FieldByName('TOTAL_AMOUNT').AsCurrency;
      Q.Close;

      Q.SQL.Text :=
        'SELECT COALESCE(SUM(PAYMENT_AMOUNT),0) AS PAID_AMOUNT ' +
        'FROM POS_PURCHASE_PAYMENT WHERE STORE_ID=:STORE_ID AND PURCHASE_ID=:PURCHASE_ID';
      Q.ParamByName('STORE_ID').AsInteger := FStoreID;
      Q.ParamByName('PURCHASE_ID').AsLargeInt := APurchaseID;
      Q.Open;
      PaidAmount := Q.FieldByName('PAID_AMOUNT').AsCurrency;
      Q.Close;
      BalanceAmount := PurchaseAmount - PaidAmount;
      if AAmount <= 0 then raise Exception.Create('지급 금액은 0보다 커야 합니다.');
      if AAmount > BalanceAmount then
        raise Exception.Create('지급 금액이 미지급 잔액을 초과합니다.');
      PaymentID := 0;
      Q.SQL.Text := 'SELECT GEN_ID(GEN_POS_PURCHASE_PAYMENT_ID, 1) FROM RDB$DATABASE';
      Q.Open;
      PaymentID := Q.Fields[0].AsLargeInt;
      Q.Close;
      Q.SQL.Text :=
        'INSERT INTO POS_PURCHASE_PAYMENT (PAYMENT_ID, STORE_ID, PURCHASE_ID, ' +
        'PAYMENT_DATE, PAYMENT_AMOUNT, PAYMENT_METHOD, NOTE, EMPLOYEE_ID) ' +
        'VALUES (:ID, :STORE_ID, :PURCHASE_ID, CURRENT_DATE, :AMOUNT, :METHOD, :NOTE, :EMPLOYEE_ID)';
      Q.ParamByName('ID').AsLargeInt := PaymentID;
      Q.ParamByName('STORE_ID').AsInteger := FStoreID;
      Q.ParamByName('PURCHASE_ID').AsLargeInt := APurchaseID;
      Q.ParamByName('AMOUNT').AsCurrency := AAmount;
      Q.ParamByName('METHOD').AsString := AMethod;
      Q.ParamByName('NOTE').AsString := ANote;
      Q.ParamByName('EMPLOYEE_ID').AsInteger := FEmployeeID;
      Q.ExecSQL;
    finally
      Q.Free;
    end;
    dmDatabase.Connection.Commit;
  except
    dmDatabase.Connection.Rollback;
    raise;
  end;
end;

procedure TfrmPayables.PaymentClick(Sender: TObject);
var
  ID: Int64;
  SAmount, SMethod, SNote: string;
  Amount: Currency;
begin
  ID := SelectedPurchaseID;
  if ID = 0 then
  begin
    MessageDlg('지급 등록할 미지급 구매 내역을 선택해 주세요.', mtWarning, [mbOK], 0);
    Exit;
  end;
  SAmount := '';
  if not InputQuery('거래처 지급 등록', '지급 금액을 입력하세요.', SAmount) then Exit;
  if not TryStrToCurr(Trim(SAmount), Amount) or (Amount <= 0) then
  begin
    MessageDlg('지급 금액은 0보다 큰 숫자로 입력해 주세요.', mtWarning, [mbOK], 0);
    Exit;
  end;
  SMethod := 'BANK';
  if not InputQuery('지급 수단', '지급 수단을 입력하세요 (CASH/BANK/CARD/OTHER).', SMethod) then Exit;
  SMethod := UpperCase(Trim(SMethod));
  if not SameText(SMethod, 'CASH') and
     not SameText(SMethod, 'BANK') and
     not SameText(SMethod, 'CARD') and
     not SameText(SMethod, 'OTHER') then
  begin
    MessageDlg('지급 수단은 CASH, BANK, CARD, OTHER 중 하나여야 합니다.', mtWarning, [mbOK], 0);
    Exit;
  end;
  SNote := '';
  if not InputQuery('지급 비고', '지급 메모 (선택사항)', SNote) then Exit;
  try
    RegisterPayment(ID, Amount, SMethod, SNote);
    RefreshData;
    MessageDlg('지급 내역을 저장했습니다.', mtInformation, [mbOK], 0);
  except
    on E: Exception do
      MessageDlg('지급 등록 실패: ' + E.Message, mtError, [mbOK], 0);
  end;
end;

end.
