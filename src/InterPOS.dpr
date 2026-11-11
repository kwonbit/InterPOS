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
  uMasterDataForm in 'uMasterDataForm.pas' {frmMasterData},
  uSalesForm in 'uSalesForm.pas' {frmSales},
  uReceiptPrinter in 'uReceiptPrinter.pas',
  uCashDrawer in 'uCashDrawer.pas',
  uKitchenPrinter in 'uKitchenPrinter.pas',
  uKitchenDisplayForm in 'uKitchenDisplayForm.pas',
  uSalesReportForm in 'uSalesReportForm.pas',
  uShiftForm in 'uShiftForm.pas',
  uInventoryForm in 'uInventoryForm.pas',
  uBackupForm in 'uBackupForm.pas',
  uSupplierForm in 'uSupplierForm.pas',
  uPurchaseForm in 'uPurchaseForm.pas',
  uPayableForm in 'uPayableForm.pas',
  uExpenseForm in 'uExpenseForm.pas' {frmExpense},
  uScheduledBackup in 'uScheduledBackup.pas',
  uAuth in 'uAuth.pas',
  uDatabase in 'uDatabase.pas' {dmDatabase: TDataModule};

{$R *.res}

var
  LoginForm: TfrmLogin;
  BackupExitCode: Integer;

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'InterPOS';
  Application.CreateForm(TdmDatabase, dmDatabase);

  if SameText(ParamStr(1), '/backup') then
  begin
    BackupExitCode := RunScheduledBackup;
    dmDatabase.Free;
    Halt(BackupExitCode);
  end;

  try
    uDatabase.dmDatabase.Connect;
  except
    on E: Exception do
    begin
      MessageDlg(
        '데이터베이스 연결에 실패했습니다.' + sLineBreak +
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
