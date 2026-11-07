unit uSalesForm;

interface

uses
  System.SysUtils, System.Classes, System.UITypes, System.Math, System.StrUtils, Data.DB,
  FireDAC.Comp.Client, Vcl.Forms, Vcl.Controls, Vcl.Graphics, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Grids, Vcl.Dialogs, Vcl.CheckLst;

type
  TCartItem = record
    MenuID: Integer;
    MenuName: string;
    UnitPrice: Currency;
    Quantity: Integer;
    OptionText: string;
    OptionAmount: Currency;
  end;

  TOptionGroupControls = record
    GroupName: string;
    Required: Boolean;
    MaxSelect: Integer;
    List: TCheckListBox;
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
  FPaymentButton: TButton;
    procedure LoadTables;
    procedure LoadCategories;
    procedure LoadMenus(ACategoryID: Integer);
    procedure AddMenuClick(Sender: TObject);
    procedure CategoryClick(Sender: TObject);
    procedure RefreshCart;
    procedure ChangeQuantity(ADelta: Integer);
    procedure RemoveSelected;
    procedure SaveOrder;
    procedure PaymentClick(Sender: TObject);
    procedure ProcessPayment;
    procedure QuantityPlusClick(Sender: TObject);
    procedure QuantityMinusClick(Sender: TObject);
    procedure RemoveClick(Sender: TObject);
    procedure SaveClick(Sender: TObject);
    procedure TableChanged(Sender: TObject);
    procedure UpdateTableStatus;
    function SelectedTableID: Integer;
    function NextSequenceValue(const ASequenceName: string): Int64;
    function CartTotal: Currency;
    procedure AddCartItem(AMenuID: Integer; const AMenuName: string;
      APrice, AOptionAmount: Currency; const AOptionText: string);
    function SelectMenuOptions(AMenuID: Integer; out AOptionText: string;
      out AOptionAmount: Currency): Boolean;
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
  FTableCombo.OnChange := TableChanged;

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

  FPaymentButton := TButton.Create(Self);
  FPaymentButton.Parent := ButtonPanel;
  FPaymentButton.Left := 1060;
  FPaymentButton.Top := 7;
  FPaymentButton.Width := 100;
  FPaymentButton.Height := 38;
  FPaymentButton.Caption := '결제';
  FPaymentButton.Font.Style := [fsBold];
  FPaymentButton.OnClick := PaymentClick;

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
        TObject(Pointer(NativeInt(Q.FieldByName('TABLE_ID').AsInteger))));
      Q.Next;
    end;
  finally
    Q.Free;
  end;
  if FTableCombo.Items.Count > 0 then
    FTableCombo.ItemIndex := 0;
  UpdateTableStatus;
end;

procedure TfrmSales.TableChanged(Sender: TObject);
begin
  UpdateTableStatus;
end;

procedure TfrmSales.UpdateTableStatus;
var
  Q: TFDQuery;
  TableName: string;
begin
  if FTableCombo.ItemIndex < 0 then
  begin
    FStatusLabel.Caption := '등록된 테이블이 없습니다.';
    Exit;
  end;

  TableName := FTableCombo.Items[FTableCombo.ItemIndex];
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmDatabase.Connection;
    Q.SQL.Text := 'SELECT FIRST 1 ORDER_NO, TOTAL_AMOUNT FROM POS_ORDER ' +
      'WHERE STORE_ID=:STORE_ID AND TABLE_ID=:TABLE_ID ' +
      'AND ORDER_TYPE=''DINE_IN'' AND ORDER_STATUS=''OPEN'' ' +
      'ORDER BY ORDERED_AT DESC';
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.ParamByName('TABLE_ID').AsInteger := SelectedTableID;
    Q.Open;
    if not Q.IsEmpty then
      FStatusLabel.Caption := TableName + ' - 진행 중 주문 ' +
        FormatCurr('#,##0', Q.FieldByName('TOTAL_AMOUNT').AsCurrency) + '원 (추가 주문 가능)'
    else
      FStatusLabel.Caption := TableName + ' - 신규 주문';
  finally
    Q.Free;
  end;
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
  OptionText: string;
  OptionAmount: Currency;
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
    begin
      if not SelectMenuOptions(MenuID, OptionText, OptionAmount) then Exit;
      AddCartItem(MenuID, Q.FieldByName('MENU_NAME').AsString,
        Q.FieldByName('PRICE').AsCurrency, OptionAmount, OptionText);
    end;
  finally
    Q.Free;
  end;
end;

function TfrmSales.SelectMenuOptions(AMenuID: Integer;
  out AOptionText: string; out AOptionAmount: Currency): Boolean;
var
  DialogForm: TForm;
  Scroll: TScrollBox;
  GroupQuery, OptionQuery, PriceQuery: TFDQuery;
  Groups: array of TOptionGroupControls;
  GroupCount, I, J, SelectedCount, OptionID: Integer;
  GroupLabel: TLabel;
  OkButton, CancelButton: TButton;
  OptionName: string;
  GroupTop: Integer;
begin
  Result := True;
  AOptionText := '';
  AOptionAmount := 0;
  GroupQuery := TFDQuery.Create(nil);
  OptionQuery := TFDQuery.Create(nil);
  PriceQuery := TFDQuery.Create(nil);
  DialogForm := TForm.Create(nil);
  try
    GroupQuery.Connection := dmDatabase.Connection;
    GroupQuery.SQL.Text :=
      'SELECT G.OPTION_GROUP_ID, G.GROUP_NAME, G.REQUIRED_YN, G.MAX_SELECT ' +
      'FROM MENU_ITEM_OPTION_GROUP MG ' +
      'JOIN MENU_OPTION_GROUP G ON G.OPTION_GROUP_ID=MG.OPTION_GROUP_ID ' +
      'WHERE MG.MENU_ID=:MENU_ID AND G.STORE_ID=:STORE_ID ' +
      'AND G.ACTIVE_YN=''Y'' ORDER BY MG.DISPLAY_ORDER, G.DISPLAY_ORDER';
    GroupQuery.ParamByName('MENU_ID').AsInteger := AMenuID;
    GroupQuery.ParamByName('STORE_ID').AsInteger := FStoreID;
    GroupQuery.Open;
    if GroupQuery.IsEmpty then Exit;

    DialogForm.Caption := '메뉴 옵션 선택';
    DialogForm.Font.Name := Font.Name;
    DialogForm.Position := poScreenCenter;
    DialogForm.BorderStyle := bsDialog;
    DialogForm.Width := 440;
    DialogForm.Height := 560;

    Scroll := TScrollBox.Create(DialogForm);
    Scroll.Parent := DialogForm;
    Scroll.Align := alClient;

    GroupCount := 0;
    GroupTop := 8;
    OptionQuery.Connection := dmDatabase.Connection;
    while not GroupQuery.Eof do
    begin
      SetLength(Groups, GroupCount + 1);
      Groups[GroupCount].GroupName := GroupQuery.FieldByName('GROUP_NAME').AsString;
      Groups[GroupCount].Required := SameText(
        GroupQuery.FieldByName('REQUIRED_YN').AsString, 'Y');
      Groups[GroupCount].MaxSelect := GroupQuery.FieldByName('MAX_SELECT').AsInteger;

      GroupLabel := TLabel.Create(DialogForm);
      GroupLabel.Parent := Scroll;
      GroupLabel.Left := 12;
      GroupLabel.Top := GroupTop;
      GroupLabel.Caption := Groups[GroupCount].GroupName;
      GroupLabel.Font.Style := [fsBold];
      GroupTop := GroupTop + 24;

      Groups[GroupCount].List := TCheckListBox.Create(DialogForm);
      Groups[GroupCount].List.Parent := Scroll;
      Groups[GroupCount].List.Left := 12;
      Groups[GroupCount].List.Top := GroupTop;
      Groups[GroupCount].List.Width := 390;
      Groups[GroupCount].List.Height := 24;
      Groups[GroupCount].List.IntegralHeight := True;
      OptionQuery.Close;
      OptionQuery.SQL.Text :=
        'SELECT OPTION_ID, OPTION_NAME FROM MENU_OPTION ' +
        'WHERE OPTION_GROUP_ID=:GROUP_ID AND ACTIVE_YN=''Y'' ' +
        'ORDER BY DISPLAY_ORDER, OPTION_ID';
      OptionQuery.ParamByName('GROUP_ID').AsInteger :=
        GroupQuery.FieldByName('OPTION_GROUP_ID').AsInteger;
      OptionQuery.Open;
      while not OptionQuery.Eof do
      begin
        Groups[GroupCount].List.Items.AddObject(
          OptionQuery.FieldByName('OPTION_NAME').AsString,
          TObject(Pointer(NativeInt(OptionQuery.FieldByName('OPTION_ID').AsInteger))));
        OptionQuery.Next;
      end;
      Groups[GroupCount].List.Height := Max(28,
        Groups[GroupCount].List.Items.Count * 20 + 4);
      GroupTop := GroupTop + Groups[GroupCount].List.Height + 12;
      Inc(GroupCount);
      GroupQuery.Next;
    end;
    Scroll.VertScrollBar.Range := GroupTop;

    OkButton := TButton.Create(DialogForm);
    OkButton.Parent := DialogForm;
    OkButton.Caption := '선택 완료';
    OkButton.ModalResult := mrOk;
    OkButton.Default := True;
    OkButton.Left := 210;
    OkButton.Top := 480;
    OkButton.Width := 95;

    CancelButton := TButton.Create(DialogForm);
    CancelButton.Parent := DialogForm;
    CancelButton.Caption := '취소';
    CancelButton.ModalResult := mrCancel;
    CancelButton.Cancel := True;
    CancelButton.Left := 315;
    CancelButton.Top := 480;
    CancelButton.Width := 85;

    if DialogForm.ShowModal <> mrOk then
    begin
      Result := False;
      Exit;
    end;

    PriceQuery.Connection := dmDatabase.Connection;
    for I := 0 to GroupCount - 1 do
    begin
      SelectedCount := 0;
      for J := 0 to Groups[I].List.Items.Count - 1 do
        if Groups[I].List.Checked[J] then Inc(SelectedCount);
      if Groups[I].Required and (SelectedCount = 0) then
      begin
        MessageDlg(Groups[I].GroupName + ' 옵션을 선택해 주세요.',
          mtWarning, [mbOK], 0);
        Result := False;
        Exit;
      end;
      if (Groups[I].MaxSelect > 0) and
        (SelectedCount > Groups[I].MaxSelect) then
      begin
        MessageDlg(Groups[I].GroupName + ' 옵션은 최대 ' +
          IntToStr(Groups[I].MaxSelect) + '개까지 선택할 수 있습니다.',
          mtWarning, [mbOK], 0);
        Result := False;
        Exit;
      end;
      for J := 0 to Groups[I].List.Items.Count - 1 do
        if Groups[I].List.Checked[J] then
        begin
          OptionID := NativeInt(Pointer(Groups[I].List.Items.Objects[J]));
          OptionName := Groups[I].List.Items[J];
          PriceQuery.Close;
          PriceQuery.SQL.Text :=
            'SELECT ADD_PRICE FROM MENU_OPTION WHERE OPTION_ID=:OPTION_ID';
          PriceQuery.ParamByName('OPTION_ID').AsInteger := OptionID;
          PriceQuery.Open;
          AOptionAmount := AOptionAmount + PriceQuery.Fields[0].AsCurrency;
          if AOptionText <> '' then AOptionText := AOptionText + ', ';
          AOptionText := AOptionText + Groups[I].GroupName + ':' + OptionName;
        end;
    end;
  finally
    DialogForm.Free;
    PriceQuery.Free;
    OptionQuery.Free;
    GroupQuery.Free;
  end;
end;

procedure TfrmSales.AddCartItem(AMenuID: Integer; const AMenuName: string;
  APrice, AOptionAmount: Currency; const AOptionText: string);
var
  I, N: Integer;
begin
  for I := 0 to High(FCart) do
    if (FCart[I].MenuID = AMenuID) and
      SameText(FCart[I].OptionText, AOptionText) then
    begin
      Inc(FCart[I].Quantity);
      RefreshCart;
      Exit;
    end;
  N := Length(FCart);
  SetLength(FCart, N + 1);
  FCart[N].MenuID := AMenuID;
  FCart[N].MenuName := AMenuName;
  FCart[N].UnitPrice := APrice + AOptionAmount;
  FCart[N].Quantity := 1;
  FCart[N].OptionText := AOptionText;
  FCart[N].OptionAmount := AOptionAmount;
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
    if FCart[I].OptionText <> '' then
      FCartGrid.Cells[0, I + 1] := FCartGrid.Cells[0, I + 1] +
        ' [' + FCart[I].OptionText + ']';
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
    Result := NativeInt(Pointer(FTableCombo.Items.Objects[FTableCombo.ItemIndex]));
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

procedure TfrmSales.PaymentClick(Sender: TObject);
begin
  try
    ProcessPayment;
  except
    on E: Exception do
      MessageDlg('결제 처리에 실패했습니다: ' + E.Message,
        mtError, [mbOK], 0);
  end;
end;

procedure TfrmSales.ProcessPayment;
var
  OrderID: Int64;
  OrderNo: string;
  OrderTotal, PaidAmount, RemainingAmount, ReceivedAmount: Currency;
  PaymentID: Int64;
  Q: TFDQuery;
  DialogForm: TForm;
  MethodGroup: TRadioGroup;
  AmountLabel, ReceivedLabel, ChangeLabel: TLabel;
  ReceivedEdit: TEdit;
  OkButton, CancelButton: TButton;
  MethodCode: string;
begin
  if SelectedTableID = 0 then
    raise Exception.Create('먼저 테이블을 선택해 주세요.');
  if Length(FCart) > 0 then
    raise Exception.Create('장바구니에 저장하지 않은 메뉴가 있습니다. 먼저 주문 저장을 해주세요.');

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmDatabase.Connection;
    Q.SQL.Text := 'SELECT FIRST 1 ORDER_ID, ORDER_NO, TOTAL_AMOUNT ' +
      'FROM POS_ORDER WHERE STORE_ID=:STORE_ID AND TABLE_ID=:TABLE_ID ' +
      'AND ORDER_TYPE=''DINE_IN'' AND ORDER_STATUS=''OPEN'' ' +
      'ORDER BY ORDERED_AT DESC';
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.ParamByName('TABLE_ID').AsInteger := SelectedTableID;
    Q.Open;
    if Q.IsEmpty then
      raise Exception.Create('선택한 테이블에 결제할 진행 중 주문이 없습니다.');
    OrderID := Q.FieldByName('ORDER_ID').AsLargeInt;
    OrderNo := Q.FieldByName('ORDER_NO').AsString;
    OrderTotal := Q.FieldByName('TOTAL_AMOUNT').AsCurrency;
    Q.Close;

    Q.SQL.Text := 'SELECT COALESCE(SUM(PAYMENT_AMOUNT), 0) FROM POS_PAYMENT ' +
      'WHERE ORDER_ID=:ORDER_ID';
    Q.ParamByName('ORDER_ID').AsLargeInt := OrderID;
    Q.Open;
    PaidAmount := Q.Fields[0].AsCurrency;
    Q.Close;
  finally
    Q.Free;
  end;

  RemainingAmount := OrderTotal - PaidAmount;
  if RemainingAmount <= 0 then
    raise Exception.Create('이미 결제가 완료된 주문입니다.');

  DialogForm := TForm.Create(nil);
  try
    DialogForm.Caption := '주문 결제';
    DialogForm.Font.Name := Font.Name;
    DialogForm.Position := poScreenCenter;
    DialogForm.BorderStyle := bsDialog;
    DialogForm.Width := 390;
    DialogForm.Height := 300;

    AmountLabel := TLabel.Create(DialogForm);
    AmountLabel.Parent := DialogForm;
    AmountLabel.Left := 24;
    AmountLabel.Top := 18;
    AmountLabel.Caption := '결제할 금액: ' + FormatCurr('#,##0', RemainingAmount) + '원';
    AmountLabel.Font.Size := 14;
    AmountLabel.Font.Style := [fsBold];

    MethodGroup := TRadioGroup.Create(DialogForm);
    MethodGroup.Parent := DialogForm;
    MethodGroup.Left := 24;
    MethodGroup.Top := 55;
    MethodGroup.Width := 330;
    MethodGroup.Height := 70;
    MethodGroup.Caption := '결제 수단';
    MethodGroup.Items.Add('현금');
    MethodGroup.Items.Add('카드');
    MethodGroup.ItemIndex := 0;

    ReceivedLabel := TLabel.Create(DialogForm);
    ReceivedLabel.Parent := DialogForm;
    ReceivedLabel.Left := 24;
    ReceivedLabel.Top := 142;
    ReceivedLabel.Caption := '받은 현금';

    ReceivedEdit := TEdit.Create(DialogForm);
    ReceivedEdit.Parent := DialogForm;
    ReceivedEdit.Left := 110;
    ReceivedEdit.Top := 137;
    ReceivedEdit.Width := 180;
    ReceivedEdit.Text := FormatCurr('0', RemainingAmount);

    ChangeLabel := TLabel.Create(DialogForm);
    ChangeLabel.Parent := DialogForm;
    ChangeLabel.Left := 24;
    ChangeLabel.Top := 174;
    ChangeLabel.Caption := '현금 선택 시 받은 금액을 입력하세요.';

    OkButton := TButton.Create(DialogForm);
    OkButton.Parent := DialogForm;
    OkButton.Left := 160;
    OkButton.Top := 215;
    OkButton.Width := 90;
    OkButton.Caption := '결제 완료';
    OkButton.ModalResult := mrOk;
    OkButton.Default := True;

    CancelButton := TButton.Create(DialogForm);
    CancelButton.Parent := DialogForm;
    CancelButton.Left := 260;
    CancelButton.Top := 215;
    CancelButton.Width := 90;
    CancelButton.Caption := '취소';
    CancelButton.ModalResult := mrCancel;
    CancelButton.Cancel := True;

    if DialogForm.ShowModal <> mrOk then Exit;
    if MethodGroup.ItemIndex = 0 then
    begin
      MethodCode := 'CASH';
      if not TryStrToCurr(Trim(ReceivedEdit.Text), ReceivedAmount) then
        raise Exception.Create('받은 현금 금액을 올바르게 입력해 주세요.');
      if ReceivedAmount < RemainingAmount then
        raise Exception.Create('받은 현금이 결제 금액보다 적습니다.');
    end
    else
    begin
      MethodCode := 'CARD';
      ReceivedAmount := RemainingAmount;
    end;
  finally
    DialogForm.Free;
  end;

  dmDatabase.Connection.StartTransaction;
  try
    Q := TFDQuery.Create(nil);
    try
      Q.Connection := dmDatabase.Connection;
      Q.SQL.Text := 'SELECT ORDER_STATUS, TOTAL_AMOUNT FROM POS_ORDER ' +
        'WHERE STORE_ID=:STORE_ID AND ORDER_ID=:ORDER_ID WITH LOCK';
      Q.ParamByName('STORE_ID').AsInteger := FStoreID;
      Q.ParamByName('ORDER_ID').AsLargeInt := OrderID;
      Q.Open;
      if Q.IsEmpty or (Q.FieldByName('ORDER_STATUS').AsString <> 'OPEN') then
        raise Exception.Create('주문 상태가 변경되었습니다. 주문을 다시 확인해 주세요.');
      OrderTotal := Q.FieldByName('TOTAL_AMOUNT').AsCurrency;
      Q.Close;

      Q.SQL.Text := 'SELECT COALESCE(SUM(PAYMENT_AMOUNT), 0) FROM POS_PAYMENT ' +
        'WHERE ORDER_ID=:ORDER_ID';
      Q.ParamByName('ORDER_ID').AsLargeInt := OrderID;
      Q.Open;
      PaidAmount := Q.Fields[0].AsCurrency;
      Q.Close;
      RemainingAmount := OrderTotal - PaidAmount;
      if RemainingAmount <= 0 then
        raise Exception.Create('이미 결제가 완료된 주문입니다.');
      if (MethodCode = 'CASH') and (ReceivedAmount < RemainingAmount) then
        raise Exception.Create('주문 금액이 변경되었습니다. 받은 현금이 결제 금액보다 적습니다. 다시 결제해 주세요.');

      PaymentID := NextSequenceValue('GEN_POS_PAYMENT_ID');
      Q.SQL.Text := 'INSERT INTO POS_PAYMENT ' +
        '(PAYMENT_ID, ORDER_ID, PAYMENT_METHOD, PAYMENT_AMOUNT) ' +
        'VALUES (:ID, :ORDER_ID, :METHOD, :AMOUNT)';
      Q.ParamByName('ID').AsLargeInt := PaymentID;
      Q.ParamByName('ORDER_ID').AsLargeInt := OrderID;
      Q.ParamByName('METHOD').AsString := MethodCode;
      Q.ParamByName('AMOUNT').AsCurrency := RemainingAmount;
      Q.ExecSQL;

      Q.SQL.Text := 'UPDATE POS_ORDER SET ORDER_STATUS=''PAID'' ' +
        'WHERE STORE_ID=:STORE_ID AND ORDER_ID=:ORDER_ID';
      Q.ParamByName('STORE_ID').AsInteger := FStoreID;
      Q.ParamByName('ORDER_ID').AsLargeInt := OrderID;
      Q.ExecSQL;
    finally
      Q.Free;
    end;
    dmDatabase.Connection.Commit;
  except
    dmDatabase.Connection.Rollback;
    raise;
  end;

  UpdateTableStatus;
  MessageDlg('결제가 완료되었습니다.' + sLineBreak +
    '주문번호: ' + OrderNo + sLineBreak +
    '결제수단: ' + IfThen(MethodCode = 'CASH', '현금', '카드') + sLineBreak +
    '결제금액: ' + FormatCurr('#,##0', RemainingAmount) + '원' +
    IfThen(MethodCode = 'CASH', sLineBreak + '거스름돈: ' +
      FormatCurr('#,##0', ReceivedAmount - RemainingAmount) + '원', ''),
    mtInformation, [mbOK], 0);
end;

procedure TfrmSales.SaveOrder;
var
  OrderID, OrderItemID: Int64;
  OrderNo: string;
  Q: TFDQuery;
  I: Integer;
  Total, ExistingTotal: Currency;
  IsExistingOrder: Boolean;
begin
  if SelectedTableID = 0 then
    raise Exception.Create('먼저 테이블을 선택해 주세요.');
  if Length(FCart) = 0 then
    raise Exception.Create('주문할 메뉴를 선택해 주세요.');

  Total := CartTotal;
  ExistingTotal := 0;
  IsExistingOrder := False;
  OrderID := 0;
  dmDatabase.Connection.StartTransaction;
  try
    Q := TFDQuery.Create(nil);
    try
      Q.Connection := dmDatabase.Connection;
      Q.SQL.Text := 'SELECT FIRST 1 ORDER_ID, ORDER_NO, TOTAL_AMOUNT FROM POS_ORDER ' +
        'WHERE STORE_ID=:STORE_ID AND TABLE_ID=:TABLE_ID ' +
        'AND ORDER_TYPE=''DINE_IN'' AND ORDER_STATUS=''OPEN'' ' +
        'ORDER BY ORDERED_AT DESC';
      Q.ParamByName('STORE_ID').AsInteger := FStoreID;
      Q.ParamByName('TABLE_ID').AsInteger := SelectedTableID;
      Q.Open;
      if not Q.IsEmpty then
      begin
        IsExistingOrder := True;
        OrderID := Q.FieldByName('ORDER_ID').AsLargeInt;
        OrderNo := Q.FieldByName('ORDER_NO').AsString;
        ExistingTotal := Q.FieldByName('TOTAL_AMOUNT').AsCurrency;
      end;
      Q.Close;

      if not IsExistingOrder then
      begin
        OrderID := NextSequenceValue('GEN_POS_ORDER_ID');
        OrderNo := FormatDateTime('yyyymmddhhnnss', Now) + '-' +
          FormatFloat('000000', OrderID);
        Q.SQL.Text := 'INSERT INTO POS_ORDER ' +
          '(ORDER_ID, STORE_ID, TABLE_ID, ORDER_NO, ORDER_TYPE, ORDER_STATUS, TOTAL_AMOUNT) ' +
          'VALUES (:ORDER_ID, :STORE_ID, :TABLE_ID, :ORDER_NO, ''DINE_IN'', ''OPEN'', :TOTAL)';
        Q.ParamByName('ORDER_ID').AsLargeInt := OrderID;
        Q.ParamByName('STORE_ID').AsInteger := FStoreID;
        Q.ParamByName('TABLE_ID').AsInteger := SelectedTableID;
        Q.ParamByName('ORDER_NO').AsString := OrderNo;
        Q.ParamByName('TOTAL').AsCurrency := Total;
        Q.ExecSQL;
      end;

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
        Q.ParamByName('OPTION_TEXT').AsString := FCart[I].OptionText;
        Q.ParamByName('OPTION_AMOUNT').AsCurrency := FCart[I].OptionAmount;
        Q.ExecSQL;
      end;

      if IsExistingOrder then
      begin
        Q.SQL.Text := 'UPDATE POS_ORDER SET TOTAL_AMOUNT=:TOTAL ' +
          'WHERE STORE_ID=:STORE_ID AND ORDER_ID=:ORDER_ID';
        Q.ParamByName('TOTAL').AsCurrency := ExistingTotal + Total;
        Q.ParamByName('STORE_ID').AsInteger := FStoreID;
        Q.ParamByName('ORDER_ID').AsLargeInt := OrderID;
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
  UpdateTableStatus;
  if IsExistingOrder then
    FStatusLabel.Caption := '기존 주문에 추가 저장되었습니다. 주문번호: ' + OrderNo;
  MessageDlg('주문이 정상적으로 저장되었습니다.' + sLineBreak +
    '주문번호: ' + OrderNo + sLineBreak +
    '추가 금액: ' + FormatCurr('#,##0', Total) + '원' + sLineBreak +
    '테이블 주문 합계: ' + FormatCurr('#,##0', ExistingTotal + Total) + '원',
    mtInformation, [mbOK], 0);
end;

end.
