unit uIngredientMovementReportForm;

interface

uses
  System.SysUtils, System.Classes, System.DateUtils, Data.DB,
  FireDAC.Comp.Client, FireDAC.Stan.Param,
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Grids,
  Vcl.Dialogs, Vcl.Graphics, Vcl.ComCtrls;

type
  TfrmIngredientMovementReport = class(TForm)
  private
    FStoreID: Integer;
    FStartDate: TDateTimePicker;
    FEndDate: TDateTimePicker;
    FIngredientCombo: TComboBox;
    FTypeCombo: TComboBox;
    FGrid: TStringGrid;
    FSummaryLabel: TLabel;
    FStatusLabel: TLabel;
    FExportButton: TButton;
    procedure BuildUI;
    procedure LoadIngredients;
    procedure RefreshClick(Sender: TObject);
    procedure ExportClick(Sender: TObject);
    procedure SetStatus(const AText: string);
    function NewQuery: TFDQuery;
    function SelectedIngredientID: Int64;
    function CsvField(const AValue: string): string;
    function MovementName(const ACode: string): string;
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetStoreID(AStoreID: Integer);
  end;

implementation

uses
  uDatabase;

constructor TfrmIngredientMovementReport.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  BuildUI;
end;

function TfrmIngredientMovementReport.NewQuery: TFDQuery;
begin
  Result := TFDQuery.Create(nil);
  Result.Connection := dmDatabase.Connection;
end;

procedure TfrmIngredientMovementReport.SetStoreID(AStoreID: Integer);
begin
  FStoreID := AStoreID;
  if FStoreID <= 0 then
    raise Exception.Create('매장 정보를 확인해 주세요.');
  LoadIngredients;
  RefreshClick(nil);
end;

procedure TfrmIngredientMovementReport.BuildUI;
var
  Header, FilterPanel, SummaryPanel, BottomPanel: TPanel;
  L: TLabel;
  B: TButton;
begin
  Caption := '원재료 재고 현황 및 입출고 분석';
  Font.Name := '맑은 고딕';
  Position := poScreenCenter;
  Width := 1320;
  Height := 760;
  Constraints.MinWidth := 1050;
  Constraints.MinHeight := 620;

  Header := TPanel.Create(Self);
  Header.Parent := Self;
  Header.Align := alTop;
  Header.Height := 54;
  Header.BevelOuter := bvNone;
  L := TLabel.Create(Self);
  L.Parent := Header;
  L.SetBounds(16, 13, 900, 28);
  L.Caption := '기간과 원재료를 선택하여 입고·판매 사용·재고 조정 내역을 확인합니다.';
  L.Font.Name := Font.Name;
  L.Font.Size := 12;
  L.Font.Style := [fsBold];

  FilterPanel := TPanel.Create(Self);
  FilterPanel.Parent := Self;
  FilterPanel.Align := alTop;
  FilterPanel.Height := 82;
  FilterPanel.BevelOuter := bvLowered;

  L := TLabel.Create(Self);
  L.Parent := FilterPanel;
  L.SetBounds(14, 12, 65, 22);
  L.Caption := '시작일';
  FStartDate := TDateTimePicker.Create(Self);
  FStartDate.Parent := FilterPanel;
  FStartDate.SetBounds(78, 8, 135, 28);
  FStartDate.Kind := dtkDate;
  FStartDate.Date := StartOfTheMonth(Date);

  L := TLabel.Create(Self);
  L.Parent := FilterPanel;
  L.SetBounds(226, 12, 65, 22);
  L.Caption := '종료일';
  FEndDate := TDateTimePicker.Create(Self);
  FEndDate.Parent := FilterPanel;
  FEndDate.SetBounds(290, 8, 135, 28);
  FEndDate.Kind := dtkDate;
  FEndDate.Date := Date;

  L := TLabel.Create(Self);
  L.Parent := FilterPanel;
  L.SetBounds(440, 12, 65, 22);
  L.Caption := '원재료';
  FIngredientCombo := TComboBox.Create(Self);
  FIngredientCombo.Parent := FilterPanel;
  FIngredientCombo.SetBounds(505, 8, 245, 28);
  FIngredientCombo.Style := csDropDownList;

  L := TLabel.Create(Self);
  L.Parent := FilterPanel;
  L.SetBounds(765, 12, 65, 22);
  L.Caption := '구분';
  FTypeCombo := TComboBox.Create(Self);
  FTypeCombo.Parent := FilterPanel;
  FTypeCombo.SetBounds(815, 8, 135, 28);
  FTypeCombo.Style := csDropDownList;
  FTypeCombo.Items.Add('전체');
  FTypeCombo.Items.Add('입고');
  FTypeCombo.Items.Add('사용/출고');
  FTypeCombo.Items.Add('재고조정');
  FTypeCombo.ItemIndex := 0;

  B := TButton.Create(Self);
  B.Parent := FilterPanel;
  B.SetBounds(970, 7, 105, 32);
  B.Caption := '조회';
  B.OnClick := RefreshClick;

  FExportButton := TButton.Create(Self);
  FExportButton.Parent := FilterPanel;
  FExportButton.SetBounds(1085, 7, 135, 32);
  FExportButton.Caption := 'CSV 내보내기';
  FExportButton.OnClick := ExportClick;

  FStatusLabel := TLabel.Create(Self);
  FStatusLabel.Parent := FilterPanel;
  FStatusLabel.SetBounds(16, 48, 1180, 22);
  FStatusLabel.Caption := '조회 조건을 선택해 주세요.';

  SummaryPanel := TPanel.Create(Self);
  SummaryPanel.Parent := Self;
  SummaryPanel.Align := alTop;
  SummaryPanel.Height := 48;
  SummaryPanel.BevelOuter := bvNone;
  FSummaryLabel := TLabel.Create(Self);
  FSummaryLabel.Parent := SummaryPanel;
  FSummaryLabel.SetBounds(16, 13, 1250, 24);
  FSummaryLabel.Font.Style := [fsBold];
  FSummaryLabel.Caption := '입고 0 | 사용/출고 0 | 재고조정 0';

  FGrid := TStringGrid.Create(Self);
  FGrid.Parent := Self;
  FGrid.Align := alClient;
  FGrid.FixedRows := 1;
  FGrid.FixedCols := 0;
  FGrid.ColCount := 10;
  FGrid.RowCount := 2;
  FGrid.DefaultRowHeight := 27;
  FGrid.Options := FGrid.Options + [goRowSelect, goColSizing];
  FGrid.Cells[0,0] := '일시';
  FGrid.Cells[1,0] := '원재료명';
  FGrid.Cells[2,0] := '단위';
  FGrid.Cells[3,0] := '구분';
  FGrid.Cells[4,0] := '수량';
  FGrid.Cells[5,0] := '변경 전';
  FGrid.Cells[6,0] := '변경 후';
  FGrid.Cells[7,0] := '단가';
  FGrid.Cells[8,0] := '내용 / 사유';
  FGrid.Cells[9,0] := '담당자';
  FGrid.ColWidths[0] := 135;
  FGrid.ColWidths[1] := 145;
  FGrid.ColWidths[2] := 55;
  FGrid.ColWidths[3] := 85;
  FGrid.ColWidths[4] := 85;
  FGrid.ColWidths[5] := 85;
  FGrid.ColWidths[6] := 85;
  FGrid.ColWidths[7] := 95;
  FGrid.ColWidths[8] := 260;
  FGrid.ColWidths[9] := 110;

  BottomPanel := TPanel.Create(Self);
  BottomPanel.Parent := Self;
  BottomPanel.Align := alBottom;
  BottomPanel.Height := 48;
  BottomPanel.BevelOuter := bvNone;
  B := TButton.Create(Self);
  B.Parent := BottomPanel;
  B.SetBounds(1120, 6, 150, 34);
  B.Caption := '닫기';
  B.ModalResult := mrClose;
end;

procedure TfrmIngredientMovementReport.LoadIngredients;
var
  Q: TFDQuery;
begin
  FIngredientCombo.Items.BeginUpdate;
  try
    FIngredientCombo.Items.Clear;
    FIngredientCombo.Items.Add('0 | 전체 원재료');
    Q := NewQuery;
    try
      Q.SQL.Text := 'SELECT INGREDIENT_ID, INGREDIENT_NAME, UNIT_CODE ' +
        'FROM POS_INGREDIENT WHERE STORE_ID=:STORE_ID ' +
        'ORDER BY ACTIVE_YN DESC, INGREDIENT_NAME';
      Q.ParamByName('STORE_ID').AsInteger := FStoreID;
      Q.Open;
      while not Q.Eof do
      begin
        FIngredientCombo.Items.Add(Q.FieldByName('INGREDIENT_ID').AsString +
          ' | ' + Q.FieldByName('INGREDIENT_NAME').AsString + ' (' +
          Q.FieldByName('UNIT_CODE').AsString + ')');
        Q.Next;
      end;
    finally
      Q.Free;
    end;
    FIngredientCombo.ItemIndex := 0;
  finally
    FIngredientCombo.Items.EndUpdate;
  end;
end;

function TfrmIngredientMovementReport.SelectedIngredientID: Int64;
var
  S: string;
  P: Integer;
begin
  Result := 0;
  if FIngredientCombo.ItemIndex < 0 then Exit;
  S := FIngredientCombo.Items[FIngredientCombo.ItemIndex];
  P := Pos(' | ', S);
  if P > 1 then
    TryStrToInt64(Copy(S, 1, P - 1), Result);
end;

function TfrmIngredientMovementReport.MovementName(const ACode: string): string;
begin
  if SameText(ACode, 'IN') then Result := '입고'
  else if SameText(ACode, 'OUT') then Result := '사용/출고'
  else if SameText(ACode, 'ADJUST') then Result := '재고조정'
  else Result := ACode;
end;

procedure TfrmIngredientMovementReport.SetStatus(const AText: string);
begin
  FStatusLabel.Caption := AText;
end;

procedure TfrmIngredientMovementReport.RefreshClick(Sender: TObject);
var
  Q: TFDQuery;
  R: Integer;
  InQty, OutQty, AdjustQty: Double;
  InCount, OutCount, AdjustCount: Integer;
  TypeCode: string;
begin
  if FStartDate.Date > FEndDate.Date then
  begin
    MessageDlg('시작일은 종료일보다 늦을 수 없습니다.', mtWarning, [mbOK], 0);
    Exit;
  end;

  Q := NewQuery;
  try
    Q.SQL.Text :=
      'SELECT COUNT(*) AS MOVEMENT_COUNT, ' +
      'COALESCE(SUM(IIF(M.MOVEMENT_TYPE=''IN'', M.QUANTITY, 0)),0) AS IN_QTY, ' +
      'COALESCE(SUM(IIF(M.MOVEMENT_TYPE=''OUT'', M.QUANTITY, 0)),0) AS OUT_QTY, ' +
      'COALESCE(SUM(IIF(M.MOVEMENT_TYPE=''ADJUST'', M.QUANTITY, 0)),0) AS ADJUST_QTY, ' +
      'SUM(IIF(M.MOVEMENT_TYPE=''IN'',1,0)) AS IN_COUNT, ' +
      'SUM(IIF(M.MOVEMENT_TYPE=''OUT'',1,0)) AS OUT_COUNT, ' +
      'SUM(IIF(M.MOVEMENT_TYPE=''ADJUST'',1,0)) AS ADJUST_COUNT ' +
      'FROM POS_INGREDIENT_MOVEMENT M ' +
      'WHERE M.STORE_ID=:STORE_ID AND M.CREATED_AT>=:START_AT AND M.CREATED_AT<:END_AT ' +
      'AND (:INGREDIENT_ID=0 OR M.INGREDIENT_ID=:INGREDIENT_ID) ' +
      'AND (:MOVEMENT_TYPE=''ALL'' OR M.MOVEMENT_TYPE=:MOVEMENT_TYPE)';
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.ParamByName('START_AT').AsDateTime := Trunc(FStartDate.Date);
    Q.ParamByName('END_AT').AsDateTime := Trunc(FEndDate.Date) + 1;
    Q.ParamByName('INGREDIENT_ID').AsLargeInt := SelectedIngredientID;
    case FTypeCombo.ItemIndex of
      1: TypeCode := 'IN';
      2: TypeCode := 'OUT';
      3: TypeCode := 'ADJUST';
    else
      TypeCode := 'ALL';
    end;
    Q.ParamByName('MOVEMENT_TYPE').AsString := TypeCode;
    Q.Open;
    InQty := Q.FieldByName('IN_QTY').AsFloat;
    OutQty := Q.FieldByName('OUT_QTY').AsFloat;
    AdjustQty := Q.FieldByName('ADJUST_QTY').AsFloat;
    InCount := Q.FieldByName('IN_COUNT').AsInteger;
    OutCount := Q.FieldByName('OUT_COUNT').AsInteger;
    AdjustCount := Q.FieldByName('ADJUST_COUNT').AsInteger;
    Q.Close;

    FSummaryLabel.Caption :=
      Format('입고 %s (%d건)    |    사용/출고 %s (%d건)    |    재고조정 %s (%d건)',
        [FormatFloat('#,##0.###', InQty), InCount,
         FormatFloat('#,##0.###', OutQty), OutCount,
         FormatFloat('#,##0.###', AdjustQty), AdjustCount]);

    Q.SQL.Text :=
      'SELECT M.CREATED_AT, I.INGREDIENT_NAME, I.UNIT_CODE, M.MOVEMENT_TYPE, ' +
      'M.QUANTITY, M.STOCK_BEFORE, M.STOCK_AFTER, M.UNIT_COST, ' +
      'M.DESCRIPTION, E.EMPLOYEE_NAME ' +
      'FROM POS_INGREDIENT_MOVEMENT M ' +
      'JOIN POS_INGREDIENT I ON I.INGREDIENT_ID=M.INGREDIENT_ID ' +
      'LEFT JOIN EMPLOYEE E ON E.EMPLOYEE_ID=M.EMPLOYEE_ID ' +
      'WHERE M.STORE_ID=:STORE_ID AND M.CREATED_AT>=:START_AT AND M.CREATED_AT<:END_AT ' +
      'AND (:INGREDIENT_ID=0 OR M.INGREDIENT_ID=:INGREDIENT_ID) ' +
      'AND (:MOVEMENT_TYPE=''ALL'' OR M.MOVEMENT_TYPE=:MOVEMENT_TYPE) ' +
      'ORDER BY M.CREATED_AT DESC, M.MOVEMENT_ID DESC';
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.ParamByName('START_AT').AsDateTime := Trunc(FStartDate.Date);
    Q.ParamByName('END_AT').AsDateTime := Trunc(FEndDate.Date) + 1;
    Q.ParamByName('INGREDIENT_ID').AsLargeInt := SelectedIngredientID;
    Q.ParamByName('MOVEMENT_TYPE').AsString := TypeCode;
    Q.Open;

    FGrid.RowCount := 2;
    R := 1;
    while not Q.Eof do
    begin
      if R >= FGrid.RowCount then FGrid.RowCount := R + 1;
      FGrid.Cells[0,R] := FormatDateTime('yyyy-mm-dd hh:nn', Q.FieldByName('CREATED_AT').AsDateTime);
      FGrid.Cells[1,R] := Q.FieldByName('INGREDIENT_NAME').AsString;
      FGrid.Cells[2,R] := Q.FieldByName('UNIT_CODE').AsString;
      FGrid.Cells[3,R] := MovementName(Q.FieldByName('MOVEMENT_TYPE').AsString);
      FGrid.Cells[4,R] := FormatFloat('#,##0.###', Q.FieldByName('QUANTITY').AsFloat);
      FGrid.Cells[5,R] := FormatFloat('#,##0.###', Q.FieldByName('STOCK_BEFORE').AsFloat);
      FGrid.Cells[6,R] := FormatFloat('#,##0.###', Q.FieldByName('STOCK_AFTER').AsFloat);
      FGrid.Cells[7,R] := FormatCurr('#,##0.0000', Q.FieldByName('UNIT_COST').AsCurrency);
      FGrid.Cells[8,R] := Q.FieldByName('DESCRIPTION').AsString;
      FGrid.Cells[9,R] := Q.FieldByName('EMPLOYEE_NAME').AsString;
      Inc(R);
      Q.Next;
    end;
    if R > 1 then FGrid.RowCount := R else FGrid.RowCount := 2;
    if R = 1 then FGrid.Cells[1,1] := '조회된 입출고 이력이 없습니다.';
    SetStatus(Format('%s ~ %s | %d건 조회',
      [FormatDateTime('yyyy-mm-dd', FStartDate.Date),
       FormatDateTime('yyyy-mm-dd', FEndDate.Date), R - 1]));
    FExportButton.Enabled := R > 1;
  finally
    Q.Free;
  end;
end;

function TfrmIngredientMovementReport.CsvField(const AValue: string): string;
begin
  Result := '"' + StringReplace(AValue, '"', '""', [rfReplaceAll]) + '"';
end;

procedure TfrmIngredientMovementReport.ExportClick(Sender: TObject);
var
  SaveDialog: TSaveDialog;
  Lines: TStringList;
  I, C: Integer;
  FileName: string;
  HeaderLine: string;
begin
  if (FGrid.RowCount <= 1) or
    ((FGrid.RowCount = 2) and (FGrid.Cells[1,1] = '조회된 입출고 이력이 없습니다.')) then
  begin
    MessageDlg('내보낼 입출고 이력이 없습니다. 먼저 조회해 주세요.', mtInformation, [mbOK], 0);
    Exit;
  end;

  SaveDialog := TSaveDialog.Create(Self);
  try
    SaveDialog.Title := '원재료 입출고 보고서 CSV 저장';
    SaveDialog.Filter := 'CSV 파일 (*.csv)|*.csv';
    SaveDialog.DefaultExt := 'csv';
    SaveDialog.FileName := 'InterPOS_Ingredient_Movement_' +
      FormatDateTime('yyyymmdd', FStartDate.Date) + '_' +
      FormatDateTime('yyyymmdd', FEndDate.Date) + '.csv';
    SaveDialog.Options := SaveDialog.Options + [ofPathMustExist, ofOverwritePrompt];
    if not SaveDialog.Execute then Exit;
    FileName := SaveDialog.FileName;
    if ExtractFileExt(FileName) = '' then FileName := FileName + '.csv';

    Lines := TStringList.Create;
    try
      Lines.Add(CsvField('InterPOS 원재료 입출고 분석'));
      Lines.Add(CsvField('조회 시작일') + ',' + CsvField(FormatDateTime('yyyy-mm-dd', FStartDate.Date)));
      Lines.Add(CsvField('조회 종료일') + ',' + CsvField(FormatDateTime('yyyy-mm-dd', FEndDate.Date)));
      Lines.Add(CsvField(FSummaryLabel.Caption));
      Lines.Add('');
      HeaderLine := '';
      for C := 0 to FGrid.ColCount - 1 do
      begin
        if C > 0 then HeaderLine := HeaderLine + ',';
        HeaderLine := HeaderLine + CsvField(FGrid.Cells[C,0]);
      end;
      Lines.Add(HeaderLine);
      for I := 1 to FGrid.RowCount - 1 do
      begin
        if Trim(FGrid.Cells[0,I]) = '' then Continue;
        HeaderLine := '';
        for C := 0 to FGrid.ColCount - 1 do
        begin
          if C > 0 then HeaderLine := HeaderLine + ',';
          HeaderLine := HeaderLine + CsvField(FGrid.Cells[C,I]);
        end;
        Lines.Add(HeaderLine);
      end;
      Lines.SaveToFile(FileName, TEncoding.UTF8);
    finally
      Lines.Free;
    end;
    MessageDlg('원재료 입출고 보고서를 저장했습니다.' + sLineBreak + FileName,
      mtInformation, [mbOK], 0);
  finally
    SaveDialog.Free;
  end;
end;

end.
