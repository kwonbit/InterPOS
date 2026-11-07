unit uMasterDataForm;

interface

uses
  System.SysUtils, System.Classes, System.UITypes, Data.DB,
  FireDAC.Comp.Client, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.DBGrids, Vcl.Dialogs;

type
  TfrmMasterData = class(TForm)
  published
    procedure FormCreate(Sender: TObject);
  private
    FStoreID: Integer;
    FPages: TPageControl;
    FQueries: array[0..2] of TFDQuery;
    FSources: array[0..2] of TDataSource;
    FGrids: array[0..2] of TDBGrid;
    procedure BuildPage(AIndex: Integer; const ACaption: string);
    procedure ActionClick(Sender: TObject);
    procedure GridDblClick(Sender: TObject);
    procedure RefreshPage(AIndex: Integer);
    function SelectedID(AIndex: Integer): Integer;
    function NextID(const ATable, AField: string): Integer;
    procedure AddRecord(AIndex: Integer);
    procedure EditRecord(AIndex: Integer);
    procedure ToggleRecord(AIndex: Integer);
  public
    procedure SetStoreID(AStoreID: Integer);
    procedure ShowPage(AIndex: Integer);
  end;

implementation

uses
  uDatabase;

{$R *.dfm}


type
  TMenuOptionManager = class(TForm)
  private
    FStoreID: Integer;
    FGroups: TComboBox;
    FMenus: TComboBox;
    FOptions: TListBox;
    procedure LoadGroups;
    procedure LoadMenus;
    procedure LoadOptions;
    procedure GroupChange(Sender: TObject);
    procedure AddGroupClick(Sender: TObject);
    procedure AddOptionClick(Sender: TObject);
    procedure LinkClick(Sender: TObject);
    procedure UnlinkClick(Sender: TObject);
    function SelectedGroupID: Integer;
    function SelectedMenuID: Integer;
  public
    constructor CreateManager(AOwner: TComponent; AStoreID: Integer);
  end;

constructor TMenuOptionManager.CreateManager(AOwner: TComponent; AStoreID: Integer);
var
  L: TLabel;
  P: TPanel;
  B: TButton;
begin
  inherited CreateNew(AOwner);
  FStoreID := AStoreID;
  Caption := '메뉴 옵션 관리';
  Font.Name := '맑은 고딕';
  Position := poScreenCenter;
  BorderStyle := bsDialog;
  Width := 680;
  Height := 540;

  L := TLabel.Create(Self);
  L.Parent := Self; L.Left := 20; L.Top := 20;
  L.Caption := '옵션 그룹';

  FGroups := TComboBox.Create(Self);
  FGroups.Parent := Self; FGroups.Left := 20; FGroups.Top := 44;
  FGroups.Width := 300; FGroups.Style := csDropDownList;
  FGroups.OnChange := GroupChange;

  B := TButton.Create(Self);
  B.Parent := Self; B.Left := 330; B.Top := 42;
  B.Width := 145; B.Height := 30; B.Caption := '옵션 그룹 등록';
  B.OnClick := AddGroupClick;

  L := TLabel.Create(Self);
  L.Parent := Self; L.Left := 20; L.Top := 92;
  L.Caption := '선택 그룹의 옵션 목록';

  FOptions := TListBox.Create(Self);
  FOptions.Parent := Self; FOptions.Left := 20; FOptions.Top := 116;
  FOptions.Width := 610; FOptions.Height := 230;
  FOptions.ItemHeight := 24;

  B := TButton.Create(Self);
  B.Parent := Self; B.Left := 20; B.Top := 358;
  B.Width := 145; B.Height := 36; B.Caption := '옵션 등록';
  B.OnClick := AddOptionClick;

  L := TLabel.Create(Self);
  L.Parent := Self; L.Left := 20; L.Top := 410;
  L.Caption := '옵션을 연결할 메뉴';

  FMenus := TComboBox.Create(Self);
  FMenus.Parent := Self; FMenus.Left := 20; FMenus.Top := 434;
  FMenus.Width := 300; FMenus.Style := csDropDownList;

  B := TButton.Create(Self);
  B.Parent := Self; B.Left := 330; B.Top := 432;
  B.Width := 145; B.Height := 32; B.Caption := '선택 메뉴에 연결';
  B.OnClick := LinkClick;

  B := TButton.Create(Self);
  B.Parent := Self; B.Left := 485; B.Top := 432;
  B.Width := 145; B.Height := 32; B.Caption := '메뉴 연결 해제';
  B.OnClick := UnlinkClick;

  P := TPanel.Create(Self);
  P.Parent := Self; P.Align := alBottom; P.Height := 38;
  P.BevelOuter := bvNone;
  L := TLabel.Create(Self);
  L.Parent := P; L.Align := alClient;
  L.Caption := '그룹 등록 → 옵션 등록 → 메뉴 선택 후 그룹 연결';
  L.Layout := tlCenter;

  LoadGroups;
  LoadMenus;
end;

function TMenuOptionManager.SelectedGroupID: Integer;
begin
  Result := 0;
  if FGroups.ItemIndex >= 0 then
    Result := NativeInt(FGroups.Items.Objects[FGroups.ItemIndex]);
end;

function TMenuOptionManager.SelectedMenuID: Integer;
begin
  Result := 0;
  if FMenus.ItemIndex >= 0 then
    Result := NativeInt(FMenus.Items.Objects[FMenus.ItemIndex]);
end;

procedure TMenuOptionManager.LoadGroups;
var
  Q: TFDQuery;
begin
  FGroups.Items.Clear;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmDatabase.Connection;
    Q.SQL.Text := 'SELECT OPTION_GROUP_ID, GROUP_NAME FROM MENU_OPTION_GROUP ' +
      'WHERE STORE_ID=:STORE_ID AND ACTIVE_YN=''Y'' ORDER BY DISPLAY_ORDER, OPTION_GROUP_ID';
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.Open;
    while not Q.Eof do
    begin
      FGroups.Items.AddObject(Q.FieldByName('GROUP_NAME').AsString,
        TObject(Pointer(NativeInt(Q.FieldByName('OPTION_GROUP_ID').AsInteger))));
      Q.Next;
    end;
  finally Q.Free; end;
  if FGroups.Items.Count > 0 then FGroups.ItemIndex := 0;
  LoadOptions;
end;

procedure TMenuOptionManager.LoadMenus;
var
  Q: TFDQuery;
begin
  FMenus.Items.Clear;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmDatabase.Connection;
    Q.SQL.Text := 'SELECT MENU_ID, MENU_NAME FROM MENU_ITEM ' +
      'WHERE STORE_ID=:STORE_ID AND ACTIVE_YN=''Y'' ORDER BY MENU_NAME, MENU_ID';
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.Open;
    while not Q.Eof do
    begin
      FMenus.Items.AddObject(Q.FieldByName('MENU_NAME').AsString,
        TObject(Pointer(NativeInt(Q.FieldByName('MENU_ID').AsInteger))));
      Q.Next;
    end;
  finally Q.Free; end;
  if FMenus.Items.Count > 0 then FMenus.ItemIndex := 0;
end;

procedure TMenuOptionManager.LoadOptions;
var
  Q: TFDQuery;
  S: string;
begin
  FOptions.Items.Clear;
  if SelectedGroupID = 0 then Exit;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmDatabase.Connection;
    Q.SQL.Text := 'SELECT OPTION_ID, OPTION_NAME, ADD_PRICE FROM MENU_OPTION ' +
      'WHERE OPTION_GROUP_ID=:GROUP_ID AND ACTIVE_YN=''Y'' ORDER BY DISPLAY_ORDER, OPTION_ID';
    Q.ParamByName('GROUP_ID').AsInteger := SelectedGroupID;
    Q.Open;
    while not Q.Eof do
    begin
      S := Q.FieldByName('OPTION_NAME').AsString + '  (+' +
        FormatCurr('#,##0', Q.FieldByName('ADD_PRICE').AsCurrency) + '원)';
      FOptions.Items.AddObject(S,
        TObject(Pointer(NativeInt(Q.FieldByName('OPTION_ID').AsInteger))));
      Q.Next;
    end;
  finally Q.Free; end;
end;

procedure TMenuOptionManager.GroupChange(Sender: TObject);
begin
  LoadOptions;
end;

procedure TMenuOptionManager.AddGroupClick(Sender: TObject);
var
  NameValue, RequiredValue, MaxValue, RequiredYN: string;
  MaxSelect, NewID: Integer;
  Q: TFDQuery;
begin
  NameValue := '';
  if not InputQuery('옵션 그룹 등록', '그룹 이름 (예: 맵기 선택)', NameValue) then Exit;
  if Trim(NameValue) = '' then Exit;
  RequiredValue := 'N';
  if not InputQuery('옵션 그룹 등록', '필수 선택 여부 (Y/N)', RequiredValue) then Exit;
  RequiredYN := UpperCase(Trim(RequiredValue));
  if (RequiredYN <> 'Y') and (RequiredYN <> 'N') then
    raise Exception.Create('필수 선택 여부는 Y 또는 N으로 입력해 주세요.');
  MaxValue := '1';
  if not InputQuery('옵션 그룹 등록', '최대 선택 개수 (0은 제한 없음)', MaxValue) then Exit;
  if not TryStrToInt(Trim(MaxValue), MaxSelect) or (MaxSelect < 0) then
    raise Exception.Create('최대 선택 개수를 올바르게 입력해 주세요.');
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmDatabase.Connection;
    Q.SQL.Text := 'SELECT COALESCE(MAX(OPTION_GROUP_ID), 0) + 1 FROM MENU_OPTION_GROUP';
    Q.Open; NewID := Q.Fields[0].AsInteger; Q.Close;
    Q.SQL.Text := 'INSERT INTO MENU_OPTION_GROUP ' +
      '(OPTION_GROUP_ID, STORE_ID, GROUP_NAME, REQUIRED_YN, MAX_SELECT, DISPLAY_ORDER, ACTIVE_YN) ' +
      'VALUES (:ID, :STORE_ID, :NAME, :REQ, :MAX, :ORD, ''Y'')';
    Q.ParamByName('ID').AsInteger := NewID;
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.ParamByName('NAME').AsString := Trim(NameValue);
    Q.ParamByName('REQ').AsString := RequiredYN;
    Q.ParamByName('MAX').AsInteger := MaxSelect;
    Q.ParamByName('ORD').AsInteger := NewID;
    Q.ExecSQL;
  finally Q.Free; end;
  LoadGroups;
end;

procedure TMenuOptionManager.AddOptionClick(Sender: TObject);
var
  NameValue, PriceValue: string;
  Price: Currency;
  NewID: Integer;
  Q: TFDQuery;
begin
  if SelectedGroupID = 0 then
    raise Exception.Create('먼저 옵션 그룹을 등록하고 선택해 주세요.');
  NameValue := '';
  if not InputQuery('옵션 등록', '옵션 이름 (예: 보통맛)', NameValue) then Exit;
  if Trim(NameValue) = '' then Exit;
  PriceValue := '0';
  if not InputQuery('옵션 등록', '추가 금액', PriceValue) then Exit;
  if not TryStrToCurr(Trim(PriceValue), Price) then
    raise Exception.Create('추가 금액을 올바르게 입력해 주세요.');
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmDatabase.Connection;
    Q.SQL.Text := 'SELECT COALESCE(MAX(OPTION_ID), 0) + 1 FROM MENU_OPTION';
    Q.Open; NewID := Q.Fields[0].AsInteger; Q.Close;
    Q.SQL.Text := 'INSERT INTO MENU_OPTION ' +
      '(OPTION_ID, OPTION_GROUP_ID, OPTION_NAME, ADD_PRICE, DISPLAY_ORDER, ACTIVE_YN) ' +
      'VALUES (:ID, :GROUP_ID, :NAME, :PRICE, :ORD, ''Y'')';
    Q.ParamByName('ID').AsInteger := NewID;
    Q.ParamByName('GROUP_ID').AsInteger := SelectedGroupID;
    Q.ParamByName('NAME').AsString := Trim(NameValue);
    Q.ParamByName('PRICE').AsCurrency := Price;
    Q.ParamByName('ORD').AsInteger := NewID;
    Q.ExecSQL;
  finally Q.Free; end;
  LoadOptions;
end;

procedure TMenuOptionManager.LinkClick(Sender: TObject);
var
  Q: TFDQuery;
begin
  if (SelectedGroupID = 0) or (SelectedMenuID = 0) then
    raise Exception.Create('옵션 그룹과 메뉴를 모두 선택해 주세요.');
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmDatabase.Connection;
    Q.SQL.Text := 'SELECT COUNT(*) FROM MENU_ITEM_OPTION_GROUP ' +
      'WHERE MENU_ID=:MENU_ID AND OPTION_GROUP_ID=:GROUP_ID';
    Q.ParamByName('MENU_ID').AsInteger := SelectedMenuID;
    Q.ParamByName('GROUP_ID').AsInteger := SelectedGroupID;
    Q.Open;
    if Q.Fields[0].AsInteger > 0 then
    begin
      MessageDlg('이미 연결된 옵션 그룹입니다.', mtInformation, [mbOK], 0);
      Exit;
    end;
    Q.Close;
    Q.SQL.Text := 'INSERT INTO MENU_ITEM_OPTION_GROUP (MENU_ID, OPTION_GROUP_ID, DISPLAY_ORDER) ' +
      'VALUES (:MENU_ID, :GROUP_ID, 0)';
    Q.ParamByName('MENU_ID').AsInteger := SelectedMenuID;
    Q.ParamByName('GROUP_ID').AsInteger := SelectedGroupID;
    Q.ExecSQL;
  finally Q.Free; end;
  MessageDlg('선택한 옵션 그룹을 메뉴에 연결했습니다.', mtInformation, [mbOK], 0);
end;

procedure TMenuOptionManager.UnlinkClick(Sender: TObject);
var
  Q: TFDQuery;
begin
  if (SelectedGroupID = 0) or (SelectedMenuID = 0) then
    raise Exception.Create('옵션 그룹과 메뉴를 모두 선택해 주세요.');
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmDatabase.Connection;
    Q.SQL.Text := 'DELETE FROM MENU_ITEM_OPTION_GROUP ' +
      'WHERE MENU_ID=:MENU_ID AND OPTION_GROUP_ID=:GROUP_ID';
    Q.ParamByName('MENU_ID').AsInteger := SelectedMenuID;
    Q.ParamByName('GROUP_ID').AsInteger := SelectedGroupID;
    Q.ExecSQL;
  finally Q.Free; end;
  MessageDlg('선택한 메뉴에서 옵션 그룹 연결을 해제했습니다.', mtInformation, [mbOK], 0);
end;

procedure TfrmMasterData.FormCreate(Sender: TObject);
begin
  Caption := '기초정보 관리';
  Font.Name := '맑은 고딕';
  Width := 980;
  Height := 620;
  Position := poScreenCenter;
  FPages := TPageControl.Create(Self);
  FPages.Parent := Self;
  FPages.Align := alClient;
  BuildPage(0, '테이블 관리');
  BuildPage(1, '음식 종류');
  BuildPage(2, '음식 메뉴');
end;

procedure TfrmMasterData.SetStoreID(AStoreID: Integer);
begin
  FStoreID := AStoreID;
  RefreshPage(0);
  RefreshPage(1);
  RefreshPage(2);
end;

procedure TfrmMasterData.ShowPage(AIndex: Integer);
begin
  if (AIndex >= 0) and (AIndex <= 2) then
    FPages.ActivePageIndex := AIndex;
end;

procedure TfrmMasterData.BuildPage(AIndex: Integer; const ACaption: string);
var
  Tab: TTabSheet;
  Panel: TPanel;
  Btn: TButton;
  I: Integer;
  Captions: array[0..2] of string;
begin
  Tab := TTabSheet.Create(Self);
  Tab.PageControl := FPages;
  Tab.Caption := ACaption;

  FQueries[AIndex] := TFDQuery.Create(Self);
  FQueries[AIndex].Connection := dmDatabase.Connection;
  FSources[AIndex] := TDataSource.Create(Self);
  FSources[AIndex].DataSet := FQueries[AIndex];

  FGrids[AIndex] := TDBGrid.Create(Self);
  FGrids[AIndex].Parent := Tab;
  FGrids[AIndex].Align := alClient;
  FGrids[AIndex].DataSource := FSources[AIndex];
  FGrids[AIndex].Options := FGrids[AIndex].Options +
    [dgTitles, dgRowSelect, dgColLines, dgRowLines];
  FGrids[AIndex].OnDblClick := GridDblClick;

  Panel := TPanel.Create(Self);
  Panel.Parent := Tab;
  Panel.Align := alBottom;
  Panel.Height := 64;
  Panel.BevelOuter := bvNone;

  Captions[0] := '등록';
  Captions[1] := '수정';
  Captions[2] := '사용 상태 전환';
  for I := 0 to 2 do
  begin
    Btn := TButton.Create(Self);
    Btn.Parent := Panel;
    Btn.Left := 16 + I * 150;
    Btn.Top := 10;
    Btn.Width := 138;
    Btn.Height := 44;
    Btn.Caption := Captions[I];
    Btn.Tag := AIndex * 10 + I;
    Btn.OnClick := ActionClick;
  end;
  if AIndex = 2 then
  begin
    Btn := TButton.Create(Self);
    Btn.Parent := Panel;
    Btn.Left := 466;
    Btn.Top := 10;
    Btn.Width := 138;
    Btn.Height := 44;
    Btn.Caption := '메뉴 옵션 설정';
    Btn.Tag := 23;
    Btn.OnClick := ActionClick;
  end;
end;

procedure TfrmMasterData.ActionClick(Sender: TObject);
var
  Code, PageIndex, ActionIndex: Integer;
begin
  Code := TButton(Sender).Tag;
  PageIndex := Code div 10;
  ActionIndex := Code mod 10;
  try
    case ActionIndex of
      0: AddRecord(PageIndex);
      1: EditRecord(PageIndex);
      2: ToggleRecord(PageIndex);
      3: if PageIndex = 2 then
        with TMenuOptionManager.CreateManager(Self, FStoreID) do
        try ShowModal; finally Free; end;
    end;
  except
    on E: Exception do
      MessageDlg('기초정보 처리에 실패했습니다: ' + E.Message,
        mtError, [mbOK], 0);
  end;
end;

procedure TfrmMasterData.GridDblClick(Sender: TObject);
begin
  EditRecord(FPages.ActivePageIndex);
end;

function TfrmMasterData.NextID(const ATable, AField: string): Integer;
var
  Q: TFDQuery;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmDatabase.Connection;
    Q.SQL.Text := 'SELECT COALESCE(MAX(' + AField + '), 0) + 1 FROM ' + ATable;
    Q.Open;
    Result := Q.Fields[0].AsInteger;
  finally
    Q.Free;
  end;
end;

function TfrmMasterData.SelectedID(AIndex: Integer): Integer;
const
  IDFields: array[0..2] of string = ('TABLE_ID', 'CATEGORY_ID', 'MENU_ID');
begin
  Result := 0;
  if (AIndex >= 0) and (AIndex <= 2) and
    FQueries[AIndex].Active and not FQueries[AIndex].IsEmpty then
    Result := FQueries[AIndex].FieldByName(IDFields[AIndex]).AsInteger;
end;

procedure TfrmMasterData.RefreshPage(AIndex: Integer);
begin
  FQueries[AIndex].Close;
  case AIndex of
    0:
      FQueries[AIndex].SQL.Text :=
        'SELECT TABLE_ID, TABLE_NAME, TABLE_GROUP, DISPLAY_ORDER, ' +
        'CASE WHEN ACTIVE_YN=''Y'' THEN ''사용'' ELSE ''중지'' END AS STATUS ' +
        'FROM POS_TABLE WHERE STORE_ID=:STORE_ID ORDER BY DISPLAY_ORDER, TABLE_ID';
    1:
      FQueries[AIndex].SQL.Text :=
        'SELECT CATEGORY_ID, CATEGORY_NAME, DISPLAY_ORDER, ' +
        'CASE WHEN ACTIVE_YN=''Y'' THEN ''사용'' ELSE ''중지'' END AS STATUS ' +
        'FROM MENU_CATEGORY WHERE STORE_ID=:STORE_ID ORDER BY DISPLAY_ORDER, CATEGORY_ID';
    2:
      FQueries[AIndex].SQL.Text :=
        'SELECT M.MENU_ID, M.MENU_NAME, M.CATEGORY_ID, C.CATEGORY_NAME, ' +
        'M.PRICE, M.DISPLAY_ORDER, ' +
        'CASE WHEN M.ACTIVE_YN=''Y'' THEN ''사용'' ELSE ''중지'' END AS STATUS ' +
        'FROM MENU_ITEM M JOIN MENU_CATEGORY C ON C.CATEGORY_ID=M.CATEGORY_ID ' +
        'WHERE M.STORE_ID=:STORE_ID ORDER BY C.DISPLAY_ORDER, M.DISPLAY_ORDER, M.MENU_ID';
  end;
  FQueries[AIndex].ParamByName('STORE_ID').AsInteger := FStoreID;
  FQueries[AIndex].Open;
  FGrids[AIndex].Columns.Clear;
  if AIndex = 0 then
  begin
    with FGrids[AIndex].Columns.Add do begin FieldName := 'TABLE_ID'; Title.Caption := '테이블번호'; Width := 100; end;
    with FGrids[AIndex].Columns.Add do begin FieldName := 'TABLE_NAME'; Title.Caption := '테이블명'; Width := 180; end;
    with FGrids[AIndex].Columns.Add do begin FieldName := 'TABLE_GROUP'; Title.Caption := '구역'; Width := 160; end;
    with FGrids[AIndex].Columns.Add do begin FieldName := 'DISPLAY_ORDER'; Title.Caption := '정렬'; Width := 80; end;
    with FGrids[AIndex].Columns.Add do begin FieldName := 'STATUS'; Title.Caption := '상태'; Width := 90; end;
  end
  else if AIndex = 1 then
  begin
    with FGrids[AIndex].Columns.Add do begin FieldName := 'CATEGORY_ID'; Title.Caption := '종류번호'; Width := 100; end;
    with FGrids[AIndex].Columns.Add do begin FieldName := 'CATEGORY_NAME'; Title.Caption := '음식 종류'; Width := 220; end;
    with FGrids[AIndex].Columns.Add do begin FieldName := 'DISPLAY_ORDER'; Title.Caption := '정렬'; Width := 90; end;
    with FGrids[AIndex].Columns.Add do begin FieldName := 'STATUS'; Title.Caption := '상태'; Width := 90; end;
  end
  else
  begin
    with FGrids[AIndex].Columns.Add do begin FieldName := 'MENU_ID'; Title.Caption := '메뉴번호'; Width := 90; end;
    with FGrids[AIndex].Columns.Add do begin FieldName := 'MENU_NAME'; Title.Caption := '메뉴명'; Width := 180; end;
    with FGrids[AIndex].Columns.Add do begin FieldName := 'CATEGORY_NAME'; Title.Caption := '음식 종류'; Width := 150; end;
    with FGrids[AIndex].Columns.Add do begin FieldName := 'PRICE'; Title.Caption := '판매 가격'; Width := 110; end;
    with FGrids[AIndex].Columns.Add do begin FieldName := 'DISPLAY_ORDER'; Title.Caption := '정렬'; Width := 80; end;
    with FGrids[AIndex].Columns.Add do begin FieldName := 'STATUS'; Title.Caption := '상태'; Width := 90; end;
  end;
end;

procedure TfrmMasterData.AddRecord(AIndex: Integer);
var
  NameValue, GroupValue, PriceValue, DescriptionValue, CategoryValue: string;
  NewID, CategoryID: Integer;
  Price: Currency;
  Q: TFDQuery;
begin
  NameValue := '';
  GroupValue := '';
  case AIndex of
    0:
      begin
        if not InputQuery('테이블 등록', '테이블 이름을 입력하세요.', NameValue) then Exit;
        if not InputQuery('테이블 등록', '구역 이름 (선택)', GroupValue) then Exit;
        NewID := NextID('POS_TABLE', 'TABLE_ID');
        Q := TFDQuery.Create(nil);
        try
          Q.Connection := dmDatabase.Connection;
          Q.SQL.Text := 'INSERT INTO POS_TABLE (TABLE_ID, STORE_ID, TABLE_NAME, TABLE_GROUP, DISPLAY_ORDER, ACTIVE_YN) ' +
            'VALUES (:ID, :STORE_ID, :NAME, :GRP, :ORD, ''Y'')';
          Q.ParamByName('ID').AsInteger := NewID;
          Q.ParamByName('STORE_ID').AsInteger := FStoreID;
          Q.ParamByName('NAME').AsString := Trim(NameValue);
          Q.ParamByName('GRP').AsString := Trim(GroupValue);
          Q.ParamByName('ORD').AsInteger := NewID;
          Q.ExecSQL;
        finally Q.Free; end;
      end;
    1:
      begin
        if not InputQuery('음식 종류 등록', '음식 종류 이름을 입력하세요.', NameValue) then Exit;
        NewID := NextID('MENU_CATEGORY', 'CATEGORY_ID');
        Q := TFDQuery.Create(nil);
        try
          Q.Connection := dmDatabase.Connection;
          Q.SQL.Text := 'INSERT INTO MENU_CATEGORY (CATEGORY_ID, STORE_ID, CATEGORY_NAME, DISPLAY_ORDER, ACTIVE_YN) ' +
            'VALUES (:ID, :STORE_ID, :NAME, :ORD, ''Y'')';
          Q.ParamByName('ID').AsInteger := NewID;
          Q.ParamByName('STORE_ID').AsInteger := FStoreID;
          Q.ParamByName('NAME').AsString := Trim(NameValue);
          Q.ParamByName('ORD').AsInteger := NewID;
          Q.ExecSQL;
        finally Q.Free; end;
      end;
    2:
      begin
        if not InputQuery('메뉴 등록', '메뉴 이름을 입력하세요.', NameValue) then Exit;
        CategoryValue := '';
        if not InputQuery('메뉴 등록', '음식 종류 번호를 입력하세요 (음식 종류 탭에서 확인).', CategoryValue) then Exit;
        if not TryStrToInt(Trim(CategoryValue), CategoryID) then
          raise Exception.Create('음식 종류 번호가 올바르지 않습니다.');
        PriceValue := '0';
        if not InputQuery('메뉴 등록', '판매 가격을 입력하세요.', PriceValue) then Exit;
        if not TryStrToCurr(Trim(PriceValue), Price) or (Price < 0) then
          raise Exception.Create('판매 가격을 올바르게 입력해 주세요.');
        DescriptionValue := '';
        if not InputQuery('메뉴 등록', '메뉴 설명 (선택)', DescriptionValue) then Exit;
        Q := TFDQuery.Create(nil);
        try
          Q.Connection := dmDatabase.Connection;
          Q.SQL.Text := 'SELECT COUNT(*) FROM MENU_CATEGORY WHERE STORE_ID=:STORE_ID AND CATEGORY_ID=:CAT_ID AND ACTIVE_YN=''Y''';
          Q.ParamByName('STORE_ID').AsInteger := FStoreID;
          Q.ParamByName('CAT_ID').AsInteger := CategoryID;
          Q.Open;
          if Q.Fields[0].AsInteger = 0 then
            raise Exception.Create('사용 중인 음식 종류를 찾을 수 없습니다.');
          Q.Close;
          NewID := NextID('MENU_ITEM', 'MENU_ID');
          Q.SQL.Text := 'INSERT INTO MENU_ITEM (MENU_ID, STORE_ID, CATEGORY_ID, MENU_NAME, PRICE, DESCRIPTION, DISPLAY_ORDER, ACTIVE_YN) ' +
            'VALUES (:ID, :STORE_ID, :CAT_ID, :NAME, :PRICE, :DESCRIPTION, :ORD, ''Y'')';
          Q.ParamByName('ID').AsInteger := NewID;
          Q.ParamByName('STORE_ID').AsInteger := FStoreID;
          Q.ParamByName('CAT_ID').AsInteger := CategoryID;
          Q.ParamByName('NAME').AsString := Trim(NameValue);
          Q.ParamByName('PRICE').AsCurrency := Price;
          Q.ParamByName('DESCRIPTION').AsString := Trim(DescriptionValue);
          Q.ParamByName('ORD').AsInteger := NewID;
          Q.ExecSQL;
        finally Q.Free; end;
      end;
  end;
  RefreshPage(AIndex);
end;

procedure TfrmMasterData.EditRecord(AIndex: Integer);
var
  ID, CategoryID: Integer;
  NameValue, GroupValue, PriceValue, DescriptionValue, CategoryValue: string;
  Price: Currency;
  Q: TFDQuery;
begin
  ID := SelectedID(AIndex);
  if ID = 0 then Exit;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmDatabase.Connection;
    case AIndex of
      0:
        begin
          Q.SQL.Text := 'SELECT TABLE_NAME, COALESCE(TABLE_GROUP, '''') FROM POS_TABLE WHERE STORE_ID=:STORE_ID AND TABLE_ID=:ID';
          Q.ParamByName('STORE_ID').AsInteger := FStoreID;
          Q.ParamByName('ID').AsInteger := ID;
          Q.Open; NameValue := Q.Fields[0].AsString; GroupValue := Q.Fields[1].AsString; Q.Close;
          if not InputQuery('테이블 수정', '테이블 이름', NameValue) then Exit;
          if not InputQuery('테이블 수정', '구역 이름', GroupValue) then Exit;
          Q.SQL.Text := 'UPDATE POS_TABLE SET TABLE_NAME=:NAME, TABLE_GROUP=:GRP WHERE STORE_ID=:STORE_ID AND TABLE_ID=:ID';
          Q.ParamByName('NAME').AsString := Trim(NameValue);
          Q.ParamByName('GRP').AsString := Trim(GroupValue);
        end;
      1:
        begin
          Q.SQL.Text := 'SELECT CATEGORY_NAME FROM MENU_CATEGORY WHERE STORE_ID=:STORE_ID AND CATEGORY_ID=:ID';
          Q.ParamByName('STORE_ID').AsInteger := FStoreID; Q.ParamByName('ID').AsInteger := ID;
          Q.Open; NameValue := Q.Fields[0].AsString; Q.Close;
          if not InputQuery('음식 종류 수정', '음식 종류 이름', NameValue) then Exit;
          Q.SQL.Text := 'UPDATE MENU_CATEGORY SET CATEGORY_NAME=:NAME WHERE STORE_ID=:STORE_ID AND CATEGORY_ID=:ID';
          Q.ParamByName('NAME').AsString := Trim(NameValue);
        end;
      2:
        begin
          Q.SQL.Text := 'SELECT MENU_NAME, CATEGORY_ID, PRICE, COALESCE(DESCRIPTION, '''') FROM MENU_ITEM WHERE STORE_ID=:STORE_ID AND MENU_ID=:ID';
          Q.ParamByName('STORE_ID').AsInteger := FStoreID; Q.ParamByName('ID').AsInteger := ID;
          Q.Open;
          NameValue := Q.Fields[0].AsString;
          CategoryValue := Q.Fields[1].AsString;
          PriceValue := CurrToStr(Q.Fields[2].AsCurrency);
          DescriptionValue := Q.Fields[3].AsString;
          Q.Close;
          if not InputQuery('메뉴 수정', '메뉴 이름', NameValue) then Exit;
          if not InputQuery('메뉴 수정', '음식 종류 번호', CategoryValue) then Exit;
          if not TryStrToInt(Trim(CategoryValue), CategoryID) then raise Exception.Create('음식 종류 번호가 올바르지 않습니다.');
          Q.SQL.Text := 'SELECT COUNT(*) FROM MENU_CATEGORY WHERE STORE_ID=:STORE_ID AND CATEGORY_ID=:CAT_ID AND ACTIVE_YN=''Y''';
          Q.ParamByName('STORE_ID').AsInteger := FStoreID;
          Q.ParamByName('CAT_ID').AsInteger := CategoryID;
          Q.Open;
          if Q.Fields[0].AsInteger = 0 then raise Exception.Create('사용 중인 음식 종류를 찾을 수 없습니다.');
          Q.Close;
          if not InputQuery('메뉴 수정', '판매 가격', PriceValue) then Exit;
          if not TryStrToCurr(Trim(PriceValue), Price) or (Price < 0) then raise Exception.Create('판매 가격이 올바르지 않습니다.');
          if not InputQuery('메뉴 수정', '메뉴 설명', DescriptionValue) then Exit;
          Q.SQL.Text := 'UPDATE MENU_ITEM SET MENU_NAME=:NAME, CATEGORY_ID=:CAT_ID, PRICE=:PRICE, DESCRIPTION=:DESCRIPTION WHERE STORE_ID=:STORE_ID AND MENU_ID=:ID';
          Q.ParamByName('NAME').AsString := Trim(NameValue);
          Q.ParamByName('CAT_ID').AsInteger := CategoryID;
          Q.ParamByName('PRICE').AsCurrency := Price;
          Q.ParamByName('DESCRIPTION').AsString := Trim(DescriptionValue);
        end;
    end;
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.ParamByName('ID').AsInteger := ID;
    Q.ExecSQL;
  finally Q.Free; end;
  RefreshPage(AIndex);
end;

procedure TfrmMasterData.ToggleRecord(AIndex: Integer);
var
  ID: Integer;
  Q: TFDQuery;
  CurrentStatus, NewStatus, MessageText: string;
begin
  ID := SelectedID(AIndex);
  if ID = 0 then Exit;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmDatabase.Connection;
    case AIndex of
      0: Q.SQL.Text := 'SELECT ACTIVE_YN FROM POS_TABLE WHERE STORE_ID=:STORE_ID AND TABLE_ID=:ID';
      1: Q.SQL.Text := 'SELECT ACTIVE_YN FROM MENU_CATEGORY WHERE STORE_ID=:STORE_ID AND CATEGORY_ID=:ID';
      2: Q.SQL.Text := 'SELECT ACTIVE_YN FROM MENU_ITEM WHERE STORE_ID=:STORE_ID AND MENU_ID=:ID';
    end;
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.ParamByName('ID').AsInteger := ID;
    Q.Open;
    CurrentStatus := Q.Fields[0].AsString;
    Q.Close;
    if SameText(CurrentStatus, 'Y') then
    begin NewStatus := 'N'; MessageText := '선택 항목을 사용 중지하시겠습니까?'; end
    else
    begin NewStatus := 'Y'; MessageText := '선택 항목을 다시 사용하시겠습니까?'; end;
    if MessageDlg(MessageText, mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
    case AIndex of
      0: Q.SQL.Text := 'UPDATE POS_TABLE SET ACTIVE_YN=:STATUS WHERE STORE_ID=:STORE_ID AND TABLE_ID=:ID';
      1: Q.SQL.Text := 'UPDATE MENU_CATEGORY SET ACTIVE_YN=:STATUS WHERE STORE_ID=:STORE_ID AND CATEGORY_ID=:ID';
      2: Q.SQL.Text := 'UPDATE MENU_ITEM SET ACTIVE_YN=:STATUS WHERE STORE_ID=:STORE_ID AND MENU_ID=:ID';
    end;
    Q.ParamByName('STATUS').AsString := NewStatus;
    Q.ParamByName('STORE_ID').AsInteger := FStoreID;
    Q.ParamByName('ID').AsInteger := ID;
    Q.ExecSQL;
  finally Q.Free; end;
  RefreshPage(AIndex);
end;

end.
