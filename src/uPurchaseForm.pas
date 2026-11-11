unit uPurchaseForm;

interface

uses
  System.SysUtils, System.Classes, System.Math, System.UITypes,
  Data.DB, FireDAC.Comp.Client, FireDAC.Stan.Param,
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.DBGrids,
  Vcl.Grids, Vcl.Dialogs, Vcl.ComCtrls, Vcl.Graphics;

type
  TfrmPurchase = class(TForm)
  private
    FStoreID: Integer;
    FEmployeeID: Integer;
    FQuery: TFDQuery;
    FSource: TDataSource;
    FGrid: TDBGrid;
    FDetailGrid: TStringGrid;
    FSearch: TEdit;
    FStatusFilter: TComboBox;
    procedure BuildUI;
    procedure RefreshData;
    procedure LoadDetails;
    procedure SearchClick(Sender: TObject);
    procedure NewClick(Sender: TObject);
    procedure ReceiveClick(Sender: TObject);
    procedure CancelClick(Sender: TObject);
    procedure GridCellClick(Column: TColumn);
    function SelectedPurchaseID: Int64;
    function NextSequenceValue(const ASequenceName: string): Int64;
    procedure ReceivePurchase(APurchaseID: Int64);
    procedure CancelPurchase(APurchaseID: Int64);
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetContext(AStoreID, AEmployeeID: Integer);
  end;

  TfrmPurchaseEditor = class(TForm)
  private
    FStoreID: Integer;
    FEmployeeID: Integer;
    FSupplier: TComboBox;
    FDate: TDateTimePicker;
    FNote: TEdit;
    FGrid: TStringGrid;
    FTotal: TLabel;
    procedure BuildUI;
    procedure LoadSuppliers;
    procedure AddItemClick(Sender: TObject);
    procedure RemoveItemClick(Sender: TObject);
    procedure SaveClick(Sender: TObject);
    procedure UpdateTotal;
    function SelectedSupplierID: Integer;
    function SavePurchase: Int64;
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetContext(AStoreID, AEmployeeID: Integer);
  end;

  TfrmPurchaseItemDialog = class(TForm)
  private
    FMenu: TComboBox;
    FQuantity: TEdit;
    FUnitCost: TEdit;
    procedure BuildUI;
    procedure LoadMenus(AStoreID: Integer);
  public
    MenuID: Integer;
    Quantity: Double;
    UnitCost: Currency;
    constructor Create(AOwner: TComponent); override;
    function Execute(AStoreID: Integer): Boolean;
  end;

implementation

uses
  uDatabase;

function NewQuery: TFDQuery;
begin
  Result := TFDQuery.Create(nil);
  Result.Connection := dmDatabase.Connection;
end;

function GetNextID(const ASequenceName: string): Int64;
var
  Q: TFDQuery;
begin
  Q := NewQuery;
  try
    Q.SQL.Text := 'SELECT GEN_ID(' + ASequenceName + ', 1) FROM RDB$DATABASE';
    Q.Open;
    Result := Q.Fields[0].AsLargeInt;
  finally
    Q.Free;
  end;
end;

constructor TfrmPurchase.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  BuildUI;
end;

procedure TfrmPurchase.BuildUI;
var
  Header, FilterPanel, BottomPanel: TPanel;
  L: TLabel;
  B: TButton;
begin
  Caption := '구매관리 / 입고처리';
  Font.Name := '맑은 고딕';
  Position := poScreenCenter;
  Width := 1180;
  Height := 760;

  Header := TPanel.Create(Self);
  Header.Parent := Self;
  Header.Align := alTop;
  Header.Height := 54;
  Header.BevelOuter := bvNone;
  L := TLabel.Create(Self);
  L.Parent := Header;
  L.SetBounds(16, 12, 500, 30);
  L.Caption := '구매 등록 내역 및 입고 상태 관리';
  L.Font.Name := Font.Name;
  L.Font.Size := 14;
  L.Font.Style := [fsBold];

  FilterPanel := TPanel.Create(Self);
  FilterPanel.Parent := Self;
  FilterPanel.Align := alTop;
  FilterPanel.Height := 48;
  FilterPanel.BevelOuter := bvNone;
  L := TLabel.Create(Self);
  L.Parent := FilterPanel;
  L.SetBounds(16, 13, 70, 22);
  L.Caption := '상태';
  FStatusFilter := TComboBox.Create(Self);
  FStatusFilter.Parent := FilterPanel;
  FStatusFilter.SetBounds(82, 8, 150, 28);
  FStatusFilter.Style := csDropDownList;
  FStatusFilter.Items.Add('전체');
  FStatusFilter.Items.Add('작성중');
  FStatusFilter.Items.Add('입고완료');
  FStatusFilter.Items.Add('취소');
  FStatusFilter.ItemIndex := 0;

  L := TLabel.Create(Self);
  L.Parent := FilterPanel;
  L.SetBounds(250, 13, 70, 22);
  L.Caption := '거래처';
  FSearch := TEdit.Create(Self);
  FSearch.Parent := FilterPanel;
  FSearch.SetBounds(312, 8, 250, 28);
  FSearch.TextHint := '거래처명 검색';
  B := TButton.Create(Self);
  B.Parent := FilterPanel;
  B.SetBounds(572, 7, 90, 32);
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

  FDetailGrid := TStringGrid.Create(Self);
  FDetailGrid.Parent := Self;
  FDetailGrid.Align := alBottom;
  FDetailGrid.Height := 190;
  FDetailGrid.FixedRows := 1;
  FDetailGrid.FixedCols := 0;
  FDetailGrid.ColCount := 5;
  FDetailGrid.RowCount := 2;
  FDetailGrid.DefaultRowHeight := 26;
  FDetailGrid.Options := FDetailGrid.Options + [goRowSelect, goColSizing];
  FDetailGrid.Cells[0,0] := '메뉴번호';
  FDetailGrid.Cells[1,0] := '품목명';
  FDetailGrid.Cells[2,0] := '수량';
  FDetailGrid.Cells[3,0] := '매입단가';
  FDetailGrid.Cells[4,0] := '금액';
  FDetailGrid.ColWidths[0] := 0;
  FDetailGrid.ColWidths[1] := 380;
  FDetailGrid.ColWidths[2] := 130;
  FDetailGrid.ColWidths[3] := 180;
  FDetailGrid.ColWidths[4] := 180;

  BottomPanel := TPanel.Create(Self);
  BottomPanel.Parent := Self;
  BottomPanel.Align := alBottom;
  BottomPanel.Height := 58;
  BottomPanel.BevelOuter := bvNone;
  B := TButton.Create(Self);
  B.Parent := BottomPanel;
  B.SetBounds(12, 9, 130, 40);
  B.Caption := '구매 등록';
  B.OnClick := NewClick;
  B := TButton.Create(Self);
  B.Parent := BottomPanel;
  B.SetBounds(152, 9, 130, 40);
  B.Caption := '입고 확정';
  B.OnClick := ReceiveClick;
  B := TButton.Create(Self);
  B.Parent := BottomPanel;
  B.SetBounds(292, 9, 130, 40);
  B.Caption := '구매 취소';
  B.OnClick := CancelClick;
  B := TButton.Create(Self);
  B.Parent := BottomPanel;
  B.SetBounds(1030, 9, 120, 40);
  B.Caption := '닫기';
  B.ModalResult := mrClose;
end;

procedure TfrmPurchase.SetContext(AStoreID, AEmployeeID: Integer);
begin
  FStoreID := AStoreID;
  FEmployeeID := AEmployeeID;
  if (FStoreID <= 0) or (FEmployeeID <= 0) then
    raise Exception.Create('매장 및 로그인 직원 정보를 확인해 주세요.');
  FQuery.Connection := dmDatabase.Connection;
  RefreshData;
end;

function TfrmPurchase.SelectedPurchaseID: Int64;
begin
  Result := 0;
  if not FQuery.IsEmpty then
    Result := FQuery.FieldByName('PURCHASE_ID').AsLargeInt;
end;

procedure TfrmPurchase.RefreshData;
begin
  FQuery.Close;
  FQuery.SQL.Text :=
    'SELECT P.PURCHASE_ID, P.PURCHASE_DATE, S.SUPPLIER_NAME, ' +
    'IIF(P.PURCHASE_STATUS=''DRAFT'', ''작성중'', IIF(P.PURCHASE_STATUS=''RECEIVED'', ''입고완료'', ''취소'')) AS STATUS_TEXT, ' +
    'P.TOTAL_AMOUNT, E.EMPLOYEE_NAME, P.CREATED_AT ' +
    'FROM POS_PURCHASE P JOIN POS_SUPPLIER S ON S.SUPPLIER_ID=P.SUPPLIER_ID ' +
    'JOIN EMPLOYEE E ON E.EMPLOYEE_ID=P.CREATED_BY ' +
    'WHERE P.STORE_ID=:STORE_ID ';
  if FStatusFilter.ItemIndex = 1 then
    FQuery.SQL.Add('AND P.PURCHASE_STATUS=''DRAFT'' ');
  if FStatusFilter.ItemIndex = 2 then
    FQuery.SQL.Add('AND P.PURCHASE_STATUS=''RECEIVED'' ');
  if FStatusFilter.ItemIndex = 3 then
    FQuery.SQL.Add('AND P.PURCHASE_STATUS=''CANCELLED'' ');
  if Trim(FSearch.Text) <> '' then
    FQuery.SQL.Add('AND S.SUPPLIER_NAME CONTAINING :SUPPLIER_KEY ');
  FQuery.SQL.Add('ORDER BY P.PURCHASE_DATE DESC, P.PURCHASE_ID DESC');
  FQuery.ParamByName('STORE_ID').AsInteger := FStoreID;
  if Trim(FSearch.Text) <> '' then
    FQuery.ParamByName('SUPPLIER_KEY').AsString := Trim(FSearch.Text);
  FQuery.Open;
  FQuery.FieldByName('PURCHASE_ID').Visible := False;
  FQuery.FieldByName('PURCHASE_DATE').DisplayLabel := '구매일자';
  FQuery.FieldByName('SUPPLIER_NAME').DisplayLabel := '거래처';
  FQuery.FieldByName('STATUS_TEXT').DisplayLabel := '상태';
  FQuery.FieldByName('TOTAL_AMOUNT').DisplayLabel := '총 구매금액';
  FQuery.FieldByName('EMPLOYEE_NAME').DisplayLabel := '등록 직원';
  FQuery.FieldByName('CREATED_AT').DisplayLabel := '등록일시';
  LoadDetails;
end;

procedure TfrmPurchase.LoadDetails;
var
  Q: TFDQuery;
  R: Integer;
begin
  FDetailGrid.RowCount := 2;
  FDetailGrid.Cells[1,1] := '';
  if SelectedPurchaseID = 0 then Exit;
  Q := NewQuery;
  try
    Q.SQL.Text :=
      'SELECT D.MENU_ID, M.MENU_NAME, D.QUANTITY, D.UNIT_COST, D.LINE_AMOUNT ' +
      'FROM POS_PURCHASE_ITEM D JOIN MENU_ITEM M ON M.MENU_ID=D.MENU_ID ' +
      'WHERE D.STORE_ID=:STORE_ID AND D.PURCHASE_ID=:PURCHASE_ID ' +
      'ORDER BY D.PURCHASE_ITEM_ID';
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.ParamByName('PURCHASE_ID').AsLargeInt := SelectedPurchaseID;
    Q.Open;
    FDetailGrid.RowCount := Max(2, Q.RecordCount + 1);
    R := 1;
    while not Q.Eof do
    begin
      FDetailGrid.Cells[0,R] := Q.FieldByName('MENU_ID').AsString;
      FDetailGrid.Cells[1,R] := Q.FieldByName('MENU_NAME').AsString;
      FDetailGrid.Cells[2,R] := FormatFloat('#,##0.###', Q.FieldByName('QUANTITY').AsFloat);
      FDetailGrid.Cells[3,R] := FormatCurr('#,##0.00', Q.FieldByName('UNIT_COST').AsCurrency);
      FDetailGrid.Cells[4,R] := FormatCurr('#,##0.00', Q.FieldByName('LINE_AMOUNT').AsCurrency);
      Inc(R);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

procedure TfrmPurchase.GridCellClick(Column: TColumn);
begin
  LoadDetails;
end;

procedure TfrmPurchase.SearchClick(Sender: TObject);
begin
  try
    RefreshData;
  except
    on E: Exception do
      MessageDlg('구매 내역 조회 실패: ' + E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TfrmPurchase.NewClick(Sender: TObject);
var
  Editor: TfrmPurchaseEditor;
begin
  Editor := TfrmPurchaseEditor.Create(Self);
  try
    Editor.SetContext(FStoreID, FEmployeeID);
    if Editor.ShowModal = mrOk then
      RefreshData;
  finally
    Editor.Free;
  end;
end;

function TfrmPurchase.NextSequenceValue(const ASequenceName: string): Int64;
begin
  Result := GetNextID(ASequenceName);
end;

procedure TfrmPurchase.ReceivePurchase(APurchaseID: Int64);
var
  Q, QItem: TFDQuery;
  MenuID: Integer;
  Qty, BeforeQty, AfterQty: Double;
  MovementID: Int64;
  PaidAmount: Currency;
begin
  dmDatabase.Connection.StartTransaction;
  try
    Q := NewQuery;
    try
      Q.SQL.Text := 'SELECT PURCHASE_STATUS FROM POS_PURCHASE ' +
        'WHERE STORE_ID=:STORE_ID AND PURCHASE_ID=:PURCHASE_ID WITH LOCK';
      Q.ParamByName('STORE_ID').AsInteger := FStoreID;
      Q.ParamByName('PURCHASE_ID').AsLargeInt := APurchaseID;
      Q.Open;
      if Q.IsEmpty then raise Exception.Create('구매 정보를 찾을 수 없습니다.');
      if Q.FieldByName('PURCHASE_STATUS').AsString <> 'DRAFT' then
        raise Exception.Create('작성중 상태의 구매만 입고 확정할 수 있습니다.');
      Q.Close;

      QItem := NewQuery;
      try
        QItem.SQL.Text := 'SELECT MENU_ID, QUANTITY FROM POS_PURCHASE_ITEM ' +
          'WHERE STORE_ID=:STORE_ID AND PURCHASE_ID=:PURCHASE_ID';
        QItem.ParamByName('STORE_ID').AsInteger := FStoreID;
        QItem.ParamByName('PURCHASE_ID').AsLargeInt := APurchaseID;
        QItem.Open;
        while not QItem.Eof do
        begin
          MenuID := QItem.FieldByName('MENU_ID').AsInteger;
          Qty := QItem.FieldByName('QUANTITY').AsFloat;
          Q.SQL.Text := 'SELECT STOCK_MANAGED_YN, STOCK_QTY FROM MENU_ITEM ' +
            'WHERE STORE_ID=:STORE_ID AND MENU_ID=:MENU_ID WITH LOCK';
          Q.ParamByName('STORE_ID').AsInteger := FStoreID;
          Q.ParamByName('MENU_ID').AsInteger := MenuID;
          Q.Open;
          if Q.IsEmpty then raise Exception.Create('구매 품목 메뉴를 찾을 수 없습니다.');
          if Q.FieldByName('STOCK_MANAGED_YN').AsString <> 'Y' then
            raise Exception.Create('재고관리 미사용 메뉴가 포함되어 있습니다. 메뉴 재고관리 설정을 확인하세요.');
          BeforeQty := Q.FieldByName('STOCK_QTY').AsFloat;
          Q.Close;
          AfterQty := BeforeQty + Qty;

          Q.SQL.Text := 'UPDATE MENU_ITEM SET STOCK_QTY=:STOCK_QTY ' +
            'WHERE STORE_ID=:STORE_ID AND MENU_ID=:MENU_ID';
          Q.ParamByName('STOCK_QTY').AsFloat := AfterQty;
          Q.ParamByName('STORE_ID').AsInteger := FStoreID;
          Q.ParamByName('MENU_ID').AsInteger := MenuID;
          Q.ExecSQL;

          MovementID := NextSequenceValue('GEN_POS_STOCK_MOVEMENT_ID');
          Q.SQL.Text :=
            'INSERT INTO POS_STOCK_MOVEMENT ' +
            '(STOCK_MOVEMENT_ID, STORE_ID, MENU_ID, MOVEMENT_TYPE, QUANTITY, ' +
            'STOCK_BEFORE, STOCK_AFTER, REASON_CODE, DESCRIPTION, REFERENCE_TYPE, ' +
            'REFERENCE_ID, EMPLOYEE_ID) VALUES ' +
            '(:ID, :STORE_ID, :MENU_ID, ''IN'', :QTY, :BEFORE_QTY, :AFTER_QTY, ' +
            '''PURCHASE'', :DESCRIPTION, ''PURCHASE'', :REFERENCE_ID, :EMPLOYEE_ID)';
          Q.ParamByName('ID').AsLargeInt := MovementID;
          Q.ParamByName('STORE_ID').AsInteger := FStoreID;
          Q.ParamByName('MENU_ID').AsInteger := MenuID;
          Q.ParamByName('QTY').AsFloat := Qty;
          Q.ParamByName('BEFORE_QTY').AsFloat := BeforeQty;
          Q.ParamByName('AFTER_QTY').AsFloat := AfterQty;
          Q.ParamByName('DESCRIPTION').AsString := '구매 입고 #' + IntToStr(APurchaseID);
          Q.ParamByName('REFERENCE_ID').AsLargeInt := APurchaseID;
          Q.ParamByName('EMPLOYEE_ID').AsInteger := FEmployeeID;
          Q.ExecSQL;
          QItem.Next;
        end;
      finally
        QItem.Free;
      end;

      Q.SQL.Text := 'UPDATE POS_PURCHASE SET PURCHASE_STATUS=''RECEIVED'', ' +
        'RECEIVED_BY=:EMPLOYEE_ID, RECEIVED_AT=CURRENT_TIMESTAMP ' +
        'WHERE STORE_ID=:STORE_ID AND PURCHASE_ID=:PURCHASE_ID';
      Q.ParamByName('EMPLOYEE_ID').AsInteger := FEmployeeID;
      Q.ParamByName('STORE_ID').AsInteger := FStoreID;
      Q.ParamByName('PURCHASE_ID').AsLargeInt := APurchaseID;
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

procedure TfrmPurchase.CancelPurchase(APurchaseID: Int64);
var
  Q, QItem: TFDQuery;
  StatusText: UnicodeString;
  MenuID: Integer;
  Qty, BeforeQty, AfterQty: Double;
  MovementID: Int64;
begin
  dmDatabase.Connection.StartTransaction;
  try
    Q := NewQuery;
    try
      Q.SQL.Text := 'SELECT PURCHASE_STATUS FROM POS_PURCHASE ' +
        'WHERE STORE_ID=:STORE_ID AND PURCHASE_ID=:PURCHASE_ID WITH LOCK';
      Q.ParamByName('STORE_ID').AsInteger := FStoreID;
      Q.ParamByName('PURCHASE_ID').AsLargeInt := APurchaseID;
      Q.Open;
      if Q.IsEmpty then raise Exception.Create('구매 정보를 찾을 수 없습니다.');
      StatusText := Q.FieldByName('PURCHASE_STATUS').AsString;
      Q.Close;
      if StatusText = 'CANCELLED' then
        raise Exception.Create('이미 취소된 구매입니다.');
      if (StatusText <> 'DRAFT') and (StatusText <> 'RECEIVED') then
        raise Exception.Create('취소할 수 없는 구매 상태입니다.');

      if StatusText = 'RECEIVED' then
      begin
        Q.SQL.Text := 'SELECT COALESCE(SUM(PAYMENT_AMOUNT), 0) AS PAID_AMOUNT ' +
          'FROM POS_PURCHASE_PAYMENT WHERE STORE_ID=:STORE_ID AND PURCHASE_ID=:PURCHASE_ID';
        Q.ParamByName('STORE_ID').AsInteger := FStoreID;
        Q.ParamByName('PURCHASE_ID').AsLargeInt := APurchaseID;
        Q.Open;
        PaidAmount := Q.FieldByName('PAID_AMOUNT').AsCurrency;
        Q.Close;
        if PaidAmount > 0 then
          raise Exception.Create('지급 내역이 등록된 구매는 취소할 수 없습니다. 지급 내역을 먼저 정산해야 합니다.');

        QItem := NewQuery;
        try
          QItem.SQL.Text := 'SELECT MENU_ID, SUM(QUANTITY) AS TOTAL_QTY ' +
            'FROM POS_PURCHASE_ITEM WHERE STORE_ID=:STORE_ID ' +
            'AND PURCHASE_ID=:PURCHASE_ID GROUP BY MENU_ID';
          QItem.ParamByName('STORE_ID').AsInteger := FStoreID;
          QItem.ParamByName('PURCHASE_ID').AsLargeInt := APurchaseID;
          QItem.Open;
          while not QItem.Eof do
          begin
            MenuID := QItem.FieldByName('MENU_ID').AsInteger;
            Qty := QItem.FieldByName('TOTAL_QTY').AsFloat;
            Q.SQL.Text := 'SELECT STOCK_QTY FROM MENU_ITEM ' +
              'WHERE STORE_ID=:STORE_ID AND MENU_ID=:MENU_ID WITH LOCK';
            Q.ParamByName('STORE_ID').AsInteger := FStoreID;
            Q.ParamByName('MENU_ID').AsInteger := MenuID;
            Q.Open;
            if Q.IsEmpty then raise Exception.Create('취소할 재고 메뉴를 찾을 수 없습니다.');
            BeforeQty := Q.FieldByName('STOCK_QTY').AsFloat;
            Q.Close;
            if BeforeQty < Qty then
              raise Exception.CreateFmt('현재고 부족으로 구매를 취소할 수 없습니다. 메뉴번호 %d, 현재고 %.3f, 취소수량 %.3f',
                [MenuID, BeforeQty, Qty]);
            AfterQty := BeforeQty - Qty;

            Q.SQL.Text := 'UPDATE MENU_ITEM SET STOCK_QTY=:STOCK_QTY ' +
              'WHERE STORE_ID=:STORE_ID AND MENU_ID=:MENU_ID';
            Q.ParamByName('STOCK_QTY').AsFloat := AfterQty;
            Q.ParamByName('STORE_ID').AsInteger := FStoreID;
            Q.ParamByName('MENU_ID').AsInteger := MenuID;
            Q.ExecSQL;

            MovementID := NextSequenceValue('GEN_POS_STOCK_MOVEMENT_ID');
            Q.SQL.Text :=
              'INSERT INTO POS_STOCK_MOVEMENT ' +
              '(STOCK_MOVEMENT_ID, STORE_ID, MENU_ID, MOVEMENT_TYPE, QUANTITY, ' +
              'STOCK_BEFORE, STOCK_AFTER, REASON_CODE, DESCRIPTION, REFERENCE_TYPE, ' +
              'REFERENCE_ID, EMPLOYEE_ID) VALUES ' +
              '(:ID, :STORE_ID, :MENU_ID, ''OUT'', :QTY, :BEFORE_QTY, :AFTER_QTY, ' +
              '''PURCHASE_CANCEL'', :DESCRIPTION, ''PURCHASE'', :REFERENCE_ID, :EMPLOYEE_ID)';
            Q.ParamByName('ID').AsLargeInt := MovementID;
            Q.ParamByName('STORE_ID').AsInteger := FStoreID;
            Q.ParamByName('MENU_ID').AsInteger := MenuID;
            Q.ParamByName('QTY').AsFloat := Qty;
            Q.ParamByName('BEFORE_QTY').AsFloat := BeforeQty;
            Q.ParamByName('AFTER_QTY').AsFloat := AfterQty;
            Q.ParamByName('DESCRIPTION').AsString := '구매 취소 #' + IntToStr(APurchaseID);
            Q.ParamByName('REFERENCE_ID').AsLargeInt := APurchaseID;
            Q.ParamByName('EMPLOYEE_ID').AsInteger := FEmployeeID;
            Q.ExecSQL;
            QItem.Next;
          end;
        finally
          QItem.Free;
        end;
      end;

      Q.SQL.Text := 'UPDATE POS_PURCHASE SET PURCHASE_STATUS=''CANCELLED'', ' +
        'CANCELLED_BY=:EMPLOYEE_ID, CANCELLED_AT=CURRENT_TIMESTAMP ' +
        'WHERE STORE_ID=:STORE_ID AND PURCHASE_ID=:PURCHASE_ID';
      Q.ParamByName('EMPLOYEE_ID').AsInteger := FEmployeeID;
      Q.ParamByName('STORE_ID').AsInteger := FStoreID;
      Q.ParamByName('PURCHASE_ID').AsLargeInt := APurchaseID;
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

procedure TfrmPurchase.ReceiveClick(Sender: TObject);
var
  ID: Int64;
begin
  ID := SelectedPurchaseID;
  if ID = 0 then
  begin
    MessageDlg('입고 확정할 구매 내역을 선택해 주세요.', mtWarning, [mbOK], 0);
    Exit;
  end;
  if MessageDlg('선택한 구매를 입고 확정하고 재고를 증가시키겠습니까?',
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  try
    ReceivePurchase(ID);
    RefreshData;
    MessageDlg('입고가 확정되었습니다. 재고 및 재고 이력에 반영했습니다.',
      mtInformation, [mbOK], 0);
  except
    on E: Exception do
      MessageDlg('입고 처리 실패: ' + E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TfrmPurchase.CancelClick(Sender: TObject);
var
  ID: Int64;
begin
  ID := SelectedPurchaseID;
  if ID = 0 then
  begin
    MessageDlg('취소할 구매 내역을 선택해 주세요.', mtWarning, [mbOK], 0);
    Exit;
  end;
  if MessageDlg('구매를 취소하시겠습니까? 이미 입고된 구매는 재고를 차감합니다.',
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  try
    CancelPurchase(ID);
    RefreshData;
    MessageDlg('구매가 취소되었습니다.', mtInformation, [mbOK], 0);
  except
    on E: Exception do
      MessageDlg('구매 취소 실패: ' + E.Message, mtError, [mbOK], 0);
  end;
end;

constructor TfrmPurchaseEditor.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  BuildUI;
end;

procedure TfrmPurchaseEditor.BuildUI;
var
  Header, DetailPanel, BottomPanel: TPanel;
  L: TLabel;
  B: TButton;
begin
  Caption := '구매 등록';
  Font.Name := '맑은 고딕';
  Position := poScreenCenter;
  Width := 850;
  Height := 600;

  Header := TPanel.Create(Self);
  Header.Parent := Self;
  Header.Align := alTop;
  Header.Height := 110;
  Header.BevelOuter := bvNone;
  L := TLabel.Create(Self);
  L.Parent := Header;
  L.SetBounds(16, 12, 70, 22);
  L.Caption := '거래처';
  FSupplier := TComboBox.Create(Self);
  FSupplier.Parent := Header;
  FSupplier.SetBounds(92, 8, 360, 28);
  FSupplier.Style := csDropDownList;
  L := TLabel.Create(Self);
  L.Parent := Header;
  L.SetBounds(480, 12, 70, 22);
  L.Caption := '구매일자';
  FDate := TDateTimePicker.Create(Self);
  FDate.Parent := Header;
  FDate.SetBounds(550, 8, 180, 28);
  FDate.Date := Date;
  L := TLabel.Create(Self);
  L.Parent := Header;
  L.SetBounds(16, 58, 70, 22);
  L.Caption := '비고';
  FNote := TEdit.Create(Self);
  FNote.Parent := Header;
  FNote.SetBounds(92, 54, 638, 28);

  DetailPanel := TPanel.Create(Self);
  DetailPanel.Parent := Self;
  DetailPanel.Align := alClient;
  DetailPanel.BevelOuter := bvNone;
  FGrid := TStringGrid.Create(Self);
  FGrid.Parent := DetailPanel;
  FGrid.Align := alClient;
  FGrid.FixedRows := 1;
  FGrid.FixedCols := 0;
  FGrid.ColCount := 5;
  FGrid.RowCount := 2;
  FGrid.DefaultRowHeight := 28;
  FGrid.Options := FGrid.Options + [goRowSelect, goColSizing];
  FGrid.Cells[0,0] := '메뉴번호';
  FGrid.Cells[1,0] := '품목명';
  FGrid.Cells[2,0] := '수량';
  FGrid.Cells[3,0] := '매입단가';
  FGrid.Cells[4,0] := '금액';
  FGrid.ColWidths[0] := 0;
  FGrid.ColWidths[1] := 320;
  FGrid.ColWidths[2] := 110;
  FGrid.ColWidths[3] := 140;
  FGrid.ColWidths[4] := 140;

  BottomPanel := TPanel.Create(Self);
  BottomPanel.Parent := Self;
  BottomPanel.Align := alBottom;
  BottomPanel.Height := 86;
  BottomPanel.BevelOuter := bvNone;
  B := TButton.Create(Self);
  B.Parent := BottomPanel;
  B.SetBounds(12, 8, 110, 38);
  B.Caption := '품목 추가';
  B.OnClick := AddItemClick;
  B := TButton.Create(Self);
  B.Parent := BottomPanel;
  B.SetBounds(132, 8, 110, 38);
  B.Caption := '품목 삭제';
  B.OnClick := RemoveItemClick;
  FTotal := TLabel.Create(Self);
  FTotal.Parent := BottomPanel;
  FTotal.SetBounds(270, 15, 300, 28);
  FTotal.Font.Style := [fsBold];
  FTotal.Caption := '합계: 0';
  B := TButton.Create(Self);
  B.Parent := BottomPanel;
  B.SetBounds(610, 8, 100, 38);
  B.Caption := '저장';
  B.OnClick := SaveClick;
  B := TButton.Create(Self);
  B.Parent := BottomPanel;
  B.SetBounds(720, 8, 100, 38);
  B.Caption := '닫기';
  B.ModalResult := mrCancel;
end;

procedure TfrmPurchaseEditor.SetContext(AStoreID, AEmployeeID: Integer);
begin
  FStoreID := AStoreID;
  FEmployeeID := AEmployeeID;
  LoadSuppliers;
end;

procedure TfrmPurchaseEditor.LoadSuppliers;
var
  Q: TFDQuery;
begin
  FSupplier.Items.Clear;
  Q := NewQuery;
  try
    Q.SQL.Text := 'SELECT SUPPLIER_ID, SUPPLIER_NAME FROM POS_SUPPLIER ' +
      'WHERE STORE_ID=:STORE_ID AND ACTIVE_YN=''Y'' ORDER BY SUPPLIER_NAME';
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.Open;
    while not Q.Eof do
    begin
      FSupplier.Items.Add(Q.FieldByName('SUPPLIER_ID').AsString + ' | ' +
        Q.FieldByName('SUPPLIER_NAME').AsString);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
  if FSupplier.Items.Count > 0 then FSupplier.ItemIndex := 0;
end;

function TfrmPurchaseEditor.SelectedSupplierID: Integer;
var
  S: string;
  P: Integer;
begin
  Result := 0;
  if FSupplier.ItemIndex < 0 then Exit;
  S := FSupplier.Items[FSupplier.ItemIndex];
  P := Pos(' | ', S);
  if P > 1 then TryStrToInt(Copy(S, 1, P - 1), Result);
end;

procedure TfrmPurchaseEditor.AddItemClick(Sender: TObject);
var
  D: TfrmPurchaseItemDialog;
  R, I, MenuID: Integer;
  Found: Boolean;
begin
  D := TfrmPurchaseItemDialog.Create(Self);
  try
    if not D.Execute(FStoreID) then Exit;
    Found := False;
    for I := 1 to FGrid.RowCount - 1 do
      if TryStrToInt(FGrid.Cells[0,I], MenuID) and (MenuID = D.MenuID) then
      begin
        Found := True;
        MessageDlg('같은 품목이 이미 등록되어 있습니다. 기존 품목을 삭제한 후 다시 추가해 주세요.',
          mtWarning, [mbOK], 0);
        Exit;
      end;
    R := FGrid.RowCount;
    if (R = 2) and (FGrid.Cells[1,1] = '') then R := 1;
    FGrid.RowCount := R + 1;
    FGrid.Cells[0,R] := IntToStr(D.MenuID);
    FGrid.Cells[1,R] := Copy(D.FMenu.Items[D.FMenu.ItemIndex],
      Pos(' | ', D.FMenu.Items[D.FMenu.ItemIndex]) + 3, MaxInt);
    FGrid.Cells[2,R] := FloatToStr(D.Quantity);
    FGrid.Cells[3,R] := CurrToStr(D.UnitCost);
    FGrid.Cells[4,R] := FormatCurr('0.00', D.Quantity * D.UnitCost);
    UpdateTotal;
  finally
    D.Free;
  end;
end;

procedure TfrmPurchaseEditor.RemoveItemClick(Sender: TObject);
var
  R, I: Integer;
begin
  R := FGrid.Row;
  if (R <= 0) or (R >= FGrid.RowCount) or (FGrid.Cells[1,R] = '') then Exit;
  for I := R to FGrid.RowCount - 2 do
    FGrid.Rows[I].Assign(FGrid.Rows[I + 1]);
  if FGrid.RowCount > 2 then
    FGrid.RowCount := FGrid.RowCount - 1
  else
    FGrid.Rows[1].Clear;
  UpdateTotal;
end;

procedure TfrmPurchaseEditor.UpdateTotal;
var
  I: Integer;
  Amount, Total: Currency;
begin
  Total := 0;
  for I := 1 to FGrid.RowCount - 1 do
    if TryStrToCurr(FGrid.Cells[4,I], Amount) then Total := Total + Amount;
  FTotal.Caption := '합계: ' + FormatCurr('#,##0.00', Total);
end;

function TfrmPurchaseEditor.SavePurchase: Int64;
var
  Q: TFDQuery;
  I, MenuID, ItemCount: Integer;
  Qty: Double;
  UnitCost, LineAmount, Total: Currency;
  PurchaseItemID: Int64;
begin
  if SelectedSupplierID <= 0 then
    raise Exception.Create('사용 중인 거래처를 선택해 주세요.');
  Total := 0;
  ItemCount := 0;
  for I := 1 to FGrid.RowCount - 1 do
  begin
    if not TryStrToInt(FGrid.Cells[0,I], MenuID) then Continue;
    Inc(ItemCount);
    if TryStrToCurr(FGrid.Cells[4,I], LineAmount) then
      Total := Total + LineAmount;
  end;
  if ItemCount = 0 then raise Exception.Create('구매 품목을 한 개 이상 등록해 주세요.');

  dmDatabase.Connection.StartTransaction;
  try
    Result := GetNextID('GEN_POS_PURCHASE_ID');
    Q := NewQuery;
    try
      Q.SQL.Text :=
        'INSERT INTO POS_PURCHASE (PURCHASE_ID, STORE_ID, SUPPLIER_ID, ' +
        'PURCHASE_DATE, PURCHASE_STATUS, TOTAL_AMOUNT, NOTE, CREATED_BY) ' +
        'VALUES (:ID, :STORE_ID, :SUPPLIER_ID, :PURCHASE_DATE, ''DRAFT'', ' +
        ':TOTAL_AMOUNT, :NOTE, :CREATED_BY)';
      Q.ParamByName('ID').AsLargeInt := Result;
      Q.ParamByName('STORE_ID').AsInteger := FStoreID;
      Q.ParamByName('SUPPLIER_ID').AsInteger := SelectedSupplierID;
      Q.ParamByName('PURCHASE_DATE').AsDate := FDate.Date;
      Q.ParamByName('TOTAL_AMOUNT').AsCurrency := Total;
      Q.ParamByName('NOTE').AsString := Trim(FNote.Text);
      Q.ParamByName('CREATED_BY').AsInteger := FEmployeeID;
      Q.ExecSQL;

      for I := 1 to FGrid.RowCount - 1 do
      begin
        if not TryStrToInt(FGrid.Cells[0,I], MenuID) then Continue;
        if not TryStrToFloat(FGrid.Cells[2,I], Qty) or (Qty <= 0) then
          raise Exception.Create('구매 수량이 올바르지 않습니다.');
        if not TryStrToCurr(FGrid.Cells[3,I], UnitCost) or (UnitCost < 0) then
          raise Exception.Create('매입 단가가 올바르지 않습니다.');
        LineAmount := SimpleRoundTo(Qty * UnitCost, -2);
        PurchaseItemID := GetNextID('GEN_POS_PURCHASE_ITEM_ID');
        Q.SQL.Text :=
          'INSERT INTO POS_PURCHASE_ITEM (PURCHASE_ITEM_ID, STORE_ID, ' +
          'PURCHASE_ID, MENU_ID, QUANTITY, UNIT_COST, LINE_AMOUNT) ' +
          'VALUES (:ITEM_ID, :STORE_ID, :PURCHASE_ID, :MENU_ID, :QTY, :UNIT_COST, :LINE_AMOUNT)';
        Q.ParamByName('ITEM_ID').AsLargeInt := PurchaseItemID;
        Q.ParamByName('STORE_ID').AsInteger := FStoreID;
        Q.ParamByName('PURCHASE_ID').AsLargeInt := Result;
        Q.ParamByName('MENU_ID').AsInteger := MenuID;
        Q.ParamByName('QTY').AsFloat := Qty;
        Q.ParamByName('UNIT_COST').AsCurrency := UnitCost;
        Q.ParamByName('LINE_AMOUNT').AsCurrency := LineAmount;
        Q.ExecSQL;
      end;
    finally
      Q.Free;
    end;
    dmDatabase.Connection.Commit;
  except
    dmDatabase.Connection.Rollback;
    raise;
  end;
end;

procedure TfrmPurchaseEditor.SaveClick(Sender: TObject);
begin
  try
    SavePurchase;
    ModalResult := mrOk;
  except
    on E: Exception do
      MessageDlg('구매 등록 실패: ' + E.Message, mtError, [mbOK], 0);
  end;
end;

constructor TfrmPurchaseItemDialog.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  BuildUI;
end;

procedure TfrmPurchaseItemDialog.BuildUI;
var
  L: TLabel;
  B: TButton;
begin
  Caption := '구매 품목 추가';
  Font.Name := '맑은 고딕';
  Position := poScreenCenter;
  BorderStyle := bsDialog;
  Width := 470;
  Height := 250;
  L := TLabel.Create(Self);
  L.Parent := Self;
  L.SetBounds(18, 20, 90, 22);
  L.Caption := '재고 메뉴';
  FMenu := TComboBox.Create(Self);
  FMenu.Parent := Self;
  FMenu.SetBounds(112, 16, 320, 28);
  FMenu.Style := csDropDownList;
  L := TLabel.Create(Self);
  L.Parent := Self;
  L.SetBounds(18, 66, 90, 22);
  L.Caption := '수량';
  FQuantity := TEdit.Create(Self);
  FQuantity.Parent := Self;
  FQuantity.SetBounds(112, 62, 140, 28);
  FQuantity.Text := '1';
  L := TLabel.Create(Self);
  L.Parent := Self;
  L.SetBounds(18, 112, 90, 22);
  L.Caption := '매입 단가';
  FUnitCost := TEdit.Create(Self);
  FUnitCost.Parent := Self;
  FUnitCost.SetBounds(112, 108, 140, 28);
  FUnitCost.Text := '0';
  B := TButton.Create(Self);
  B.Parent := Self;
  B.SetBounds(220, 160, 100, 36);
  B.Caption := '확인';
  B.ModalResult := mrOk;
  B := TButton.Create(Self);
  B.Parent := Self;
  B.SetBounds(330, 160, 100, 36);
  B.Caption := '취소';
  B.ModalResult := mrCancel;
end;

procedure TfrmPurchaseItemDialog.LoadMenus(AStoreID: Integer);
var
  Q: TFDQuery;
begin
  FMenu.Items.Clear;
  Q := NewQuery;
  try
    Q.SQL.Text := 'SELECT MENU_ID, MENU_NAME FROM MENU_ITEM ' +
      'WHERE STORE_ID=:STORE_ID AND ACTIVE_YN=''Y'' AND STOCK_MANAGED_YN=''Y'' ' +
      'ORDER BY MENU_NAME';
    Q.ParamByName('STORE_ID').AsInteger := AStoreID;
    Q.Open;
    while not Q.Eof do
    begin
      FMenu.Items.Add(Q.FieldByName('MENU_ID').AsString + ' | ' +
        Q.FieldByName('MENU_NAME').AsString);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
  if FMenu.Items.Count > 0 then FMenu.ItemIndex := 0;
end;

function TfrmPurchaseItemDialog.Execute(AStoreID: Integer): Boolean;
var
  S: string;
  P: Integer;
begin
  LoadMenus(AStoreID);
  if FMenu.Items.Count = 0 then
    raise Exception.Create('재고관리가 사용 설정된 메뉴가 없습니다. 먼저 메뉴의 재고관리를 설정해 주세요.');
  Result := ShowModal = mrOk;
  if not Result then Exit;
  if FMenu.ItemIndex < 0 then
    raise Exception.Create('구매할 메뉴를 선택해 주세요.');
  S := FMenu.Items[FMenu.ItemIndex];
  P := Pos(' | ', S);
  if (P <= 1) or not TryStrToInt(Copy(S, 1, P - 1), MenuID) then
    raise Exception.Create('메뉴 정보를 확인할 수 없습니다.');
  if not TryStrToFloat(Trim(FQuantity.Text), Quantity) or (Quantity <= 0) then
    raise Exception.Create('수량은 0보다 큰 숫자로 입력해 주세요.');
  if not TryStrToCurr(Trim(FUnitCost.Text), UnitCost) or (UnitCost < 0) then
    raise Exception.Create('매입 단가는 0 이상의 숫자로 입력해 주세요.');
end;

end.
