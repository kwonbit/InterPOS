unit uLoginForm;
interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  uAuth;

type
  TfrmLogin = class(TForm)
    pnlLogin: TPanel;
    lblLoginTitle: TLabel;
    lblLoginID: TLabel;
    edtLoginID: TEdit;
    lblPassword: TLabel;
    edtPassword: TEdit;
    btnLogin: TButton;
    pnlSetup: TPanel;
    lblSetupTitle: TLabel;
    lblStoreName: TLabel;
    edtStoreName: TEdit;
    lblOwnerName: TLabel;
    edtOwnerName: TEdit;
    lblSetupLoginID: TLabel;
    edtSetupLoginID: TEdit;
    lblSetupPassword: TLabel;
    edtSetupPassword: TEdit;
    lblConfirmPassword: TLabel;
    edtConfirmPassword: TEdit;
    btnCreateOwner: TButton;
    lblMessage: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure btnLoginClick(Sender: TObject);
    procedure btnCreateOwnerClick(Sender: TObject);
  private
    FSession: TEmployeeSession;
    FStoreID: Integer;
    procedure ShowLogin;
    procedure ShowFirstRunSetup;
  public
    property Session: TEmployeeSession read FSession;
  end;

var
  frmLogin: TfrmLogin;

implementation

uses
  uDatabase;

{$R *.dfm}

procedure TfrmLogin.FormCreate(Sender: TObject);
begin
  FStoreID := dmDatabase.StoreID;
  lblMessage.Caption := '';
  if ActiveEmployeeCount(dmDatabase.Connection, FStoreID) = 0 then
    ShowFirstRunSetup
  else
    ShowLogin;
end;

procedure TfrmLogin.ShowLogin;
begin
  pnlSetup.Visible := False;
  pnlLogin.Visible := True;
end;

procedure TfrmLogin.ShowFirstRunSetup;
begin
  pnlLogin.Visible := False;
  pnlSetup.Visible := True;
  lblMessage.Caption := '최초 실행입니다. 점주 계정을 먼저 등록해 주세요.';
end;

procedure TfrmLogin.btnLoginClick(Sender: TObject);
begin
  if Trim(edtLoginID.Text) = '' then
  begin
    MessageDlg('아이디를 입력해 주세요.', mtWarning, [mbOK], 0);
    edtLoginID.SetFocus;
    Exit;
  end;

  if not AuthenticateEmployee(dmDatabase.Connection, FStoreID,
    edtLoginID.Text, edtPassword.Text, FSession) then
  begin
    MessageDlg('아이디 또는 비밀번호가 올바르지 않습니다.', mtError, [mbOK], 0);
    edtPassword.Clear;
    edtPassword.SetFocus;
    Exit;
  end;

  ModalResult := mrOk;
end;

procedure TfrmLogin.btnCreateOwnerClick(Sender: TObject);
begin
  if Trim(edtStoreName.Text) = '' then
  begin
    MessageDlg('매장명을 입력해 주세요.', mtWarning, [mbOK], 0);
    edtStoreName.SetFocus;
    Exit;
  end;

  if Trim(edtOwnerName.Text) = '' then
  begin
    MessageDlg('점주 이름을 입력해 주세요.', mtWarning, [mbOK], 0);
    edtOwnerName.SetFocus;
    Exit;
  end;

  if Trim(edtSetupLoginID.Text) = '' then
  begin
    MessageDlg('로그인 아이디를 입력해 주세요.', mtWarning, [mbOK], 0);
    edtSetupLoginID.SetFocus;
    Exit;
  end;

  if Length(edtSetupPassword.Text) < 8 then
  begin
    MessageDlg('비밀번호는 8자 이상 입력해 주세요.', mtWarning, [mbOK], 0);
    edtSetupPassword.SetFocus;
    Exit;
  end;

  if edtSetupPassword.Text <> edtConfirmPassword.Text then
  begin
    MessageDlg('비밀번호 확인이 일치하지 않습니다.', mtWarning, [mbOK], 0);
    edtConfirmPassword.SetFocus;
    Exit;
  end;

  try
    CreateInitialOwner(dmDatabase.Connection, FStoreID,
      Trim(edtStoreName.Text), Trim(edtOwnerName.Text),
      Trim(edtSetupLoginID.Text), edtSetupPassword.Text);

    if not AuthenticateEmployee(dmDatabase.Connection, FStoreID,
      edtSetupLoginID.Text, edtSetupPassword.Text, FSession) then
      raise Exception.Create('점주 계정 생성 후 로그인하지 못했습니다.');

    MessageDlg('점주 계정이 생성되었습니다.', mtInformation, [mbOK], 0);
    ModalResult := mrOk;
  except
    on E: Exception do
      MessageDlg('초기 계정 생성 실패: ' + E.Message, mtError, [mbOK], 0);
  end;
end;

end.
