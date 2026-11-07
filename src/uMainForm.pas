unit uMainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, uAuth;

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
    FSession: TEmployeeSession;
    procedure UpdateDatabaseStatus;
  public
    procedure SetSession(const ASession: TEmployeeSession);
  end;

var
  frmMain: TfrmMain;

implementation

uses
  uDatabase;

{$R *.dfm}

procedure TfrmMain.SetSession(const ASession: TEmployeeSession);
begin
  FSession := ASession;
  if FSession.EmployeeID > 0 then
    Caption := 'InterPOS - ' + FSession.EmployeeName + ' (' +
      RoleDisplayName(FSession.RoleCode) + ')';
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  Font.Name := #$B9D1#$C740' '#$ACE0#$B515;
  Caption := 'InterPOS - '#$C74C#$C2DD#$C810' POS';
  lblTitle.Font.Name := Font.Name;
  lblTitle.Caption := 'InterPOS | '#$C74C#$C2DD#$C810' POS';
  lblStatus.Font.Name := Font.Name;
  btnSales.Font.Name := Font.Name;
  btnSales.Caption := 'POS '#$D310#$B9E4;
  btnTable.Font.Name := Font.Name;
  btnTable.Caption := #$D14C#$C774#$BE14' '#$AD00#$B9AC;
  btnMenu.Font.Name := Font.Name;
  btnMenu.Caption := #$BA54#$B274' '#$AD00#$B9AC;
  btnClose.Font.Name := Font.Name;
  btnClose.Caption := #$B85C#$ADF8#$C544#$C6C3;
  UpdateDatabaseStatus;
end;

procedure TfrmMain.UpdateDatabaseStatus;
begin
  if dmDatabase.IsConnected then
    lblStatus.Caption := #$B370#$C774#$D130#$BCA0#$C774#$C2A4' '#$C5F0#$ACB0#$B428
  else
    lblStatus.Caption := #$B370#$C774#$D130#$BCA0#$C774#$C2A4' '#$BBF8#$C5F0#$ACB0;
end;

procedure TfrmMain.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain.btnSalesClick(Sender: TObject);
begin
  ShowMessage('POS '#$D310#$B9E4' '#$D654#$BA74#$C740' '#$B2E4#$C74C' '#$AC1C#$BC1C' '#$B2E8#$ACC4#$C5D0#$C11C' '#$AD6C#$D604#$D569#$B2C8#$B2E4'.');
end;

end.
