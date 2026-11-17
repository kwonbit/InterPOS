unit uIngredientForecastForm;

interface

uses
  System.SysUtils, System.Classes, System.Math, System.DateUtils, Data.DB,
  FireDAC.Comp.Client, FireDAC.Stan.Param,
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Grids,
  Vcl.Dialogs, Vcl.Graphics;

type
  TfrmIngredientForecast = class(TForm)
  private
    FStoreID: Integer;
    FLookbackEdit: TEdit;
    FCoverDaysEdit: TEdit;
    FLeadDaysEdit: TEdit;
    FOnlyRecommend: TCheckBox;
    FGrid: TStringGrid;
    FSummary: TLabel;
    FStatus: TLabel;
    FExportButton: TButton;
    procedure BuildUI;
    procedure RefreshClick(Sender: TObject);
    procedure ExportClick(Sender: TObject);
    function NewQuery: TFDQuery;
    function CsvField(const AValue: string): string;
    function ReadPositiveInt(AEdit: TEdit; const ACaption: string): Integer;
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetStoreID(AStoreID: Integer);
  end;

implementation

uses
  uDatabase;

constructor TfrmIngredientForecast.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  BuildUI;
end;

function TfrmIngredientForecast.NewQuery: TFDQuery;
begin
  Result := TFDQuery.Create(nil);
  Result.Connection := dmDatabase.Connection;
end;

procedure TfrmIngredientForecast.SetStoreID(AStoreID: Integer);
begin
  FStoreID := AStoreID;
  if FStoreID <= 0 then
    raise Exception.Create('매장 정보를 확인해 주세요.');
  RefreshClick(nil);
end;

procedure TfrmIngredientForecast.BuildUI;
var
  Header, FilterPanel, SummaryPanel, BottomPanel: TPanel;
  L: TLabel;
  B: TButton;
begin
  Caption := '원재료 재고 예측 및 구매 추천';
  Font.Name := '맑은 고딕';
  Position := poScreenCenter;
  Width := 1390;
  Height := 760;
  Constraints.MinWidth := 1120;
  Constraints.MinHeight := 620;

  Header := TPanel.Create(Self);
  Header.Parent := Self;
  Header.Align := alTop;
  Header.Height := 58;
  Header.BevelOuter := bvNone;
  L := TLabel.Create(Self);
  L.Parent := Header;
  L.SetBounds(16, 14, 1250, 28);
  L.Caption := '최근 원재료 사용량을 분석하여 예상 소진일과 권장 구매량을 계산합니다.';
  L.Font.Name := Font.Name;
  L.Font.Size := 12;
  L.Font.Style := [fsBold];

  FilterPanel := TPanel.Create(Self);
  FilterPanel.Parent := Self;
  FilterPanel.Align := alTop;
  FilterPanel.Height := 96;
  FilterPanel.BevelOuter := bvLowered;

  L := TLabel.Create(Self);
  L.Parent := FilterPanel;
  L.SetBounds(14, 13, 90, 22);
  L.Caption := '사용 분석 기간';
  FLookbackEdit := TEdit.Create(Self);
  FLookbackEdit.Parent := FilterPanel;
  FLookbackEdit.SetBounds(105, 9, 55, 28);
  FLookbackEdit.Text := '30';
  L := TLabel.Create(Self);
  L.Parent := FilterPanel;
  L.SetBounds(165, 13, 30, 22);
  L.Caption := '일';

  L := TLabel.Create(Self);
  L.Parent := FilterPanel;
  L.SetBounds(220, 13, 90, 22);
  L.Caption := '목표 보유 기간';
  FCoverDaysEdit := TEdit.Create(Self);
  FCoverDaysEdit.Parent := FilterPanel;
  FCoverDaysEdit.SetBounds(312, 9, 55, 28);
  FCoverDaysEdit.Text := '14';
  L := TLabel.Create(Self);
  L.Parent := FilterPanel;
  L.SetBounds(372, 13, 30, 22);
  L.Caption := '일';

  L := TLabel.Create(Self);
  L.Parent := FilterPanel;
  L.SetBounds(430, 13, 90, 22);
  L.Caption := '입고 소요일';
  FLeadDaysEdit := TEdit.Create(Self);
  FLeadDaysEdit.Parent := FilterPanel;
  FLeadDaysEdit.SetBounds(522, 9, 55, 28);
  FLeadDaysEdit.Text := '3';
  L := TLabel.Create(Self);
  L.Parent := FilterPanel;
  L.SetBounds(582, 13, 30, 22);
  L.Caption := '일';

  B := TButton.Create(Self);
  B.Parent := FilterPanel;
  B.SetBounds(640, 7, 100, 32);
  B.Caption := '분석 조회';
  B.OnClick := RefreshClick;

  FExportButton := TButton.Create(Self);
  FExportButton.Parent := FilterPanel;
  FExportButton.SetBounds(750, 7, 130, 32);
  FExportButton.Caption := 'CSV 내보내기';
  FExportButton.OnClick := ExportClick;

  FOnlyRecommend := TCheckBox.Create(Self);
  FOnlyRecommend.Parent := FilterPanel;
  FOnlyRecommend.SetBounds(900, 12, 230, 24);
  FOnlyRecommend.Caption := '구매 권장 / 재고 부족만 보기';
  FOnlyRecommend.OnClick := RefreshClick;

  FStatus := TLabel.Create(Self);
  FStatus.Parent := FilterPanel;
  FStatus.SetBounds(16, 53, 1280, 22);
  FStatus.Caption := '분석 조건을 입력하고 조회해 주세요.';

  SummaryPanel := TPanel.Create(Self);
  SummaryPanel.Parent := Self;
  SummaryPanel.Align := alTop;
  SummaryPanel.Height := 48;
  SummaryPanel.BevelOuter := bvNone;
  FSummary := TLabel.Create(Self);
  FSummary.Parent := SummaryPanel;
  FSummary.SetBounds(16, 13, 1300, 24);
  FSummary.Font.Style := [fsBold];
  FSummary.Caption := '분석 원재료 0개 | 구매 권장 0개 | 재고 소진 임박 0개';

  FGrid := TStringGrid.Create(Self);
  FGrid.Parent := Self;
  FGrid.Align := alClient;
  FGrid.FixedRows := 1;
  FGrid.FixedCols := 0;
  FGrid.ColCount := 9;
  FGrid.RowCount := 2;
  FGrid.DefaultRowHeight := 28;
  FGrid.Options := FGrid.Options + [goRowSelect, goColSizing];
  FGrid.Cells[0,0] := '원재료명';
  FGrid.Cells[1,0] := '단위';
  FGrid.Cells[2,0] := '현재고';
  FGrid.Cells[3,0] := '일평균 사용량';
  FGrid.Cells[4,0] := '예상 잔여일';
  FGrid.Cells[5,0] := '예상 소진일';
  FGrid.Cells[6,0] := '안전재고';
  FGrid.Cells[7,0] := '권장 구매량';
  FGrid.Cells[8,0] := '재고 상태';
  FGrid.ColWidths[0] := 180;
  FGrid.ColWidths[1] := 60;
  FGrid.ColWidths[2] := 105;
  FGrid.ColWidths[3] := 125;
  FGrid.ColWidths[4] := 105;
  FGrid.ColWidths[5] := 120;
  FGrid.ColWidths[6] := 105;
  FGrid.ColWidths[7] := 125;
  FGrid.ColWidths[8] := 150;

  BottomPanel := TPanel.Create(Self);
  BottomPanel.Parent := Self;
  BottomPanel.Align := alBottom;
  BottomPanel.Height := 50;
  BottomPanel.BevelOuter := bvNone;
  B := TButton.Create(Self);
  B.Parent := BottomPanel;
  B.SetBounds(1200, 7, 150, 34);
  B.Caption := '닫기';
  B.ModalResult := mrClose;
end;

function TfrmIngredientForecast.ReadPositiveInt(AEdit: TEdit;
  const ACaption: string): Integer;
begin
  if not TryStrToInt(Trim(AEdit.Text), Result) or (Result <= 0) or
    (Result > 365) then
    raise Exception.Create(ACaption + '은(는) 1~365 사이의 정수로 입력해 주세요.');
end;

procedure TfrmIngredientForecast.RefreshClick(Sender: TObject);
var
  Q: TFDQuery;
  LookbackDays, CoverDays, LeadDays: Integer;
  StartAt, EndAt: TDateTime;
  R, TotalCount, RecommendCount, UrgentCount: Integer;
  StockQty, SafetyQty, UsedQty, AvgDaily, DaysLeft, TargetQty, RecommendQty: Double;
  StatusText, DepletionText: string;
begin
  try
    LookbackDays := ReadPositiveInt(FLookbackEdit, '사용 분석 기간');
    CoverDays := ReadPositiveInt(FCoverDaysEdit, '목표 보유 기간');
    LeadDays := ReadPositiveInt(FLeadDaysEdit, '입고 소요일');
  except
    on E: Exception do
    begin
      MessageDlg(E.Message, mtWarning, [mbOK], 0);
      Exit;
    end;
  end;

  StartAt := Trunc(Date) - LookbackDays + 1;
  EndAt := Trunc(Date) + 1;
  Q := NewQuery;
  try
    Q.SQL.Text :=
      'SELECT I.INGREDIENT_ID, I.INGREDIENT_NAME, I.UNIT_CODE, ' +
      'I.STOCK_QTY, I.LOW_STOCK_QTY, ' +
      'COALESCE(SUM(M.QUANTITY),0) AS USED_QTY, ' +
      'COUNT(M.MOVEMENT_ID) AS MOVEMENT_COUNT ' +
      'FROM POS_INGREDIENT I ' +
      'LEFT JOIN POS_INGREDIENT_MOVEMENT M ON M.INGREDIENT_ID=I.INGREDIENT_ID ' +
      'AND M.STORE_ID=I.STORE_ID AND M.MOVEMENT_TYPE=''OUT'' ' +
      'AND M.CREATED_AT>=:START_AT AND M.CREATED_AT<:END_AT ' +
      'WHERE I.STORE_ID=:STORE_ID AND I.ACTIVE_YN=''Y'' ' +
      'GROUP BY I.INGREDIENT_ID, I.INGREDIENT_NAME, I.UNIT_CODE, ' +
      'I.STOCK_QTY, I.LOW_STOCK_QTY ORDER BY I.INGREDIENT_NAME';
    Q.ParamByName('START_AT').AsDateTime := StartAt;
    Q.ParamByName('END_AT').AsDateTime := EndAt;
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.Open;

    FGrid.RowCount := 2;
    R := 1;
    TotalCount := 0;
    RecommendCount := 0;
    UrgentCount := 0;
    while not Q.Eof do
    begin
      StockQty := Q.FieldByName('STOCK_QTY').AsFloat;
      SafetyQty := Q.FieldByName('LOW_STOCK_QTY').AsFloat;
      UsedQty := Q.FieldByName('USED_QTY').AsFloat;
      AvgDaily := UsedQty / LookbackDays;
      RecommendQty := 0;
      DaysLeft := -1;
      DepletionText := '자료 부족';

      if AvgDaily > 0 then
      begin
        DaysLeft := StockQty / AvgDaily;
        if DaysLeft <= 0 then
          DepletionText := '소진 / 음수'
        else
          DepletionText := FormatDateTime('yyyy-mm-dd',
            Date + Ceil(DaysLeft));
        TargetQty := Max(SafetyQty, AvgDaily * (LeadDays + CoverDays));
        RecommendQty := Max(0, TargetQty - StockQty);
      end
      else
      begin
        RecommendQty := Max(0, SafetyQty - StockQty);
      end;

      if StockQty <= 0 then
        StatusText := '재고 소진 / 음수'
      else if AvgDaily <= 0 then
      begin
        if RecommendQty > 0 then StatusText := '사용이력 없음 / 부족'
        else StatusText := '사용이력 없음';
      end
      else if DaysLeft <= LeadDays then
        StatusText := '발주 시급'
      else if (StockQty <= SafetyQty) or (RecommendQty > 0) then
        StatusText := '구매 권장'
      else
        StatusText := '정상';

      if FOnlyRecommend.Checked and (RecommendQty <= 0) and
        (StockQty > SafetyQty) then
      begin
        Q.Next;
        Continue;
      end;

      if R >= FGrid.RowCount then FGrid.RowCount := R + 1;
      FGrid.Cells[0,R] := Q.FieldByName('INGREDIENT_NAME').AsString;
      FGrid.Cells[1,R] := Q.FieldByName('UNIT_CODE').AsString;
      FGrid.Cells[2,R] := FormatFloat('#,##0.###', StockQty);
      FGrid.Cells[3,R] := FormatFloat('#,##0.###', AvgDaily);
      if AvgDaily > 0 then
        FGrid.Cells[4,R] := FormatFloat('#,##0.0', DaysLeft)
      else
        FGrid.Cells[4,R] := '-';
      FGrid.Cells[5,R] := DepletionText;
      FGrid.Cells[6,R] := FormatFloat('#,##0.###', SafetyQty);
      FGrid.Cells[7,R] := FormatFloat('#,##0.###', RecommendQty);
      FGrid.Cells[8,R] := StatusText;

      Inc(TotalCount);
      if RecommendQty > 0 then Inc(RecommendCount);
      if (AvgDaily > 0) and (DaysLeft <= LeadDays) then Inc(UrgentCount);
      Inc(R);
      Q.Next;
    end;

    if R = 1 then
      FGrid.Cells[0,1] := '조건에 해당하는 원재료가 없습니다.';
    FGrid.RowCount := Max(2, R);
    FSummary.Caption := Format(
      '분석 원재료 %d개    |    구매 권장 %d개    |    입고 소요일 내 소진 예상 %d개',
      [TotalCount, RecommendCount, UrgentCount]);
    FStatus.Caption := Format(
      '분석 기간: %s ~ %s (%d일)    |    목표 보유 %d일    |    입고 소요일 %d일',
      [FormatDateTime('yyyy-mm-dd', StartAt),
       FormatDateTime('yyyy-mm-dd', Date), LookbackDays, CoverDays, LeadDays]);
    FExportButton.Enabled := TotalCount > 0;
  finally
    Q.Free;
  end;
end;

function TfrmIngredientForecast.CsvField(const AValue: string): string;
begin
  Result := '"' + StringReplace(AValue, '"', '""', [rfReplaceAll]) + '"';
end;

procedure TfrmIngredientForecast.ExportClick(Sender: TObject);
var
  SaveDialog: TSaveDialog;
  Lines: TStringList;
  I, C: Integer;
  LineText, FileName: string;
begin
  if (FGrid.RowCount <= 1) or (FGrid.Cells[0,1] = '조건에 해당하는 원재료가 없습니다.') then
  begin
    MessageDlg('내보낼 분석 결과가 없습니다. 먼저 조회해 주세요.', mtInformation, [mbOK], 0);
    Exit;
  end;

  SaveDialog := TSaveDialog.Create(Self);
  try
    SaveDialog.Title := '원재료 재고 예측 보고서 저장';
    SaveDialog.Filter := 'CSV 파일 (*.csv)|*.csv';
    SaveDialog.DefaultExt := 'csv';
    SaveDialog.FileName := 'InterPOS_Ingredient_Forecast_' +
      FormatDateTime('yyyymmdd', Date) + '.csv';
    SaveDialog.Options := SaveDialog.Options + [ofPathMustExist, ofOverwritePrompt];
    if not SaveDialog.Execute then Exit;
    FileName := SaveDialog.FileName;
    if ExtractFileExt(FileName) = '' then FileName := FileName + '.csv';

    Lines := TStringList.Create;
    try
      Lines.Add(CsvField('InterPOS 원재료 재고 예측 및 구매 추천'));
      Lines.Add(CsvField(FStatus.Caption));
      Lines.Add(CsvField(FSummary.Caption));
      Lines.Add('');
      LineText := '';
      for C := 0 to FGrid.ColCount - 1 do
      begin
        if C > 0 then LineText := LineText + ',';
        LineText := LineText + CsvField(FGrid.Cells[C,0]);
      end;
      Lines.Add(LineText);
      for I := 1 to FGrid.RowCount - 1 do
      begin
        if Trim(FGrid.Cells[0,I]) = '' then Continue;
        if FGrid.Cells[0,I] = '조건에 해당하는 원재료가 없습니다.' then Continue;
        LineText := '';
        for C := 0 to FGrid.ColCount - 1 do
        begin
          if C > 0 then LineText := LineText + ',';
          LineText := LineText + CsvField(FGrid.Cells[C,I]);
        end;
        Lines.Add(LineText);
      end;
      Lines.SaveToFile(FileName, TEncoding.UTF8);
    finally
      Lines.Free;
    end;
    MessageDlg('원재료 재고 예측 보고서를 저장했습니다.' + sLineBreak + FileName,
      mtInformation, [mbOK], 0);
  finally
    SaveDialog.Free;
  end;
end;

end.
