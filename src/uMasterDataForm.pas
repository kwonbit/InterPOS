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
  Caption := #$AE30#$CD08#$C815#$BCF4' '#$AD00#$B9AC;
  Font.Name := #$B9D1#$C740' '#$ACE0#$B515;
  Width := 980;
  Height := 620;
  Position := poScreenCenter;
  FPages := TPageControl.Create(Self);
  FPages.Parent := Self;
  FPages.Align := alClient;
  BuildPage(0, #$D14C#$C774#$BE14' '#$AD00#$B9AC);
  BuildPage(1, #$C74C#$C2DD' '#$C885#$B958);
  BuildPage(2, #$C74C#$C2DD' '#$BA54#$B274);
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

  Captions[0] := #$B4F1#$B85D;
  Captions[1] := #$C218#$C815;
  Captions[2] := #$C0AC#$C6A9' '#$C0C1#$D0DC' '#$C804#$D658;
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
      MessageDlg(#$AE30#$CD08#$C815#$BCF4' '#$CC98#$B9AC#$C5D0' '#$C2E4#$D328#$D588#$C2B5#$B2C8#$B2E4': ' + E.Message,
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
        'CASE WHEN ACTIVE_YN=''''Y'''' THEN '''''#$C0AC#$C6A9''''' ELSE '''''#$C911#$C9C0''''' END AS STATUS ' +
        'FROM POS_TABLE WHERE STORE_ID=:STORE_ID ORDER BY DISPLAY_ORDER, TABLE_ID';
    1:
      FQueries[AIndex].SQL.Text :=
        'SELECT CATEGORY_ID, CATEGORY_NAME, DISPLAY_ORDER, ' +
        'CASE WHEN ACTIVE_YN=''''Y'''' THEN '''''#$C0AC#$C6A9''''' ELSE '''''#$C911#$C9C0''''' END AS STATUS ' +
        'FROM MENU_CATEGORY WHERE STORE_ID=:STORE_ID ORDER BY DISPLAY_ORDER, CATEGORY_ID';
    2:
      FQueries[AIndex].SQL.Text :=
        'SELECT M.MENU_ID, M.MENU_NAME, M.CATEGORY_ID, C.CATEGORY_NAME, ' +
        'M.PRICE, M.DISPLAY_ORDER, ' +
        'CASE WHEN M.ACTIVE_YN=''''Y'''' THEN '''''#$C0AC#$C6A9''''' ELSE '''''#$C911#$C9C0''''' END AS STATUS ' +
        'FROM MENU_ITEM M JOIN MENU_CATEGORY C ON C.CATEGORY_ID=M.CATEGORY_ID ' +
        'WHERE M.STORE_ID=:STORE_ID ORDER BY C.DISPLAY_ORDER, M.DISPLAY_ORDER, M.MENU_ID';
  end;
  FQueries[AIndex].ParamByName('STORE_ID').AsInteger := FStoreID;
  FQueries[AIndex].Open;
  FGrids[AIndex].Columns.Clear;
  if AIndex = 0 then
  begin
    with FGrids[AIndex].Columns.Add do begin FieldName := 'TABLE_ID'; Title.Caption := #$D14C#$C774#$BE14' '#$BC88#$D638; Width := 100; end;
    with FGrids[AIndex].Columns.Add do begin FieldName := 'TABLE_NAME'; Title.Caption := #$D14C#$C774#$BE14#$BA85; Width := 180; end;
    with FGrids[AIndex].Columns.Add do begin FieldName := 'TABLE_GROUP'; Title.Caption := #$AD6C#$C5ED; Width := 160; end;
    with FGrids[AIndex].Columns.Add do begin FieldName := 'DISPLAY_ORDER'; Title.Caption := #$C815#$B82C; Width := 80; end;
    with FGrids[AIndex].Columns.Add do begin FieldName := 'STATUS'; Title.Caption := #$C0C1#$D0DC; Width := 90; end;
  end
  else if AIndex = 1 then
  begin
    with FGrids[AIndex].Columns.Add do begin FieldName := 'CATEGORY_ID'; Title.Caption := #$C885#$B958' '#$BC88#$D638; Width := 100; end;
    with FGrids[AIndex].Columns.Add do begin FieldName := 'CATEGORY_NAME'; Title.Caption := #$C74C#$C2DD' '#$C885#$B958; Width := 220; end;
    with FGrids[AIndex].Columns.Add do begin FieldName := 'DISPLAY_ORDER'; Title.Caption := #$C815#$B82C; Width := 90; end;
    with FGrids[AIndex].Columns.Add do begin FieldName := 'STATUS'; Title.Caption := #$C0C1#$D0DC; Width := 90; end;
  end
  else
  begin
    with FGrids[AIndex].Columns.Add do begin FieldName := 'MENU_ID'; Title.Caption := #$BA54#$B274' '#$BC88#$D638; Width := 90; end;
    with FGrids[AIndex].Columns.Add do begin FieldName := 'MENU_NAME'; Title.Caption := #$BA54#$B274#$BA85; Width := 180; end;
    with FGrids[AIndex].Columns.Add do begin FieldName := 'CATEGORY_NAME'; Title.Caption := #$C74C#$C2DD' '#$C885#$B958; Width := 150; end;
    with FGrids[AIndex].Columns.Add do begin FieldName := 'PRICE'; Title.Caption := #$D310#$B9E4' '#$AC00#$ACA9; Width := 110; end;
    with FGrids[AIndex].Columns.Add do begin FieldName := 'DISPLAY_ORDER'; Title.Caption := #$C815#$B82C; Width := 80; end;
    with FGrids[AIndex].Columns.Add do begin FieldName := 'STATUS'; Title.Caption := #$C0C1#$D0DC; Width := 90; end;
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
        if not InputQuery(#$D14C#$C774#$BE14' '#$B4F1#$B85D, #$D14C#$C774#$BE14' '#$C774#$B984#$C744' '#$C785#$B825#$D558#$C138#$C694'.', NameValue) then Exit;
        if not InputQuery(#$D14C#$C774#$BE14' '#$B4F1#$B85D, #$AD6C#$C5ED' '#$C774#$B984' ('#$C120#$D0DD')', GroupValue) then Exit;
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
        if not InputQuery(#$C74C#$C2DD' '#$C885#$B958' '#$B4F1#$B85D, #$C74C#$C2DD' '#$C885#$B958' '#$C774#$B984#$C744' '#$C785#$B825#$D558#$C138#$C694'.', NameValue) then Exit;
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
        if not InputQuery(#$BA54#$B274' '#$B4F1#$B85D, #$BA54#$B274' '#$C774#$B984#$C744' '#$C785#$B825#$D558#$C138#$C694'.', NameValue) then Exit;
        CategoryValue := ;
        if not InputQuery(#$BA54#$B274' '#$B4F1#$B85D, #$C74C#$C2DD' '#$C885#$B958' '#$BC88#$D638#$B97C' '#$C785#$B825#$D558#$C138#$C694' ('#$C74C#$C2DD' '#$C885#$B958' '#$D0ED#$C5D0#$C11C' '#$D655#$C778').', CategoryValue) then Exit;
        if not TryStrToInt(Trim(CategoryValue), CategoryID) then
          raise Exception.Create(#$C74C#$C2DD' '#$C885#$B958' '#$BC88#$D638#$AC00' '#$C62C#$BC14#$B974#$C9C0' '#$C54A#$C2B5#$B2C8#$B2E4'.');
        PriceValue := '0';
        if not InputQuery(#$BA54#$B274' '#$B4F1#$B85D, #$D310#$B9E4' '#$AC00#$ACA9#$C744' '#$C785#$B825#$D558#$C138#$C694'.', PriceValue) then Exit;
        if not TryStrToCurr(Trim(PriceValue), Price) or (Price < 0) then
          raise Exception.Create(#$D310#$B9E4' '#$AC00#$ACA9#$C744' '#$C62C#$BC14#$B974#$AC8C' '#$C785#$B825#$D574' '#$C8FC#$C138#$C694'.');
        DescriptionValue := ;
        if not InputQuery(#$BA54#$B274' '#$B4F1#$B85D, #$BA54#$B274' '#$C124#$BA85' ('#$C120#$D0DD')', DescriptionValue) then Exit;
        Q := TFDQuery.Create(nil);
        try
          Q.Connection := dmDatabase.Connection;
          Q.SQL.Text := 'SELECT COUNT(*) FROM MENU_CATEGORY WHERE STORE_ID=:STORE_ID AND CATEGORY_ID=:CAT_ID AND ACTIVE_YN=''Y''';
          Q.ParamByName('STORE_ID').AsInteger := FStoreID;
          Q.ParamByName('CAT_ID').AsInteger := CategoryID;
          Q.Open;
          if Q.Fields[0].AsInteger = 0 then
            raise Exception.Create(#$C0AC#$C6A9' '#$C911#$C778' '#$C74C#$C2DD' '#$C885#$B958#$B97C' '#$CC3E#$C744' '#$C218' '#$C5C6#$C2B5#$B2C8#$B2E4'.');
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
          if not InputQuery(#$D14C#$C774#$BE14' '#$C218#$C815, #$D14C#$C774#$BE14' '#$C774#$B984, NameValue) then Exit;
          if not InputQuery(#$D14C#$C774#$BE14' '#$C218#$C815, #$AD6C#$C5ED' '#$C774#$B984, GroupValue) then Exit;
          Q.SQL.Text := 'UPDATE POS_TABLE SET TABLE_NAME=:NAME, TABLE_GROUP=:GRP WHERE STORE_ID=:STORE_ID AND TABLE_ID=:ID';
          Q.ParamByName('NAME').AsString := Trim(NameValue);
          Q.ParamByName('GRP').AsString := Trim(GroupValue);
        end;
      1:
        begin
          Q.SQL.Text := 'SELECT CATEGORY_NAME FROM MENU_CATEGORY WHERE STORE_ID=:STORE_ID AND CATEGORY_ID=:ID';
          Q.ParamByName('STORE_ID').AsInteger := FStoreID; Q.ParamByName('ID').AsInteger := ID;
          Q.Open; NameValue := Q.Fields[0].AsString; Q.Close;
          if not InputQuery(#$C74C#$C2DD' '#$C885#$B958' '#$C218#$C815, #$C74C#$C2DD' '#$C885#$B958' '#$C774#$B984, NameValue) then Exit;
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
          if not InputQuery(#$BA54#$B274' '#$C218#$C815, #$BA54#$B274' '#$C774#$B984, NameValue) then Exit;
          if not InputQuery(#$BA54#$B274' '#$C218#$C815, #$C74C#$C2DD' '#$C885#$B958' '#$BC88#$D638, CategoryValue) then Exit;
          if not TryStrToInt(Trim(CategoryValue), CategoryID) then raise Exception.Create(#$C74C#$C2DD' '#$C885#$B958' '#$BC88#$D638#$AC00' '#$C62C#$BC14#$B974#$C9C0' '#$C54A#$C2B5#$B2C8#$B2E4'.');
          Q.SQL.Text := 'SELECT COUNT(*) FROM MENU_CATEGORY WHERE STORE_ID=:STORE_ID AND CATEGORY_ID=:CAT_ID AND ACTIVE_YN=''Y''';
          Q.ParamByName('STORE_ID').AsInteger := FStoreID;
          Q.ParamByName('CAT_ID').AsInteger := CategoryID;
          Q.Open;
          if Q.Fields[0].AsInteger = 0 then raise Exception.Create(#$C0AC#$C6A9' '#$C911#$C778' '#$C74C#$C2DD' '#$C885#$B958#$B97C' '#$CC3E#$C744' '#$C218' '#$C5C6#$C2B5#$B2C8#$B2E4'.');
          Q.Close;
          if not InputQuery(#$BA54#$B274' '#$C218#$C815, #$D310#$B9E4' '#$AC00#$ACA9, PriceValue) then Exit;
          if not TryStrToCurr(Trim(PriceValue), Price) or (Price < 0) then raise Exception.Create(#$D310#$B9E4' '#$AC00#$ACA9#$C774' '#$C62C#$BC14#$B974#$C9C0' '#$C54A#$C2B5#$B2C8#$B2E4'.');
          if not InputQuery(#$BA54#$B274' '#$C218#$C815, #$BA54#$B274' '#$C124#$BA85, DescriptionValue) then Exit;
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
    begin NewStatus := 'N'; MessageText := #$C120#$D0DD' '#$D56D#$BAA9#$C744' '#$C0AC#$C6A9' '#$C911#$C9C0#$D558#$C2DC#$ACA0#$C2B5#$B2C8#$AE4C'?'; end
    else
    begin NewStatus := 'Y'; MessageText := #$C120#$D0DD' '#$D56D#$BAA9#$C744' '#$B2E4#$C2DC' '#$C0AC#$C6A9#$D558#$C2DC#$ACA0#$C2B5#$B2C8#$AE4C'?'; end;
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
