unit uIngredientPurchaseForm;

interface

uses
  System.SysUtils, System.Classes, System.Math, System.UITypes,
  Data.DB, FireDAC.Comp.Client, FireDAC.Stan.Param,
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Grids, Vcl.Dialogs, Vcl.ComCtrls, Vcl.Graphics;

type
  TfrmIngredientPurchase = class(TForm)
  private
    FStoreID: Integer;
    FEmployeeID: Integer;
    FSupplier: TComboBox;
    FDate: TDateTimePicker;
    FNote: TEdit;
    FIngredient: TComboBox;
    FQuantity: TEdit;
    FUnitCost: TEdit;
    FGrid: TStringGrid;
    FTotal: TLabel;
    procedure BuildUI;
    procedure LoadSuppliers;
    procedure LoadIngredients;
    procedure AddItemClick(Sender: TObject);
    procedure RemoveItemClick(Sender: TObject);
    procedure SaveClick(Sender: TObject);
    procedure UpdateTotal;
    function SelectedID(ACombo: TComboBox): Int64;
    function SavePurchase: Int64;
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetContext(AStoreID, AEmployeeID: Integer);
  end;

implementation

uses
  uDatabase;

function NewIngredientPurchaseQuery: TFDQuery;
begin
  Result := TFDQuery.Create(nil);
  Result.Connection := dmDatabase.Connection;
end;

function NextIngredientPurchaseID(const ASequenceName: string): Int64;
var
  Q: TFDQuery;
begin
  Q := NewIngredientPurchaseQuery;
  try
    Q.SQL.Text := 'SELECT GEN_ID(' + ASequenceName + ', 1) FROM RDB$DATABASE';
    Q.Open;
    Result := Q.Fields[0].AsLargeInt;
  finally
    Q.Free;
  end;
end;

constructor TfrmIngredientPurchase.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  BuildUI;
end;

procedure TfrmIngredientPurchase.BuildUI;
var
  Header, InputPanel, BottomPanel: TPanel;
  L: TLabel;
  B: TButton;
begin
  Caption := '원재료 구매 등록';
  Font.Name := '맑은 고딕';
  Position := poScreenCenter;
  Width := 980;
  Height := 680;

  Header := TPanel.Create(Self);
  Header.Parent := Self;
  Header.Align := alTop;
  Header.Height := 112;
  Header.BevelOuter := bvNone;

  L := TLabel.Create(Self);
  L.Parent := Header;
  L.SetBounds(16, 14, 70, 22);
  L.Caption := '거래처';
  FSupplier := TComboBox.Create(Self);
  FSupplier.Parent := Header;
  FSupplier.SetBounds(92, 10, 350, 28);
  FSupplier.Style := csDropDownList;

  L := TLabel.Create(Self);
  L.Parent := Header;
  L.SetBounds(470, 14, 70, 22);
  L.Caption := '구매일자';
  FDate := TDateTimePicker.Create(Self);
  FDate.Parent := Header;
  FDate.SetBounds(545, 10, 180, 28);
  FDate.Date := Date;

  L := TLabel.Create(Self);
  L.Parent := Header;
  L.SetBounds(16, 62, 70, 22);
  L.Caption := '비고';
  FNote := TEdit.Create(Self);
  FNote.Parent := Header;
  FNote.SetBounds(92, 58, 633, 28);

  InputPanel := TPanel.Create(Self);
  InputPanel.Parent := Self;
  InputPanel.Align := alTop;
  InputPanel.Height := 92;
  InputPanel.BevelOuter := bvNone;

  L := TLabel.Create(Self);
  L.Parent := InputPanel;
  L.SetBounds(16, 14, 70, 22);
  L.Caption := '원재료';
  FIngredient := TComboBox.Create(Self);
  FIngredient.Parent := InputPanel;
  FIngredient.SetBounds(92, 10, 300, 28);
  FIngredient.Style := csDropDownList;

  L := TLabel.Create(Self);
  L.Parent := InputPanel;
  L.SetBounds(410, 14, 45, 22);
  L.Caption := '수량';
  FQuantity := TEdit.Create(Self);
  FQuantity.Parent := InputPanel;
  FQuantity.SetBounds(458, 10, 100, 28);
  FQuantity.Text := '1';

  L := TLabel.Create(Self);
  L.Parent := InputPanel;
  L.SetBounds(575, 14, 70, 22);
  L.Caption := '단위 단가';
  FUnitCost := TEdit.Create(Self);
  FUnitCost.Parent := InputPanel;
  FUnitCost.SetBounds(648, 10, 120, 28);
  FUnitCost.Text := '0';

  B := TButton.Create(Self);
  B.Parent := InputPanel;
  B.SetBounds(790, 8, 150, 34);
  B.Caption := '구매 품목 추가';
  B.OnClick := AddItemClick;

  FGrid := TStringGrid.Create(Self);
  FGrid.Parent := Self;
  FGrid.Align := alClient;
  FGrid.FixedRows := 1;
  FGrid.FixedCols := 0;
  FGrid.ColCount := 6;
  FGrid.RowCount := 2;
  FGrid.DefaultRowHeight := 28;
  FGrid.Options := FGrid.Options + [goRowSelect, goColSizing];
  FGrid.Cells[0,0] := '원재료ID';
  FGrid.Cells[1,0] := '원재료명';
  FGrid.Cells[2,0] := '단위';
  FGrid.Cells[3,0] := '수량';
  FGrid.Cells[4,0] := '단위 단가';
  FGrid.Cells[5,0] := '금액';
  FGrid.ColWidths[0] := 0;
  FGrid.ColWidths[1] := 300;
  FGrid.ColWidths[2] := 80;
  FGrid.ColWidths[3] := 120;
  FGrid.ColWidths[4] := 150;
  FGrid.ColWidths[5] := 160;

  BottomPanel := TPanel.Create(Self);
  BottomPanel.Parent := Self;
  BottomPanel.Align := alBottom;
  BottomPanel.Height := 64;
  BottomPanel.BevelOuter := bvNone;

  B := TButton.Create(Self);
  B.Parent := BottomPanel;
  B.SetBounds(12, 12, 120, 38);
  B.Caption := '선택 품목 삭제';
  B.OnClick := RemoveItemClick;

  FTotal := TLabel.Create(Self);
  FTotal.Parent := BottomPanel;
  FTotal.SetBounds(300, 18, 330, 28);
  FTotal.Font.Style := [fsBold];
  FTotal.Font.Size := 11;
  FTotal.Caption := '합계: 0 원';

  B := TButton.Create(Self);
  B.Parent := BottomPanel;
  B.SetBounds(730, 12, 100, 38);
  B.Caption := '저장';
  B.OnClick := SaveClick;

  B := TButton.Create(Self);
  B.Parent := BottomPanel;
  B.SetBounds(840, 12, 100, 38);
  B.Caption := '닫기';
  B.ModalResult := mrCancel;
end;

procedure TfrmIngredientPurchase.SetContext(AStoreID, AEmployeeID: Integer);
begin
  FStoreID := AStoreID;
  FEmployeeID := AEmployeeID;
  if (FStoreID <= 0) or (FEmployeeID <= 0) then
    raise Exception.Create('매장 및 로그인 직원 정보를 확인해 주세요.');
  LoadSuppliers;
  LoadIngredients;
end;

procedure TfrmIngredientPurchase.LoadSuppliers;
var
  Q: TFDQuery;
begin
  FSupplier.Items.Clear;
  Q := NewIngredientPurchaseQuery;
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

procedure TfrmIngredientPurchase.LoadIngredients;
var
  Q: TFDQuery;
begin
  FIngredient.Items.Clear;
  Q := NewIngredientPurchaseQuery;
  try
    Q.SQL.Text := 'SELECT INGREDIENT_ID, INGREDIENT_NAME, UNIT_CODE FROM POS_INGREDIENT ' +
      'WHERE STORE_ID=:STORE_ID AND ACTIVE_YN=''Y'' ORDER BY INGREDIENT_NAME';
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.Open;
    while not Q.Eof do
    begin
      FIngredient.Items.Add(Q.FieldByName('INGREDIENT_ID').AsString + ' | ' +
        Q.FieldByName('INGREDIENT_NAME').AsString + ' (' +
        Q.FieldByName('UNIT_CODE').AsString + ')');
      Q.Next;
    end;
  finally
    Q.Free;
  end;
  if FIngredient.Items.Count > 0 then FIngredient.ItemIndex := 0;
end;

function TfrmIngredientPurchase.SelectedID(ACombo: TComboBox): Int64;
var
  S: string;
  P: Integer;
begin
  Result := 0;
  if ACombo.ItemIndex < 0 then Exit;
  S := ACombo.Items[ACombo.ItemIndex];
  P := Pos(' | ', S);
  if P > 1 then TryStrToInt64(Copy(S, 1, P - 1), Result);
end;

procedure TfrmIngredientPurchase.AddItemClick(Sender: TObject);
var
  ID: Int64;
  I, R, P: Integer;
  Qty: Double;
  Cost: Currency;
  S, NameText, UnitText: string;
begin
  ID := SelectedID(FIngredient);
  if ID <= 0 then
  begin
    MessageDlg('구매할 원재료를 선택해 주세요.', mtWarning, [mbOK], 0);
    Exit;
  end;
  if not TryStrToFloat(Trim(FQuantity.Text), Qty) or (Qty <= 0) then
  begin
    MessageDlg('수량은 0보다 큰 숫자로 입력해 주세요.', mtWarning, [mbOK], 0);
    Exit;
  end;
  if not TryStrToCurr(Trim(FUnitCost.Text), Cost) or (Cost < 0) then
  begin
    MessageDlg('단위 단가는 0 이상의 숫자로 입력해 주세요.', mtWarning, [mbOK], 0);
    Exit;
  end;
  for I := 1 to FGrid.RowCount - 1 do
    if (FGrid.Cells[0,I] <> '') and (StrToInt64Def(FGrid.Cells[0,I], 0) = ID) then
    begin
      MessageDlg('같은 원재료가 이미 목록에 있습니다. 기존 품목을 삭제한 후 다시 추가해 주세요.',
        mtWarning, [mbOK], 0);
      Exit;
    end;

  S := FIngredient.Items[FIngredient.ItemIndex];
  P := Pos(' | ', S);
  NameText := Copy(S, P + 3, MaxInt);
  UnitText := '';
  P := LastDelimiter('(', NameText);
  if (P > 0) and (Length(NameText) > P) and (NameText[Length(NameText)] = ')') then
  begin
    UnitText := Copy(NameText, P + 1, Length(NameText) - P - 1);
    NameText := Trim(Copy(NameText, 1, P - 1));
  end;

  R := FGrid.RowCount;
  if (R = 2) and (FGrid.Cells[1,1] = '') then R := 1;
  FGrid.RowCount := R + 1;
  FGrid.Cells[0,R] := IntToStr(ID);
  FGrid.Cells[1,R] := NameText;
  FGrid.Cells[2,R] := UnitText;
  FGrid.Cells[3,R] := FloatToStr(Qty);
  FGrid.Cells[4,R] := CurrToStr(Cost);
  FGrid.Cells[5,R] := FormatCurr('0.00', Qty * Cost);
  UpdateTotal;
end;

procedure TfrmIngredientPurchase.RemoveItemClick(Sender: TObject);
var
  R, I: Integer;
begin
  R := FGrid.Row;
  if (R < 1) or (R >= FGrid.RowCount) or (FGrid.Cells[0,R] = '') then Exit;
  for I := R to FGrid.RowCount - 2 do
    FGrid.Rows[I].Assign(FGrid.Rows[I + 1]);
  if FGrid.RowCount > 2 then
    FGrid.RowCount := FGrid.RowCount - 1
  else
    FGrid.Rows[1].Clear;
  UpdateTotal;
end;

procedure TfrmIngredientPurchase.UpdateTotal;
var
  I: Integer;
  Amount, Total: Currency;
begin
  Total := 0;
  for I := 1 to FGrid.RowCount - 1 do
    if TryStrToCurr(FGrid.Cells[5,I], Amount) then Total := Total + Amount;
  FTotal.Caption := '합계: ' + FormatCurr('#,##0.00', Total) + ' 원';
end;

function TfrmIngredientPurchase.SavePurchase: Int64;
var
  Q: TFDQuery;
  I, ItemCount: Integer;
  IngredientID: Int64;
  Qty: Double;
  UnitCost, LineAmount, Total: Currency;
  ItemID: Int64;
begin
  if SelectedID(FSupplier) <= 0 then
    raise Exception.Create('사용 중인 거래처를 선택해 주세요.');
  Total := 0;
  ItemCount := 0;
  for I := 1 to FGrid.RowCount - 1 do
    if StrToInt64Def(FGrid.Cells[0,I], 0) > 0 then
    begin
      Inc(ItemCount);
      if TryStrToCurr(FGrid.Cells[5,I], LineAmount) then Total := Total + LineAmount;
    end;
  if ItemCount = 0 then
    raise Exception.Create('구매 원재료를 한 개 이상 추가해 주세요.');

  dmDatabase.Connection.StartTransaction;
  try
    Result := NextIngredientPurchaseID('GEN_POS_PURCHASE_ID');
    Q := NewIngredientPurchaseQuery;
    try
      Q.SQL.Text := 'INSERT INTO POS_PURCHASE (PURCHASE_ID, STORE_ID, SUPPLIER_ID, ' +
        'PURCHASE_DATE, PURCHASE_STATUS, TOTAL_AMOUNT, NOTE, CREATED_BY) ' +
        'VALUES (:ID, :STORE_ID, :SUPPLIER_ID, :PURCHASE_DATE, ''DRAFT'', :TOTAL_AMOUNT, :NOTE, :CREATED_BY)';
      Q.ParamByName('ID').AsLargeInt := Result;
      Q.ParamByName('STORE_ID').AsInteger := FStoreID;
      Q.ParamByName('SUPPLIER_ID').AsInteger := SelectedID(FSupplier);
      Q.ParamByName('PURCHASE_DATE').AsDate := FDate.Date;
      Q.ParamByName('TOTAL_AMOUNT').AsCurrency := Total;
      Q.ParamByName('NOTE').AsString := Trim(FNote.Text);
      Q.ParamByName('CREATED_BY').AsInteger := FEmployeeID;
      Q.ExecSQL;

      for I := 1 to FGrid.RowCount - 1 do
      begin
        IngredientID := StrToInt64Def(FGrid.Cells[0,I], 0);
        if IngredientID <= 0 then Continue;
        if not TryStrToFloat(FGrid.Cells[3,I], Qty) or (Qty <= 0) then
          raise Exception.Create('구매 수량이 올바르지 않습니다.');
        if not TryStrToCurr(FGrid.Cells[4,I], UnitCost) or (UnitCost < 0) then
          raise Exception.Create('매입 단가가 올바르지 않습니다.');
        LineAmount := SimpleRoundTo(Qty * UnitCost, -2);
        ItemID := NextIngredientPurchaseID('GEN_POS_ING_PURCHASE_ITEM_ID');
        Q.SQL.Text := 'INSERT INTO POS_INGREDIENT_PURCHASE_ITEM ' +
          '(INGREDIENT_PURCHASE_ITEM_ID, STORE_ID, PURCHASE_ID, INGREDIENT_ID, QUANTITY, UNIT_COST, LINE_AMOUNT) ' +
          'VALUES (:ITEM_ID, :STORE_ID, :PURCHASE_ID, :INGREDIENT_ID, :QTY, :UNIT_COST, :LINE_AMOUNT)';
        Q.ParamByName('ITEM_ID').AsLargeInt := ItemID;
        Q.ParamByName('STORE_ID').AsInteger := FStoreID;
        Q.ParamByName('PURCHASE_ID').AsLargeInt := Result;
        Q.ParamByName('INGREDIENT_ID').AsLargeInt := IngredientID;
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

procedure TfrmIngredientPurchase.SaveClick(Sender: TObject);
begin
  try
    SavePurchase;
    MessageDlg('원재료 구매가 작성중 상태로 저장되었습니다. 구매관리에서 입고 확정해 주세요.',
      mtInformation, [mbOK], 0);
    ModalResult := mrOk;
  except
    on E: Exception do
      MessageDlg('원재료 구매 저장 실패: ' + E.Message, mtError, [mbOK], 0);
  end;
end;

end.
