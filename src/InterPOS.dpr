program InterPOS;
uses
  System.SysUtils,
  System.UITypes,
  FireDAC.DApt,
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
  Application.CreateForm(TdmDatabase, uDatabase.dmDatabase);

  try
    uDatabase.dmDatabase.Connect;
  except
    on E: Exception do
    begin
      MessageDlg(#$B370#$C774#$D130#$BCA0#$C774#$C2A4' '#$C5F0#$ACB0#$C5D0' '#$C2E4#$D328#$D588#$C2B5#$B2C8#$B2E4. + sLineBreak +
        E.Message + sLineBreak + sLineBreak +
        InterPOS.ini#$C758' '#$C811#$C18D' '#$C815#$BCF4#$C640' 'Firebird' 'Server' '#$C0C1#$D0DC#$B97C' '#$D655#$C778#$D574' '#$C8FC#$C138#$C694.,
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
