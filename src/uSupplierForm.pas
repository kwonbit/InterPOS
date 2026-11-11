unit uSupplierForm;

interface

uses
  System.SysUtils, System.Classes, System.UITypes,
  Data.DB, FireDAC.Comp.Client, FireDAC.Stan.Param,
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.DBGrids, Vcl.Dialogs, Vcl.Graphics;

type
  TfrmSupplier = class(TForm)
  private
    FStoreID: Integer;
    FQuery: TFDQuery;
    FSource: TDataSource;
    FGrid: TDBGrid;
    FSearch: TEdit;
    procedure BuildUI;
    procedure RefreshData;
    procedure SearchClick(Sender: TObject);
    procedure AddClick(Sender: TObject);
    procedure EditClick(Sender: TObject);
    procedure ToggleClick(Sender: TObject);
    function SelectedSupplierID: Integer;
    procedure EditSupplier(AID: Integer);
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetStoreID(AStoreID: Integer);
  end;

implementation

uses
  uDatabase;

constructor TfrmSupplier.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  BuildUI;
end;

procedure TfrmSupplier.BuildUI;
var
  Header, FilterPanel, ButtonPanel: TPanel;
  L: TLabel;
  B: TButton;
begin
  Caption := '거래처 관리';
  Font.Name := '맑은 고딕';
  Position := poScreenCenter;
  Width := 1080;
  Height := 650;

  Header := TPanel.Create(Self);
  Header.Parent := Self;
  Header.Align := alTop;
  Header.Height := 58;
  Header.BevelOuter := bvNone;
  L := TLabel.Create(Self);
  L.Parent := Header;
  L.SetBounds(16, 12, 500, 32);
  L.Caption := '거래처 / 공급업체 관리';
  L.Font.Name := Font.Name;
  L.Font.Size := 14;
  L.Font.Style := [fsBold];

  FilterPanel := TPanel.Create(Self);
  FilterPanel.Parent := Self;
  FilterPanel.Align := alTop;
  FilterPanel.Height := 48;
  FilterPanel.BevelOuter := bvNone;
  L := TLabel.Create(Self);
  L.Parent := FilterPanel;
  L.SetBounds(16, 14, 70, 22);
  L.Caption := '거래처 검색';
  FSearch := TEdit.Create(Self);
  FSearch.Parent := FilterPanel;
  FSearch.SetBounds(92, 9, 260, 28);
  B := TButton.Create(Self);
  B.Parent := FilterPanel;
  B.SetBounds(362, 7, 90, 32);
  B.Caption := '검색';
  B.OnClick := SearchClick;

  FQuery := TFDQuery.Create(Self);
  FQuery.Connection := dmDatabase.Connection;
  FSource := TDataSource.Create(Self);
  FSource.DataSet := FQuery;
  FGrid := TDBGrid.Create(Self);
  FGrid.Parent := Self;
  FGrid.Align := alClient;
  FGrid.DataSource := FSource;
  FGrid.ReadOnly := True;
  FGrid.Options := FGrid.Options + [dgRowSelect, dgTitles, dgIndicator];
  FGrid.OnDblClick := EditClick;

  ButtonPanel := TPanel.Create(Self);
  ButtonPanel.Parent := Self;
  ButtonPanel.Align := alBottom;
  ButtonPanel.Height := 58;
  ButtonPanel.BevelOuter := bvNone;

  B := TButton.Create(Self);
  B.Parent := ButtonPanel;
  B.SetBounds(14, 10, 120, 38);
  B.Caption := '거래처 등록';
  B.OnClick := AddClick;

  B := TButton.Create(Self);
  B.Parent := ButtonPanel;
  B.SetBounds(144, 10, 120, 38);
  B.Caption := '거래처 수정';
  B.OnClick := EditClick;

  B := TButton.Create(Self);
  B.Parent := ButtonPanel;
  B.SetBounds(274, 10, 140, 38);
  B.Caption := '사용 / 중지 전환';
  B.OnClick := ToggleClick;

  B := TButton.Create(Self);
  B.Parent := ButtonPanel;
  B.SetBounds(940, 10, 120, 38);
  B.Caption := '닫기';
  B.ModalResult := mrClose;
end;

procedure TfrmSupplier.SetStoreID(AStoreID: Integer);
begin
  FStoreID := AStoreID;
  if FStoreID <= 0 then
    raise Exception.Create('매장 정보가 올바르지 않습니다.');
  RefreshData;
end;

procedure TfrmSupplier.RefreshData;
begin
  FQuery.Close;
  FQuery.SQL.Text :=
    'SELECT SUPPLIER_ID, SUPPLIER_NAME, BUSINESS_NO, CONTACT_NAME, ' +
    'TEL, EMAIL, ADDRESS, IIF(ACTIVE_YN=''Y'', ''사용'', ''중지'') AS STATUS_TEXT ' +
    'FROM POS_SUPPLIER WHERE STORE_ID=:STORE_ID ';
  if Trim(FSearch.Text) <> '' then
    FQuery.SQL.Add(
      'AND (SUPPLIER_NAME CONTAINING :KEYWORD OR ' +
      'COALESCE(BUSINESS_NO, '''') CONTAINING :KEYWORD OR ' +
      'COALESCE(TEL, '''') CONTAINING :KEYWORD) ');
  FQuery.SQL.Add('ORDER BY ACTIVE_YN DESC, SUPPLIER_NAME');
  FQuery.ParamByName('STORE_ID').AsInteger := FStoreID;
  if Trim(FSearch.Text) <> '' then
    FQuery.ParamByName('KEYWORD').AsString := Trim(FSearch.Text);
  FQuery.Open;
  FQuery.FieldByName('SUPPLIER_ID').Visible := False;
  FQuery.FieldByName('SUPPLIER_NAME').DisplayLabel := '거래처명';
  FQuery.FieldByName('BUSINESS_NO').DisplayLabel := '사업자번호';
  FQuery.FieldByName('CONTACT_NAME').DisplayLabel := '담당자';
  FQuery.FieldByName('TEL').DisplayLabel := '전화번호';
  FQuery.FieldByName('EMAIL').DisplayLabel := '이메일';
  FQuery.FieldByName('ADDRESS').DisplayLabel := '주소';
  FQuery.FieldByName('STATUS_TEXT').DisplayLabel := '상태';
end;

function TfrmSupplier.SelectedSupplierID: Integer;
begin
  Result := 0;
  if not FQuery.IsEmpty then
    Result := FQuery.FieldByName('SUPPLIER_ID').AsInteger;
end;

procedure TfrmSupplier.SearchClick(Sender: TObject);
begin
  RefreshData;
end;

procedure TfrmSupplier.AddClick(Sender: TObject);
begin
  EditSupplier(0);
end;

procedure TfrmSupplier.EditClick(Sender: TObject);
var
  ID: Integer;
begin
  ID := SelectedSupplierID;
  if ID = 0 then
  begin
    MessageDlg('수정할 거래처를 선택해 주세요.', mtWarning, [mbOK], 0);
    Exit;
  end;
  EditSupplier(ID);
end;

procedure TfrmSupplier.EditSupplier(AID: Integer);
var
  Q: TFDQuery;
  NameText, BusinessNo, ContactName, TelText, EmailText, AddressText, NoteText: string;
  function AskField(const ATitle, APrompt: string; var AValue: string): Boolean;
  begin
    Result := InputQuery(ATitle, APrompt, AValue);
  end;
begin
  NameText := '';
  BusinessNo := '';
  ContactName := '';
  TelText := '';
  EmailText := '';
  AddressText := '';
  NoteText := '';

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmDatabase.Connection;
    if AID > 0 then
    begin
      Q.SQL.Text := 'SELECT * FROM POS_SUPPLIER WHERE STORE_ID=:STORE_ID AND SUPPLIER_ID=:ID';
      Q.ParamByName('STORE_ID').AsInteger := FStoreID;
      Q.ParamByName('ID').AsInteger := AID;
      Q.Open;
      if Q.IsEmpty then
        raise Exception.Create('거래처 정보를 찾을 수 없습니다.');
      NameText := Q.FieldByName('SUPPLIER_NAME').AsString;
      BusinessNo := Q.FieldByName('BUSINESS_NO').AsString;
      ContactName := Q.FieldByName('CONTACT_NAME').AsString;
      TelText := Q.FieldByName('TEL').AsString;
      EmailText := Q.FieldByName('EMAIL').AsString;
      AddressText := Q.FieldByName('ADDRESS').AsString;
      NoteText := Q.FieldByName('NOTE').AsString;
      Q.Close;
    end;

    if not AskField('거래처 등록/수정', '거래처명 (필수)', NameText) then Exit;
    NameText := Trim(NameText);
    if NameText = '' then
      raise Exception.Create('거래처명은 필수입니다.');
    if not AskField('거래처 정보', '사업자등록번호', BusinessNo) then Exit;
    if not AskField('거래처 정보', '담당자명', ContactName) then Exit;
    if not AskField('거래처 정보', '전화번호', TelText) then Exit;
    if not AskField('거래처 정보', '이메일', EmailText) then Exit;
    if not AskField('거래처 정보', '주소', AddressText) then Exit;
    if not AskField('거래처 정보', '비고', NoteText) then Exit;

    if AID = 0 then
    begin
      Q.SQL.Text :=
        'INSERT INTO POS_SUPPLIER (SUPPLIER_ID, STORE_ID, SUPPLIER_NAME, ' +
        'BUSINESS_NO, CONTACT_NAME, TEL, EMAIL, ADDRESS, NOTE) ' +
        'VALUES (GEN_ID(GEN_POS_SUPPLIER_ID, 1), :STORE_ID, :NAME, ' +
        ':BIZ, :CONTACT, :TEL, :EMAIL, :ADDRESS, :NOTE)';
    end
    else
    begin
      Q.SQL.Text :=
        'UPDATE POS_SUPPLIER SET SUPPLIER_NAME=:NAME, BUSINESS_NO=:BIZ, ' +
        'CONTACT_NAME=:CONTACT, TEL=:TEL, EMAIL=:EMAIL, ADDRESS=:ADDRESS, ' +
        'NOTE=:NOTE, UPDATED_AT=CURRENT_TIMESTAMP ' +
        'WHERE STORE_ID=:STORE_ID AND SUPPLIER_ID=:ID';
      Q.ParamByName('ID').AsInteger := AID;
    end;
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.ParamByName('NAME').AsString := NameText;
    Q.ParamByName('BIZ').AsString := BusinessNo;
    Q.ParamByName('CONTACT').AsString := ContactName;
    Q.ParamByName('TEL').AsString := TelText;
    Q.ParamByName('EMAIL').AsString := EmailText;
    Q.ParamByName('ADDRESS').AsString := AddressText;
    Q.ParamByName('NOTE').AsString := NoteText;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
  RefreshData;
end;

procedure TfrmSupplier.ToggleClick(Sender: TObject);
var
  ID: Integer;
  Q: TFDQuery;
begin
  ID := SelectedSupplierID;
  if ID = 0 then
  begin
    MessageDlg('사용 상태를 변경할 거래처를 선택해 주세요.', mtWarning, [mbOK], 0);
    Exit;
  end;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmDatabase.Connection;
    Q.SQL.Text :=
      'UPDATE POS_SUPPLIER SET ACTIVE_YN=IIF(ACTIVE_YN=''Y'', ''N'', ''Y''), ' +
      'UPDATED_AT=CURRENT_TIMESTAMP WHERE STORE_ID=:STORE_ID AND SUPPLIER_ID=:ID';
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.ParamByName('ID').AsInteger := ID;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
  RefreshData;
end;

end.
