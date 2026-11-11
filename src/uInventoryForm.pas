unit uInventoryForm;

interface

uses
  System.SysUtils, System.Classes, System.Math, System.StrUtils, System.UITypes,
  FireDAC.Comp.Client, FireDAC.Stan.Param,
  Vcl.Forms, Vcl.Controls, Vcl.Graphics, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Grids, Vcl.Dialogs;

type
  TfrmInventory = class(TForm)
  private
    FStoreID: Integer;
    FEmployeeID: Integer;
    FGrid: TStringGrid;
    FStatusLabel: TLabel;
    FRefreshButton: TButton;
    FManageButton: TButton;
    FHistoryButton: TButton;
    procedure BuildUI;
    procedure RefreshData;
    procedure RefreshClick(Sender: TObject);
    procedure ManageClick(Sender: TObject);
    procedure MovementClick(Sender: TObject);
    procedure HistoryClick(Sender: TObject);
    procedure ShowHistory(AMenuID: Integer);
    function SelectedMenuID: Integer;
    function NextSequenceValue(const ASequenceName: string): Int64;
    procedure RegisterMovement(const AMovementType: string;
      AQuantity: Double; const AReason, ADescription: string);
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetContext(AStoreID, AEmployeeID: Integer);
  end;

implementation

uses
  uDatabase;

constructor TfrmInventory.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  BuildUI;
end;

procedure TfrmInventory.BuildUI;
var
  Header, ButtonPanel: TPanel;
  L: TLabel;
  B: TButton;
begin
  Caption := '재고관리';
  Font.Name := '맑은 고딕';
  Width := 1120;
  Height := 700;
  Position := poScreenCenter;

  Header := TPanel.Create(Self);
  Header.Parent := Self;
  Header.Align := alTop;
  Header.Height := 76;
  Header.BevelOuter := bvNone;

  L := TLabel.Create(Self);
  L.Parent := Header;
  L.Left := 16;
  L.Top := 12;
  L.Caption := '상품별 재고 현황';
  L.Font.Name := Font.Name;
  L.Font.Size := 14;
  L.Font.Style := [fsBold];

  FStatusLabel := TLabel.Create(Self);
  FStatusLabel.Parent := Header;
  FStatusLabel.Left := 18;
  FStatusLabel.Top := 46;
  FStatusLabel.Caption := '재고관리 상품을 선택하세요.';
  FStatusLabel.Font.Name := Font.Name;

  FGrid := TStringGrid.Create(Self);
  FGrid.Parent := Self;
  FGrid.Align := alClient;
  FGrid.FixedRows := 1;
  FGrid.FixedCols := 0;
  FGrid.ColCount := 7;
  FGrid.RowCount := 2;
  FGrid.DefaultRowHeight := 30;
  FGrid.Options := FGrid.Options + [goRowSelect, goColSizing];
  FGrid.Cells[0, 0] := '메뉴번호';
  FGrid.Cells[1, 0] := '메뉴명';
  FGrid.Cells[2, 0] := '분류';
  FGrid.Cells[3, 0] := '재고관리';
  FGrid.Cells[4, 0] := '현재고';
  FGrid.Cells[5, 0] := '안전재고';
  FGrid.Cells[6, 0] := '재고상태';
  FGrid.ColWidths[0] := 0;
  FGrid.ColWidths[1] := 260;
  FGrid.ColWidths[2] := 180;
  FGrid.ColWidths[3] := 100;
  FGrid.ColWidths[4] := 130;
  FGrid.ColWidths[5] := 130;
  FGrid.ColWidths[6] := 140;

  ButtonPanel := TPanel.Create(Self);
  ButtonPanel.Parent := Self;
  ButtonPanel.Align := alBottom;
  ButtonPanel.Height := 66;
  ButtonPanel.BevelOuter := bvNone;

  FManageButton := TButton.Create(Self);
  FManageButton.Parent := ButtonPanel;
  FManageButton.SetBounds(12, 12, 145, 42);
  FManageButton.Caption := '재고관리 설정';
  FManageButton.OnClick := ManageClick;

  B := TButton.Create(Self);
  B.Parent := ButtonPanel;
  B.SetBounds(170, 12, 110, 42);
  B.Caption := '입고 등록';
  B.Tag := 1;
  B.OnClick := MovementClick;

  B := TButton.Create(Self);
  B.Parent := ButtonPanel;
  B.SetBounds(292, 12, 110, 42);
  B.Caption := '출고 등록';
  B.Tag := 2;
  B.OnClick := MovementClick;

  B := TButton.Create(Self);
  B.Parent := ButtonPanel;
  B.SetBounds(414, 12, 125, 42);
  B.Caption := '재고 실사 조정';
  B.Tag := 3;
  B.OnClick := MovementClick;

  FHistoryButton := TButton.Create(Self);
  FHistoryButton.Parent := ButtonPanel;
  FHistoryButton.SetBounds(551, 12, 125, 42);
  FHistoryButton.Caption := '재고 이력';
  FHistoryButton.OnClick := HistoryClick;

  FRefreshButton := TButton.Create(Self);
  FRefreshButton.Parent := ButtonPanel;
  FRefreshButton.SetBounds(688, 12, 110, 42);
  FRefreshButton.Caption := '새로고침';
  FRefreshButton.OnClick := RefreshClick;

  B := TButton.Create(Self);
  B.Parent := ButtonPanel;
  B.SetBounds(988, 12, 110, 42);
  B.Caption := '닫기';
  B.ModalResult := mrClose;
end;

procedure TfrmInventory.SetContext(AStoreID, AEmployeeID: Integer);
begin
  FStoreID := AStoreID;
  FEmployeeID := AEmployeeID;
  if (FStoreID <= 0) or (FEmployeeID <= 0) then
    raise Exception.Create('매장 및 로그인 직원 정보를 확인해 주세요.');
  RefreshData;
end;

function TfrmInventory.SelectedMenuID: Integer;
begin
  Result := 0;
  if (FGrid.Row > 0) and (FGrid.Row < FGrid.RowCount) then
    TryStrToInt(FGrid.Cells[0, FGrid.Row], Result);
end;

function TfrmInventory.NextSequenceValue(const ASequenceName: string): Int64;
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

procedure TfrmInventory.RefreshData;
var
  Q: TFDQuery;
  R: Integer;
  Managed: Boolean;
  CurrentQty, LowQty: Double;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmDatabase.Connection;
    Q.SQL.Text :=
      'SELECT M.MENU_ID, M.MENU_NAME, C.CATEGORY_NAME, M.STOCK_MANAGED_YN, ' +
      'M.STOCK_QTY, M.LOW_STOCK_QTY ' +
      'FROM MENU_ITEM M JOIN MENU_CATEGORY C ON C.CATEGORY_ID=M.CATEGORY_ID ' +
      'WHERE M.STORE_ID=:STORE_ID AND M.ACTIVE_YN=''Y'' ' +
      'ORDER BY C.DISPLAY_ORDER, M.DISPLAY_ORDER, M.MENU_NAME';
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.Open;

    FGrid.RowCount := Max(2, Q.RecordCount + 1);
    R := 1;
    while not Q.Eof do
    begin
      Managed := SameText(Q.FieldByName('STOCK_MANAGED_YN').AsString, 'Y');
      CurrentQty := Q.FieldByName('STOCK_QTY').AsFloat;
      LowQty := Q.FieldByName('LOW_STOCK_QTY').AsFloat;
      FGrid.Cells[0, R] := Q.FieldByName('MENU_ID').AsString;
      FGrid.Cells[1, R] := Q.FieldByName('MENU_NAME').AsString;
      FGrid.Cells[2, R] := Q.FieldByName('CATEGORY_NAME').AsString;
      FGrid.Cells[3, R] := IfThen(Managed, '사용', '미사용');
      FGrid.Cells[4, R] := FormatFloat('#,##0.###', CurrentQty);
      FGrid.Cells[5, R] := FormatFloat('#,##0.###', LowQty);
      if not Managed then
        FGrid.Cells[6, R] := '미관리'
      else if (LowQty > 0) and (CurrentQty <= LowQty) then
        FGrid.Cells[6, R] := '재고 부족'
      else
        FGrid.Cells[6, R] := '정상';
      Inc(R);
      Q.Next;
    end;
  finally
    Q.Free;
  end;

  if FGrid.RowCount <= 2 then
    FStatusLabel.Caption := '등록된 메뉴가 없습니다.'
  else
    FStatusLabel.Caption := '상품을 선택한 후 재고관리 설정, 입고, 출고 또는 실사 조정을 진행하세요.';
end;

procedure TfrmInventory.RefreshClick(Sender: TObject);
begin
  try
    RefreshData;
  except
    on E: Exception do
      MessageDlg('재고 현황 조회 실패: ' + E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TfrmInventory.ManageClick(Sender: TObject);
var
  MenuID: Integer;
  Q: TFDQuery;
  ManagedText, LowText: string;
  Managed: string;
  LowQty: Double;
begin
  MenuID := SelectedMenuID;
  if MenuID = 0 then
  begin
    MessageDlg('재고관리 설정을 변경할 메뉴를 선택해 주세요.', mtWarning, [mbOK], 0);
    Exit;
  end;

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmDatabase.Connection;
    Q.SQL.Text := 'SELECT STOCK_MANAGED_YN, LOW_STOCK_QTY FROM MENU_ITEM ' +
      'WHERE STORE_ID=:STORE_ID AND MENU_ID=:MENU_ID';
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.ParamByName('MENU_ID').AsInteger := MenuID;
    Q.Open;
    if Q.IsEmpty then
      raise Exception.Create('선택한 메뉴를 찾을 수 없습니다.');
    Managed := Q.FieldByName('STOCK_MANAGED_YN').AsString;
    LowQty := Q.FieldByName('LOW_STOCK_QTY').AsFloat;
    Q.Close;

    ManagedText := IfThen(SameText(Managed, 'Y'), 'Y', 'N');
    if not InputQuery('재고관리 설정', '재고관리 사용 여부 (Y/N)', ManagedText) then Exit;
    ManagedText := UpperCase(Trim(ManagedText));
    if (ManagedText <> 'Y') and (ManagedText <> 'N') then
      raise Exception.Create('재고관리 사용 여부는 Y 또는 N으로 입력해 주세요.');

    LowText := FloatToStr(LowQty);
    if ManagedText = 'Y' then
    begin
      if not InputQuery('안전재고 설정', '안전재고 수량을 입력하세요.', LowText) then Exit;
      if not TryStrToFloat(Trim(LowText), LowQty) or (LowQty < 0) then
        raise Exception.Create('안전재고 수량을 0 이상의 숫자로 입력해 주세요.');
    end;

    Q.SQL.Text := 'UPDATE MENU_ITEM SET STOCK_MANAGED_YN=:MANAGED, ' +
      'LOW_STOCK_QTY=:LOW_QTY WHERE STORE_ID=:STORE_ID AND MENU_ID=:MENU_ID';
    Q.ParamByName('MANAGED').AsString := ManagedText;
    Q.ParamByName('LOW_QTY').AsFloat := LowQty;
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.ParamByName('MENU_ID').AsInteger := MenuID;
    Q.ExecSQL;
  finally
    Q.Free;
  end;

  RefreshData;
end;

procedure TfrmInventory.RegisterMovement(const AMovementType: string;
  AQuantity: Double; const AReason, ADescription: string);
var
  Q: TFDQuery;
  MenuID: Integer;
  BeforeQty, AfterQty, MoveQty: Double;
  MovementID: Int64;
begin
  MenuID := SelectedMenuID;
  if MenuID = 0 then
    raise Exception.Create('재고를 변경할 메뉴를 선택해 주세요.');
  if (AQuantity < 0) or ((AMovementType <> 'ADJUST') and (AQuantity <= 0)) then
    raise Exception.Create('입고/출고 수량은 0보다 커야 하며 실사 수량은 0 이상이어야 합니다.');

  dmDatabase.Connection.StartTransaction;
  try
    Q := TFDQuery.Create(nil);
    try
      Q.Connection := dmDatabase.Connection;
      Q.SQL.Text := 'SELECT STOCK_MANAGED_YN, STOCK_QTY FROM MENU_ITEM ' +
        'WHERE STORE_ID=:STORE_ID AND MENU_ID=:MENU_ID WITH LOCK';
      Q.ParamByName('STORE_ID').AsInteger := FStoreID;
      Q.ParamByName('MENU_ID').AsInteger := MenuID;
      Q.Open;
      if Q.IsEmpty then
        raise Exception.Create('선택한 메뉴를 찾을 수 없습니다.');
      if not SameText(Q.FieldByName('STOCK_MANAGED_YN').AsString, 'Y') then
        raise Exception.Create('먼저 해당 메뉴의 재고관리를 사용하도록 설정해 주세요.');
      BeforeQty := Q.FieldByName('STOCK_QTY').AsFloat;
      Q.Close;

      if AMovementType = 'IN' then
        AfterQty := BeforeQty + AQuantity
      else if AMovementType = 'OUT' then
      begin
        if BeforeQty < AQuantity then
          raise Exception.Create('현재고보다 출고 수량이 많습니다.');
        AfterQty := BeforeQty - AQuantity;
      end
      else
        AfterQty := AQuantity;

      if AMovementType = 'ADJUST' then
      begin
        MoveQty := Abs(AfterQty - BeforeQty);
        if MoveQty <= 0 then
          raise Exception.Create('실사 수량이 현재고와 같습니다. 변경할 내용이 없습니다.');
      end
      else
        MoveQty := AQuantity;

      Q.SQL.Text := 'UPDATE MENU_ITEM SET STOCK_QTY=:STOCK_QTY ' +
        'WHERE STORE_ID=:STORE_ID AND MENU_ID=:MENU_ID';
      Q.ParamByName('STOCK_QTY').AsFloat := AfterQty;
      Q.ParamByName('STORE_ID').AsInteger := FStoreID;
      Q.ParamByName('MENU_ID').AsInteger := MenuID;
      Q.ExecSQL;

      MovementID := NextSequenceValue('GEN_POS_STOCK_MOVEMENT_ID');
      Q.SQL.Text :=
        'INSERT INTO POS_STOCK_MOVEMENT ' +
        '(STOCK_MOVEMENT_ID, STORE_ID, MENU_ID, MOVEMENT_TYPE, QUANTITY, ' +
        'STOCK_BEFORE, STOCK_AFTER, REASON_CODE, DESCRIPTION, EMPLOYEE_ID) ' +
        'VALUES (:ID, :STORE_ID, :MENU_ID, :TYPE, :QTY, :BEFORE_QTY, ' +
        ':AFTER_QTY, :REASON, :DESCRIPTION, :EMPLOYEE_ID)';
      Q.ParamByName('ID').AsLargeInt := MovementID;
      Q.ParamByName('STORE_ID').AsInteger := FStoreID;
      Q.ParamByName('MENU_ID').AsInteger := MenuID;
      Q.ParamByName('TYPE').AsString := AMovementType;
      Q.ParamByName('QTY').AsFloat := MoveQty;
      Q.ParamByName('BEFORE_QTY').AsFloat := BeforeQty;
      Q.ParamByName('AFTER_QTY').AsFloat := AfterQty;
      Q.ParamByName('REASON').AsString := AReason;
      Q.ParamByName('DESCRIPTION').AsString := ADescription;
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
end;

procedure TfrmInventory.MovementClick(Sender: TObject);
var
  B: TButton;
  TypeCode, AmountText, Reason, Description: string;
  Amount: Double;
begin
  try
    B := Sender as TButton;
    if B.Tag = 1 then
    begin
      TypeCode := 'IN';
      Reason := 'PURCHASE';
      AmountText := '1';
      if not InputQuery('재고 입고', '입고 수량을 입력하세요.', AmountText) then Exit;
    end
    else if B.Tag = 2 then
    begin
      TypeCode := 'OUT';
      Reason := 'MANUAL_OUT';
      AmountText := '1';
      if not InputQuery('재고 출고', '출고 수량을 입력하세요.', AmountText) then Exit;
    end
    else
    begin
      TypeCode := 'ADJUST';
      Reason := 'STOCKTAKE';
      AmountText := '0';
      if not InputQuery('재고 실사 조정', '실제 재고 수량을 입력하세요.', AmountText) then Exit;
    end;

    if not TryStrToFloat(Trim(AmountText), Amount) or (Amount < 0) then
    begin
      MessageDlg('수량을 0 이상의 숫자로 입력해 주세요.', mtWarning, [mbOK], 0);
      Exit;
    end;
    if (TypeCode <> 'ADJUST') and (Amount <= 0) then
    begin
      MessageDlg('입고/출고 수량은 0보다 커야 합니다.', mtWarning, [mbOK], 0);
      Exit;
    end;

    Description := '';
    if not InputQuery('재고 사유', '비고를 입력하세요. (선택)', Description) then Exit;
    RegisterMovement(TypeCode, Amount, Reason, Description);
    MessageDlg('재고 내역이 저장되었습니다.', mtInformation, [mbOK], 0);
  except
    on E: Exception do
      MessageDlg('재고 처리 실패: ' + E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TfrmInventory.HistoryClick(Sender: TObject);
var
  MenuID: Integer;
begin
  MenuID := SelectedMenuID;
  if MenuID = 0 then
  begin
    MessageDlg('재고 이력을 조회할 메뉴를 선택해 주세요.', mtWarning, [mbOK], 0);
    Exit;
  end;
  ShowHistory(MenuID);
end;

procedure TfrmInventory.ShowHistory(AMenuID: Integer);
var
  Dlg: TForm;
  Grid: TStringGrid;
  Q: TFDQuery;
  R: Integer;
begin
  Dlg := TForm.Create(Self);
  try
    Dlg.Caption := '상품별 재고 입출고 이력';
    Dlg.Font.Name := Font.Name;
    Dlg.Position := poScreenCenter;
    Dlg.Width := 1050;
    Dlg.Height := 520;

    Grid := TStringGrid.Create(Dlg);
    Grid.Parent := Dlg;
    Grid.Align := alClient;
    Grid.FixedRows := 1;
    Grid.FixedCols := 0;
    Grid.ColCount := 7;
    Grid.RowCount := 2;
    Grid.DefaultRowHeight := 27;
    Grid.Options := Grid.Options + [goRowSelect, goColSizing];
    Grid.Cells[0, 0] := '일시';
    Grid.Cells[1, 0] := '구분';
    Grid.Cells[2, 0] := '수량';
    Grid.Cells[3, 0] := '변경 전';
    Grid.Cells[4, 0] := '변경 후';
    Grid.Cells[5, 0] := '사유/비고';
    Grid.Cells[6, 0] := '처리 직원';
    Grid.ColWidths[0] := 145;
    Grid.ColWidths[1] := 80;
    Grid.ColWidths[2] := 90;
    Grid.ColWidths[3] := 90;
    Grid.ColWidths[4] := 90;
    Grid.ColWidths[5] := 300;
    Grid.ColWidths[6] := 120;

    Q := TFDQuery.Create(nil);
    try
      Q.Connection := dmDatabase.Connection;
      Q.SQL.Text :=
        'SELECT M.CREATED_AT, M.MOVEMENT_TYPE, M.QUANTITY, ' +
        'M.STOCK_BEFORE, M.STOCK_AFTER, M.REASON_CODE, M.DESCRIPTION, ' +
        'E.EMPLOYEE_NAME FROM POS_STOCK_MOVEMENT M ' +
        'JOIN EMPLOYEE E ON E.EMPLOYEE_ID=M.EMPLOYEE_ID ' +
        'WHERE M.STORE_ID=:STORE_ID AND M.MENU_ID=:MENU_ID ' +
        'ORDER BY M.CREATED_AT DESC ROWS 300';
      Q.ParamByName('STORE_ID').AsInteger := FStoreID;
      Q.ParamByName('MENU_ID').AsInteger := AMenuID;
      Q.Open;
      Grid.RowCount := Max(2, Q.RecordCount + 1);
      R := 1;
      while not Q.Eof do
      begin
        Grid.Cells[0, R] := FormatDateTime('yyyy-mm-dd hh:nn',
          Q.FieldByName('CREATED_AT').AsDateTime);
        if Q.FieldByName('MOVEMENT_TYPE').AsString = 'IN' then
          Grid.Cells[1, R] := '입고'
        else if Q.FieldByName('MOVEMENT_TYPE').AsString = 'OUT' then
          Grid.Cells[1, R] := '출고'
        else
          Grid.Cells[1, R] := '실사조정';
        Grid.Cells[2, R] := FormatFloat('#,##0.###', Q.FieldByName('QUANTITY').AsFloat);
        Grid.Cells[3, R] := FormatFloat('#,##0.###', Q.FieldByName('STOCK_BEFORE').AsFloat);
        Grid.Cells[4, R] := FormatFloat('#,##0.###', Q.FieldByName('STOCK_AFTER').AsFloat);
        Grid.Cells[5, R] := Q.FieldByName('REASON_CODE').AsString + ' ' +
          Q.FieldByName('DESCRIPTION').AsString;
        Grid.Cells[6, R] := Q.FieldByName('EMPLOYEE_NAME').AsString;
        Inc(R);
        Q.Next;
      end;
      if R = 1 then
        Grid.Cells[0, 1] := '재고 이력이 없습니다.';
    finally
      Q.Free;
    end;
    Dlg.ShowModal;
  finally
    Dlg.Free;
  end;
end;

end.
