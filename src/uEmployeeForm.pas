unit uEmployeeForm;
interface

uses
  System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.DBGrids, Data.DB,
  FireDAC.Comp.Client, System.UITypes, uAuth;

type
  TfrmEmployee = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    grdEmployees: TDBGrid;
    pnlButtons: TPanel;
    btnAdd: TButton;
    btnPassword: TButton;
    btnDeactivate: TButton;
    btnClose: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure btnPasswordClick(Sender: TObject);
    procedure btnDeactivateClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
  private
    FActor: TEmployeeSession;
    FQuery: TFDQuery;
    FDataSource: TDataSource;
    procedure RefreshEmployees;
    procedure DataSourceDataChange(Sender: TObject; Field: TField);
    procedure UpdateAccountToggleButton;
    function SelectedEmployeeID: Integer;
  public
    procedure SetActor(const AActor: TEmployeeSession);
  end;

var
  frmEmployee: TfrmEmployee;

implementation

uses
  uDatabase;

{$R *.dfm}

procedure TfrmEmployee.FormCreate(Sender: TObject);
begin
  FQuery := TFDQuery.Create(Self);
  FQuery.Connection := dmDatabase.Connection;
  FDataSource := TDataSource.Create(Self);
  FDataSource.DataSet := FQuery;
  FDataSource.OnDataChange := DataSourceDataChange;
  grdEmployees.DataSource := FDataSource;
  btnDeactivate.Caption := '사용 중지';
  btnDeactivate.Enabled := False;
end;

procedure TfrmEmployee.SetActor(const AActor: TEmployeeSession);
begin
  FActor := AActor;
  RefreshEmployees;
end;

procedure TfrmEmployee.RefreshEmployees;
begin
  FQuery.Close;
  FQuery.SQL.Text :=
    'SELECT EMPLOYEE_ID, EMPLOYEE_NAME, LOGIN_ID, ROLE_CODE, ' +
    'ACTIVE_YN, CASE WHEN ACTIVE_YN = ''Y'' THEN ''사용 중'' ELSE ''사용 중지'' END AS ACCOUNT_STATUS ' +
    'FROM EMPLOYEE WHERE STORE_ID = :STORE_ID ORDER BY EMPLOYEE_ID';
  FQuery.ParamByName('STORE_ID').AsInteger := FActor.StoreID;
  FQuery.Open;

  grdEmployees.Columns.Clear;
  with grdEmployees.Columns.Add do
  begin FieldName := 'EMPLOYEE_ID'; Title.Caption := '직원번호'; Width := 80; end;
  with grdEmployees.Columns.Add do
  begin FieldName := 'EMPLOYEE_NAME'; Title.Caption := '직원명'; Width := 180; end;
  with grdEmployees.Columns.Add do
  begin FieldName := 'LOGIN_ID'; Title.Caption := '로그인 ID'; Width := 180; end;
  with grdEmployees.Columns.Add do
  begin FieldName := 'ROLE_CODE'; Title.Caption := '권한'; Width := 110; end;
  with grdEmployees.Columns.Add do
  begin FieldName := 'ACCOUNT_STATUS'; Title.Caption := '상태'; Width := 100; end;
  UpdateAccountToggleButton;
end;

procedure TfrmEmployee.DataSourceDataChange(Sender: TObject; Field: TField);
begin
  UpdateAccountToggleButton;
end;

procedure TfrmEmployee.UpdateAccountToggleButton;
begin
  btnDeactivate.Enabled := Assigned(FQuery) and FQuery.Active and not FQuery.IsEmpty;
  if not btnDeactivate.Enabled then
  begin
    btnDeactivate.Caption := '사용 중지';
    Exit;
  end;

  if SameText(FQuery.FieldByName('ACTIVE_YN').AsString, 'Y') then
    btnDeactivate.Caption := '사용 중지'
  else
    btnDeactivate.Caption := '사용하기';
end;

function TfrmEmployee.SelectedEmployeeID: Integer;
begin
  Result := 0;
  if Assigned(FQuery) and not FQuery.IsEmpty then
    Result := FQuery.FieldByName('EMPLOYEE_ID').AsInteger;
end;

function PromptMaskedPassword(const ATitle: string; out APassword: string): Boolean;
var
  Dlg: TForm;
  EditPassword: TEdit;
  Lbl: TLabel;
  BtnOK, BtnCancel: TButton;
begin
  Dlg := TForm.Create(nil);
  try
    Dlg.Caption := ATitle;
    Dlg.Position := poScreenCenter;
    Dlg.BorderStyle := bsDialog;
    Dlg.ClientWidth := 380;
    Dlg.ClientHeight := 140;
    Lbl := TLabel.Create(Dlg);
    Lbl.Parent := Dlg;
    Lbl.Left := 20;
    Lbl.Top := 20;
    Lbl.Caption := '새 비밀번호를 입력하세요 (8자 이상).';
    EditPassword := TEdit.Create(Dlg);
    EditPassword.Parent := Dlg;
    EditPassword.Left := 20;
    EditPassword.Top := 48;
    EditPassword.Width := 340;
    EditPassword.PasswordChar := '*';
    BtnOK := TButton.Create(Dlg);
    BtnOK.Parent := Dlg;
    BtnOK.Caption := '확인';
    BtnOK.ModalResult := mrOk;
    BtnOK.Default := True;
    BtnOK.Left := 180;
    BtnOK.Top := 92;
    BtnOK.Width := 80;
    BtnCancel := TButton.Create(Dlg);
    BtnCancel.Parent := Dlg;
    BtnCancel.Caption := '취소';
    BtnCancel.ModalResult := mrCancel;
    BtnCancel.Cancel := True;
    BtnCancel.Left := 270;
    BtnCancel.Top := 92;
    BtnCancel.Width := 80;
    Result := Dlg.ShowModal = mrOk;
    if Result then
      APassword := EditPassword.Text;
  finally
    Dlg.Free;
  end;
end;

procedure TfrmEmployee.btnAddClick(Sender: TObject);
var
  EmployeeName, LoginID, Password, RoleCode: string;
begin
  EmployeeName := '';
  LoginID := '';
  Password := '';
  RoleCode := 'STAFF';

  if not InputQuery('직원 등록', '직원 이름을 입력하세요.', EmployeeName) then Exit;
  if not InputQuery('직원 등록', '로그인 ID를 입력하세요.', LoginID) then Exit;
  if not PromptMaskedPassword('직원 초기 비밀번호', Password) then Exit;

  if SameText(FActor.RoleCode, 'OWNER') then
    if not InputQuery('직원 권한', '권한 코드 (STAFF 또는 MANAGER)', RoleCode) then Exit;

  try
    AddEmployee(dmDatabase.Connection, FActor, EmployeeName, LoginID,
      Password, RoleCode);
    MessageDlg('직원이 등록되었습니다.', mtInformation, [mbOK], 0);
    RefreshEmployees;
  except
    on E: Exception do
      MessageDlg('직원 등록 실패: ' + E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TfrmEmployee.btnPasswordClick(Sender: TObject);
var
  NewPassword: string;
  EmployeeID: Integer;
begin
  EmployeeID := SelectedEmployeeID;
  if EmployeeID = 0 then
  begin
    MessageDlg('비밀번호를 변경할 직원을 선택해 주세요.', mtWarning, [mbOK], 0);
    Exit;
  end;

  NewPassword := '';
  if not PromptMaskedPassword('직원 비밀번호 변경', NewPassword) then Exit;
  try
    UpdateEmployeePassword(dmDatabase.Connection, FActor, EmployeeID, NewPassword);
    MessageDlg('비밀번호가 변경되었습니다.', mtInformation, [mbOK], 0);
  except
    on E: Exception do
      MessageDlg('비밀번호 변경 실패: ' + E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TfrmEmployee.btnDeactivateClick(Sender: TObject);
var
  EmployeeID: Integer;
  WillActivate: Boolean;
  ConfirmText: string;
begin
  EmployeeID := SelectedEmployeeID;
  if EmployeeID = 0 then
  begin
    MessageDlg('상태를 변경할 직원을 선택해 주세요.', mtWarning, [mbOK], 0);
    Exit;
  end;

  WillActivate := not SameText(FQuery.FieldByName('ACTIVE_YN').AsString, 'Y');
  if WillActivate then
    ConfirmText := '선택한 직원의 계정을 다시 사용하도록 변경하시겠습니까?'
  else
    ConfirmText := '선택한 직원의 로그인을 중지하시겠습니까?';

  if MessageDlg(ConfirmText, mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  try
    WillActivate := ToggleEmployeeActive(dmDatabase.Connection, FActor, EmployeeID);
    if WillActivate then
      MessageDlg('직원 계정이 사용 상태로 변경되었습니다.', mtInformation, [mbOK], 0)
    else
      MessageDlg('직원 계정이 중지되었습니다.', mtInformation, [mbOK], 0);
    RefreshEmployees;
  except
    on E: Exception do
      MessageDlg('직원 계정 상태 변경 실패: ' + E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TfrmEmployee.btnCloseClick(Sender: TObject);
begin
  Close;
end;

end.
