unit uIngredientStocktakeForm;

interface

uses
  System.SysUtils, System.Classes, System.Math, Data.DB,
  FireDAC.Comp.Client, FireDAC.Stan.Param,
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Grids,
  Vcl.Dialogs, Vcl.Graphics;

type
  TfrmIngredientStocktake = class(TForm)
  private
    FStoreID: Integer;
    FEmployeeID: Integer;
    FGrid: TStringGrid;
    FReasonEdit: TEdit;
    FSummary: TLabel;
    procedure BuildUI;
    procedure LoadIngredients;
    procedure GridSetEditText(Sender: TObject; ACol, ARow: Integer;
      const Value: string);
    procedure SaveClick(Sender: TObject);
    procedure HistoryClick(Sender: TObject);
    function NewQuery: TFDQuery;
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetContext(AStoreID, AEmployeeID: Integer);
  end;

implementation

uses
  uDatabase;

constructor TfrmIngredientStocktake.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  BuildUI;
end;

function TfrmIngredientStocktake.NewQuery: TFDQuery;
begin
  Result := TFDQuery.Create(nil);
  Result.Connection := dmDatabase.Connection;
end;

procedure TfrmIngredientStocktake.SetContext(AStoreID, AEmployeeID: Integer);
begin
  FStoreID := AStoreID;
  FEmployeeID := AEmployeeID;
  if (FStoreID <= 0) or (FEmployeeID <= 0) then
    raise Exception.Create('매장 및 로그인 직원 정보를 확인해 주세요.');
  LoadIngredients;
end;

procedure TfrmIngredientStocktake.BuildUI;
var
  P: TPanel;
  L: TLabel;
  B: TButton;
begin
  Caption := '원재료 재고 실사 및 수량 조정';
  Font.Name := '맑은 고딕';
  Position := poScreenCenter;
  Width := 1050;
  Height := 700;

  P := TPanel.Create(Self);
  P.Parent := Self;
  P.Align := alTop;
  P.Height := 92;
  P.BevelOuter := bvNone;

  L := TLabel.Create(Self);
  L.Parent := P;
  L.SetBounds(14, 10, 900, 22);
  L.Caption := '실사수량을 입력하면 장부재고와 차이가 자동 계산됩니다. 저장 시 재고 및 조정 이력이 함께 반영됩니다.';
  L.Font.Style := [fsBold];

  L := TLabel.Create(Self);
  L.Parent := P;
  L.SetBounds(14, 48, 80, 22);
  L.Caption := '조정 사유';
  FReasonEdit := TEdit.Create(Self);
  FReasonEdit.Parent := P;
  FReasonEdit.SetBounds(96, 43, 520, 28);
  FReasonEdit.TextHint := '예: 월말 재고 실사 / 파손 / 폐기';

  FGrid := TStringGrid.Create(Self);
  FGrid.Parent := Self;
  FGrid.Align := alClient;
  FGrid.FixedRows := 1;
  FGrid.FixedCols := 0;
  FGrid.ColCount := 6;
  FGrid.RowCount := 2;
  FGrid.DefaultRowHeight := 28;
  FGrid.Options := FGrid.Options + [goRowSelect, goColSizing, goEditing];
  FGrid.Cells[0,0] := 'ID';
  FGrid.Cells[1,0] := '원재료명';
  FGrid.Cells[2,0] := '단위';
  FGrid.Cells[3,0] := '장부재고';
  FGrid.Cells[4,0] := '실사수량(입력)';
  FGrid.Cells[5,0] := '차이';
  FGrid.ColWidths[0] := 0;
  FGrid.ColWidths[1] := 250;
  FGrid.ColWidths[2] := 80;
  FGrid.ColWidths[3] := 150;
  FGrid.ColWidths[4] := 170;
  FGrid.ColWidths[5] := 140;
  FGrid.OnSetEditText := GridSetEditText;

  P := TPanel.Create(Self);
  P.Parent := Self;
  P.Align := alBottom;
  P.Height := 72;
  P.BevelOuter := bvNone;

  FSummary := TLabel.Create(Self);
  FSummary.Parent := P;
  FSummary.SetBounds(14, 12, 600, 24);
  FSummary.Caption := '실사수량을 입력한 원재료만 조정됩니다.';

  B := TButton.Create(Self);
  B.Parent := P;
  B.SetBounds(630, 16, 125, 36);
  B.Caption := '실사 이력 조회';
  B.OnClick := HistoryClick;

  B := TButton.Create(Self);
  B.Parent := P;
  B.SetBounds(765, 16, 125, 36);
  B.Caption := '재고 조정 저장';
  B.OnClick := SaveClick;

  B := TButton.Create(Self);
  B.Parent := P;
  B.SetBounds(900, 16, 110, 36);
  B.Caption := '닫기';
  B.ModalResult := mrClose;
end;

procedure TfrmIngredientStocktake.LoadIngredients;
var
  Q: TFDQuery;
  R: Integer;
  Stock: Double;
begin
  Q := NewQuery;
  try
    Q.SQL.Text := 'SELECT INGREDIENT_ID, INGREDIENT_NAME, UNIT_CODE, STOCK_QTY ' +
      'FROM POS_INGREDIENT WHERE STORE_ID=:STORE_ID AND ACTIVE_YN=''Y'' ' +
      'ORDER BY INGREDIENT_NAME';
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.Open;
    FGrid.RowCount := Max(2, Q.RecordCount + 1);
    R := 1;
    while not Q.Eof do
    begin
      Stock := Q.FieldByName('STOCK_QTY').AsFloat;
      FGrid.Cells[0,R] := Q.FieldByName('INGREDIENT_ID').AsString;
      FGrid.Cells[1,R] := Q.FieldByName('INGREDIENT_NAME').AsString;
      FGrid.Cells[2,R] := Q.FieldByName('UNIT_CODE').AsString;
      FGrid.Cells[3,R] := FormatFloat('0.###', Stock);
      FGrid.Cells[4,R] := '';
      FGrid.Cells[5,R] := '';
      Inc(R);
      Q.Next;
    end;
    if R = 1 then FGrid.Cells[1,1] := '등록된 원재료가 없습니다.';
    FSummary.Caption := Format('%d종 원재료 조회 | 실사수량을 입력한 항목만 저장됩니다.', [R - 1]);
  finally
    Q.Free;
  end;
end;

procedure TfrmIngredientStocktake.GridSetEditText(Sender: TObject;
  ACol, ARow: Integer; const Value: string);
var
  Counted, BookQty: Double;
begin
  if (ACol <> 4) or (ARow < 1) then Exit;
  if not TryStrToFloat(Trim(Value), Counted) then
  begin
    FGrid.Cells[5,ARow] := '입력 확인';
    Exit;
  end;
  if not TryStrToFloat(FGrid.Cells[3,ARow], BookQty) then Exit;
  FGrid.Cells[5,ARow] := FormatFloat('+0.###;-0.###;0', Counted - BookQty);
end;

procedure TfrmIngredientStocktake.SaveClick(Sender: TObject);
var
  Q, LockQ: TFDQuery;
  I, Changed: Integer;
  IngredientID, MovementID, StocktakeID: Int64;
  CountedQty, BookQty, DiffQty, NewStock: Double;
  Reason: string;
begin
  if Trim(FReasonEdit.Text) = '' then
  begin
    MessageDlg('재고 조정 사유를 입력해 주세요.', mtWarning, [mbOK], 0);
    Exit;
  end;
  if FGrid.EditorMode then FGrid.EditorMode := False;
  Reason := Trim(FReasonEdit.Text);
  Changed := 0;
  Q := NewQuery;
  LockQ := NewQuery;
  try
    dmDatabase.Connection.StartTransaction;
    try
      for I := 1 to FGrid.RowCount - 1 do
      begin
        if Trim(FGrid.Cells[0,I]) = '' then Continue;
        if Trim(FGrid.Cells[4,I]) = '' then Continue;
        if not TryStrToInt64(FGrid.Cells[0,I], IngredientID) then Continue;
        if not TryStrToFloat(Trim(FGrid.Cells[4,I]), CountedQty) or
          (CountedQty < 0) then
          raise Exception.Create(FGrid.Cells[1,I] + ': 실사수량은 0 이상의 숫자여야 합니다.');

        LockQ.Close;
        LockQ.SQL.Text := 'SELECT STOCK_QTY FROM POS_INGREDIENT ' +
          'WHERE STORE_ID=:STORE_ID AND INGREDIENT_ID=:ID AND ACTIVE_YN=''Y'' WITH LOCK';
        LockQ.ParamByName('STORE_ID').AsInteger := FStoreID;
        LockQ.ParamByName('ID').AsLargeInt := IngredientID;
        LockQ.Open;
        if LockQ.IsEmpty then
          raise Exception.Create(FGrid.Cells[1,I] + ': 원재료 정보를 찾을 수 없습니다.');
        BookQty := LockQ.Fields[0].AsFloat;
        LockQ.Close;

        DiffQty := CountedQty - BookQty;
        if Abs(DiffQty) < 0.0005 then Continue;
        NewStock := CountedQty;

        Q.Close;
        Q.SQL.Text := 'UPDATE POS_INGREDIENT SET STOCK_QTY=:QTY, ' +
          'UPDATED_AT=CURRENT_TIMESTAMP WHERE STORE_ID=:STORE_ID AND INGREDIENT_ID=:ID';
        Q.ParamByName('QTY').AsFloat := NewStock;
        Q.ParamByName('STORE_ID').AsInteger := FStoreID;
        Q.ParamByName('ID').AsLargeInt := IngredientID;
        Q.ExecSQL;

        MovementID := 0;
        Q.Close;
        Q.SQL.Text := 'SELECT GEN_ID(GEN_POS_INGREDIENT_MOVEMENT_ID, 1) FROM RDB$DATABASE';
        Q.Open;
        MovementID := Q.Fields[0].AsLargeInt;
        Q.Close;
        Q.SQL.Text := 'INSERT INTO POS_INGREDIENT_MOVEMENT ' +
          '(MOVEMENT_ID, STORE_ID, INGREDIENT_ID, MOVEMENT_TYPE, QUANTITY, ' +
          'STOCK_BEFORE, STOCK_AFTER, UNIT_COST, REFERENCE_TYPE, REFERENCE_ID, ' +
          'DESCRIPTION, EMPLOYEE_ID) VALUES (:ID,:STORE_ID,:ING,''ADJUST'',:QTY,' +
          ':BEFORE_QTY,:AFTER_QTY,0,''STOCKTAKE'',:REF,:DESCRIPTION,:EMPLOYEE_ID)';
        Q.ParamByName('ID').AsLargeInt := MovementID;
        Q.ParamByName('STORE_ID').AsInteger := FStoreID;
        Q.ParamByName('ING').AsLargeInt := IngredientID;
        Q.ParamByName('QTY').AsFloat := Abs(DiffQty);
        Q.ParamByName('BEFORE_QTY').AsFloat := BookQty;
        Q.ParamByName('AFTER_QTY').AsFloat := NewStock;
        Q.ParamByName('REF').AsLargeInt := 0;
        Q.ParamByName('DESCRIPTION').AsString := Reason;
        Q.ParamByName('EMPLOYEE_ID').AsInteger := FEmployeeID;
        Q.ExecSQL;

        Q.Close;
        Q.SQL.Text := 'SELECT GEN_ID(GEN_POS_ING_STOCKTAKE_ID, 1) FROM RDB$DATABASE';
        Q.Open;
        StocktakeID := Q.Fields[0].AsLargeInt;
        Q.Close;
        Q.SQL.Text := 'INSERT INTO POS_INGREDIENT_STOCKTAKE ' +
          '(STOCKTAKE_ID, STORE_ID, INGREDIENT_ID, BOOK_QTY, COUNTED_QTY, ' +
          'DIFFERENCE_QTY, REASON, EMPLOYEE_ID) ' +
          'VALUES (:ID,:STORE_ID,:ING,:BOOK,:COUNTED,:DIFF,:REASON,:EMPLOYEE_ID)';
        Q.ParamByName('ID').AsLargeInt := StocktakeID;
        Q.ParamByName('STORE_ID').AsInteger := FStoreID;
        Q.ParamByName('ING').AsLargeInt := IngredientID;
        Q.ParamByName('BOOK').AsFloat := BookQty;
        Q.ParamByName('COUNTED').AsFloat := CountedQty;
        Q.ParamByName('DIFF').AsFloat := DiffQty;
        Q.ParamByName('REASON').AsString := Reason;
        Q.ParamByName('EMPLOYEE_ID').AsInteger := FEmployeeID;
        Q.ExecSQL;
        Inc(Changed);
      end;
      dmDatabase.Connection.Commit;
    except
      dmDatabase.Connection.Rollback;
      raise;
    end;
    if Changed = 0 then
      MessageDlg('변경된 실사수량이 없습니다.', mtInformation, [mbOK], 0)
    else
    begin
      MessageDlg(Format('%d개 원재료의 재고를 조정했습니다.', [Changed]),
        mtInformation, [mbOK], 0);
      LoadIngredients;
      FReasonEdit.Clear;
    end;
  except
    on E: Exception do
      MessageDlg('재고 실사 저장 실패: ' + E.Message, mtError, [mbOK], 0);
  end;
  LockQ.Free;
  Q.Free;
end;

procedure TfrmIngredientStocktake.HistoryClick(Sender: TObject);
var
  Q: TFDQuery;
  S: TStringList;
  N: Integer;
begin
  Q := NewQuery;
  S := TStringList.Create;
  try
    Q.SQL.Text := 'SELECT FIRST 50 H.CREATED_AT, I.INGREDIENT_NAME, I.UNIT_CODE, ' +
      'H.BOOK_QTY, H.COUNTED_QTY, H.DIFFERENCE_QTY, H.REASON, E.EMPLOYEE_NAME ' +
      'FROM POS_INGREDIENT_STOCKTAKE H ' +
      'JOIN POS_INGREDIENT I ON I.INGREDIENT_ID=H.INGREDIENT_ID ' +
      'JOIN EMPLOYEE E ON E.EMPLOYEE_ID=H.EMPLOYEE_ID ' +
      'WHERE H.STORE_ID=:STORE_ID ORDER BY H.CREATED_AT DESC, H.STOCKTAKE_ID DESC';
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.Open;
    N := 0;
    while not Q.Eof do
    begin
      S.Add(FormatDateTime('yyyy-mm-dd hh:nn', Q.FieldByName('CREATED_AT').AsDateTime) +
        ' | ' + Q.FieldByName('INGREDIENT_NAME').AsString +
        ' | 장부 ' + FormatFloat('0.###', Q.FieldByName('BOOK_QTY').AsFloat) +
        ' → 실사 ' + FormatFloat('0.###', Q.FieldByName('COUNTED_QTY').AsFloat) +
        ' (' + FormatFloat('+0.###;-0.###;0', Q.FieldByName('DIFFERENCE_QTY').AsFloat) +
        ') ' + Q.FieldByName('UNIT_CODE').AsString +
        ' | ' + Q.FieldByName('REASON').AsString +
        ' | ' + Q.FieldByName('EMPLOYEE_NAME').AsString);
      Inc(N);
      Q.Next;
    end;
    if N = 0 then S.Add('재고 실사 이력이 없습니다.');
    MessageDlg(S.Text, mtInformation, [mbOK], 0);
  finally
    S.Free;
    Q.Free;
  end;
end;

end.
