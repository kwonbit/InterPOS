unit uEmployeeForm;

interface

uses
  System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.DBGrids, Data.DB,
  FireDAC.Comp.Client, uAuth;

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
  grdEmployees.DataSource := FDataSource;
  RefreshEmployees;
end;

procedure TfrmEmployee.SetActor(const AActor: TEmployeeSession);
begin
  FActor := AActor;
  if SameText(FActor.RoleCode, 'MANAGER') then
    btnAdd.Caption := '직원 등록';
end;

procedure TfrmEmployee.RefreshEmployees;
begin
  FQuery.Close;
  FQuery.SQL.Text :=
    'SELECT EMPLOYEE_ID, EMPLOYEE_NAME, LOGIN_ID, ROLE_CODE, ' +
    'CASE WHEN ACTIVE_YN = ''Y'' THEN ''사용'' ELSE ''중지'' END AS ACCOUNT_STATUS ' +
    'FROM EMPLOYEE WHERE STORE_ID = :STORE_ID ORDER BY EMPLOYEE_ID';
  FQuery.ParamByName('STORE_ID').AsInteger := FActor.StoreID;
  FQuery.Open;

  if grdEmployees.Columns.Count >= 5 then
  begin
    grdEmployees.Columns[0].Width := 70;
    grdEmployees.Columns[1].Width := 150;
    grdEmployees.Columns[2].Width := 130;
    grdEmployees.Columns[3].Width := 90;
    grdEmployees.Columns[4].Width := 90;
    grdEmployees.Columns[0].Title.Caption := '직원번호';
    grdEmployees.Columns[1].Title.Caption := '직원명';
    grdEmployees.Columns[2].Title.Caption := '로그인 ID';
    grdEmployees.Columns[3].Title.Caption := '권한';
    grdEmployees.Columns[4].Title.Caption := '상태';
  end;
end;

function TfrmEmployee.SelectedEmployeeID: Integer;
begin
  Result := 0;
  if Assigned(FQuery) and not FQuery.IsEmpty then
    Result := FQuery.FieldByName('EMPLOYEE_ID').AsInteger;
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
  if not InputQuery('직원 등록', '초기 비밀번호(8자 이상)를 입력하세요.', Password) then Exit;

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
  if not InputQuery('비밀번호 변경', '새 비밀번호(8자 이상)', NewPassword) then Exit;
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
begin
  EmployeeID := SelectedEmployeeID;
  if EmployeeID = 0 then
  begin
    MessageDlg('사용 중지할 직원을 선택해 주세요.', mtWarning, [mbOK], 0);
    Exit;
  end;
  if MessageDlg('선택한 직원의 로그인을 중지하시겠습니까?',
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  try
    DeactivateEmployee(dmDatabase.Connection, FActor, EmployeeID);
    RefreshEmployees;
  except
    on E: Exception do
      MessageDlg('직원 사용 중지 실패: ' + E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TfrmEmployee.btnCloseClick(Sender: TObject);
begin
  Close;
end;

end.
