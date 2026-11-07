unit uMainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls;

type
  TfrmMain = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    pnlWork: TPanel;
    btnSales: TButton;
    btnTable: TButton;
    btnMenu: TButton;
    btnClose: TButton;
    lblStatus: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure btnSalesClick(Sender: TObject);
  private
    procedure UpdateDatabaseStatus;
  public
  end;

var
  frmMain: TfrmMain;

implementation

uses
  uDatabase;

{$R *.dfm}

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  Caption := 'InterPOS - 음식점 POS';
  UpdateDatabaseStatus;
end;

procedure TfrmMain.UpdateDatabaseStatus;
begin
  if dmDatabase.IsConnected then
    lblStatus.Caption := '데이터베이스 연결됨'
  else
    lblStatus.Caption := '데이터베이스 미연결';
end;

procedure TfrmMain.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain.btnSalesClick(Sender: TObject);
begin
  ShowMessage('POS 판매 화면은 다음 개발 단계에서 구현합니다.');
end;

end.
