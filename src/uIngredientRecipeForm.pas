unit uIngredientRecipeForm;

interface

uses
  System.SysUtils, System.Classes, System.Math, System.UITypes, Data.DB,
  FireDAC.Comp.Client, FireDAC.Stan.Param,
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Grids,
  Vcl.Dialogs, Vcl.Graphics;

type
  TfrmIngredientRecipe = class(TForm)
  private
    FStoreID: Integer;
    FEmployeeID: Integer;
    FIngredientGrid: TStringGrid;
    FRecipeGrid: TStringGrid;
    FNameEdit: TEdit;
    FUnitCombo: TComboBox;
    FLowStockEdit: TEdit;
    FMenuCombo: TComboBox;
    FIngredientCombo: TComboBox;
    FRecipeQtyEdit: TEdit;
    FSelectedIngredientID: Int64;
    procedure BuildUI;
    procedure RefreshIngredients;
    procedure RefreshMenus;
    procedure RefreshRecipes;
    procedure IngredientGridClick(Sender: TObject);
    procedure MenuChanged(Sender: TObject);
    procedure ClearIngredient;
    procedure SaveIngredientClick(Sender: TObject);
    procedure DisableIngredientClick(Sender: TObject);
    procedure AddRecipeClick(Sender: TObject);
    procedure DeleteRecipeClick(Sender: TObject);
    function NextID(const ASequenceName: string): Int64;
    function ComboID(ACombo: TComboBox): Int64;
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetContext(AStoreID, AEmployeeID: Integer);
  end;

implementation

uses
  uDatabase;

function NewIngredientQuery: TFDQuery;
begin
  Result := TFDQuery.Create(nil);
  Result.Connection := dmDatabase.Connection;
end;

constructor TfrmIngredientRecipe.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  BuildUI;
end;

procedure TfrmIngredientRecipe.SetContext(AStoreID, AEmployeeID: Integer);
begin
  FStoreID := AStoreID;
  FEmployeeID := AEmployeeID;
  if (FStoreID <= 0) or (FEmployeeID <= 0) then
    raise Exception.Create('매장 및 로그인 직원 정보를 확인해 주세요.');
  RefreshIngredients;
  RefreshMenus;
  RefreshRecipes;
end;

procedure TfrmIngredientRecipe.BuildUI;
var
  Header, LeftPanel, RightPanel, EntryPanel, RecipeEntry: TPanel;
  L: TLabel;
  B: TButton;
begin
  Caption := '원재료 및 메뉴 레시피 관리';
  Font.Name := '맑은 고딕';
  Position := poScreenCenter;
  Width := 1240;
  Height := 760;

  Header := TPanel.Create(Self);
  Header.Parent := Self;
  Header.Align := alTop;
  Header.Height := 58;
  Header.BevelOuter := bvNone;
  L := TLabel.Create(Self);
  L.Parent := Header;
  L.SetBounds(16, 15, 900, 30);
  L.Caption := '원재료를 등록하고 메뉴 1개당 필요한 사용량을 레시피로 설정합니다.';
  L.Font.Name := Font.Name;
  L.Font.Size := 13;
  L.Font.Style := [fsBold];

  LeftPanel := TPanel.Create(Self);
  LeftPanel.Parent := Self;
  LeftPanel.Align := alLeft;
  LeftPanel.Width := 570;
  LeftPanel.BevelOuter := bvLowered;

  RightPanel := TPanel.Create(Self);
  RightPanel.Parent := Self;
  RightPanel.Align := alClient;
  RightPanel.BevelOuter := bvNone;

  EntryPanel := TPanel.Create(Self);
  EntryPanel.Parent := LeftPanel;
  EntryPanel.Align := alTop;
  EntryPanel.Height := 148;
  EntryPanel.BevelOuter := bvNone;

  L := TLabel.Create(Self);
  L.Parent := EntryPanel;
  L.SetBounds(14, 12, 80, 22);
  L.Caption := '원재료명';
  FNameEdit := TEdit.Create(Self);
  FNameEdit.Parent := EntryPanel;
  FNameEdit.SetBounds(96, 8, 220, 28);
  FNameEdit.TextHint := '예: 돼지고기';

  L := TLabel.Create(Self);
  L.Parent := EntryPanel;
  L.SetBounds(330, 12, 55, 22);
  L.Caption := '단위';
  FUnitCombo := TComboBox.Create(Self);
  FUnitCombo.Parent := EntryPanel;
  FUnitCombo.SetBounds(386, 8, 145, 28);
  FUnitCombo.Style := csDropDownList;
  FUnitCombo.Items.Add('g');
  FUnitCombo.Items.Add('kg');
  FUnitCombo.Items.Add('ml');
  FUnitCombo.Items.Add('L');
  FUnitCombo.Items.Add('개');
  FUnitCombo.Items.Add('봉');
  FUnitCombo.Items.Add('팩');
  FUnitCombo.ItemIndex := 0;

  L := TLabel.Create(Self);
  L.Parent := EntryPanel;
  L.SetBounds(14, 52, 80, 22);
  L.Caption := '안전재고';
  FLowStockEdit := TEdit.Create(Self);
  FLowStockEdit.Parent := EntryPanel;
  FLowStockEdit.SetBounds(96, 48, 140, 28);
  FLowStockEdit.Text := '0';
  L := TLabel.Create(Self);
  L.Parent := EntryPanel;
  L.SetBounds(245, 52, 270, 22);
  L.Caption := '수량은 위에서 선택한 단위 기준으로 입력';

  B := TButton.Create(Self);
  B.Parent := EntryPanel;
  B.SetBounds(96, 94, 110, 34);
  B.Caption := '신규 등록';
  B.OnClick := SaveIngredientClick;
  B := TButton.Create(Self);
  B.Parent := EntryPanel;
  B.SetBounds(216, 94, 110, 34);
  B.Caption := '입력 초기화';
  B.OnClick := procedure(Sender: TObject) begin ClearIngredient; end;
  B := TButton.Create(Self);
  B.Parent := EntryPanel;
  B.SetBounds(336, 94, 110, 34);
  B.Caption := '사용 중지';
  B.OnClick := DisableIngredientClick;

  FIngredientGrid := TStringGrid.Create(Self);
  FIngredientGrid.Parent := LeftPanel;
  FIngredientGrid.Align := alClient;
  FIngredientGrid.FixedRows := 1;
  FIngredientGrid.FixedCols := 0;
  FIngredientGrid.ColCount := 6;
  FIngredientGrid.RowCount := 2;
  FIngredientGrid.DefaultRowHeight := 27;
  FIngredientGrid.Options := FIngredientGrid.Options + [goRowSelect, goColSizing];
  FIngredientGrid.Cells[0,0] := 'ID';
  FIngredientGrid.Cells[1,0] := '원재료명';
  FIngredientGrid.Cells[2,0] := '단위';
  FIngredientGrid.Cells[3,0] := '현재고';
  FIngredientGrid.Cells[4,0] := '안전재고';
  FIngredientGrid.Cells[5,0] := '평균단가';
  FIngredientGrid.ColWidths[0] := 0;
  FIngredientGrid.ColWidths[1] := 180;
  FIngredientGrid.ColWidths[2] := 55;
  FIngredientGrid.ColWidths[3] := 90;
  FIngredientGrid.ColWidths[4] := 90;
  FIngredientGrid.ColWidths[5] := 100;
  FIngredientGrid.OnClick := IngredientGridClick;

  L := TLabel.Create(Self);
  L.Parent := RightPanel;
  L.SetBounds(18, 16, 90, 22);
  L.Caption := '대상 메뉴';
  FMenuCombo := TComboBox.Create(Self);
  FMenuCombo.Parent := RightPanel;
  FMenuCombo.SetBounds(110, 12, 360, 28);
  FMenuCombo.Style := csDropDownList;
  FMenuCombo.OnChange := MenuChanged;

  RecipeEntry := TPanel.Create(Self);
  RecipeEntry.Parent := RightPanel;
  RecipeEntry.Align := alTop;
  RecipeEntry.SetBounds(0, 50, 650, 94);
  RecipeEntry.Height := 94;
  RecipeEntry.BevelOuter := bvNone;

  L := TLabel.Create(Self);
  L.Parent := RecipeEntry;
  L.SetBounds(18, 12, 80, 22);
  L.Caption := '원재료';
  FIngredientCombo := TComboBox.Create(Self);
  FIngredientCombo.Parent := RecipeEntry;
  FIngredientCombo.SetBounds(110, 8, 250, 28);
  FIngredientCombo.Style := csDropDownList;

  L := TLabel.Create(Self);
  L.Parent := RecipeEntry;
  L.SetBounds(375, 12, 65, 22);
  L.Caption := '사용량';
  FRecipeQtyEdit := TEdit.Create(Self);
  FRecipeQtyEdit.Parent := RecipeEntry;
  FRecipeQtyEdit.SetBounds(440, 8, 100, 28);
  FRecipeQtyEdit.TextHint := '예: 150';

  B := TButton.Create(Self);
  B.Parent := RecipeEntry;
  B.SetBounds(110, 48, 130, 34);
  B.Caption := '레시피 추가';
  B.OnClick := AddRecipeClick;
  B := TButton.Create(Self);
  B.Parent := RecipeEntry;
  B.SetBounds(250, 48, 130, 34);
  B.Caption := '선택 레시피 삭제';
  B.OnClick := DeleteRecipeClick;

  FRecipeGrid := TStringGrid.Create(Self);
  FRecipeGrid.Parent := RightPanel;
  FRecipeGrid.Align := alClient;
  FRecipeGrid.FixedRows := 1;
  FRecipeGrid.FixedCols := 0;
  FRecipeGrid.ColCount := 4;
  FRecipeGrid.RowCount := 2;
  FRecipeGrid.DefaultRowHeight := 28;
  FRecipeGrid.Options := FRecipeGrid.Options + [goRowSelect, goColSizing];
  FRecipeGrid.Cells[0,0] := '레시피ID';
  FRecipeGrid.Cells[1,0] := '원재료명';
  FRecipeGrid.Cells[2,0] := '사용량';
  FRecipeGrid.Cells[3,0] := '단위';
  FRecipeGrid.ColWidths[0] := 0;
  FRecipeGrid.ColWidths[1] := 250;
  FRecipeGrid.ColWidths[2] := 120;
  FRecipeGrid.ColWidths[3] := 80;

  B := TButton.Create(Self);
  B.Parent := Self;
  B.Align := alBottom;
  B.Height := 48;
  B.Caption := '닫기';
  B.ModalResult := mrClose;
end;

function TfrmIngredientRecipe.NextID(const ASequenceName: string): Int64;
var
  Q: TFDQuery;
begin
  Q := NewIngredientQuery;
  try
    Q.SQL.Text := 'SELECT GEN_ID(' + ASequenceName + ', 1) FROM RDB$DATABASE';
    Q.Open;
    Result := Q.Fields[0].AsLargeInt;
  finally
    Q.Free;
  end;
end;

function TfrmIngredientRecipe.ComboID(ACombo: TComboBox): Int64;
var
  S: string;
  P: Integer;
begin
  Result := 0;
  if ACombo.ItemIndex < 0 then Exit;
  S := ACombo.Items[ACombo.ItemIndex];
  P := Pos(' | ', S);
  if (P > 1) then
    TryStrToInt64(Copy(S, 1, P - 1), Result);
end;

procedure TfrmIngredientRecipe.RefreshIngredients;
var
  Q: TFDQuery;
  R: Integer;
begin
  Q := NewIngredientQuery;
  try
    Q.SQL.Text := 'SELECT INGREDIENT_ID, INGREDIENT_NAME, UNIT_CODE, STOCK_QTY, ' +
      'LOW_STOCK_QTY, AVG_UNIT_COST FROM POS_INGREDIENT ' +
      'WHERE STORE_ID=:STORE_ID AND ACTIVE_YN=''Y'' ORDER BY INGREDIENT_NAME';
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.Open;
    FIngredientGrid.RowCount := Max(2, Q.RecordCount + 1);
    FIngredientCombo.Items.Clear;
    R := 1;
    while not Q.Eof do
    begin
      FIngredientGrid.Cells[0,R] := Q.FieldByName('INGREDIENT_ID').AsString;
      FIngredientGrid.Cells[1,R] := Q.FieldByName('INGREDIENT_NAME').AsString;
      FIngredientGrid.Cells[2,R] := Q.FieldByName('UNIT_CODE').AsString;
      FIngredientGrid.Cells[3,R] := FormatFloat('#,##0.###', Q.FieldByName('STOCK_QTY').AsFloat);
      FIngredientGrid.Cells[4,R] := FormatFloat('#,##0.###', Q.FieldByName('LOW_STOCK_QTY').AsFloat);
      FIngredientGrid.Cells[5,R] := FormatCurr('#,##0.0000', Q.FieldByName('AVG_UNIT_COST').AsCurrency);
      FIngredientCombo.Items.Add(Q.FieldByName('INGREDIENT_ID').AsString + ' | ' +
        Q.FieldByName('INGREDIENT_NAME').AsString);
      Inc(R);
      Q.Next;
    end;
    if FIngredientCombo.Items.Count > 0 then FIngredientCombo.ItemIndex := 0;
    if R = 1 then FIngredientGrid.Cells[1,1] := '등록된 원재료가 없습니다.';
  finally
    Q.Free;
  end;
end;

procedure TfrmIngredientRecipe.RefreshMenus;
var
  Q: TFDQuery;
begin
  Q := NewIngredientQuery;
  try
    Q.SQL.Text := 'SELECT MENU_ID, MENU_NAME FROM MENU_ITEM ' +
      'WHERE STORE_ID=:STORE_ID AND ACTIVE_YN=''Y'' ORDER BY MENU_NAME';
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.Open;
    FMenuCombo.Items.Clear;
    while not Q.Eof do
    begin
      FMenuCombo.Items.Add(Q.FieldByName('MENU_ID').AsString + ' | ' +
        Q.FieldByName('MENU_NAME').AsString);
      Q.Next;
    end;
    if FMenuCombo.Items.Count > 0 then FMenuCombo.ItemIndex := 0;
  finally
    Q.Free;
  end;
end;

procedure TfrmIngredientRecipe.RefreshRecipes;
var
  Q: TFDQuery;
  R: Integer;
  MenuID: Int64;
begin
  FRecipeGrid.RowCount := 2;
  FRecipeGrid.Cells[1,1] := '';
  MenuID := ComboID(FMenuCombo);
  if MenuID <= 0 then Exit;
  Q := NewIngredientQuery;
  try
    Q.SQL.Text := 'SELECT R.RECIPE_ID, I.INGREDIENT_NAME, R.QUANTITY, I.UNIT_CODE ' +
      'FROM POS_MENU_RECIPE R JOIN POS_INGREDIENT I ON I.INGREDIENT_ID=R.INGREDIENT_ID ' +
      'WHERE R.STORE_ID=:STORE_ID AND R.MENU_ID=:MENU_ID ' +
      'ORDER BY I.INGREDIENT_NAME';
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.ParamByName('MENU_ID').AsLargeInt := MenuID;
    Q.Open;
    FRecipeGrid.RowCount := Max(2, Q.RecordCount + 1);
    R := 1;
    while not Q.Eof do
    begin
      FRecipeGrid.Cells[0,R] := Q.FieldByName('RECIPE_ID').AsString;
      FRecipeGrid.Cells[1,R] := Q.FieldByName('INGREDIENT_NAME').AsString;
      FRecipeGrid.Cells[2,R] := FormatFloat('#,##0.####', Q.FieldByName('QUANTITY').AsFloat);
      FRecipeGrid.Cells[3,R] := Q.FieldByName('UNIT_CODE').AsString;
      Inc(R);
      Q.Next;
    end;
    if R = 1 then FRecipeGrid.Cells[1,1] := '등록된 레시피가 없습니다.';
  finally
    Q.Free;
  end;
end;

procedure TfrmIngredientRecipe.IngredientGridClick(Sender: TObject);
var
  ID: Int64;
begin
  if (FIngredientGrid.Row < 1) or
    not TryStrToInt64(FIngredientGrid.Cells[0,FIngredientGrid.Row], ID) then Exit;
  FSelectedIngredientID := ID;
  FNameEdit.Text := FIngredientGrid.Cells[1,FIngredientGrid.Row];
  FUnitCombo.ItemIndex := FUnitCombo.Items.IndexOf(FIngredientGrid.Cells[2,FIngredientGrid.Row]);
  FLowStockEdit.Text := FIngredientGrid.Cells[4,FIngredientGrid.Row];
end;

procedure TfrmIngredientRecipe.ClearIngredient;
begin
  FSelectedIngredientID := 0;
  FNameEdit.Clear;
  FUnitCombo.ItemIndex := 0;
  FLowStockEdit.Text := '0';
end;

procedure TfrmIngredientRecipe.SaveIngredientClick(Sender: TObject);
var
  Q: TFDQuery;
  LowQty: Double;
  ID: Int64;
begin
  try
    if Trim(FNameEdit.Text) = '' then
      raise Exception.Create('원재료명을 입력해 주세요.');
    if FUnitCombo.ItemIndex < 0 then
      raise Exception.Create('재고 단위를 선택해 주세요.');
    if not TryStrToFloat(Trim(FLowStockEdit.Text), LowQty) or (LowQty < 0) then
      raise Exception.Create('안전재고는 0 이상의 숫자로 입력해 주세요.');
    Q := NewIngredientQuery;
    try
      if FSelectedIngredientID > 0 then
      begin
        Q.SQL.Text := 'UPDATE POS_INGREDIENT SET INGREDIENT_NAME=:NAME, ' +
          'UNIT_CODE=:UNIT, LOW_STOCK_QTY=:LOW_QTY, UPDATED_AT=CURRENT_TIMESTAMP ' +
          'WHERE STORE_ID=:STORE_ID AND INGREDIENT_ID=:ID AND ACTIVE_YN=''Y''';
        ID := FSelectedIngredientID;
      end
      else
      begin
        ID := NextID('GEN_POS_INGREDIENT_ID');
        Q.SQL.Text := 'INSERT INTO POS_INGREDIENT (INGREDIENT_ID, STORE_ID, ' +
          'INGREDIENT_NAME, UNIT_CODE, LOW_STOCK_QTY, CREATED_BY) ' +
          'VALUES (:ID, :STORE_ID, :NAME, :UNIT, :LOW_QTY, :EMPLOYEE_ID)';
        Q.ParamByName('EMPLOYEE_ID').AsInteger := FEmployeeID;
      end;
      Q.ParamByName('ID').AsLargeInt := ID;
      Q.ParamByName('STORE_ID').AsInteger := FStoreID;
      Q.ParamByName('NAME').AsString := Trim(FNameEdit.Text);
      Q.ParamByName('UNIT').AsString := FUnitCombo.Text;
      Q.ParamByName('LOW_QTY').AsFloat := LowQty;
      Q.ExecSQL;
    finally
      Q.Free;
    end;
    ClearIngredient;
    RefreshIngredients;
    MessageDlg('원재료 정보를 저장했습니다.', mtInformation, [mbOK], 0);
  except
    on E: Exception do
      MessageDlg('원재료 저장 실패: ' + E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TfrmIngredientRecipe.DisableIngredientClick(Sender: TObject);
var
  Q: TFDQuery;
begin
  if FSelectedIngredientID <= 0 then
  begin
    MessageDlg('사용 중지할 원재료를 목록에서 선택해 주세요.', mtWarning, [mbOK], 0);
    Exit;
  end;
  if MessageDlg('선택한 원재료를 사용 중지하시겠습니까?', mtConfirmation,
    [mbYes, mbNo], 0) <> mrYes then Exit;
  Q := NewIngredientQuery;
  try
    Q.SQL.Text := 'UPDATE POS_INGREDIENT SET ACTIVE_YN=''N'', UPDATED_AT=CURRENT_TIMESTAMP ' +
      'WHERE STORE_ID=:STORE_ID AND INGREDIENT_ID=:ID AND ACTIVE_YN=''Y''';
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.ParamByName('ID').AsLargeInt := FSelectedIngredientID;
    Q.ExecSQL;
    ClearIngredient;
    RefreshIngredients;
    RefreshRecipes;
  except
    on E: Exception do
      MessageDlg('원재료 사용 중지 실패: ' + E.Message, mtError, [mbOK], 0);
  end;
  Q.Free;
end;

procedure TfrmIngredientRecipe.MenuChanged(Sender: TObject);
begin
  RefreshRecipes;
end;

procedure TfrmIngredientRecipe.AddRecipeClick(Sender: TObject);
var
  Q: TFDQuery;
  MenuID, IngredientID, RecipeID: Int64;
  Qty: Double;
begin
  try
    MenuID := ComboID(FMenuCombo);
    IngredientID := ComboID(FIngredientCombo);
    if MenuID <= 0 then raise Exception.Create('메뉴를 선택해 주세요.');
    if IngredientID <= 0 then raise Exception.Create('원재료를 선택해 주세요.');
    if not TryStrToFloat(Trim(FRecipeQtyEdit.Text), Qty) or (Qty <= 0) then
      raise Exception.Create('사용량은 0보다 큰 숫자로 입력해 주세요.');
    RecipeID := NextID('GEN_POS_MENU_RECIPE_ID');
    Q := NewIngredientQuery;
    try
      Q.SQL.Text := 'INSERT INTO POS_MENU_RECIPE (RECIPE_ID, STORE_ID, MENU_ID, ' +
        'INGREDIENT_ID, QUANTITY, CREATED_BY) VALUES (:ID, :STORE_ID, :MENU_ID, ' +
        ':INGREDIENT_ID, :QTY, :EMPLOYEE_ID)';
      Q.ParamByName('ID').AsLargeInt := RecipeID;
      Q.ParamByName('STORE_ID').AsInteger := FStoreID;
      Q.ParamByName('MENU_ID').AsLargeInt := MenuID;
      Q.ParamByName('INGREDIENT_ID').AsLargeInt := IngredientID;
      Q.ParamByName('QTY').AsFloat := Qty;
      Q.ParamByName('EMPLOYEE_ID').AsInteger := FEmployeeID;
      Q.ExecSQL;
    finally
      Q.Free;
    end;
    FRecipeQtyEdit.Clear;
    RefreshRecipes;
  except
    on E: Exception do
      MessageDlg('레시피 등록 실패: ' + E.Message +
        sLineBreak + '같은 메뉴에 동일한 원재료가 이미 등록되어 있는지 확인해 주세요.',
        mtError, [mbOK], 0);
  end;
end;

procedure TfrmIngredientRecipe.DeleteRecipeClick(Sender: TObject);
var
  Q: TFDQuery;
  RecipeID: Int64;
begin
  if (FRecipeGrid.Row < 1) or
    not TryStrToInt64(FRecipeGrid.Cells[0,FRecipeGrid.Row], RecipeID) then Exit;
  if MessageDlg('선택한 레시피를 삭제하시겠습니까?', mtConfirmation,
    [mbYes, mbNo], 0) <> mrYes then Exit;
  Q := NewIngredientQuery;
  try
    Q.SQL.Text := 'DELETE FROM POS_MENU_RECIPE WHERE STORE_ID=:STORE_ID AND RECIPE_ID=:ID';
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.ParamByName('ID').AsLargeInt := RecipeID;
    Q.ExecSQL;
    RefreshRecipes;
  except
    on E: Exception do
      MessageDlg('레시피 삭제 실패: ' + E.Message, mtError, [mbOK], 0);
  end;
  Q.Free;
end;

end.
