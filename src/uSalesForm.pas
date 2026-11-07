unit uSalesForm;

interface

uses
  System.SysUtils, System.Classes, System.UITypes, System.Math, Data.DB,
  FireDAC.Comp.Client, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Grids, Vcl.Dialogs;

type
  TCartItem = record
    MenuID: Integer;
    MenuName: string;
    UnitPrice: Currency;
    Quantity: Integer;
  end;

  TfrmSales = class(TForm)
  published
    procedure FormCreate(Sender: TObject);
  private
    FStoreID: Integer;
    FCart: array of TCartItem;
    FTableCombo: TComboBox;
    FCategoryPanel: TScrollBox;
    FMenuPanel: TScrollBox;
    FCartGrid: TStringGrid;
    FTotalLabel: TLabel;
    FStatusLabel: TLabel;
    procedure LoadTables;
    procedure LoadCategories;
    procedure LoadMenus(ACategoryID: Integer);
    procedure AddMenuClick(Sender: TObject);
    procedure CategoryClick(Sender: TObject);
    procedure RefreshCart;
    procedure ChangeQuantity(ADelta: Integer);
    procedure RemoveSelected;
    procedure SaveOrder;
    procedure QuantityPlusClick(Sender: TObject);
    procedure QuantityMinusClick(Sender: TObject);
    procedure RemoveClick(Sender: TObject);
    procedure SaveClick(Sender: TObject);
    function SelectedTableID: Integer;
    function NextSequenceValue(const ASequenceName: string): Int64;
    function CartTotal: Currency;
    procedure AddCartItem(AMenuID: Integer; const AMenuName: string;
      APrice: Currency);
  public
    procedure SetStoreID(AStoreID: Integer);
  end;

implementation

uses
  uDatabase;

{$R *.dfm}

procedure TfrmSales.FormCreate(Sender: TObject);
var
  Header, CartPanel, ButtonPanel: TPanel;
  Lbl: TLabel;
  Btn: TButton;
begin
  Caption := 'POS 판매';
  Font.Name := '맑은 고딕';
  Width := 1180;
  Height := 760;
  Position := poScreenCenter;

  Header := TPanel.Create(Self);
  Header.Parent := Self;
  Header.Align := alTop;
  Header.Height := 58;
  Header.BevelOuter := bvNone;

  Lbl := TLabel.Create(Self);
  Lbl.Parent := Header;
  Lbl.Left := 16;
  Lbl.Top := 20;
  Lbl.Caption := '테이블 선택';
  Lbl.Font.Name := Font.Name;

  FTableCombo := TComboBox.Create(Self);
  FTableCombo.Parent := Header;
  FTableCombo.Left := 110;
  FTableCombo.Top := 13;
  FTableCombo.Width := 220;
  FTableCombo.Style := csDropDownList;
  FTableCombo.Font.Name := Font.Name;

  FStatusLabel := TLabel.Create(Self);
  FStatusLabel.Parent := Header;
  FStatusLabel.Left := 360;
  FStatusLabel.Top := 20;
  FStatusLabel.Caption := '주문할 메뉴를 선택하세요.';
  FStatusLabel.Font.Name := Font.Name;

  FCategoryPanel := TScrollBox.Create(Self);
  FCategoryPanel.Parent := Self;
  FCategoryPanel.Align := alTop;
  FCategoryPanel.Height := 58;
  FCategoryPanel.HorzScrollBar.Visible := True;
  FCategoryPanel.VertScrollBar.Visible := False;

  FMenuPanel := TScrollBox.Create(Self);
  FMenuPanel.Parent := Self;
  FMenuPanel.Align := alClient;
  FMenuPanel.BorderStyle := bsNone;

  CartPanel := TPanel.Create(Self);
  CartPanel.Parent := Self;
  CartPanel.Align := alBottom;
  CartPanel.Height := 280;
  CartPanel.BevelOuter := bvNone;

  FCartGrid := TStringGrid.Create(Self);
  FCartGrid.Parent := CartPanel;
  FCartGrid.Align := alClient;
  FCartGrid.FixedRows := 1;
  FCartGrid.FixedCols := 0;
  FCartGrid.ColCount := 4;
  FCartGrid.RowCount := 2;
  FCartGrid.DefaultRowHeight := 28;
  FCartGrid.Options := FCartGrid.Options + [goRowSelect, goColSizing];
  FCartGrid.Cells[0, 0] := '메뉴';
  FCartGrid.Cells[1, 0] := '단가';
  FCartGrid.Cells[2, 0] := '수량';
  FCartGrid.Cells[3, 0] := '금액';
  FCartGrid.ColWidths[0] := 430;
  FCartGrid.ColWidths[1] := 130;
  FCartGrid.ColWidths[2] := 90;
  FCartGrid.ColWidths[3] := 150;

  ButtonPanel := TPanel.Create(Self);
  ButtonPanel.Parent := CartPanel;
  ButtonPanel.Align := alBottom;
  ButtonPanel.Height := 54;
  ButtonPanel.BevelOuter := bvNone;

  Btn := TButton.Create(Self);
  Btn.Parent := ButtonPanel;
  Btn.Left := 12;
  Btn.Top := 7;
  Btn.Width := 90;
  Btn.Height := 38;
  Btn.Caption := '수량 +';
  Btn.OnClick := QuantityPlusClick;

  Btn := TButton.Create(Self);
  Btn.Parent := ButtonPanel;
  Btn.Left := 108;
  Btn.Top := 7;
  Btn.Width := 90;
  Btn.Height := 38;
  Btn.Caption := '수량 -';
  Btn.OnClick := QuantityMinusClick;

  Btn := TButton.Create(Self);
  Btn.Parent := ButtonPanel;
  Btn.Left := 204;
  Btn.Top := 7;
  Btn.Width := 90;
  Btn.Height := 38;
  Btn.Caption := '삭제';
  Btn.OnClick := RemoveClick;

  FTotalLabel := TLabel.Create(Self);
  FTotalLabel.Parent := ButtonPanel;
  FTotalLabel.Left := 430;
  FTotalLabel.Top := 17;
  FTotalLabel.Caption := '합계: 0원';
  FTotalLabel.Font.Name := Font.Name;
  FTotalLabel.Font.Size := 14;
  FTotalLabel.Font.Style := [fsBold];

  Btn := TButton.Create(Self);
  Btn.Parent := ButtonPanel;
  Btn.Left := 900;
  Btn.Top := 7;
  Btn.Width := 150;
  Btn.Height := 38;
  Btn.Caption := '주문 저장';
  Btn.Font.Style := [fsBold];
  Btn.OnClick := SaveClick;

  RefreshCart;
end;

procedure TfrmSales.SetStoreID(AStoreID: Integer);
begin
  FStoreID := AStoreID;
  LoadTables;
  LoadCategories;
end;

procedure TfrmSales.LoadTables;
var
  Q: TFDQuery;
begin
  FTableCombo.Items.Clear;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmDatabase.Connection;
    Q.SQL.Text := 'SELECT TABLE_ID, TABLE_NAME FROM POS_TABLE ' +
      'WHERE STORE_ID=:STORE_ID AND ACTIVE_YN=''Y'' ORDER BY DISPLAY_ORDER, TABLE_ID';
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.Open;
    while not Q.Eof do
    begin
      FTableCombo.Items.AddObject(Q.FieldByName('TABLE_NAME').AsString,
        TObject(NativeInt(Q.FieldByName('TABLE_ID').AsInteger)));
      Q.Next;
    end;
  finally
    Q.Free;
  end;
  if FTableCombo.Items.Count > 0 then
    FTableCombo.ItemIndex := 0;
end;

procedure TfrmSales.LoadCategories;
var
  Q: TFDQuery;
  Btn: TButton;
  X: Integer;
begin
  while FCategoryPanel.ControlCount > 0 do
    FCategoryPanel.Controls[0].Free;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmDatabase.Connection;
    Q.SQL.Text := 'SELECT CATEGORY_ID, CATEGORY_NAME FROM MENU_CATEGORY ' +
      'WHERE STORE_ID=:STORE_ID AND ACTIVE_YN=''Y'' ORDER BY DISPLAY_ORDER, CATEGORY_ID';
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.Open;
    X := 8;
    while not Q.Eof do
    begin
      Btn := TButton.Create(FCategoryPanel);
      Btn.Parent := FCategoryPanel;
      Btn.Left := X;
      Btn.Top := 8;
      Btn.Width := 130;
      Btn.Height := 38;
      Btn.Caption := Q.FieldByName('CATEGORY_NAME').AsString;
      Btn.Tag := Q.FieldByName('CATEGORY_ID').AsInteger;
      Btn.OnClick := CategoryClick;
      X := X + 138;
      Q.Next;
    end;
    if not Q.IsEmpty then
    begin
      Q.First;
      LoadMenus(Q.FieldByName('CATEGORY_ID').AsInteger);
    end;
  finally
    Q.Free;
  end;
end;

procedure TfrmSales.CategoryClick(Sender: TObject);
begin
  LoadMenus(TButton(Sender).Tag);
end;

procedure TfrmSales.LoadMenus(ACategoryID: Integer);
var
  Q: TFDQuery;
  Btn: TButton;
  X, Y: Integer;
begin
  while FMenuPanel.ControlCount > 0 do
    FMenuPanel.Controls[0].Free;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmDatabase.Connection;
    Q.SQL.Text := 'SELECT MENU_ID, MENU_NAME, PRICE FROM MENU_ITEM ' +
      'WHERE STORE_ID=:STORE_ID AND CATEGORY_ID=:CATEGORY_ID AND ACTIVE_YN=''Y'' ' +
      'ORDER BY DISPLAY_ORDER, MENU_ID';
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.ParamByName('CATEGORY_ID').AsInteger := ACategoryID;
    Q.Open;
    X := 12;
    Y := 12;
    while not Q.Eof do
    begin
      Btn := TButton.Create(FMenuPanel);
      Btn.Parent := FMenuPanel;
      Btn.Left := X;
      Btn.Top := Y;
      Btn.Width := 180;
      Btn.Height := 88;
      Btn.Tag := Q.FieldByName('MENU_ID').AsInteger;
      Btn.Caption := Q.FieldByName('MENU_NAME').AsString + sLineBreak +
        FormatCurr('#,##0', Q.FieldByName('PRICE').AsCurrency) + '원';
      Btn.OnClick := AddMenuClick;
      X := X + 192;
      if X + 180 > FMenuPanel.ClientWidth then
      begin
        X := 12;
        Y := Y + 98;
      end;
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

procedure TfrmSales.AddMenuClick(Sender: TObject);
var
  MenuID: Integer;
  Q: TFDQuery;
begin
  MenuID := TButton(Sender).Tag;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmDatabase.Connection;
    Q.SQL.Text := 'SELECT MENU_NAME, PRICE FROM MENU_ITEM ' +
      'WHERE STORE_ID=:STORE_ID AND MENU_ID=:MENU_ID AND ACTIVE_YN=''Y''';
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.ParamByName('MENU_ID').AsInteger := MenuID;
    Q.Open;
    if not Q.IsEmpty then
      AddCartItem(MenuID, Q.FieldByName('MENU_NAME').AsString,
        Q.FieldByName('PRICE').AsCurrency);
  finally
    Q.Free;
  end;
end;

procedure TfrmSales.AddCartItem(AMenuID: Integer; const AMenuName: string;
  APrice: Currency);
var
  I, N: Integer;
begin
  for I := 0 to High(FCart) do
    if FCart[I].MenuID = AMenuID then
    begin
      Inc(FCart[I].Quantity);
      RefreshCart;
      Exit;
    end;
  N := Length(FCart);
  SetLength(FCart, N + 1);
  FCart[N].MenuID := AMenuID;
  FCart[N].MenuName := AMenuName;
  FCart[N].UnitPrice := APrice;
  FCart[N].Quantity := 1;
  RefreshCart;
end;

function TfrmSales.CartTotal: Currency;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to High(FCart) do
    Result := Result + FCart[I].UnitPrice * FCart[I].Quantity;
end;

procedure TfrmSales.RefreshCart;
var
  I: Integer;
begin
  FCartGrid.RowCount := Max(2, Length(FCart) + 1);
  for I := 0 to High(FCart) do
  begin
    FCartGrid.Cells[0, I + 1] := FCart[I].MenuName;
    FCartGrid.Cells[1, I + 1] := FormatCurr('#,##0', FCart[I].UnitPrice);
    FCartGrid.Cells[2, I + 1] := IntToStr(FCart[I].Quantity);
    FCartGrid.Cells[3, I + 1] := FormatCurr('#,##0',
      FCart[I].UnitPrice * FCart[I].Quantity);
  end;
  if Length(FCart) = 0 then
  begin
    FCartGrid.Cells[0, 1] := '';
    FCartGrid.Cells[1, 1] := '';
    FCartGrid.Cells[2, 1] := '';
    FCartGrid.Cells[3, 1] := '';
  end;
  FTotalLabel.Caption := '합계: ' + FormatCurr('#,##0', CartTotal) + '원';
end;

procedure TfrmSales.ChangeQuantity(ADelta: Integer);
var
  RowIndex, CartIndex, I: Integer;
begin
  RowIndex := FCartGrid.Row;
  CartIndex := RowIndex - 1;
  if (CartIndex < 0) or (CartIndex > High(FCart)) then Exit;
  Inc(FCart[CartIndex].Quantity, ADelta);
  if FCart[CartIndex].Quantity <= 0 then
  begin
    for I := CartIndex to High(FCart) - 1 do
      FCart[I] := FCart[I + 1];
    SetLength(FCart, Length(FCart) - 1);
  end;
  RefreshCart;
end;

procedure TfrmSales.RemoveSelected;
var
  CartIndex, I: Integer;
begin
  CartIndex := FCartGrid.Row - 1;
  if (CartIndex < 0) or (CartIndex > High(FCart)) then Exit;
  for I := CartIndex to High(FCart) - 1 do
    FCart[I] := FCart[I + 1];
  SetLength(FCart, Length(FCart) - 1);
  RefreshCart;
end;

function TfrmSales.SelectedTableID: Integer;
begin
  Result := 0;
  if FTableCombo.ItemIndex >= 0 then
    Result := NativeInt(FTableCombo.Items.Objects[FTableCombo.ItemIndex]);
end;

function TfrmSales.NextSequenceValue(const ASequenceName: string): Int64;
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

procedure TfrmSales.QuantityPlusClick(Sender: TObject);
begin
  ChangeQuantity(1);
end;

procedure TfrmSales.QuantityMinusClick(Sender: TObject);
begin
  ChangeQuantity(-1);
end;

procedure TfrmSales.RemoveClick(Sender: TObject);
begin
  RemoveSelected;
end;

procedure TfrmSales.SaveClick(Sender: TObject);
begin
  try
    SaveOrder;
  except
    on E: Exception do
      MessageDlg('주문 저장에 실패했습니다: ' + E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TfrmSales.SaveOrder;
var
  OrderID, OrderItemID: Int64;
  OrderNo: string;
  Q: TFDQuery;
  I: Integer;
  Total: Currency;
begin
  if SelectedTableID = 0 then
    raise Exception.Create('먼저 테이블을 선택해 주세요.');
  if Length(FCart) = 0 then
    raise Exception.Create('주문할 메뉴를 선택해 주세요.');

  Total := CartTotal;
  OrderID := 0;
  dmDatabase.Connection.StartTransaction;
  try
    OrderID := NextSequenceValue('GEN_POS_ORDER_ID');
    OrderNo := FormatDateTime('yyyymmddhhnnss', Now) + '-' +
      FormatFloat('000000', OrderID);

    Q := TFDQuery.Create(nil);
    try
      Q.Connection := dmDatabase.Connection;
      Q.SQL.Text := 'INSERT INTO POS_ORDER ' +
        '(ORDER_ID, STORE_ID, TABLE_ID, ORDER_NO, ORDER_TYPE, ORDER_STATUS, TOTAL_AMOUNT) ' +
        'VALUES (:ORDER_ID, :STORE_ID, :TABLE_ID, :ORDER_NO, ''DINE_IN'', ''OPEN'', :TOTAL)';
      Q.ParamByName('ORDER_ID').AsLargeInt := OrderID;
      Q.ParamByName('STORE_ID').AsInteger := FStoreID;
      Q.ParamByName('TABLE_ID').AsInteger := SelectedTableID;
      Q.ParamByName('ORDER_NO').AsString := OrderNo;
      Q.ParamByName('TOTAL').AsCurrency := Total;
      Q.ExecSQL;

      for I := 0 to High(FCart) do
      begin
        OrderItemID := NextSequenceValue('GEN_POS_ORDER_ITEM_ID');
        Q.SQL.Text := 'INSERT INTO POS_ORDER_ITEM ' +
          '(ORDER_ITEM_ID, ORDER_ID, MENU_ID, MENU_NAME, UNIT_PRICE, QUANTITY, LINE_AMOUNT, OPTION_TEXT, OPTION_AMOUNT) ' +
          'VALUES (:ITEM_ID, :ORDER_ID, :MENU_ID, :MENU_NAME, :UNIT_PRICE, :QUANTITY, :LINE_AMOUNT, :OPTION_TEXT, :OPTION_AMOUNT)';
        Q.ParamByName('ITEM_ID').AsLargeInt := OrderItemID;
        Q.ParamByName('ORDER_ID').AsLargeInt := OrderID;
        Q.ParamByName('MENU_ID').AsInteger := FCart[I].MenuID;
        Q.ParamByName('MENU_NAME').AsString := FCart[I].MenuName;
        Q.ParamByName('UNIT_PRICE').AsCurrency := FCart[I].UnitPrice;
        Q.ParamByName('QUANTITY').AsInteger := FCart[I].Quantity;
        Q.ParamByName('LINE_AMOUNT').AsCurrency := FCart[I].UnitPrice * FCart[I].Quantity;
        Q.ParamByName('OPTION_TEXT').AsString := '';
        Q.ParamByName('OPTION_AMOUNT').AsCurrency := 0;
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

  SetLength(FCart, 0);
  RefreshCart;
  FStatusLabel.Caption := '주문이 저장되었습니다. 주문번호: ' + OrderNo;
  MessageDlg('주문이 정상적으로 저장되었습니다.' + sLineBreak +
    '주문번호: ' + OrderNo, mtInformation, [mbOK], 0);
end;

end.
