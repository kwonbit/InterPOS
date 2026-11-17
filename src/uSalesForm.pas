unit uSalesForm;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.UITypes, System.Math, System.StrUtils, System.DateUtils, Data.DB,
  FireDAC.Comp.Client, FireDAC.Stan.Param, Vcl.Forms, Vcl.Controls, Vcl.Graphics, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Grids, Vcl.Dialogs, Vcl.CheckLst;

type
  TIntegerArray = array of Integer;

  TCartItem = record
    MenuID: Integer;
    MenuName: string;
    UnitPrice: Currency;
    Quantity: Integer;
    OptionText: string;
    OptionAmount: Currency;
    OrderItemID: Int64;
    IsPersisted: Boolean;
    OriginalQuantity: Integer;
  end;

  TCartItemArray = array of TCartItem;

  TOptionGroupControls = record
    GroupName: string;
    Required: Boolean;
    MaxSelect: Integer;
    List: TCheckListBox;
    OptionIDs: TIntegerArray;
  end;

  TfrmSales = class(TForm)
  published
    procedure FormCreate(Sender: TObject);
  private
    FStoreID: Integer;
    FTerminalID: Integer;
    FEmployeeID: Integer;
    FCart: TCartItemArray;
    FCartGroups: array of TIntegerArray;
    FTableCombo: TComboBox;
    FTableIDs: TIntegerArray;
    FTableNameLabel: TLabel;
    FCustomerCountEdit: TEdit;
    FOrdererEdit: TEdit;
    FTablePanel: TPanel;
    FSalesPanel: TPanel;
    FTableCards: TScrollBox;
    FShowTableMenus: Boolean;
    FLoadedOrderID: Int64;
    FLoadedOrderItemIDs: array of Int64;
    FCategoryPanel: TScrollBox;
    FMenuPanel: TScrollBox;
    FCartGrid: TStringGrid;
    FLoadOrderButton: TButton;
    FTotalLabel: TLabel;
    FStatusLabel: TLabel;
    FPaymentButton: TButton;
    procedure DrawCartCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
    procedure LoadTables;
    procedure TableCardClick(Sender: TObject);
    procedure LoadExistingOrderClick(Sender: TObject);
    procedure TableDisplayToggleClick(Sender: TObject);
    procedure BackToTablesClick(Sender: TObject);
    procedure LoadCategories;
    procedure LoadMenus(ACategoryID: Integer);
    procedure AddMenuClick(Sender: TObject);
    procedure CategoryClick(Sender: TObject);
    procedure RefreshCart;
    procedure ChangeQuantity(ADelta: Integer);
    procedure RemoveSelected;
    procedure SaveOrder;
    procedure PaymentClick(Sender: TObject);
    procedure ConfigurePrinterClick(Sender: TObject);
    procedure ReprintReceiptClick(Sender: TObject);
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
    procedure SetContext(AStoreID, ATerminalID, AEmployeeID: Integer);
  end;

implementation

uses
  uDatabase, uReceiptPrinter, uKitchenPrinter, uCashDrawer;

{$R *.dfm}

procedure TfrmSales.FormCreate(Sender: TObject);
var
  Header, MainPanel, MenuArea, CartPanel, CartHeader, ButtonPanel: TPanel;
  TableHeader: TPanel;
  Lbl, TableTitle: TLabel;
  CustomerCountLabel, OrdererLabel: TLabel;
  Btn, PrinterBtn, ReprintBtn, BackBtn, TableDisplayBtn: TButton;
begin
  Caption := 'POS 판매';
  Font.Name := '맑은 고딕';
  Font.Size := 10;
  Width := 1280;
  Height := 800;
  Constraints.MinWidth := 1080;
  Constraints.MinHeight := 680;
  Position := poScreenCenter;
  Color := $00F1F3F5;
  FShowTableMenus := False;
  FLoadedOrderID := 0;

  { 후불제 매장의 첫 화면은 테이블 현황 화면이다. }
  FTablePanel := TPanel.Create(Self);
  FTablePanel.Parent := Self;
  FTablePanel.Align := alClient;
  FTablePanel.BevelOuter := bvNone;
  FTablePanel.Color := $00F1F3F5;
  FTablePanel.ParentBackground := False;

  TableHeader := TPanel.Create(Self);
  TableHeader.Parent := FTablePanel;
  TableHeader.Align := alTop;
  TableHeader.Height := 76;
  TableHeader.BevelOuter := bvNone;
  TableHeader.Color := clWhite;
  TableHeader.ParentBackground := False;

  TableTitle := TLabel.Create(Self);
  TableTitle.Parent := TableHeader;
  TableTitle.Left := 22;
  TableTitle.Top := 13;
  TableTitle.Caption := '테이블 선택';
  TableTitle.Font.Name := Font.Name;
  TableTitle.Font.Size := 17;
  TableTitle.Font.Style := [fsBold];

  Lbl := TLabel.Create(Self);
  Lbl.Parent := TableHeader;
  Lbl.Left := 24;
  Lbl.Top := 44;
  Lbl.Caption := '테이블을 선택하면 주문 화면으로 이동합니다.';
  Lbl.Font.Name := Font.Name;
  Lbl.Font.Size := 9;
  Lbl.Font.Color := clGrayText;

  TableDisplayBtn := TButton.Create(Self);
  TableDisplayBtn.Parent := TableHeader;
  TableDisplayBtn.Left := 1040;
  TableDisplayBtn.Top := 18;
  TableDisplayBtn.Width := 150;
  TableDisplayBtn.Height := 40;
  TableDisplayBtn.Caption := '메뉴표기';
  TableDisplayBtn.Font.Name := Font.Name;
  TableDisplayBtn.OnClick := TableDisplayToggleClick;

  FTableCards := TScrollBox.Create(Self);
  FTableCards.Parent := FTablePanel;
  FTableCards.Align := alClient;
  FTableCards.BorderStyle := bsNone;
  FTableCards.Color := $00F1F3F5;
  FTableCards.HorzScrollBar.Visible := False;

  FSalesPanel := TPanel.Create(Self);
  FSalesPanel.Parent := Self;
  FSalesPanel.Align := alClient;
  FSalesPanel.BevelOuter := bvNone;
  FSalesPanel.Color := $00F1F3F5;
  FSalesPanel.ParentBackground := False;
  FSalesPanel.Visible := False;

  Header := TPanel.Create(Self);
  Header.Parent := FSalesPanel;
  Header.Align := alTop;
  Header.Height := 66;
  Header.BevelOuter := bvNone;
  Header.Color := clWhite;
  Header.ParentBackground := False;

  Lbl := TLabel.Create(Self);
  Lbl.Parent := Header;
  Lbl.Left := 18;
  Lbl.Top := 23;
  Lbl.Caption := '테이블';
  Lbl.Font.Name := Font.Name;
  Lbl.Font.Size := 11;
  Lbl.Font.Style := [fsBold];

  FTableNameLabel := TLabel.Create(Self);
  FTableNameLabel.Parent := Header;
  FTableNameLabel.Left := 78;
  FTableNameLabel.Top := 23;
  FTableNameLabel.Caption := '';
  FTableNameLabel.Font.Name := Font.Name;
  FTableNameLabel.Font.Size := 11;
  FTableNameLabel.Font.Style := [fsBold];

  FTableCombo := TComboBox.Create(Self);
  FTableCombo.Parent := Header;
  FTableCombo.Left := 78;
  FTableCombo.Top := 16;
  FTableCombo.Width := 210;
  FTableCombo.Height := 34;
  FTableCombo.Style := csDropDownList;
  FTableCombo.Font.Name := Font.Name;
  FTableCombo.Font.Size := 11;
  FTableCombo.OnChange := TableChanged;
  FTableCombo.Visible := False;

  FStatusLabel := TLabel.Create(Self);
  FStatusLabel.Parent := Header;
  CustomerCountLabel := TLabel.Create(Self);
  CustomerCountLabel.Parent := Header;
  CustomerCountLabel.SetBounds(310, 12, 55, 18);
  CustomerCountLabel.Caption := '인원';
  CustomerCountLabel.Font.Name := Font.Name;
  CustomerCountLabel.Font.Size := 9;
  FCustomerCountEdit := TEdit.Create(Self);
  FCustomerCountEdit.Parent := Header;
  FCustomerCountEdit.SetBounds(310, 32, 58, 26);
  FCustomerCountEdit.Text := '1';
  FCustomerCountEdit.MaxLength := 3;
  FCustomerCountEdit.Alignment := taRightJustify;
  OrdererLabel := TLabel.Create(Self);
  OrdererLabel.Parent := Header;
  OrdererLabel.SetBounds(380, 12, 70, 18);
  OrdererLabel.Caption := '주문자';
  OrdererLabel.Font.Name := Font.Name;
  OrdererLabel.Font.Size := 9;
  FOrdererEdit := TEdit.Create(Self);
  FOrdererEdit.Parent := Header;
  FOrdererEdit.SetBounds(380, 32, 130, 26);
  FOrdererEdit.MaxLength := 60;
  FStatusLabel.Left := 525;
  FStatusLabel.Top := 24;
  FStatusLabel.Caption := '주문할 메뉴를 선택하세요.';
  FStatusLabel.Font.Name := Font.Name;
  FStatusLabel.Font.Size := 10;

  BackBtn := TButton.Create(Self);
  BackBtn.Parent := Header;
  BackBtn.Left := 1080;
  BackBtn.Top := 14;
  BackBtn.Width := 150;
  BackBtn.Height := 38;
  BackBtn.Caption := '테이블 목록';
  BackBtn.Font.Name := Font.Name;
  BackBtn.OnClick := BackToTablesClick;

  MainPanel := TPanel.Create(Self);
  MainPanel.Parent := FSalesPanel;
  MainPanel.Align := alClient;
  MainPanel.BevelOuter := bvNone;
  MainPanel.Padding.Left := 8;
  MainPanel.Padding.Top := 8;
  MainPanel.Padding.Right := 8;
  MainPanel.Padding.Bottom := 8;
  MainPanel.Color := $00F1F3F5;
  MainPanel.ParentBackground := False;

  { 주문상품/결제 영역은 오른쪽에 고정하고 메뉴 영역이 남은 폭을 사용한다. }
  CartPanel := TPanel.Create(Self);
  CartPanel.Parent := MainPanel;
  CartPanel.Align := alRight;
  CartPanel.Width := 480;
  CartPanel.BevelOuter := bvNone;
  CartPanel.Color := clWhite;
  CartPanel.ParentBackground := False;

  CartHeader := TPanel.Create(Self);
  CartHeader.Parent := CartPanel;
  CartHeader.Align := alTop;
  CartHeader.Height := 48;
  CartHeader.BevelOuter := bvNone;
  CartHeader.Color := clWhite;
  CartHeader.ParentBackground := False;

  Lbl := TLabel.Create(Self);
  Lbl.Parent := CartHeader;
  Lbl.Left := 16;
  Lbl.Top := 14;
  Lbl.Caption := '주문 상품';
  Lbl.Font.Name := Font.Name;
  Lbl.Font.Size := 14;
  Lbl.Font.Style := [fsBold];

  FLoadOrderButton := TButton.Create(Self);
  FLoadOrderButton.Parent := CartHeader;
  FLoadOrderButton.Left := 310;
  FLoadOrderButton.Top := 7;
  FLoadOrderButton.Width := 112;
  FLoadOrderButton.Height := 34;
  FLoadOrderButton.Caption := '주문내역';
  FLoadOrderButton.Font.Name := Font.Name;
  FLoadOrderButton.OnClick := LoadExistingOrderClick;

  FCartGrid := TStringGrid.Create(Self);
  FCartGrid.Parent := CartPanel;
  FCartGrid.Align := alClient;
  FCartGrid.FixedRows := 1;
  FCartGrid.FixedCols := 0;
  FCartGrid.ColCount := 4;
  FCartGrid.RowCount := 2;
  FCartGrid.DefaultRowHeight := 38;
  FCartGrid.Font.Name := Font.Name;
  FCartGrid.Font.Size := 9;
  FCartGrid.Options := FCartGrid.Options + [goRowSelect, goColSizing];
  FCartGrid.Cells[0, 0] := '메뉴 / 옵션';
  FCartGrid.Cells[1, 0] := '단가';
  FCartGrid.Cells[2, 0] := '수량';
  FCartGrid.Cells[3, 0] := '금액';
  FCartGrid.ColWidths[0] := 205;
  FCartGrid.ColWidths[1] := 76;
  FCartGrid.ColWidths[2] := 52;
  FCartGrid.ColWidths[3] := 105;
  FCartGrid.OnDrawCell := DrawCartCell;

  ButtonPanel := TPanel.Create(Self);
  ButtonPanel.Parent := CartPanel;
  ButtonPanel.Align := alBottom;
  ButtonPanel.Height := 112;
  ButtonPanel.BevelOuter := bvNone;
  ButtonPanel.Color := clWhite;
  ButtonPanel.ParentBackground := False;

  Btn := TButton.Create(Self);
  Btn.Parent := ButtonPanel;
  Btn.Left := 10;
  Btn.Top := 7;
  Btn.Width := 78;
  Btn.Height := 40;
  Btn.Caption := '수량 +';
  Btn.Font.Name := Font.Name;
  Btn.OnClick := QuantityPlusClick;

  Btn := TButton.Create(Self);
  Btn.Parent := ButtonPanel;
  Btn.Left := 94;
  Btn.Top := 7;
  Btn.Width := 78;
  Btn.Height := 40;
  Btn.Caption := '수량 -';
  Btn.Font.Name := Font.Name;
  Btn.OnClick := QuantityMinusClick;

  Btn := TButton.Create(Self);
  Btn.Parent := ButtonPanel;
  Btn.Left := 178;
  Btn.Top := 7;
  Btn.Width := 78;
  Btn.Height := 40;
  Btn.Caption := '선택삭제';
  Btn.Font.Name := Font.Name;
  Btn.OnClick := RemoveClick;

  FTotalLabel := TLabel.Create(Self);
  FTotalLabel.Parent := ButtonPanel;
  FTotalLabel.Left := 274;
  FTotalLabel.Top := 18;
  FTotalLabel.Caption := '합계: 0원';
  FTotalLabel.Font.Name := Font.Name;
  FTotalLabel.Font.Size := 13;
  FTotalLabel.Font.Style := [fsBold];

  Btn := TButton.Create(Self);
  Btn.Parent := ButtonPanel;
  Btn.Left := 8;
  Btn.Top := 59;
  Btn.Width := 108;
  Btn.Height := 42;
  Btn.Caption := '주문 저장';
  Btn.Font.Name := Font.Name;
  Btn.Font.Style := [fsBold];
  Btn.OnClick := SaveClick;

  PrinterBtn := TButton.Create(Self);
  PrinterBtn.Parent := ButtonPanel;
  PrinterBtn.Left := 122;
  PrinterBtn.Top := 59;
  PrinterBtn.Width := 100;
  PrinterBtn.Height := 42;
  PrinterBtn.Caption := '프린터 설정';
  PrinterBtn.Font.Name := Font.Name;
  PrinterBtn.OnClick := ConfigurePrinterClick;

  ReprintBtn := TButton.Create(Self);
  ReprintBtn.Parent := ButtonPanel;
  ReprintBtn.Left := 228;
  ReprintBtn.Top := 59;
  ReprintBtn.Width := 108;
  ReprintBtn.Height := 42;
  ReprintBtn.Caption := '주문내역 재출력';
  ReprintBtn.Font.Name := Font.Name;
  ReprintBtn.OnClick := ReprintReceiptClick;

  FPaymentButton := TButton.Create(Self);
  FPaymentButton.Parent := ButtonPanel;
  FPaymentButton.Left := 342;
  FPaymentButton.Top := 59;
  FPaymentButton.Width := 126;
  FPaymentButton.Height := 42;
  FPaymentButton.Caption := '결제';
  FPaymentButton.Font.Name := Font.Name;
  FPaymentButton.Font.Style := [fsBold];
  FPaymentButton.OnClick := PaymentClick;

  MenuArea := TPanel.Create(Self);
  MenuArea.Parent := MainPanel;
  MenuArea.Align := alClient;
  MenuArea.BevelOuter := bvNone;
  MenuArea.Color := $00F1F3F5;
  MenuArea.ParentBackground := False;

  FCategoryPanel := TScrollBox.Create(Self);
  FCategoryPanel.Parent := MenuArea;
  FCategoryPanel.Align := alTop;
  FCategoryPanel.Height := 76;
  FCategoryPanel.BorderStyle := bsNone;
  FCategoryPanel.Color := clWhite;
  FCategoryPanel.HorzScrollBar.Visible := True;
  FCategoryPanel.VertScrollBar.Visible := False;

  FMenuPanel := TScrollBox.Create(Self);
  FMenuPanel.Parent := MenuArea;
  FMenuPanel.Align := alClient;
  FMenuPanel.BorderStyle := bsNone;
  FMenuPanel.Color := $00F1F3F5;
  FMenuPanel.HorzScrollBar.Visible := False;

  RefreshCart;
end;

procedure TfrmSales.SetStoreID(AStoreID: Integer);
begin
  FStoreID := AStoreID;
  LoadTables;
  LoadCategories;
end;

procedure TfrmSales.SetContext(AStoreID, ATerminalID, AEmployeeID: Integer);
begin
  FTerminalID := ATerminalID;
  FEmployeeID := AEmployeeID;
  SetStoreID(AStoreID);
end;

procedure TfrmSales.LoadTables;
var
  Q, QOrder, QItems: TFDQuery;
  Card: TPanel;
  NameLabel, StateLabel, AmountLabel, DetailLabel: TLabel;
  TableID, OrderID, X, Y, Cols, ColIndex: Integer;
  TableName, StateText, DetailText: string;
  Amount: Currency;
  OrderedAt: TDateTime;
begin
  FTableCombo.Items.Clear;
  SetLength(FTableIDs, 0);
  while FTableCards.ControlCount > 0 do
    FTableCards.Controls[0].Free;

  Q := TFDQuery.Create(nil);
  QOrder := TFDQuery.Create(nil);
  QItems := TFDQuery.Create(nil);
  try
    Q.Connection := dmDatabase.Connection;
    QOrder.Connection := dmDatabase.Connection;
    QItems.Connection := dmDatabase.Connection;
    Q.SQL.Text := 'SELECT TABLE_ID, TABLE_NAME FROM POS_TABLE ' +
      'WHERE STORE_ID=:STORE_ID AND ACTIVE_YN=''Y'' ORDER BY DISPLAY_ORDER, TABLE_ID';
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.Open;

    X := 14;
    Y := 14;
    Cols := Max(1, (Width - 70) div 236);
    ColIndex := 0;
    while not Q.Eof do
    begin
      TableID := Q.FieldByName('TABLE_ID').AsInteger;
      TableName := Q.FieldByName('TABLE_NAME').AsString;
      FTableCombo.Items.Add(TableName);
      SetLength(FTableIDs, Length(FTableIDs) + 1);
      FTableIDs[High(FTableIDs)] := TableID;

      OrderID := 0;
      Amount := 0;
      StateText := '주문 대기';
      DetailText := '새 주문을 시작할 수 있습니다.';
      QOrder.Close;
      QOrder.SQL.Text :=
        'SELECT FIRST 1 ORDER_ID, TOTAL_AMOUNT, ORDERED_AT, ' +
        'CUSTOMER_COUNT, ORDERER_NAME FROM POS_ORDER ' +
        'WHERE STORE_ID=:STORE_ID AND TABLE_ID=:TABLE_ID ' +
        'AND ORDER_TYPE=''DINE_IN'' AND ORDER_STATUS=''OPEN'' ' +
        'ORDER BY ORDERED_AT DESC';
      QOrder.ParamByName('STORE_ID').AsInteger := FStoreID;
      QOrder.ParamByName('TABLE_ID').AsInteger := TableID;
      QOrder.Open;
      if not QOrder.IsEmpty then
      begin
        OrderID := QOrder.FieldByName('ORDER_ID').AsLargeInt;
        Amount := QOrder.FieldByName('TOTAL_AMOUNT').AsCurrency;
        OrderedAt := QOrder.FieldByName('ORDERED_AT').AsDateTime;
        StateText := '주문 진행중';
        DetailText := '인원 ' + QOrder.FieldByName('CUSTOMER_COUNT').AsString + '명';
        if Trim(QOrder.FieldByName('ORDERER_NAME').AsString) <> '' then
          DetailText := DetailText + ' / ' + Trim(QOrder.FieldByName('ORDERER_NAME').AsString);
        DetailText := DetailText + ' / 최초 ' + FormatDateTime('HH:NN', OrderedAt) +
          ' / 경과 ' + IntToStr(MinutesBetween(Now, OrderedAt)) + '분';
        if FShowTableMenus then
        begin
          QItems.Close;
          QItems.SQL.Text :=
            'SELECT MENU_NAME, SUM(QUANTITY) AS ITEM_QTY ' +
            'FROM POS_ORDER_ITEM WHERE ORDER_ID=:ORDER_ID ' +
            'GROUP BY MENU_NAME ORDER BY MENU_NAME';
          QItems.ParamByName('ORDER_ID').AsLargeInt := OrderID;
          QItems.Open;
          DetailText := '인원 ' + QOrder.FieldByName('CUSTOMER_COUNT').AsString + '명';
          if Trim(QOrder.FieldByName('ORDERER_NAME').AsString) <> '' then
            DetailText := DetailText + ' / ' + Trim(QOrder.FieldByName('ORDERER_NAME').AsString);
          DetailText := DetailText + sLineBreak;
          while not QItems.Eof do
          begin
            if Length(DetailText) > 0 then
              if DetailText[Length(DetailText)] <> #10 then DetailText := DetailText + ' / ';
            DetailText := DetailText + QItems.FieldByName('MENU_NAME').AsString +
              ' ' + QItems.FieldByName('ITEM_QTY').AsString;
            QItems.Next;
          end;
          if Trim(DetailText) = '' then DetailText := '주문 상품 없음';
        end;
      end;

      Card := TPanel.Create(FTableCards);
      Card.Parent := FTableCards;
      Card.SetBounds(X, Y, 218, 146);
      Card.BevelOuter := bvRaised;
      Card.ParentBackground := False;
      if OrderID > 0 then Card.Color := $00FCE8D8 else Card.Color := clWhite;
      Card.Tag := TableID;
      Card.Cursor := crHandPoint;
      Card.OnClick := TableCardClick;

      NameLabel := TLabel.Create(Card);
      NameLabel.Parent := Card;
      NameLabel.SetBounds(14, 12, 190, 30);
      NameLabel.Caption := TableName;
      NameLabel.Font.Name := Font.Name;
      NameLabel.Font.Size := 15;
      NameLabel.Font.Style := [fsBold];
      NameLabel.Tag := TableID;
      NameLabel.Cursor := crHandPoint;
      NameLabel.OnClick := TableCardClick;

      StateLabel := TLabel.Create(Card);
      StateLabel.Parent := Card;
      StateLabel.SetBounds(14, 49, 190, 22);
      StateLabel.Caption := StateText;
      StateLabel.Font.Name := Font.Name;
      StateLabel.Font.Size := 10;
      StateLabel.Font.Style := [fsBold];
      if OrderID > 0 then StateLabel.Font.Color := clMaroon
      else StateLabel.Font.Color := clGreen;
      StateLabel.Tag := TableID;
      StateLabel.Cursor := crHandPoint;
      StateLabel.OnClick := TableCardClick;

      AmountLabel := TLabel.Create(Card);
      AmountLabel.Parent := Card;
      AmountLabel.SetBounds(14, 77, 190, 24);
      if OrderID > 0 then AmountLabel.Caption := FormatCurr('#,##0', Amount) + '원'
      else AmountLabel.Caption := '주문 전';
      AmountLabel.Font.Name := Font.Name;
      AmountLabel.Font.Size := 13;
      AmountLabel.Font.Style := [fsBold];
      AmountLabel.Tag := TableID;
      AmountLabel.Cursor := crHandPoint;
      AmountLabel.OnClick := TableCardClick;

      DetailLabel := TLabel.Create(Card);
      DetailLabel.Parent := Card;
      DetailLabel.SetBounds(14, 110, 190, 28);
      DetailLabel.Caption := DetailText;
      DetailLabel.Font.Name := Font.Name;
      DetailLabel.Font.Size := 8;
      DetailLabel.WordWrap := True;
      DetailLabel.Font.Color := clGrayText;
      DetailLabel.Tag := TableID;
      DetailLabel.Cursor := crHandPoint;
      DetailLabel.OnClick := TableCardClick;

      Inc(ColIndex);
      if ColIndex >= Cols then
      begin
        ColIndex := 0;
        X := 14;
        Inc(Y, 158);
      end
      else
        Inc(X, 232);
      Q.Next;
    end;
  finally
    QItems.Free;
    QOrder.Free;
    Q.Free;
  end;

  if FTableCombo.Items.Count > 0 then
  begin
    if FTableCombo.ItemIndex < 0 then FTableCombo.ItemIndex := 0;
  end;
  UpdateTableStatus;
end;

procedure TfrmSales.TableCardClick(Sender: TObject);
var
  TableID, I: Integer;
  Q: TFDQuery;
begin
  TableID := TControl(Sender).Tag;
  for I := 0 to FTableCombo.Items.Count - 1 do
    if (I < Length(FTableIDs)) and (FTableIDs[I] = TableID) then
    begin
      FTableCombo.ItemIndex := I;
      FTableNameLabel.Caption := FTableCombo.Items[I];
      Break;
    end;
  SetLength(FCart, 0);
  SetLength(FLoadedOrderItemIDs, 0);
  FLoadedOrderID := 0;
  FLoadOrderButton.Caption := '주문내역';
  FCustomerCountEdit.Text := '1';
  FOrdererEdit.Clear;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmDatabase.Connection;
    Q.SQL.Text := 'SELECT FIRST 1 CUSTOMER_COUNT, ORDERER_NAME FROM POS_ORDER ' +
      'WHERE STORE_ID=:STORE_ID AND TABLE_ID=:TABLE_ID ' +
      'AND ORDER_TYPE=''DINE_IN'' AND ORDER_STATUS=''OPEN'' ' +
      'ORDER BY ORDERED_AT DESC';
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.ParamByName('TABLE_ID').AsInteger := TableID;
    Q.Open;
    if not Q.IsEmpty then
    begin
      FCustomerCountEdit.Text := Q.FieldByName('CUSTOMER_COUNT').AsString;
      FOrdererEdit.Text := Q.FieldByName('ORDERER_NAME').AsString;
    end;
  finally
    Q.Free;
  end;
  RefreshCart;
  UpdateTableStatus;
  FTablePanel.Visible := False;
  FSalesPanel.Visible := True;
  FSalesPanel.BringToFront;
end;


procedure TfrmSales.LoadExistingOrderClick(Sender: TObject);
var
  Q, QItems: TFDQuery;
  OrderID: Int64;
  N: Integer;
begin
  if FLoadedOrderID > 0 then
  begin
    SetLength(FCart, 0);
    SetLength(FLoadedOrderItemIDs, 0);
    FLoadedOrderID := 0;
    FLoadOrderButton.Caption := '주문내역';
    RefreshCart;
    UpdateTableStatus;
    FStatusLabel.Caption := '주문 리스트를 화면에서 초기화했습니다. DB 주문내역은 그대로 유지됩니다.';
    Exit;
  end;

  if SelectedTableID = 0 then
    raise Exception.Create('먼저 테이블을 선택해 주세요.');
  if Length(FCart) > 0 then
    if MessageDlg('현재 주문 리스트의 미저장 내용은 지워집니다. 기존 주문내역을 불러올까요?',
      mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  Q := TFDQuery.Create(nil);
  QItems := TFDQuery.Create(nil);
  try
    Q.Connection := dmDatabase.Connection;
    QItems.Connection := dmDatabase.Connection;
    Q.SQL.Text :=
      'SELECT FIRST 1 ORDER_ID FROM POS_ORDER ' +
      'WHERE STORE_ID=:STORE_ID AND TABLE_ID=:TABLE_ID ' +
      'AND ORDER_TYPE=''DINE_IN'' AND ORDER_STATUS=''OPEN'' ' +
      'ORDER BY ORDERED_AT DESC';
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.ParamByName('TABLE_ID').AsInteger := SelectedTableID;
    Q.Open;
    if Q.IsEmpty then
      raise Exception.Create('선택한 테이블에 불러올 진행 중 주문이 없습니다.');
    OrderID := Q.FieldByName('ORDER_ID').AsLargeInt;
    Q.Close;

    SetLength(FCart, 0);
    SetLength(FLoadedOrderItemIDs, 0);
    QItems.SQL.Text :=
      'SELECT ORDER_ITEM_ID, MENU_ID, MENU_NAME, UNIT_PRICE, QUANTITY, ' +
      'OPTION_TEXT, OPTION_AMOUNT FROM POS_ORDER_ITEM ' +
      'WHERE ORDER_ID=:ORDER_ID ORDER BY ORDER_ITEM_ID';
    QItems.ParamByName('ORDER_ID').AsLargeInt := OrderID;
    QItems.Open;
    while not QItems.Eof do
    begin
      N := Length(FCart);
      SetLength(FCart, N + 1);
      FCart[N].OrderItemID := QItems.FieldByName('ORDER_ITEM_ID').AsLargeInt;
      FCart[N].IsPersisted := True;
      FCart[N].OriginalQuantity := QItems.FieldByName('QUANTITY').AsInteger;
      FCart[N].MenuID := QItems.FieldByName('MENU_ID').AsInteger;
      FCart[N].MenuName := QItems.FieldByName('MENU_NAME').AsString;
      FCart[N].UnitPrice := QItems.FieldByName('UNIT_PRICE').AsCurrency;
      FCart[N].Quantity := FCart[N].OriginalQuantity;
      FCart[N].OptionText := QItems.FieldByName('OPTION_TEXT').AsString;
      FCart[N].OptionAmount := QItems.FieldByName('OPTION_AMOUNT').AsCurrency;
      N := Length(FLoadedOrderItemIDs);
      SetLength(FLoadedOrderItemIDs, N + 1);
      FLoadedOrderItemIDs[N] := FCart[N].OrderItemID;
      QItems.Next;
    end;
    FLoadedOrderID := OrderID;
  finally
    QItems.Free;
    Q.Free;
  end;

  FLoadOrderButton.Caption := '초기화';
  RefreshCart;
  FStatusLabel.Caption := '기존 주문내역을 불러왔습니다. 메뉴 추가·수량 변경·삭제 후 주문 저장을 눌러주세요.';
  if Length(FCart) = 0 then
    MessageDlg('기존 주문에 등록된 메뉴가 없습니다.', mtInformation, [mbOK], 0);
end;

procedure TfrmSales.TableDisplayToggleClick(Sender: TObject);
begin
  FShowTableMenus := not FShowTableMenus;
  if FShowTableMenus then
    TButton(Sender).Caption := '메뉴 숨김'
  else
    TButton(Sender).Caption := '메뉴표기';
  LoadTables;
end;

procedure TfrmSales.BackToTablesClick(Sender: TObject);
begin
  if Length(FCart) > 0 then
    if MessageDlg('저장하지 않은 상품이 있습니다. 취소하고 테이블 목록으로 이동할까요?',
      mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  SetLength(FCart, 0);
  SetLength(FLoadedOrderItemIDs, 0);
  FLoadedOrderID := 0;
  FLoadOrderButton.Caption := '주문내역';
  RefreshCart;
  LoadTables;
  FSalesPanel.Visible := False;
  FTablePanel.Visible := True;
  FTablePanel.BringToFront;
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
    X := 10;
    while not Q.Eof do
    begin
      Btn := TButton.Create(FCategoryPanel);
      Btn.Parent := FCategoryPanel;
      Btn.Left := X;
      Btn.Top := 10;
      Btn.Width := 142;
      Btn.Height := 54;
      Btn.Caption := Q.FieldByName('CATEGORY_NAME').AsString;
      Btn.Tag := Q.FieldByName('CATEGORY_ID').AsInteger;
      Btn.Font.Name := Font.Name;
      Btn.Font.Size := 10;
      Btn.Font.Style := [fsBold];
      Btn.OnClick := CategoryClick;
      X := X + 150;
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
    Q.SQL.Text := 'SELECT MENU_ID, MENU_NAME, PRICE, SOLD_OUT_YN FROM MENU_ITEM ' +
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
      Btn.Width := 174;
      Btn.Height := 104;
      Btn.Tag := Q.FieldByName('MENU_ID').AsInteger;
      Btn.Caption := Q.FieldByName('MENU_NAME').AsString + sLineBreak +
        FormatCurr('#,##0', Q.FieldByName('PRICE').AsCurrency) + '원';
      Btn.Font.Name := Font.Name;
      Btn.Font.Size := 11;
      Btn.Font.Style := [fsBold];
      Btn.Enabled := not SameText(Q.FieldByName('SOLD_OUT_YN').AsString, 'Y');
      if not Btn.Enabled then
        Btn.Caption := Btn.Caption + sLineBreak + '[품절]';
      Btn.OnClick := AddMenuClick;
      Inc(X, 186);
      if X + 174 > FMenuPanel.ClientWidth then
      begin
        X := 12;
        Inc(Y, 114);
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
    Q.SQL.Text := 'SELECT MENU_NAME, PRICE, SOLD_OUT_YN FROM MENU_ITEM ' +
      'WHERE STORE_ID=:STORE_ID AND MENU_ID=:MENU_ID AND ACTIVE_YN=''Y''';
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.ParamByName('MENU_ID').AsInteger := MenuID;
    Q.Open;
    if not Q.IsEmpty then
    begin
      if SameText(Q.FieldByName('SOLD_OUT_YN').AsString, 'Y') then
      begin
        MessageDlg('품절 처리된 메뉴입니다. 판매할 수 없습니다.', mtWarning, [mbOK], 0);
        Exit;
      end;
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
        Groups[GroupCount].List.Items.Add(
          OptionQuery.FieldByName('OPTION_NAME').AsString);
        SetLength(Groups[GroupCount].OptionIDs,
          Length(Groups[GroupCount].OptionIDs) + 1);
        Groups[GroupCount].OptionIDs[High(Groups[GroupCount].OptionIDs)] :=
          OptionQuery.FieldByName('OPTION_ID').AsInteger;
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
          OptionID := Groups[I].OptionIDs[J];
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
    if (not FCart[I].IsPersisted) and
      (FCart[I].MenuID = AMenuID) and
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


procedure TfrmSales.DrawCartCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
var
  S: string;
  TextRect: TRect;
begin
  if gdFixed in State then
  begin
    FCartGrid.Canvas.Brush.Color := $00E9EDF2;
    FCartGrid.Canvas.Font.Style := [fsBold];
    FCartGrid.Canvas.Font.Color := clWindowText;
  end
  else if gdSelected in State then
  begin
    FCartGrid.Canvas.Brush.Color := $00DCEBFA;
    FCartGrid.Canvas.Font.Style := [];
    FCartGrid.Canvas.Font.Color := clWindowText;
  end
  else
  begin
    FCartGrid.Canvas.Brush.Color := clWhite;
    FCartGrid.Canvas.Font.Style := [];
    FCartGrid.Canvas.Font.Color := clWindowText;
  end;
  FCartGrid.Canvas.FillRect(Rect);
  S := FCartGrid.Cells[ACol, ARow];
  TextRect := Rect;
  InflateRect(TextRect, -6, 0);
  if ACol >= 1 then
    DrawText(FCartGrid.Canvas.Handle, PChar(S), Length(S), TextRect,
      DT_SINGLELINE or DT_VCENTER or DT_RIGHT or DT_END_ELLIPSIS)
  else
    DrawText(FCartGrid.Canvas.Handle, PChar(S), Length(S), TextRect,
      DT_SINGLELINE or DT_VCENTER or DT_LEFT or DT_END_ELLIPSIS);
  FCartGrid.Canvas.Pen.Color := $00E5E5E5;
  FCartGrid.Canvas.MoveTo(Rect.Left, Rect.Bottom - 1);
  FCartGrid.Canvas.LineTo(Rect.Right, Rect.Bottom - 1);
end;

procedure TfrmSales.RefreshCart;
var
  I, J, G, N, GroupQty: Integer;
  Found: Boolean;
  GroupTotal: Currency;
  DisplayName: string;
begin
  SetLength(FCartGroups, 0);
  for I := 0 to High(FCart) do
  begin
    Found := False;
    for G := 0 to High(FCartGroups) do
    begin
      J := FCartGroups[G][0];
      if (FCart[J].MenuID = FCart[I].MenuID) and
        (FCart[J].UnitPrice = FCart[I].UnitPrice) and
        (FCart[J].OptionAmount = FCart[I].OptionAmount) and
        SameText(FCart[J].OptionText, FCart[I].OptionText) then
      begin
        N := Length(FCartGroups[G]);
        SetLength(FCartGroups[G], N + 1);
        FCartGroups[G][N] := I;
        Found := True;
        Break;
      end;
    end;
    if not Found then
    begin
      G := Length(FCartGroups);
      SetLength(FCartGroups, G + 1);
      SetLength(FCartGroups[G], 1);
      FCartGroups[G][0] := I;
    end;
  end;

  FCartGrid.RowCount := Max(2, Length(FCartGroups) + 1);
  for G := 0 to High(FCartGroups) do
  begin
    I := FCartGroups[G][0];
    GroupQty := 0;
    GroupTotal := 0;
    for J := 0 to High(FCartGroups[G]) do
    begin
      N := FCartGroups[G][J];
      Inc(GroupQty, FCart[N].Quantity);
      GroupTotal := GroupTotal + FCart[N].UnitPrice * FCart[N].Quantity;
    end;
    DisplayName := FCart[I].MenuName;
    if FCart[I].OptionText <> '' then
      DisplayName := DisplayName + ' [' + FCart[I].OptionText + ']';
    FCartGrid.Cells[0, G + 1] := DisplayName;
    FCartGrid.Cells[1, G + 1] := FormatCurr('#,##0', FCart[I].UnitPrice);
    FCartGrid.Cells[2, G + 1] := IntToStr(GroupQty);
    FCartGrid.Cells[3, G + 1] := FormatCurr('#,##0', GroupTotal);
  end;
  if Length(FCartGroups) = 0 then
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
  GroupIndex, CartIndex, I: Integer;
begin
  GroupIndex := FCartGrid.Row - 1;
  if (GroupIndex < 0) or (GroupIndex > High(FCartGroups)) then Exit;
  if Length(FCartGroups[GroupIndex]) = 0 then Exit;

  { 같은 품목으로 저장된 여러 DB 행 중 마지막 행의 수량을 조정한다. }
  CartIndex := FCartGroups[GroupIndex][High(FCartGroups[GroupIndex])];
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
  GroupIndex, I, J, N: Integer;
  KeepItem: Boolean;
  NewCart: TCartItemArray;
begin
  GroupIndex := FCartGrid.Row - 1;
  if (GroupIndex < 0) or (GroupIndex > High(FCartGroups)) then Exit;

  { 선택한 합산 품목에 포함된 모든 실제 주문 항목을 화면에서 제거한다. }
  for I := 0 to High(FCart) do
  begin
    KeepItem := True;
    for J := 0 to High(FCartGroups[GroupIndex]) do
      if FCartGroups[GroupIndex][J] = I then
      begin
        KeepItem := False;
        Break;
      end;
    if KeepItem then
    begin
      N := Length(NewCart);
      SetLength(NewCart, N + 1);
      NewCart[N] := FCart[I];
    end;
  end;
  FCart := NewCart;
  RefreshCart;
end;

function TfrmSales.SelectedTableID: Integer;
begin
  Result := 0;
  if FTableCombo.ItemIndex >= 0 then
    if FTableCombo.ItemIndex < Length(FTableIDs) then
      Result := FTableIDs[FTableCombo.ItemIndex];
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

procedure TfrmSales.ConfigurePrinterClick(Sender: TObject);
var
  Settings: TReceiptPrinterSettings;
  PortText, BaudText: string;
begin
  try
  Settings := TReceiptPrinter.LoadSettings;
  PortText := Settings.PortName;
  BaudText := IntToStr(Settings.BaudRate);
  if not InputQuery('영수증 프린터 설정', '시리얼 포트 (예: COM1)', PortText) then Exit;
  if not InputQuery('영수증 프린터 설정', '통신 속도 (2400~115200)', BaudText) then Exit;
  Settings.PortName := UpperCase(Trim(PortText));
  if not TryStrToInt(Trim(BaudText), Settings.BaudRate) then
    raise Exception.Create('통신 속도는 숫자로 입력해 주세요.');
  TReceiptPrinter.SaveSettings(Settings);
  if MessageDlg('프린터 설정이 저장되었습니다.' + sLineBreak +
    '테스트 인쇄를 실행하시겠습니까?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    TReceiptPrinter.TestPrint(Settings);
  MessageDlg('프린터 설정이 저장되었습니다.', mtInformation, [mbOK], 0);
  except
    on E: Exception do
      MessageDlg('프린터 설정/테스트 인쇄에 실패했습니다: ' + E.Message,
        mtError, [mbOK], 0);
  end;
end;

procedure TfrmSales.ReprintReceiptClick(Sender: TObject);
begin
  try
    if SelectedTableID = 0 then
      raise Exception.Create('먼저 테이블을 선택해 주세요.');

    TReceiptPrinter.PrintUnpaidTableOrders(
      dmDatabase.Connection, FStoreID, SelectedTableID);
    MessageDlg('선택한 테이블의 미결제 주문저장 내역을 영수증 1장으로 출력했습니다.',
      mtInformation, [mbOK], 0);
  except
    on E: Exception do
      MessageDlg('주문내역 재출력에 실패했습니다: ' + E.Message,
        mtError, [mbOK], 0);
  end;
end;

procedure TfrmSales.ProcessPayment;
var
  OrderID: Int64;
  OrderNo: string;
  OrderTotal, PaidAmount, RemainingAmount, ReceivedAmount: Currency;
  PaymentID: Int64;
  Q, QItems, QStock: TFDQuery;
  MenuID: Integer;
  MenuName: string;
  ItemQty, StockBefore, StockAfter: Double;
  StockMovementID, IngredientID: Int64;
  IngredientName, IngredientUnit: string;
  IngredientQty, IngredientStockBefore, IngredientStockAfter,
    IngredientUnitCost: Double;
  IngredientShortageWarnings: string;
  DialogForm: TForm;
  MethodGroup: TRadioGroup;
  AmountLabel, ReceivedLabel, ChangeLabel: TLabel;
  ReceivedEdit: TEdit;
  OkButton, CancelButton: TButton;
  MethodCode: string;
  I, J: Integer;
  CartHasChanges, ItemFound: Boolean;
begin
  IngredientShortageWarnings := '';
  if SelectedTableID = 0 then
    raise Exception.Create('먼저 테이블을 선택해 주세요.');

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

    CartHasChanges := False;
    if Length(FCart) > 0 then
    begin
      if (FLoadedOrderID = 0) or (FLoadedOrderID <> OrderID) then
        CartHasChanges := True
      else
      begin
        for I := 0 to High(FCart) do
          if (not FCart[I].IsPersisted) or
            (FCart[I].Quantity <> FCart[I].OriginalQuantity) then
          begin
            CartHasChanges := True;
            Break;
          end;

        if not CartHasChanges then
          for I := 0 to High(FLoadedOrderItemIDs) do
          begin
            ItemFound := False;
            for J := 0 to High(FCart) do
              if FCart[J].IsPersisted and
                (FCart[J].OrderItemID = FLoadedOrderItemIDs[I]) then
              begin
                ItemFound := True;
                Break;
              end;
            if not ItemFound then
            begin
              CartHasChanges := True;
              Break;
            end;
          end;
      end;
    end;
    if CartHasChanges then
      raise Exception.Create('장바구니에 저장하지 않은 메뉴 변경이 있습니다. 먼저 주문 저장을 해주세요.');

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
    QItems := TFDQuery.Create(nil);
    QStock := TFDQuery.Create(nil);
    try
      Q.Connection := dmDatabase.Connection;
      QItems.Connection := dmDatabase.Connection;
      QStock.Connection := dmDatabase.Connection;
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

      // Deduct managed menu stock only when the order is fully paid.
      QItems.SQL.Text :=
        'SELECT MENU_ID, MIN(MENU_NAME) AS MENU_NAME, SUM(QUANTITY) AS ITEM_QTY ' +
        'FROM POS_ORDER_ITEM WHERE ORDER_ID=:ORDER_ID GROUP BY MENU_ID';
      QItems.ParamByName('ORDER_ID').AsLargeInt := OrderID;
      QItems.Open;
      while not QItems.Eof do
      begin
        MenuID := QItems.FieldByName('MENU_ID').AsInteger;
        MenuName := QItems.FieldByName('MENU_NAME').AsString;
        ItemQty := QItems.FieldByName('ITEM_QTY').AsFloat;

        QStock.Close;
        QStock.SQL.Text := 'SELECT STOCK_MANAGED_YN, STOCK_QTY FROM MENU_ITEM ' +
          'WHERE STORE_ID=:STORE_ID AND MENU_ID=:MENU_ID WITH LOCK';
        QStock.ParamByName('STORE_ID').AsInteger := FStoreID;
        QStock.ParamByName('MENU_ID').AsInteger := MenuID;
        QStock.Open;
        if not QStock.IsEmpty and
          SameText(QStock.FieldByName('STOCK_MANAGED_YN').AsString, 'Y') then
        begin
          StockBefore := QStock.FieldByName('STOCK_QTY').AsFloat;
          if StockBefore < ItemQty then
            raise Exception.CreateFmt('재고가 부족합니다. 메뉴: %s / 현재고: %s / 주문수량: %s',
              [MenuName, FormatFloat('#,##0.###', StockBefore),
               FormatFloat('#,##0.###', ItemQty)]);
          StockAfter := StockBefore - ItemQty;
          QStock.Close;

          Q.SQL.Text := 'UPDATE MENU_ITEM SET STOCK_QTY=:STOCK_QTY ' +
            'WHERE STORE_ID=:STORE_ID AND MENU_ID=:MENU_ID';
          Q.ParamByName('STOCK_QTY').AsFloat := StockAfter;
          Q.ParamByName('STORE_ID').AsInteger := FStoreID;
          Q.ParamByName('MENU_ID').AsInteger := MenuID;
          Q.ExecSQL;

          StockMovementID := NextSequenceValue('GEN_POS_STOCK_MOVEMENT_ID');
          Q.SQL.Text :=
            'INSERT INTO POS_STOCK_MOVEMENT ' +
            '(STOCK_MOVEMENT_ID, STORE_ID, MENU_ID, MOVEMENT_TYPE, QUANTITY, ' +
            'STOCK_BEFORE, STOCK_AFTER, REASON_CODE, DESCRIPTION, ' +
            'REFERENCE_TYPE, REFERENCE_ID, EMPLOYEE_ID) ' +
            'VALUES (:ID, :STORE_ID, :MENU_ID, ''OUT'', :QTY, :BEFORE_QTY, ' +
            ':AFTER_QTY, ''SALE'', :DESCRIPTION, ''ORDER'', :REFERENCE_ID, :EMPLOYEE_ID)';
          Q.ParamByName('ID').AsLargeInt := StockMovementID;
          Q.ParamByName('STORE_ID').AsInteger := FStoreID;
          Q.ParamByName('MENU_ID').AsInteger := MenuID;
          Q.ParamByName('QTY').AsFloat := ItemQty;
          Q.ParamByName('BEFORE_QTY').AsFloat := StockBefore;
          Q.ParamByName('AFTER_QTY').AsFloat := StockAfter;
          Q.ParamByName('DESCRIPTION').AsString := 'POS 판매 자동 차감 ' + OrderNo;
          Q.ParamByName('REFERENCE_ID').AsLargeInt := OrderID;
          Q.ParamByName('EMPLOYEE_ID').AsInteger := FEmployeeID;
          Q.ExecSQL;
        end
        else
          QStock.Close;
        QItems.Next;
      end;
      QItems.Close;

      // Deduct recipe ingredients in the same transaction as final payment.
      // Aggregate by ingredient first because multiple menu lines may share it.
      QItems.SQL.Text :=
        'SELECT I.INGREDIENT_ID, I.INGREDIENT_NAME, I.UNIT_CODE, ' +
        'CAST(SUM(R.QUANTITY * OI.QUANTITY) AS NUMERIC(15,3)) AS REQUIRED_QTY ' +
        'FROM POS_ORDER_ITEM OI ' +
        'JOIN POS_MENU_RECIPE R ON R.STORE_ID=:STORE_ID AND R.MENU_ID=OI.MENU_ID ' +
        'JOIN POS_INGREDIENT I ON I.STORE_ID=R.STORE_ID ' +
        'AND I.INGREDIENT_ID=R.INGREDIENT_ID ' +
        'WHERE OI.ORDER_ID=:ORDER_ID ' +
        'GROUP BY I.INGREDIENT_ID, I.INGREDIENT_NAME, I.UNIT_CODE ' +
        'ORDER BY I.INGREDIENT_ID';
      QItems.ParamByName('STORE_ID').AsInteger := FStoreID;
      QItems.ParamByName('ORDER_ID').AsLargeInt := OrderID;
      QItems.Open;
      while not QItems.Eof do
      begin
        IngredientID := QItems.FieldByName('INGREDIENT_ID').AsLargeInt;
        IngredientName := QItems.FieldByName('INGREDIENT_NAME').AsString;
        IngredientUnit := QItems.FieldByName('UNIT_CODE').AsString;
        IngredientQty := QItems.FieldByName('REQUIRED_QTY').AsFloat;
        if IngredientQty <= 0 then
          raise Exception.Create('레시피 사용량이 원재료 재고 단위의 최소 정밀도(0.001)보다 작습니다: ' + IngredientName);

        QStock.Close;
        QStock.SQL.Text :=
          'SELECT ACTIVE_YN, STOCK_QTY, AVG_UNIT_COST FROM POS_INGREDIENT ' +
          'WHERE STORE_ID=:STORE_ID AND INGREDIENT_ID=:INGREDIENT_ID WITH LOCK';
        QStock.ParamByName('STORE_ID').AsInteger := FStoreID;
        QStock.ParamByName('INGREDIENT_ID').AsLargeInt := IngredientID;
        QStock.Open;
        if QStock.IsEmpty then
          raise Exception.Create('레시피 원재료 정보를 찾을 수 없습니다: ' + IngredientName);
        if not SameText(QStock.FieldByName('ACTIVE_YN').AsString, 'Y') then
          raise Exception.Create('사용 중지된 원재료가 레시피에 등록되어 있습니다: ' + IngredientName);

        IngredientStockBefore := QStock.FieldByName('STOCK_QTY').AsFloat;
        IngredientUnitCost := QStock.FieldByName('AVG_UNIT_COST').AsFloat;
        if IngredientStockBefore < IngredientQty then
        begin
          if IngredientShortageWarnings <> '' then
            IngredientShortageWarnings := IngredientShortageWarnings + sLineBreak;
          IngredientShortageWarnings := IngredientShortageWarnings +
            Format('원재료: %s / 현재고: %s %s / 필요량: %s %s / 결제 후 재고: %s %s',
              [IngredientName, FormatFloat('#,##0.###', IngredientStockBefore),
               IngredientUnit, FormatFloat('#,##0.###', IngredientQty), IngredientUnit,
               FormatFloat('#,##0.###', IngredientStockBefore - IngredientQty), IngredientUnit]);
        end;
        // 재고가 부족해도 판매를 막지 않고 실제 사용량만큼 차감하여 음수 재고로 기록한다.
        IngredientStockAfter := IngredientStockBefore - IngredientQty;
        QStock.Close;

        Q.SQL.Text :=
          'UPDATE POS_INGREDIENT SET STOCK_QTY=:STOCK_QTY, ' +
          'UPDATED_AT=CURRENT_TIMESTAMP ' +
          'WHERE STORE_ID=:STORE_ID AND INGREDIENT_ID=:INGREDIENT_ID';
        Q.ParamByName('STOCK_QTY').AsFloat := IngredientStockAfter;
        Q.ParamByName('STORE_ID').AsInteger := FStoreID;
        Q.ParamByName('INGREDIENT_ID').AsLargeInt := IngredientID;
        Q.ExecSQL;

        StockMovementID := NextSequenceValue('GEN_POS_INGREDIENT_MOVEMENT_ID');
        Q.SQL.Text :=
          'INSERT INTO POS_INGREDIENT_MOVEMENT ' +
          '(MOVEMENT_ID, STORE_ID, INGREDIENT_ID, MOVEMENT_TYPE, QUANTITY, ' +
          'STOCK_BEFORE, STOCK_AFTER, UNIT_COST, REFERENCE_TYPE, REFERENCE_ID, ' +
          'DESCRIPTION, EMPLOYEE_ID) ' +
          'VALUES (:ID, :STORE_ID, :INGREDIENT_ID, ''OUT'', :QTY, :BEFORE_QTY, ' +
          ':AFTER_QTY, :UNIT_COST, ''SALE'', :REFERENCE_ID, :DESCRIPTION, :EMPLOYEE_ID)';
        Q.ParamByName('ID').AsLargeInt := StockMovementID;
        Q.ParamByName('STORE_ID').AsInteger := FStoreID;
        Q.ParamByName('INGREDIENT_ID').AsLargeInt := IngredientID;
        Q.ParamByName('QTY').AsFloat := IngredientQty;
        Q.ParamByName('BEFORE_QTY').AsFloat := IngredientStockBefore;
        Q.ParamByName('AFTER_QTY').AsFloat := IngredientStockAfter;
        Q.ParamByName('UNIT_COST').AsFloat := IngredientUnitCost;
        Q.ParamByName('REFERENCE_ID').AsLargeInt := OrderID;
        Q.ParamByName('DESCRIPTION').AsString := 'POS 판매 원재료 자동 차감 ' + OrderNo;
        Q.ParamByName('EMPLOYEE_ID').AsInteger := FEmployeeID;
        Q.ExecSQL;

        QItems.Next;
      end;
      QItems.Close;

      PaymentID := NextSequenceValue('GEN_POS_PAYMENT_ID');
      Q.SQL.Text := 'INSERT INTO POS_PAYMENT ' +
        '(PAYMENT_ID, ORDER_ID, PAYMENT_METHOD, PAYMENT_AMOUNT, ' +
        'RECEIVED_AMOUNT, CHANGE_AMOUNT, PAYMENT_STATUS) ' +
        'VALUES (:ID, :ORDER_ID, :METHOD, :AMOUNT, :RECEIVED, :CHANGE, ''APPROVED'')';
      Q.ParamByName('ID').AsLargeInt := PaymentID;
      Q.ParamByName('ORDER_ID').AsLargeInt := OrderID;
      Q.ParamByName('METHOD').AsString := MethodCode;
      Q.ParamByName('AMOUNT').AsCurrency := RemainingAmount;
      Q.ParamByName('RECEIVED').AsCurrency := ReceivedAmount;
      Q.ParamByName('CHANGE').AsCurrency := ReceivedAmount - RemainingAmount;
      Q.ExecSQL;

      Q.SQL.Text := 'UPDATE POS_ORDER SET ORDER_STATUS=''PAID'', ' +
        'EMPLOYEE_ID=COALESCE(EMPLOYEE_ID,:EMPLOYEE_ID), ' +
        'TERMINAL_ID=COALESCE(TERMINAL_ID,:TERMINAL_ID), UPDATED_AT=CURRENT_TIMESTAMP ' +
        'WHERE STORE_ID=:STORE_ID AND ORDER_ID=:ORDER_ID';
      Q.ParamByName('EMPLOYEE_ID').AsInteger := FEmployeeID;
      Q.ParamByName('TERMINAL_ID').AsInteger := FTerminalID;
      Q.ParamByName('STORE_ID').AsInteger := FStoreID;
      Q.ParamByName('ORDER_ID').AsLargeInt := OrderID;
      Q.ExecSQL;
    finally
      QStock.Free;
      QItems.Free;
      Q.Free;
    end;
    dmDatabase.Connection.Commit;
  except
    dmDatabase.Connection.Rollback;
    raise;
  end;

  UpdateTableStatus;
  if IngredientShortageWarnings <> '' then
    MessageDlg('원재료 재고가 부족하지만 결제는 정상 완료되었습니다.' +
      sLineBreak + sLineBreak + IngredientShortageWarnings +
      sLineBreak + sLineBreak + '재고관리에서 원재료 입고를 등록해 주세요.',
      mtWarning, [mbOK], 0);
  try
    TReceiptPrinter.PrintReceipt(dmDatabase.Connection, FStoreID, OrderID);
  except
    on E: Exception do
      MessageDlg('결제는 완료되었지만 영수증 출력에 실패했습니다.' + sLineBreak +
        E.Message + sLineBreak + '영수증 재출력 버튼으로 다시 시도해 주세요.',
        mtWarning, [mbOK], 0);
  end;

  if MethodCode = 'CASH' then
  begin
    try
      TCashDrawer.OpenIfEnabled;
    except
      on E: Exception do
        MessageDlg('결제는 완료되었지만 돈통 열기에 실패했습니다.' + sLineBreak +
          E.Message + sLineBreak + '돈통 연결 및 [CashDrawer] 설정을 확인해 주세요.',
          mtWarning, [mbOK], 0);
    end;
  end;

  MessageDlg('결제가 완료되었습니다.' + sLineBreak +
    '주문번호: ' + OrderNo + sLineBreak +
    '결제수단: ' + IfThen(MethodCode = 'CASH', '현금', '카드') + sLineBreak +
    '결제금액: ' + FormatCurr('#,##0', RemainingAmount) + '원' +
    IfThen(MethodCode = 'CASH', sLineBreak + '거스름돈: ' +
      FormatCurr('#,##0', ReceivedAmount - RemainingAmount) + '원', ''),
    mtInformation, [mbOK], 0);

  { 결제 완료 후 주문 편집 상태를 초기화하고 테이블 현황으로 복귀한다. }
  SetLength(FCart, 0);
  SetLength(FLoadedOrderItemIDs, 0);
  FLoadedOrderID := 0;
  FLoadOrderButton.Caption := '주문내역';
  FTableNameLabel.Caption := '';
  RefreshCart;
  LoadTables;
  FSalesPanel.Visible := False;
  FTablePanel.Visible := True;
  FTablePanel.BringToFront;
end;

procedure TfrmSales.SaveOrder;
var
  OrderID, OrderItemID, KitchenTicketID: Int64;
  OrderNo: string;
  Q: TFDQuery;
  I, J: Integer;
  Total, ExistingTotal: Currency;
  CustomerCount: Integer;
  IsExistingOrder, HasKitchenChanges, ItemFound: Boolean;
begin
  CustomerCount := StrToIntDef(Trim(FCustomerCountEdit.Text), 0);
  if CustomerCount < 1 then
    raise Exception.Create('방문 인원은 1명 이상 입력해 주세요.');
  if SelectedTableID = 0 then
    raise Exception.Create('먼저 테이블을 선택해 주세요.');
  if Length(FCart) = 0 then
    raise Exception.Create('주문 상품을 모두 삭제할 수 없습니다. 주문 취소 기능을 이용해 주세요.');

  Total := CartTotal;
  ExistingTotal := 0;
  IsExistingOrder := False;
  HasKitchenChanges := False;
  OrderID := 0;
  KitchenTicketID := 0;
  dmDatabase.Connection.StartTransaction;
  try
    Q := TFDQuery.Create(nil);
    try
      Q.Connection := dmDatabase.Connection;
      Q.SQL.Text := 'SELECT TABLE_ID FROM POS_TABLE ' +
        'WHERE STORE_ID=:STORE_ID AND TABLE_ID=:TABLE_ID WITH LOCK';
      Q.ParamByName('STORE_ID').AsInteger := FStoreID;
      Q.ParamByName('TABLE_ID').AsInteger := SelectedTableID;
      Q.Open;
      if Q.IsEmpty then
        raise Exception.Create('선택한 테이블을 찾을 수 없거나 다른 매장에 속해 있습니다.');
      Q.Close;

      Q.SQL.Text := 'SELECT FIRST 1 ORDER_ID, ORDER_NO, TOTAL_AMOUNT FROM POS_ORDER ' +
        'WHERE STORE_ID=:STORE_ID AND TABLE_ID=:TABLE_ID ' +
        'AND ORDER_TYPE=''DINE_IN'' AND ORDER_STATUS=''OPEN'' ' +
        'ORDER BY ORDERED_AT DESC WITH LOCK';
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

      if IsExistingOrder and (FLoadedOrderID = 0) then
        Total := ExistingTotal + Total;

      if FLoadedOrderID > 0 then
      begin
        if (not IsExistingOrder) or (OrderID <> FLoadedOrderID) then
          raise Exception.Create('불러온 주문이 다른 단말에서 변경되었거나 종료되었습니다. 주문내역을 다시 불러와 주세요.');
      end;

      if not IsExistingOrder then
      begin
        OrderID := NextSequenceValue('GEN_POS_ORDER_ID');
        OrderNo := FormatDateTime('yyyymmddhhnnss', Now) + '-' +
          FormatFloat('000000', OrderID);
        Q.SQL.Text := 'INSERT INTO POS_ORDER ' +
          '(ORDER_ID, STORE_ID, TABLE_ID, ORDER_NO, ORDER_TYPE, ORDER_STATUS, TOTAL_AMOUNT, ' +
          'EMPLOYEE_ID, TERMINAL_ID, CUSTOMER_COUNT, ORDERER_NAME, UPDATED_AT) ' +
          'VALUES (:ORDER_ID, :STORE_ID, :TABLE_ID, :ORDER_NO, ''DINE_IN'', ''OPEN'', :TOTAL, ' +
          ':EMPLOYEE_ID, :TERMINAL_ID, :CUSTOMER_COUNT, :ORDERER_NAME, CURRENT_TIMESTAMP)';
        Q.ParamByName('ORDER_ID').AsLargeInt := OrderID;
        Q.ParamByName('STORE_ID').AsInteger := FStoreID;
        Q.ParamByName('TABLE_ID').AsInteger := SelectedTableID;
        Q.ParamByName('ORDER_NO').AsString := OrderNo;
        Q.ParamByName('TOTAL').AsCurrency := Total;
        Q.ParamByName('EMPLOYEE_ID').AsInteger := FEmployeeID;
        Q.ParamByName('TERMINAL_ID').AsInteger := FTerminalID;
        Q.ParamByName('CUSTOMER_COUNT').AsInteger := CustomerCount;
        Q.ParamByName('ORDERER_NAME').AsString := Trim(FOrdererEdit.Text);
        Q.ExecSQL;
        HasKitchenChanges := True;
      end
      else if FLoadedOrderID = 0 then
      begin
        // 기존 주문내역을 불러오지 않은 경우에는 현재 동작과 같이 새 메뉴만 추가한다.
        HasKitchenChanges := True;
      end;

      if FLoadedOrderID > 0 then
      begin
        // Remove persisted lines deleted from the editable order list.
        for I := 0 to High(FLoadedOrderItemIDs) do
        begin
          ItemFound := False;
          for J := 0 to High(FCart) do
            if FCart[J].IsPersisted and
              (FCart[J].OrderItemID = FLoadedOrderItemIDs[I]) then
            begin
              ItemFound := True;
              Break;
            end;
          if not ItemFound then
          begin
            Q.SQL.Text := 'DELETE FROM POS_ORDER_ITEM ' +
              'WHERE ORDER_ID=:ORDER_ID AND ORDER_ITEM_ID=:ITEM_ID';
            Q.ParamByName('ORDER_ID').AsLargeInt := OrderID;
            Q.ParamByName('ITEM_ID').AsLargeInt := FLoadedOrderItemIDs[I];
            Q.ExecSQL;
          end;
        end;

        for I := 0 to High(FCart) do
          if not FCart[I].IsPersisted then
            HasKitchenChanges := True;
      end;

      if HasKitchenChanges then
      begin
        KitchenTicketID := NextSequenceValue('GEN_POS_KITCHEN_TICKET_ID');
        Q.SQL.Text := 'INSERT INTO POS_KITCHEN_TICKET ' +
          '(KITCHEN_TICKET_ID, ORDER_ID, TICKET_NO, STATUS) ' +
          'VALUES (:TICKET_ID, :ORDER_ID, :TICKET_NO, ''NEW'')';
        Q.ParamByName('TICKET_ID').AsLargeInt := KitchenTicketID;
        Q.ParamByName('ORDER_ID').AsLargeInt := OrderID;
        Q.ParamByName('TICKET_NO').AsString := OrderNo + '-' +
          FormatFloat('000000', KitchenTicketID);
        Q.ExecSQL;
      end;

      for I := 0 to High(FCart) do
      begin
        if FLoadedOrderID > 0 then
        begin
          if FCart[I].IsPersisted then
          begin
            if FCart[I].Quantity <> FCart[I].OriginalQuantity then
            begin
              Q.SQL.Text := 'UPDATE POS_ORDER_ITEM SET QUANTITY=:QUANTITY, ' +
                'LINE_AMOUNT=:LINE_AMOUNT ' +
                'WHERE ORDER_ID=:ORDER_ID AND ORDER_ITEM_ID=:ITEM_ID';
              Q.ParamByName('QUANTITY').AsInteger := FCart[I].Quantity;
              Q.ParamByName('LINE_AMOUNT').AsCurrency := FCart[I].UnitPrice * FCart[I].Quantity;
              Q.ParamByName('ORDER_ID').AsLargeInt := OrderID;
              Q.ParamByName('ITEM_ID').AsLargeInt := FCart[I].OrderItemID;
              Q.ExecSQL;
            end;
          end
          else
          begin
            OrderItemID := NextSequenceValue('GEN_POS_ORDER_ITEM_ID');
            Q.SQL.Text := 'INSERT INTO POS_ORDER_ITEM ' +
              '(ORDER_ITEM_ID, ORDER_ID, MENU_ID, MENU_NAME, UNIT_PRICE, QUANTITY, LINE_AMOUNT, OPTION_TEXT, OPTION_AMOUNT, KITCHEN_TICKET_ID) ' +
              'VALUES (:ITEM_ID, :ORDER_ID, :MENU_ID, :MENU_NAME, :UNIT_PRICE, :QUANTITY, :LINE_AMOUNT, :OPTION_TEXT, :OPTION_AMOUNT, :TICKET_ID)';
            Q.ParamByName('ITEM_ID').AsLargeInt := OrderItemID;
            Q.ParamByName('ORDER_ID').AsLargeInt := OrderID;
            Q.ParamByName('MENU_ID').AsInteger := FCart[I].MenuID;
            Q.ParamByName('MENU_NAME').AsString := FCart[I].MenuName;
            Q.ParamByName('UNIT_PRICE').AsCurrency := FCart[I].UnitPrice;
            Q.ParamByName('QUANTITY').AsInteger := FCart[I].Quantity;
            Q.ParamByName('LINE_AMOUNT').AsCurrency := FCart[I].UnitPrice * FCart[I].Quantity;
            Q.ParamByName('OPTION_TEXT').AsString := FCart[I].OptionText;
            Q.ParamByName('OPTION_AMOUNT').AsCurrency := FCart[I].OptionAmount;
            Q.ParamByName('TICKET_ID').AsLargeInt := KitchenTicketID;
            Q.ExecSQL;
          end;
        end
        else
        begin
          OrderItemID := NextSequenceValue('GEN_POS_ORDER_ITEM_ID');
          Q.SQL.Text := 'INSERT INTO POS_ORDER_ITEM ' +
            '(ORDER_ITEM_ID, ORDER_ID, MENU_ID, MENU_NAME, UNIT_PRICE, QUANTITY, LINE_AMOUNT, OPTION_TEXT, OPTION_AMOUNT, KITCHEN_TICKET_ID) ' +
            'VALUES (:ITEM_ID, :ORDER_ID, :MENU_ID, :MENU_NAME, :UNIT_PRICE, :QUANTITY, :LINE_AMOUNT, :OPTION_TEXT, :OPTION_AMOUNT, :TICKET_ID)';
          Q.ParamByName('ITEM_ID').AsLargeInt := OrderItemID;
          Q.ParamByName('ORDER_ID').AsLargeInt := OrderID;
          Q.ParamByName('MENU_ID').AsInteger := FCart[I].MenuID;
          Q.ParamByName('MENU_NAME').AsString := FCart[I].MenuName;
          Q.ParamByName('UNIT_PRICE').AsCurrency := FCart[I].UnitPrice;
          Q.ParamByName('QUANTITY').AsInteger := FCart[I].Quantity;
          Q.ParamByName('LINE_AMOUNT').AsCurrency := FCart[I].UnitPrice * FCart[I].Quantity;
          Q.ParamByName('OPTION_TEXT').AsString := FCart[I].OptionText;
          Q.ParamByName('OPTION_AMOUNT').AsCurrency := FCart[I].OptionAmount;
          Q.ParamByName('TICKET_ID').AsLargeInt := KitchenTicketID;
          Q.ExecSQL;
        end;
      end;

      Q.SQL.Text := 'UPDATE POS_ORDER SET TOTAL_AMOUNT=:TOTAL, ' +
        'CUSTOMER_COUNT=:CUSTOMER_COUNT, ORDERER_NAME=:ORDERER_NAME, ' +
        'EMPLOYEE_ID=COALESCE(EMPLOYEE_ID,:EMPLOYEE_ID), ' +
        'TERMINAL_ID=COALESCE(TERMINAL_ID,:TERMINAL_ID), UPDATED_AT=CURRENT_TIMESTAMP ' +
        'WHERE STORE_ID=:STORE_ID AND ORDER_ID=:ORDER_ID';
      Q.ParamByName('TOTAL').AsCurrency := Total;
      Q.ParamByName('CUSTOMER_COUNT').AsInteger := StrToIntDef(Trim(FCustomerCountEdit.Text), 1);
      Q.ParamByName('ORDERER_NAME').AsString := Trim(FOrdererEdit.Text);
      Q.ParamByName('EMPLOYEE_ID').AsInteger := FEmployeeID;
      Q.ParamByName('TERMINAL_ID').AsInteger := FTerminalID;
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

  SetLength(FCart, 0);
  SetLength(FLoadedOrderItemIDs, 0);
  FLoadedOrderID := 0;
  FLoadOrderButton.Caption := '주문내역';
  RefreshCart;
  UpdateTableStatus;
  if KitchenTicketID > 0 then
  begin
    try
      TKitchenPrinter.PrintTicket(dmDatabase.Connection, FStoreID, KitchenTicketID);
    except
      on E: Exception do
        MessageDlg('주문은 저장되었지만 주방 주문서 출력에 실패했습니다.' +
          sLineBreak + E.Message + sLineBreak +
          '주방 주문현황에서 해당 주문서를 선택해 재출력해 주세요.',
          mtWarning, [mbOK], 0);
    end;
  end;
  MessageDlg('주문이 정상적으로 저장되었습니다.' + sLineBreak +
    '주문번호: ' + OrderNo + sLineBreak +
    '주문 합계: ' + FormatCurr('#,##0', Total) + '원',
    mtInformation, [mbOK], 0);
end;

end.
