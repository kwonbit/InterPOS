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
  Captions[2] := '사용상태전환';
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
    end;
  except
    on E: Exception do
      MessageDlg('기초정보처리에실패했습니다'': ' + E.Message,
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
    with FGrids[AIndex].Columns.Add do begin FieldName := 'PRICE'; Title.Caption := '판매가격'; Width := 110; end;
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
  NameValue := ;
  GroupValue := ;
  case AIndex of
    0:
      begin
        if not InputQuery('테이블등록', '테이블이름을입력하세요''.', NameValue) then Exit;
        if not InputQuery('테이블등록', '구역이름'' (''선택'')', GroupValue) then Exit;
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
        if not InputQuery('음식종류등록', '음식종류이름을입력하세요''.', NameValue) then Exit;
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
        if not InputQuery('메뉴등록', '메뉴이름을입력하세요''.', NameValue) then Exit;
        CategoryValue := ;
        if not InputQuery('메뉴등록', '음식종류번호를입력하세요'' (''음식종류탭에서확인'').', CategoryValue) then Exit;
        if not TryStrToInt(Trim(CategoryValue), CategoryID) then
          raise Exception.Create('음식종류번호가올바르지않습니다''.');
        PriceValue := '0';
        if not InputQuery('메뉴등록', '판매가격을입력하세요''.', PriceValue) then Exit;
        if not TryStrToCurr(Trim(PriceValue), Price) or (Price < 0) then
          raise Exception.Create('판매가격을올바르게입력해주세요''.');
        DescriptionValue := ;
        if not InputQuery('메뉴등록', '메뉴설명'' (''선택'')', DescriptionValue) then Exit;
        Q := TFDQuery.Create(nil);
        try
          Q.Connection := dmDatabase.Connection;
          Q.SQL.Text := 'SELECT COUNT(*) FROM MENU_CATEGORY WHERE STORE_ID=:STORE_ID AND CATEGORY_ID=:CAT_ID AND ACTIVE_YN=''Y''';
          Q.ParamByName('STORE_ID').AsInteger := FStoreID;
          Q.ParamByName('CAT_ID').AsInteger := CategoryID;
          Q.Open;
          if Q.Fields[0].AsInteger = 0 then
            raise Exception.Create('사용중인음식종류를찾을수없습니다''.');
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
          if not InputQuery('테이블수정', '테이블이름', NameValue) then Exit;
          if not InputQuery('테이블수정', '구역이름', GroupValue) then Exit;
          Q.SQL.Text := 'UPDATE POS_TABLE SET TABLE_NAME=:NAME, TABLE_GROUP=:GRP WHERE STORE_ID=:STORE_ID AND TABLE_ID=:ID';
          Q.ParamByName('NAME').AsString := Trim(NameValue);
          Q.ParamByName('GRP').AsString := Trim(GroupValue);
        end;
      1:
        begin
          Q.SQL.Text := 'SELECT CATEGORY_NAME FROM MENU_CATEGORY WHERE STORE_ID=:STORE_ID AND CATEGORY_ID=:ID';
          Q.ParamByName('STORE_ID').AsInteger := FStoreID; Q.ParamByName('ID').AsInteger := ID;
          Q.Open; NameValue := Q.Fields[0].AsString; Q.Close;
          if not InputQuery('음식종류수정', '음식종류이름', NameValue) then Exit;
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
          if not InputQuery('메뉴수정', '메뉴이름', NameValue) then Exit;
          if not InputQuery('메뉴수정', '음식종류번호', CategoryValue) then Exit;
          if not TryStrToInt(Trim(CategoryValue), CategoryID) then raise Exception.Create('음식종류번호가올바르지않습니다''.');
          Q.SQL.Text := 'SELECT COUNT(*) FROM MENU_CATEGORY WHERE STORE_ID=:STORE_ID AND CATEGORY_ID=:CAT_ID AND ACTIVE_YN=''Y''';
          Q.ParamByName('STORE_ID').AsInteger := FStoreID;
          Q.ParamByName('CAT_ID').AsInteger := CategoryID;
          Q.Open;
          if Q.Fields[0].AsInteger = 0 then raise Exception.Create('사용중인음식종류를찾을수없습니다''.');
          Q.Close;
          if not InputQuery('메뉴수정', '판매가격', PriceValue) then Exit;
          if not TryStrToCurr(Trim(PriceValue), Price) or (Price < 0) then raise Exception.Create('판매가격이올바르지않습니다''.');
          if not InputQuery('메뉴수정', '메뉴설명', DescriptionValue) then Exit;
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
    begin NewStatus := 'N'; MessageText := '선택항목을사용중지하시겠습니까''?'; end
    else
    begin NewStatus := 'Y'; MessageText := '선택항목을다시사용하시겠습니까''?'; end;
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
