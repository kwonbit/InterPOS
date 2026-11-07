program InterPOS;

uses
  Vcl.Forms,
  uMainForm in 'uMainForm.pas' {frmMain},
  uDatabase in 'uDatabase.pas' {dmDatabase: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'InterPOS';
  Application.CreateForm(TdmDatabase, dmDatabase);
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
