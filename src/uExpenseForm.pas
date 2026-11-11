unit uExpenseForm;

interface

uses
  System.SysUtils, System.Classes, System.DateUtils, System.Math, Data.DB,
  FireDAC.Comp.Client, FireDAC.Stan.Param,
  Vcl.Forms, Vcl.Controls, Vcl.Graphics, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Grids, Vcl.ComCtrls, Vcl.Dialogs;

type
  TfrmExpense = class(TForm)
  private
    FStoreID: Integer;
    FEmployeeID: Integer;
    FStartDate: TDateTimePicker;
    FEndDate: TDateTimePicker;
    FExpenseDate: TDateTimePicker;
    FCategoryEdit: TEdit;
    FDescriptionEdit: TEdit;
    FAmountEdit: TEdit;
    FMethodCombo: TComboBox;
    FNoteEdit: TEdit;
    FGrid: TStringGrid;
    FTotalLabel: TLabel;
    FStatusLabel: TLabel;
    procedure BuildUI;
    procedure RefreshClick(Sender: TObject);
    procedure AddClick(Sender: TObject);
    procedure VoidClick(Sender: TObject);
    procedure RefreshExpenses;
    procedure SetStatus(const AText: string);
    function NextExpenseID: Int64;
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetContext(AStoreID, AEmployeeID: Integer);
  end;

implementation

uses
  uDatabase;

constructor TfrmExpense.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  BuildUI;
end;

procedure TfrmExpense.SetContext(AStoreID, AEmployeeID: Integer);
begin
  FStoreID := AStoreID;
  FEmployeeID := AEmployeeID;
  RefreshExpenses;
end;

procedure TfrmExpense.BuildUI;
var
  Header, EntryPanel, ButtonPanel: TPanel;
  L: TLabel;
  B: TButton;
begin
  Caption := '영업비용 관리';
  Font.Name := '맑은 고딕';
  Width := 1120;
  Height := 760;
  Position := poScreenCenter;

  Header := TPanel.Create(Self);
  Header.Parent := Self;
  Header.Align := alTop;
  Header.Height := 58;
  Header.BevelOuter := bvNone;

  L := TLabel.Create(Self);
  L.Parent := Header;
  L.SetBounds(14, 18, 70, 22);
  L.Caption := '조회기간';

  FStartDate := TDateTimePicker.Create(Self);
  FStartDate.Parent := Header;
  FStartDate.SetBounds(88, 12, 140, 30);
  FStartDate.Format := 'yyyy-MM-dd';
  FStartDate.Date := StartOfTheMonth(Date);

  L := TLabel.Create(Self);
  L.Parent := Header;
  L.SetBounds(238, 18, 18, 22);
  L.Caption := '~';

  FEndDate := TDateTimePicker.Create(Self);
  FEndDate.Parent := Header;
  FEndDate.SetBounds(260, 12, 140, 30);
  FEndDate.Format := 'yyyy-MM-dd';
  FEndDate.Date := Date;

  B := TButton.Create(Self);
  B.Parent := Header;
  B.SetBounds(415, 10, 110, 34);
  B.Caption := '조회';
  B.OnClick := RefreshClick;

  EntryPanel := TPanel.Create(Self);
  EntryPanel.Parent := Self;
  EntryPanel.Align := alTop;
  EntryPanel.Height := 132;
  EntryPanel.BevelOuter := bvLowered;

  L := TLabel.Create(Self);
  L.Parent := EntryPanel;
  L.SetBounds(14, 14, 70, 22);
  L.Caption := '지출일자';
  FExpenseDate := TDateTimePicker.Create(Self);
  FExpenseDate.Parent := EntryPanel;
  FExpenseDate.SetBounds(88, 9, 140, 30);
  FExpenseDate.Format := 'yyyy-MM-dd';
  FExpenseDate.Date := Date;

  L := TLabel.Create(Self);
  L.Parent := EntryPanel;
  L.SetBounds(245, 14, 55, 22);
  L.Caption := '분류';
  FCategoryEdit := TEdit.Create(Self);
  FCategoryEdit.Parent := EntryPanel;
  FCategoryEdit.SetBounds(300, 9, 160, 30);
  FCategoryEdit.TextHint := '예: 임차료, 공과금';

  L := TLabel.Create(Self);
  L.Parent := EntryPanel;
  L.SetBounds(475, 14, 55, 22);
  L.Caption := '금액';
  FAmountEdit := TEdit.Create(Self);
  FAmountEdit.Parent := EntryPanel;
  FAmountEdit.SetBounds(530, 9, 140, 30);
  FAmountEdit.TextHint := '원 단위 숫자';

  L := TLabel.Create(Self);
  L.Parent := EntryPanel;
  L.SetBounds(685, 14, 70, 22);
  L.Caption := '결제수단';
  FMethodCombo := TComboBox.Create(Self);
  FMethodCombo.Parent := EntryPanel;
  FMethodCombo.SetBounds(755, 9, 130, 30);
  FMethodCombo.Style := csDropDownList;
  FMethodCombo.Items.Add('현금');
  FMethodCombo.Items.Add('계좌이체');
  FMethodCombo.Items.Add('카드');
  FMethodCombo.Items.Add('기타');
  FMethodCombo.ItemIndex := 0;

  L := TLabel.Create(Self);
  L.Parent := EntryPanel;
  L.SetBounds(14, 58, 70, 22);
  L.Caption := '사용내역';
  FDescriptionEdit := TEdit.Create(Self);
  FDescriptionEdit.Parent := EntryPanel;
  FDescriptionEdit.SetBounds(88, 53, 582, 30);
  FDescriptionEdit.TextHint := '지출 내용을 입력하세요';

  L := TLabel.Create(Self);
  L.Parent := EntryPanel;
  L.SetBounds(685, 58, 70, 22);
  L.Caption := '비고';
  FNoteEdit := TEdit.Create(Self);
  FNoteEdit.Parent := EntryPanel;
  FNoteEdit.SetBounds(755, 53, 320, 30);

  B := TButton.Create(Self);
  B.Parent := EntryPanel;
  B.SetBounds(88, 91, 150, 32);
  B.Caption := '지출 등록';
  B.OnClick := AddClick;

  B := TButton.Create(Self);
  B.Parent := EntryPanel;
  B.SetBounds(250, 91, 150, 32);
  B.Caption := '선택 지출 취소';
  B.OnClick := VoidClick;

  FGrid := TStringGrid.Create(Self);
  FGrid.Parent := Self;
  FGrid.Align := alClient;
  FGrid.FixedRows := 1;
  FGrid.FixedCols := 0;
  FGrid.ColCount := 7;
  FGrid.RowCount := 2;
  FGrid.DefaultRowHeight := 28;
  FGrid.Options := FGrid.Options + [goRowSelect, goColSizing];
  FGrid.Cells[0, 0] := 'ID';
  FGrid.Cells[1, 0] := '지출일';
  FGrid.Cells[2, 0] := '분류';
  FGrid.Cells[3, 0] := '사용내역';
  FGrid.Cells[4, 0] := '결제수단';
  FGrid.Cells[5, 0] := '금액';
  FGrid.Cells[6, 0] := '상태';
  FGrid.ColWidths[0] := 0;
  FGrid.ColWidths[1] := 110;
  FGrid.ColWidths[2] := 130;
  FGrid.ColWidths[3] := 360;
  FGrid.ColWidths[4] := 110;
  FGrid.ColWidths[5] := 140;
  FGrid.ColWidths[6] := 90;

  ButtonPanel := TPanel.Create(Self);
  ButtonPanel.Parent := Self;
  ButtonPanel.Align := alBottom;
  ButtonPanel.Height := 54;
  ButtonPanel.BevelOuter := bvNone;

  FTotalLabel := TLabel.Create(Self);
  FTotalLabel.Parent := ButtonPanel;
  FTotalLabel.SetBounds(16, 12, 500, 26);
  FTotalLabel.Font.Size := 13;
  FTotalLabel.Font.Style := [fsBold];
  FTotalLabel.Font.Color := clBlue;

  FStatusLabel := TLabel.Create(Self);
  FStatusLabel.Parent := ButtonPanel;
  FStatusLabel.SetBounds(540, 16, 520, 22);
  FStatusLabel.Caption := '지출 내역을 조회하세요.';
end;

procedure TfrmExpense.SetStatus(const AText: string);
begin
  FStatusLabel.Caption := AText;
end;

function TfrmExpense.NextExpenseID: Int64;
var
  Q: TFDQuery;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmDatabase.Connection;
    Q.SQL.Text := 'SELECT GEN_ID(GEN_POS_OPERATING_EXPENSE_ID, 1) FROM RDB$DATABASE';
    Q.Open;
    Result := Q.Fields[0].AsLargeInt;
  finally
    Q.Free;
  end;
end;

procedure TfrmExpense.RefreshClick(Sender: TObject);
begin
  try
    RefreshExpenses;
  except
    on E: Exception do
      MessageDlg('지출 조회에 실패했습니다: ' + E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TfrmExpense.RefreshExpenses;
var
  Q: TFDQuery;
  Row: Integer;
  TotalAmount: Currency;
begin
  if FEndDate.Date < FStartDate.Date then
    raise Exception.Create('종료일은 시작일보다 빠를 수 없습니다.');

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmDatabase.Connection;
    Q.SQL.Text :=
      'SELECT EXPENSE_ID, EXPENSE_DATE, CATEGORY, DESCRIPTION, ' +
      'PAYMENT_METHOD, AMOUNT, EXPENSE_STATUS FROM POS_OPERATING_EXPENSE ' +
      'WHERE STORE_ID=:STORE_ID AND EXPENSE_DATE>=:START_DATE ' +
      'AND EXPENSE_DATE<=:END_DATE ORDER BY EXPENSE_DATE DESC, EXPENSE_ID DESC';
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.ParamByName('START_DATE').AsDate := FStartDate.Date;
    Q.ParamByName('END_DATE').AsDate := FEndDate.Date;
    Q.Open;

    FGrid.RowCount := Max(2, Q.RecordCount + 1);
    Row := 1;
    TotalAmount := 0;
    while not Q.Eof do
    begin
      FGrid.Cells[0, Row] := Q.FieldByName('EXPENSE_ID').AsString;
      FGrid.Cells[1, Row] := FormatDateTime('yyyy-mm-dd',
        Q.FieldByName('EXPENSE_DATE').AsDateTime);
      FGrid.Cells[2, Row] := Q.FieldByName('CATEGORY').AsString;
      FGrid.Cells[3, Row] := Q.FieldByName('DESCRIPTION').AsString;
      if Q.FieldByName('PAYMENT_METHOD').AsString = 'CASH' then
        FGrid.Cells[4, Row] := '현금'
      else if Q.FieldByName('PAYMENT_METHOD').AsString = 'BANK' then
        FGrid.Cells[4, Row] := '계좌이체'
      else if Q.FieldByName('PAYMENT_METHOD').AsString = 'CARD' then
        FGrid.Cells[4, Row] := '카드'
      else
        FGrid.Cells[4, Row] := '기타';
      FGrid.Cells[5, Row] := FormatCurr('#,##0', Q.FieldByName('AMOUNT').AsCurrency);
      if Q.FieldByName('EXPENSE_STATUS').AsString = 'ACTIVE' then
      begin
        FGrid.Cells[6, Row] := '정상';
        TotalAmount := TotalAmount + Q.FieldByName('AMOUNT').AsCurrency;
      end
      else
        FGrid.Cells[6, Row] := '취소';
      Inc(Row);
      Q.Next;
    end;
    if Row = 1 then
      FGrid.Cells[1, 1] := '조회된 지출 내역이 없습니다.';
  finally
    Q.Free;
  end;

  FTotalLabel.Caption := '조회기간 정상 지출 합계: ' +
    FormatCurr('#,##0', TotalAmount) + '원';
  SetStatus('조회 완료: ' + FormatDateTime('yyyy-mm-dd', FStartDate.Date) +
    ' ~ ' + FormatDateTime('yyyy-mm-dd', FEndDate.Date));
end;

procedure TfrmExpense.AddClick(Sender: TObject);
var
  Q: TFDQuery;
  ExpenseID: Int64;
  MethodCode: string;
  AmountValue: Currency;
begin
  try
    if Trim(FCategoryEdit.Text) = '' then
      raise Exception.Create('지출 분류를 입력해 주세요.');
    if Trim(FDescriptionEdit.Text) = '' then
      raise Exception.Create('사용내역을 입력해 주세요.');
    if not TryStrToCurr(Trim(FAmountEdit.Text), AmountValue) or
      (AmountValue <= 0) then
      raise Exception.Create('금액은 0보다 큰 숫자로 입력해 주세요.');

    case FMethodCombo.ItemIndex of
      0: MethodCode := 'CASH';
      1: MethodCode := 'BANK';
      2: MethodCode := 'CARD';
    else
      MethodCode := 'OTHER';
    end;

    ExpenseID := NextExpenseID;
    Q := TFDQuery.Create(nil);
    try
      Q.Connection := dmDatabase.Connection;
      Q.SQL.Text :=
        'INSERT INTO POS_OPERATING_EXPENSE (EXPENSE_ID, STORE_ID, ' +
        'EXPENSE_DATE, CATEGORY, DESCRIPTION, AMOUNT, PAYMENT_METHOD, NOTE, ' +
        'CREATED_BY) VALUES (:ID, :STORE_ID, :EXPENSE_DATE, :CATEGORY, ' +
        ':DESCRIPTION, :AMOUNT, :METHOD, :NOTE, :EMPLOYEE_ID)';
      Q.ParamByName('ID').AsLargeInt := ExpenseID;
      Q.ParamByName('STORE_ID').AsInteger := FStoreID;
      Q.ParamByName('EXPENSE_DATE').AsDate := FExpenseDate.Date;
      Q.ParamByName('CATEGORY').AsString := Trim(FCategoryEdit.Text);
      Q.ParamByName('DESCRIPTION').AsString := Trim(FDescriptionEdit.Text);
      Q.ParamByName('AMOUNT').AsCurrency := AmountValue;
      Q.ParamByName('METHOD').AsString := MethodCode;
      Q.ParamByName('NOTE').AsString := Trim(FNoteEdit.Text);
      Q.ParamByName('EMPLOYEE_ID').AsInteger := FEmployeeID;
      Q.ExecSQL;
    finally
      Q.Free;
    end;

    FCategoryEdit.Clear;
    FDescriptionEdit.Clear;
    FAmountEdit.Clear;
    FNoteEdit.Clear;
    FStartDate.Date := StartOfTheMonth(FExpenseDate.Date);
    FEndDate.Date := FExpenseDate.Date;
    RefreshExpenses;
    MessageDlg('영업비용을 등록했습니다.', mtInformation, [mbOK], 0);
  except
    on E: Exception do
      MessageDlg('영업비용 등록에 실패했습니다: ' + E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TfrmExpense.VoidClick(Sender: TObject);
var
  Q: TFDQuery;
  ExpenseID: Int64;
begin
  if FGrid.Row < 1 then Exit;
  if not TryStrToInt64(FGrid.Cells[0, FGrid.Row], ExpenseID) then Exit;
  if MessageDlg('선택한 지출을 취소 처리하시겠습니까?' + sLineBreak +
    '취소 이력은 보존되며 삭제되지 않습니다.',
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmDatabase.Connection;
    Q.SQL.Text :=
      'UPDATE POS_OPERATING_EXPENSE SET EXPENSE_STATUS=''VOID'', ' +
      'VOIDED_BY=:EMPLOYEE_ID, VOIDED_AT=CURRENT_TIMESTAMP ' +
      'WHERE STORE_ID=:STORE_ID AND EXPENSE_ID=:EXPENSE_ID ' +
      'AND EXPENSE_STATUS=''ACTIVE''';
    Q.ParamByName('EMPLOYEE_ID').AsInteger := FEmployeeID;
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.ParamByName('EXPENSE_ID').AsLargeInt := ExpenseID;
    Q.ExecSQL;
    if Q.RowsAffected = 0 then
      raise Exception.Create('이미 취소되었거나 찾을 수 없는 지출입니다.');
    RefreshExpenses;
    SetStatus('선택한 지출을 취소 처리했습니다.');
  except
    on E: Exception do
      MessageDlg('지출 취소에 실패했습니다: ' + E.Message, mtError, [mbOK], 0);
  end;
  Q.Free;
end;

end.
