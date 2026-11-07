unit uDatabase;
{$CODEPAGE UTF8}

interface

uses
  System.SysUtils, System.Classes, System.IniFiles,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error,
  FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys,
  FireDAC.Phys.FB, FireDAC.Phys.FBDef, FireDAC.VCLUI.Wait,
  FireDAC.Comp.Client;

type
  TdmDatabase = class(TDataModule)
  private
    FConnection: TFDConnection;
    FStoreID: Integer;
    procedure LoadConfiguration;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Connect;
    procedure Disconnect;
    function IsConnected: Boolean;
    property Connection: TFDConnection read FConnection;
    property StoreID: Integer read FStoreID;
  end;

var
  dmDatabase: TdmDatabase;

implementation

{$R *.dfm}

constructor TdmDatabase.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FConnection := TFDConnection.Create(Self);
  FConnection.LoginPrompt := False;
  LoadConfiguration;
end;

destructor TdmDatabase.Destroy;
begin
  Disconnect;
  inherited;
end;

procedure TdmDatabase.LoadConfiguration;
var
  Ini: TIniFile;
  IniPath: string;
begin
  FStoreID := 1;
  IniPath := ChangeFileExt(ParamStr(0), '.ini');
  if not FileExists(IniPath) then
    Exit;

  Ini := TIniFile.Create(IniPath);
  try
    FConnection.Params.Clear;
    FConnection.Params.DriverID := 'FB';
    FConnection.Params.Database := Ini.ReadString('Database', 'Database',
      'localhost:C:\InterPOS\data\INTERPOS.FDB');
    FConnection.Params.UserName := Ini.ReadString('Database', 'UserName', 'SYSDBA');
    FConnection.Params.Password := Ini.ReadString('Database', 'Password', 'masterkey');
    FConnection.Params.Values['CharacterSet'] :=
      Ini.ReadString('Database', 'CharacterSet', 'UTF8');
    FConnection.Params.Values['Protocol'] :=
      Ini.ReadString('Database', 'Protocol', 'TCPIP');
    FStoreID := Ini.ReadInteger('POS', 'StoreId', 1);
  finally
    Ini.Free;
  end;
end;

procedure TdmDatabase.Connect;
begin
  if not FConnection.Connected then
    FConnection.Connected := True;
end;

procedure TdmDatabase.Disconnect;
begin
  if Assigned(FConnection) and FConnection.Connected then
    FConnection.Connected := False;
end;

function TdmDatabase.IsConnected: Boolean;
begin
  Result := Assigned(FConnection) and FConnection.Connected;
end;

end.
