program InterPOS;
uses
  System.SysUtils,
  System.UITypes,
  Vcl.Forms,
  Vcl.Dialogs,
  uMainForm in 'uMainForm.pas' {frmMain},
  uLoginForm in 'uLoginForm.pas' {frmLogin},
  uEmployeeForm in 'uEmployeeForm.pas' {frmEmployee},
  uAuth in 'uAuth.pas',
  uDatabase in 'uDatabase.pas' {dmDatabase: TDataModule};

{$R *.res}

var
  LoginForm: TfrmLogin;

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'InterPOS';
  Application.CreateForm(TdmDatabase, dmDatabase);

  try
    dmDatabase.Connect;
  except
    on E: Exception do
    begin
      MessageDlg('데이터베이스 연결에 실패했습니다.' + sLineBreak +
        E.Message + sLineBreak + sLineBreak +
        'InterPOS.ini의 접속 정보와 Firebird Server 상태를 확인해 주세요.',
        mtError, [mbOK], 0);
      Exit;
    end;
  end;

  LoginForm := TfrmLogin.Create(nil);
  try
    if LoginForm.ShowModal = mrOk then
    begin
      Application.CreateForm(TfrmMain, frmMain);
      frmMain.SetSession(LoginForm.Session);
      Application.Run;
    end;
  finally
    LoginForm.Free;
  end;
end.
