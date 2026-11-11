unit uShiftForm;

interface

uses
  System.SysUtils, System.Classes, System.Math, System.StrUtils, Data.DB,
  FireDAC.Comp.Client, FireDAC.Stan.Param,
  Vcl.Forms, Vcl.Controls, Vcl.Graphics, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Grids, Vcl.Dialogs;

type
  TfrmShiftManagement = class(TForm)
  private
    FStoreID: Integer;
    FTerminalID: Integer;
    FEmployeeID: Integer;
    FShiftID: Int64;
    FStatusLabel: TLabel;
    FOpeningLabel: TLabel;
    FExpectedLabel: TLabel;
    FMovementLabel: TLabel;
    FGrid: TStringGrid;
    FOpenButton: TButton;
    FInButton: TButton;
    FOutButton: TButton;
    FCloseButton: TButton;
    FRefreshButton: TButton;
    FHistoryButton: TButton;
    procedure BuildUI;
    procedure EnsureTerminal;
    procedure RefreshData;
    procedure OpenShiftClick(Sender: TObject);
    procedure CashInClick(Sender: TObject);
    procedure CashOutClick(Sender: TObject);
    procedure CloseShiftClick(Sender: TObject);
    procedure RefreshClick(Sender: TObject);
    procedure HistoryClick(Sender: TObject);
    procedure ShowShiftHistory;
    procedure AddCashMovement(const AMovementType: string);
    function CurrentShiftID: Int64;
    function ExpectedCash(AShiftID: Int64): Currency;
    function NextSequenceValue(const ASequenceName: string): Int64;
    function PromptAmount(const ATitle, APrompt: string;
      out AAmount: Currency): Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetContext(AStoreID, ATerminalID, AEmployeeID: Integer);
    class function HasOpenShift(AConnection: TFDConnection;
      AStoreID, ATerminalID: Integer): Boolean; static;
  end;

implementation

uses
  uDatabase;

constructor TfrmShiftManagement.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  BuildUI;
end;

procedure TfrmShiftManagement.BuildUI;
var
  Header, SummaryPanel, ButtonPanel: TPanel;
  L: TLabel;
begin
  Caption := '영업 개점 / 마감 및 현금시재 관리';
  Font.Name := '맑은 고딕';
  Width := 980;
  Height := 650;
  Position := poScreenCenter;

  Header := TPanel.Create(Self);
  Header.Parent := Self;
  Header.Align := alTop;
  Header.Height := 64;
  Header.BevelOuter := bvNone;

  L := TLabel.Create(Self);
  L.Parent := Header;
  L.Left := 16;
  L.Top := 22;
  L.Caption := '영업 단말 시재 관리';
  L.Font.Style := [fsBold];
  L.Font.Size := 13;

  FStatusLabel := TLabel.Create(Self);
  FStatusLabel.Parent := Header;
  FStatusLabel.Left := 270;
  FStatusLabel.Top := 24;
  FStatusLabel.Caption := '영업 상태 확인 중';
  FStatusLabel.Font.Style := [fsBold];

  SummaryPanel := TPanel.Create(Self);
  SummaryPanel.Parent := Self;
  SummaryPanel.Align := alTop;
  SummaryPanel.Height := 112;
  SummaryPanel.BevelOuter := bvLowered;

  FOpeningLabel := TLabel.Create(Self);
  FOpeningLabel.Parent := SummaryPanel;
  FOpeningLabel.Left := 20;
  FOpeningLabel.Top := 18;
  FOpeningLabel.Caption := '개점 준비금: 0원';
  FOpeningLabel.Font.Size := 12;

  FExpectedLabel := TLabel.Create(Self);
  FExpectedLabel.Parent := SummaryPanel;
  FExpectedLabel.Left := 330;
  FExpectedLabel.Top := 18;
  FExpectedLabel.Caption := '현재 예상 시재: 0원';
  FExpectedLabel.Font.Size := 15;
  FExpectedLabel.Font.Style := [fsBold];
  FExpectedLabel.Font.Color := clBlue;

  FMovementLabel := TLabel.Create(Self);
  FMovementLabel.Parent := SummaryPanel;
  FMovementLabel.Left := 20;
  FMovementLabel.Top := 62;
  FMovementLabel.Caption := '입금: 0원 / 출금: 0원';

  FGrid := TStringGrid.Create(Self);
  FGrid.Parent := Self;
  FGrid.Align := alClient;
  FGrid.FixedRows := 1;
  FGrid.FixedCols := 0;
  FGrid.ColCount := 5;
  FGrid.RowCount := 2;
  FGrid.DefaultRowHeight := 27;
  FGrid.Options := FGrid.Options + [goRowSelect, goColSizing];
  FGrid.Cells[0, 0] := '일시';
  FGrid.Cells[1, 0] := '구분';
  FGrid.Cells[2, 0] := '사유';
  FGrid.Cells[3, 0] := '금액';
  FGrid.Cells[4, 0] := '처리 직원';
  FGrid.ColWidths[0] := 160;
  FGrid.ColWidths[1] := 90;
  FGrid.ColWidths[2] := 300;
  FGrid.ColWidths[3] := 130;
  FGrid.ColWidths[4] := 150;

  ButtonPanel := TPanel.Create(Self);
  ButtonPanel.Parent := Self;
  ButtonPanel.Align := alBottom;
  ButtonPanel.Height := 66;
  ButtonPanel.BevelOuter := bvNone;

  FOpenButton := TButton.Create(Self);
  FOpenButton.Parent := ButtonPanel;
  FOpenButton.SetBounds(12, 12, 150, 42);
  FOpenButton.Caption := '영업 개점';
  FOpenButton.Font.Style := [fsBold];
  FOpenButton.OnClick := OpenShiftClick;

  FInButton := TButton.Create(Self);
  FInButton.Parent := ButtonPanel;
  FInButton.SetBounds(174, 12, 130, 42);
  FInButton.Caption := '현금 입금';
  FInButton.OnClick := CashInClick;

  FOutButton := TButton.Create(Self);
  FOutButton.Parent := ButtonPanel;
  FOutButton.SetBounds(314, 12, 130, 42);
  FOutButton.Caption := '현금 출금';
  FOutButton.OnClick := CashOutClick;

  FCloseButton := TButton.Create(Self);
  FCloseButton.Parent := ButtonPanel;
  FCloseButton.SetBounds(454, 12, 150, 42);
  FCloseButton.Caption := '영업 마감';
  FCloseButton.Font.Style := [fsBold];
  FCloseButton.OnClick := CloseShiftClick;

  FRefreshButton := TButton.Create(Self);
  FRefreshButton.Parent := ButtonPanel;
  FRefreshButton.SetBounds(614, 12, 120, 42);
  FRefreshButton.Caption := '새로고침';
  FRefreshButton.OnClick := RefreshClick;

  FHistoryButton := TButton.Create(Self);
  FHistoryButton.Parent := ButtonPanel;
  FHistoryButton.SetBounds(744, 12, 130, 42);
  FHistoryButton.Caption := '마감 이력';
  FHistoryButton.OnClick := HistoryClick;
end;

procedure TfrmShiftManagement.SetContext(AStoreID, ATerminalID,
  AEmployeeID: Integer);
begin
  FStoreID := AStoreID;
  FTerminalID := ATerminalID;
  FEmployeeID := AEmployeeID;
  EnsureTerminal;
  RefreshData;
end;

procedure TfrmShiftManagement.EnsureTerminal;
var
  Q: TFDQuery;
  ExistingStoreID: Integer;
begin
  if (FStoreID <= 0) or (FTerminalID <= 0) then
    raise Exception.Create('매장번호와 POS 단말번호를 확인해 주세요.');

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmDatabase.Connection;
    Q.SQL.Text := 'SELECT STORE_ID FROM POS_TERMINAL WHERE TERMINAL_ID=:ID';
    Q.ParamByName('ID').AsInteger := FTerminalID;
    Q.Open;
    if not Q.IsEmpty then
    begin
      ExistingStoreID := Q.FieldByName('STORE_ID').AsInteger;
      if ExistingStoreID <> FStoreID then
        raise Exception.Create('설정한 POS 단말번호가 다른 매장에 등록되어 있습니다.');
      Exit;
    end;
    Q.Close;
    Q.SQL.Text := 'INSERT INTO POS_TERMINAL (TERMINAL_ID, TERMINAL_NAME, STORE_ID, ACTIVE_YN) ' +
      'VALUES (:ID, :NAME, :STORE_ID, ''Y'')';
    Q.ParamByName('ID').AsInteger := FTerminalID;
    Q.ParamByName('NAME').AsString := 'POS ' + IntToStr(FTerminalID);
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

class function TfrmShiftManagement.HasOpenShift(AConnection: TFDConnection;
  AStoreID, ATerminalID: Integer): Boolean;
var
  Q: TFDQuery;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := AConnection;
    Q.SQL.Text := 'SELECT COUNT(*) FROM POS_SHIFT WHERE STORE_ID=:STORE_ID ' +
      'AND TERMINAL_ID=:TERMINAL_ID AND SHIFT_STATUS=''OPEN''';
    Q.ParamByName('STORE_ID').AsInteger := AStoreID;
    Q.ParamByName('TERMINAL_ID').AsInteger := ATerminalID;
    Q.Open;
    Result := Q.Fields[0].AsInteger > 0;
  finally
    Q.Free;
  end;
end;

function TfrmShiftManagement.NextSequenceValue(
  const ASequenceName: string): Int64;
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

function TfrmShiftManagement.CurrentShiftID: Int64;
var
  Q: TFDQuery;
begin
  Result := 0;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmDatabase.Connection;
    Q.SQL.Text := 'SELECT FIRST 1 SHIFT_ID FROM POS_SHIFT ' +
      'WHERE STORE_ID=:STORE_ID AND TERMINAL_ID=:TERMINAL_ID ' +
      'AND SHIFT_STATUS=''OPEN'' ORDER BY OPENED_AT DESC';
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.ParamByName('TERMINAL_ID').AsInteger := FTerminalID;
    Q.Open;
    if not Q.IsEmpty then
      Result := Q.Fields[0].AsLargeInt;
  finally
    Q.Free;
  end;
end;

function TfrmShiftManagement.ExpectedCash(AShiftID: Int64): Currency;
var
  Q: TFDQuery;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmDatabase.Connection;
    Q.SQL.Text :=
      'SELECT S.OPENING_CASH ' +
      '+ COALESCE((SELECT SUM(P.PAYMENT_AMOUNT) FROM POS_PAYMENT P ' +
      'JOIN POS_ORDER O ON O.ORDER_ID=P.ORDER_ID ' +
      'WHERE O.STORE_ID=S.STORE_ID AND O.TERMINAL_ID=S.TERMINAL_ID ' +
      'AND O.ORDERED_AT>=S.OPENED_AT AND P.PAID_AT>=S.OPENED_AT ' +
      'AND P.PAYMENT_METHOD=''CASH'' ' +
      'AND COALESCE(P.PAYMENT_STATUS,''APPROVED'')=''APPROVED''), 0) ' +
      '+ COALESCE((SELECT SUM(CASE WHEN M.MOVEMENT_TYPE=''IN'' THEN M.AMOUNT ' +
      'ELSE -M.AMOUNT END) FROM POS_CASH_MOVEMENT M ' +
      'WHERE M.SHIFT_ID=S.SHIFT_ID), 0) AS EXPECTED_CASH ' +
      'FROM POS_SHIFT S WHERE S.SHIFT_ID=:SHIFT_ID';
    Q.ParamByName('SHIFT_ID').AsLargeInt := AShiftID;
    Q.Open;
    if Q.IsEmpty then
      raise Exception.Create('영업 세션을 찾을 수 없습니다.');
    Result := Q.FieldByName('EXPECTED_CASH').AsCurrency;
  finally
    Q.Free;
  end;
end;

procedure TfrmShiftManagement.RefreshData;
var
  Q: TFDQuery;
  Row: Integer;
  TotalIn, TotalOut: Currency;
begin
  FShiftID := CurrentShiftID;
  FGrid.RowCount := 2;
  FGrid.Cells[0, 1] := '';
  FGrid.Cells[1, 1] := '';
  FGrid.Cells[2, 1] := '';
  FGrid.Cells[3, 1] := '';
  FGrid.Cells[4, 1] := '';

  if FShiftID = 0 then
  begin
    FStatusLabel.Caption := '영업 미개점 - 개점 처리가 필요합니다.';
    FOpeningLabel.Caption := '개점 준비금: -';
    FExpectedLabel.Caption := '현재 예상 시재: -';
    FMovementLabel.Caption := '입금: - / 출금: -';
    FOpenButton.Enabled := True;
    FInButton.Enabled := False;
    FOutButton.Enabled := False;
    FCloseButton.Enabled := False;
    Exit;
  end;

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmDatabase.Connection;
    Q.SQL.Text := 'SELECT BUSINESS_DATE, OPENING_CASH, OPENED_AT, ' +
      'E.EMPLOYEE_NAME AS OPENED_BY_NAME FROM POS_SHIFT S ' +
      'JOIN EMPLOYEE E ON E.EMPLOYEE_ID=S.OPENED_BY WHERE S.SHIFT_ID=:ID';
    Q.ParamByName('ID').AsLargeInt := FShiftID;
    Q.Open;
    FStatusLabel.Caption := '영업 중 - 영업일자: ' +
      FormatDateTime('yyyy-mm-dd', Q.FieldByName('BUSINESS_DATE').AsDateTime) +
      ' / 개점: ' + FormatDateTime('hh:nn', Q.FieldByName('OPENED_AT').AsDateTime) +
      ' / 담당: ' + Q.FieldByName('OPENED_BY_NAME').AsString;
    FOpeningLabel.Caption := '개점 준비금: ' +
      FormatCurr('#,##0', Q.FieldByName('OPENING_CASH').AsCurrency) + '원';
    Q.Close;

    FExpectedLabel.Caption := '현재 예상 시재: ' +
      FormatCurr('#,##0', ExpectedCash(FShiftID)) + '원';

    Q.SQL.Text := 'SELECT COALESCE(SUM(IIF(MOVEMENT_TYPE=''IN'', AMOUNT, 0)),0) AS TOTAL_IN, ' +
      'COALESCE(SUM(IIF(MOVEMENT_TYPE=''OUT'', AMOUNT, 0)),0) AS TOTAL_OUT ' +
      'FROM POS_CASH_MOVEMENT WHERE SHIFT_ID=:ID';
    Q.ParamByName('ID').AsLargeInt := FShiftID;
    Q.Open;
    TotalIn := Q.FieldByName('TOTAL_IN').AsCurrency;
    TotalOut := Q.FieldByName('TOTAL_OUT').AsCurrency;
    FMovementLabel.Caption := '현금 입금: ' + FormatCurr('#,##0', TotalIn) +
      '원  /  현금 출금: ' + FormatCurr('#,##0', TotalOut) + '원';
    Q.Close;

    Q.SQL.Text := 'SELECT M.CREATED_AT, M.MOVEMENT_TYPE, M.DESCRIPTION, ' +
      'M.AMOUNT, E.EMPLOYEE_NAME FROM POS_CASH_MOVEMENT M ' +
      'JOIN EMPLOYEE E ON E.EMPLOYEE_ID=M.EMPLOYEE_ID ' +
      'WHERE M.SHIFT_ID=:ID ORDER BY M.CREATED_AT DESC';
    Q.ParamByName('ID').AsLargeInt := FShiftID;
    Q.Open;
    FGrid.RowCount := Max(2, Q.RecordCount + 1);
    Row := 1;
    while not Q.Eof do
    begin
      FGrid.Cells[0, Row] := FormatDateTime('yyyy-mm-dd hh:nn',
        Q.FieldByName('CREATED_AT').AsDateTime);
      if Q.FieldByName('MOVEMENT_TYPE').AsString = 'IN' then
        FGrid.Cells[1, Row] := '입금'
      else
        FGrid.Cells[1, Row] := '출금';
      FGrid.Cells[2, Row] := Q.FieldByName('DESCRIPTION').AsString;
      FGrid.Cells[3, Row] := FormatCurr('#,##0', Q.FieldByName('AMOUNT').AsCurrency);
      FGrid.Cells[4, Row] := Q.FieldByName('EMPLOYEE_NAME').AsString;
      Inc(Row);
      Q.Next;
    end;
  finally
    Q.Free;
  end;

  FOpenButton.Enabled := False;
  FInButton.Enabled := True;
  FOutButton.Enabled := True;
  FCloseButton.Enabled := True;
end;

function TfrmShiftManagement.PromptAmount(const ATitle, APrompt: string;
  out AAmount: Currency): Boolean;
var
  S: string;
begin
  S := '0';
  Result := InputQuery(ATitle, APrompt, S);
  if not Result then Exit;
  if not TryStrToCurr(Trim(S), AAmount) or (AAmount < 0) then
    raise Exception.Create('0 이상의 금액을 숫자로 입력해 주세요.');
end;

procedure TfrmShiftManagement.OpenShiftClick(Sender: TObject);
var
  OpeningCash: Currency;
  ShiftID: Int64;
  Q: TFDQuery;
begin
  if not PromptAmount('영업 개점', '개점 준비금(원)을 입력하세요.', OpeningCash) then Exit;
  if HasOpenShift(dmDatabase.Connection, FStoreID, FTerminalID) then
    raise Exception.Create('이미 영업 중인 단말입니다.');

  dmDatabase.Connection.StartTransaction;
  try
    ShiftID := NextSequenceValue('GEN_POS_SHIFT_ID');
    Q := TFDQuery.Create(nil);
    try
      Q.Connection := dmDatabase.Connection;
      Q.SQL.Text := 'INSERT INTO POS_SHIFT ' +
        '(SHIFT_ID, STORE_ID, TERMINAL_ID, BUSINESS_DATE, SHIFT_STATUS, ' +
        'OPENING_CASH, EXPECTED_CASH, OPENED_BY) ' +
        'VALUES (:ID, :STORE_ID, :TERMINAL_ID, CURRENT_DATE, ''OPEN'', :CASH, :CASH, :EMPLOYEE_ID)';
      Q.ParamByName('ID').AsLargeInt := ShiftID;
      Q.ParamByName('STORE_ID').AsInteger := FStoreID;
      Q.ParamByName('TERMINAL_ID').AsInteger := FTerminalID;
      Q.ParamByName('CASH').AsCurrency := OpeningCash;
      Q.ParamByName('EMPLOYEE_ID').AsInteger := FEmployeeID;
      Q.ExecSQL;
    finally
      Q.Free;
    end;
    dmDatabase.Connection.Commit;
  except
    dmDatabase.Connection.Rollback;
    raise;
  end;
  RefreshData;
  MessageDlg('영업 개점이 완료되었습니다.', mtInformation, [mbOK], 0);
end;

procedure TfrmShiftManagement.AddCashMovement(const AMovementType: string);
var
  Amount: Currency;
  Description: string;
  MovementID: Int64;
  Q: TFDQuery;
begin
  if FShiftID = 0 then
    raise Exception.Create('먼저 영업 개점을 해주세요.');
  if not PromptAmount(IfThen(AMovementType = 'IN', '현금 입금', '현금 출금'),
    '금액(원)을 입력하세요.', Amount) then Exit;
  if Amount <= 0 then
    raise Exception.Create('입출금 금액은 0보다 커야 합니다.');
  Description := '';
  if not InputQuery('현금 입출금 사유', '사유를 입력하세요.', Description) then Exit;
  if Trim(Description) = '' then
    raise Exception.Create('입출금 사유를 입력해 주세요.');

  dmDatabase.Connection.StartTransaction;
  try
    MovementID := NextSequenceValue('GEN_POS_CASH_MOVEMENT_ID');
    Q := TFDQuery.Create(nil);
    try
      Q.Connection := dmDatabase.Connection;
      Q.SQL.Text := 'INSERT INTO POS_CASH_MOVEMENT ' +
        '(CASH_MOVEMENT_ID, SHIFT_ID, MOVEMENT_TYPE, REASON_CODE, AMOUNT, DESCRIPTION, EMPLOYEE_ID) ' +
        'VALUES (:ID, :SHIFT_ID, :TYPE, :REASON, :AMOUNT, :DESCRIPTION, :EMPLOYEE_ID)';
      Q.ParamByName('ID').AsLargeInt := MovementID;
      Q.ParamByName('SHIFT_ID').AsLargeInt := FShiftID;
      Q.ParamByName('TYPE').AsString := AMovementType;
      Q.ParamByName('REASON').AsString := IfThen(AMovementType = 'IN', 'CASH_IN', 'CASH_OUT');
      Q.ParamByName('AMOUNT').AsCurrency := Amount;
      Q.ParamByName('DESCRIPTION').AsString := Trim(Description);
      Q.ParamByName('EMPLOYEE_ID').AsInteger := FEmployeeID;
      Q.ExecSQL;
    finally
      Q.Free;
    end;
    dmDatabase.Connection.Commit;
  except
    dmDatabase.Connection.Rollback;
    raise;
  end;
  RefreshData;
  MessageDlg('현금 ' + IfThen(AMovementType = 'IN', '입금', '출금') +
    ' 처리가 완료되었습니다.', mtInformation, [mbOK], 0);
end;

procedure TfrmShiftManagement.CashInClick(Sender: TObject);
begin
  try
    AddCashMovement('IN');
  except
    on E: Exception do
      MessageDlg('현금 입금에 실패했습니다: ' + E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TfrmShiftManagement.CashOutClick(Sender: TObject);
begin
  try
    AddCashMovement('OUT');
  except
    on E: Exception do
      MessageDlg('현금 출금에 실패했습니다: ' + E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TfrmShiftManagement.CloseShiftClick(Sender: TObject);
var
  CountQ, Q: TFDQuery;
  OpenOrderCount: Integer;
  CountedCash, Expected, Difference: Currency;
  NoteText: string;
begin
  if FShiftID = 0 then Exit;

  CountQ := TFDQuery.Create(nil);
  try
    CountQ.Connection := dmDatabase.Connection;
    CountQ.SQL.Text := 'SELECT COUNT(*) FROM POS_ORDER WHERE STORE_ID=:STORE_ID ' +
      'AND TERMINAL_ID=:TERMINAL_ID AND ORDER_STATUS=''OPEN''';
    CountQ.ParamByName('STORE_ID').AsInteger := FStoreID;
    CountQ.ParamByName('TERMINAL_ID').AsInteger := FTerminalID;
    CountQ.Open;
    OpenOrderCount := CountQ.Fields[0].AsInteger;
  finally
    CountQ.Free;
  end;
  if OpenOrderCount > 0 then
    raise Exception.Create('미결제 주문이 ' + IntToStr(OpenOrderCount) +
      '건 있습니다. 미결제 주문을 먼저 처리한 후 마감해 주세요.');

  Expected := ExpectedCash(FShiftID);
  if not PromptAmount('영업 마감', '실제 현금 시재를 입력하세요. 예상 시재: ' +
    FormatCurr('#,##0', Expected) + '원', CountedCash) then Exit;
  Difference := CountedCash - Expected;
  NoteText := '';
  if Difference <> 0 then
    NoteText := '시재 차이 확인: ' + FormatCurr('#,##0', Difference) + '원';

  if MessageDlg('영업을 마감하시겠습니까?' + sLineBreak +
    '예상 시재: ' + FormatCurr('#,##0', Expected) + '원' + sLineBreak +
    '실제 시재: ' + FormatCurr('#,##0', CountedCash) + '원' + sLineBreak +
    '시재 차이: ' + FormatCurr('#,##0', Difference) + '원',
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  dmDatabase.Connection.StartTransaction;
  try
    Q := TFDQuery.Create(nil);
    try
      Q.Connection := dmDatabase.Connection;
      Q.SQL.Text := 'SELECT SHIFT_ID FROM POS_SHIFT WHERE SHIFT_ID=:ID ' +
        'AND SHIFT_STATUS=''OPEN'' WITH LOCK';
      Q.ParamByName('ID').AsLargeInt := FShiftID;
      Q.Open;
      if Q.IsEmpty then
        raise Exception.Create('영업 세션 상태가 변경되었습니다. 새로고침해 주세요.');
      Q.Close;

      Expected := ExpectedCash(FShiftID);
      Difference := CountedCash - Expected;
      Q.SQL.Text := 'UPDATE POS_SHIFT SET SHIFT_STATUS=''CLOSED'', ' +
        'EXPECTED_CASH=:EXPECTED, COUNTED_CASH=:COUNTED, CASH_DIFFERENCE=:DIFF, ' +
        'CLOSED_BY=:EMPLOYEE_ID, CLOSED_AT=CURRENT_TIMESTAMP, CLOSE_NOTE=:NOTE ' +
        'WHERE SHIFT_ID=:ID AND SHIFT_STATUS=''OPEN''';
      Q.ParamByName('EXPECTED').AsCurrency := Expected;
      Q.ParamByName('COUNTED').AsCurrency := CountedCash;
      Q.ParamByName('DIFF').AsCurrency := Difference;
      Q.ParamByName('EMPLOYEE_ID').AsInteger := FEmployeeID;
      Q.ParamByName('NOTE').AsString := NoteText;
      Q.ParamByName('ID').AsLargeInt := FShiftID;
      Q.ExecSQL;
    finally
      Q.Free;
    end;
    dmDatabase.Connection.Commit;
  except
    dmDatabase.Connection.Rollback;
    raise;
  end;

  RefreshData;
  MessageDlg('영업 마감이 완료되었습니다.' + sLineBreak +
    '시재 차이: ' + FormatCurr('#,##0', Difference) + '원',
    mtInformation, [mbOK], 0);
end;


procedure TfrmShiftManagement.HistoryClick(Sender: TObject);
begin
  try
    ShowShiftHistory;
  except
    on E: Exception do
      MessageDlg('마감 이력 조회에 실패했습니다: ' + E.Message,
        mtError, [mbOK], 0);
  end;
end;

procedure TfrmShiftManagement.ShowShiftHistory;
var
  HistoryForm: TForm;
  Grid: TStringGrid;
  Q: TFDQuery;
  Row: Integer;
begin
  HistoryForm := TForm.Create(Self);
  try
    HistoryForm.Caption := 'POS 단말 영업마감 이력';
    HistoryForm.Font.Name := Font.Name;
    HistoryForm.Position := poScreenCenter;
    HistoryForm.Width := 1180;
    HistoryForm.Height := 520;

    Grid := TStringGrid.Create(HistoryForm);
    Grid.Parent := HistoryForm;
    Grid.Align := alClient;
    Grid.FixedRows := 1;
    Grid.FixedCols := 0;
    Grid.ColCount := 9;
    Grid.RowCount := 2;
    Grid.DefaultRowHeight := 27;
    Grid.Options := Grid.Options + [goRowSelect, goColSizing];
    Grid.Cells[0, 0] := '영업일자';
    Grid.Cells[1, 0] := '개점시각';
    Grid.Cells[2, 0] := '마감시각';
    Grid.Cells[3, 0] := '개점 준비금';
    Grid.Cells[4, 0] := '예상 시재';
    Grid.Cells[5, 0] := '실제 시재';
    Grid.Cells[6, 0] := '시재 차이';
    Grid.Cells[7, 0] := '개점 직원';
    Grid.Cells[8, 0] := '마감 직원';
    Grid.ColWidths[0] := 95;
    Grid.ColWidths[1] := 120;
    Grid.ColWidths[2] := 120;
    Grid.ColWidths[3] := 110;
    Grid.ColWidths[4] := 110;
    Grid.ColWidths[5] := 110;
    Grid.ColWidths[6] := 110;
    Grid.ColWidths[7] := 120;
    Grid.ColWidths[8] := 120;

    Q := TFDQuery.Create(nil);
    try
      Q.Connection := dmDatabase.Connection;
      Q.SQL.Text :=
        'SELECT S.BUSINESS_DATE, S.OPENED_AT, S.CLOSED_AT, S.OPENING_CASH, ' +
        'S.EXPECTED_CASH, S.COUNTED_CASH, S.CASH_DIFFERENCE, ' +
        'EO.EMPLOYEE_NAME AS OPENED_BY_NAME, EC.EMPLOYEE_NAME AS CLOSED_BY_NAME ' +
        'FROM POS_SHIFT S ' +
        'JOIN EMPLOYEE EO ON EO.EMPLOYEE_ID=S.OPENED_BY ' +
        'LEFT JOIN EMPLOYEE EC ON EC.EMPLOYEE_ID=S.CLOSED_BY ' +
        'WHERE S.STORE_ID=:STORE_ID AND S.TERMINAL_ID=:TERMINAL_ID ' +
        'AND S.SHIFT_STATUS=''CLOSED'' ORDER BY S.OPENED_AT DESC ROWS 100';
      Q.ParamByName('STORE_ID').AsInteger := FStoreID;
      Q.ParamByName('TERMINAL_ID').AsInteger := FTerminalID;
      Q.Open;
      Grid.RowCount := Max(2, Q.RecordCount + 1);
      Row := 1;
      while not Q.Eof do
      begin
        Grid.Cells[0, Row] := FormatDateTime('yyyy-mm-dd',
          Q.FieldByName('BUSINESS_DATE').AsDateTime);
        Grid.Cells[1, Row] := FormatDateTime('yyyy-mm-dd hh:nn',
          Q.FieldByName('OPENED_AT').AsDateTime);
        Grid.Cells[2, Row] := FormatDateTime('yyyy-mm-dd hh:nn',
          Q.FieldByName('CLOSED_AT').AsDateTime);
        Grid.Cells[3, Row] := FormatCurr('#,##0',
          Q.FieldByName('OPENING_CASH').AsCurrency);
        Grid.Cells[4, Row] := FormatCurr('#,##0',
          Q.FieldByName('EXPECTED_CASH').AsCurrency);
        Grid.Cells[5, Row] := FormatCurr('#,##0',
          Q.FieldByName('COUNTED_CASH').AsCurrency);
        Grid.Cells[6, Row] := FormatCurr('#,##0',
          Q.FieldByName('CASH_DIFFERENCE').AsCurrency);
        Grid.Cells[7, Row] := Q.FieldByName('OPENED_BY_NAME').AsString;
        Grid.Cells[8, Row] := Q.FieldByName('CLOSED_BY_NAME').AsString;
        Inc(Row);
        Q.Next;
      end;
      if Row = 1 then
        Grid.Cells[0, 1] := '조회된 마감 이력이 없습니다.';
    finally
      Q.Free;
    end;
    HistoryForm.ShowModal;
  finally
    HistoryForm.Free;
  end;
end;

procedure TfrmShiftManagement.RefreshClick(Sender: TObject);
begin
  try
    RefreshData;
  except
    on E: Exception do
      MessageDlg('영업 현황 조회에 실패했습니다: ' + E.Message,
        mtError, [mbOK], 0);
  end;
end;

end.
