unit uMainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, System.UITypes, uAuth;

type
  TfrmMain = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    pnlWork: TPanel;
    btnSales: TButton;
    btnTable: TButton;
    btnMenu: TButton;
    btnEmployee: TButton;
    btnClose: TButton;
    btnKitchen: TButton;
    lblStatus: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure btnKitchenClick(Sender: TObject);
    procedure btnSalesClick(Sender: TObject);
    procedure btnTableClick(Sender: TObject);
    procedure btnMenuClick(Sender: TObject);
    procedure btnEmployeeClick(Sender: TObject);
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
  uDatabase, uEmployeeForm, uMasterDataForm, uSalesForm, uKitchenDisplayForm;

{$R *.dfm}

procedure TfrmMain.SetSession(const ASession: TEmployeeSession);
begin
  FSession := ASession;
  btnEmployee.Visible := SameText(FSession.RoleCode, 'OWNER') or
    SameText(FSession.RoleCode, 'MANAGER');
  btnTable.Visible := btnEmployee.Visible;
  btnMenu.Visible := btnEmployee.Visible;
  if FSession.EmployeeID > 0 then
    Caption := 'InterPOS - ' + FSession.EmployeeName + ' (' +
      RoleDisplayName(FSession.RoleCode) + ')';
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  Font.Name := '맑은 고딕';
  Caption := 'InterPOS - 음식점 POS';
  lblTitle.Font.Name := Font.Name;
  lblTitle.Caption := 'InterPOS | 음식점 POS';
  lblStatus.Font.Name := Font.Name;
  btnSales.Font.Name := Font.Name;
  btnSales.Caption := 'POS 판매';
  btnTable.Font.Name := Font.Name;
  btnTable.Caption := '테이블 관리';
  btnMenu.Font.Name := Font.Name;
  btnMenu.Caption := '메뉴 관리';
  btnEmployee.Font.Name := Font.Name;
  btnEmployee.Caption := '직원 관리';
  btnClose.Font.Name := Font.Name;
  btnClose.Caption := '로그아웃';
  btnKitchen.Font.Name := Font.Name;
  btnKitchen.Caption := '주방 주문현황';
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
var
  SalesForm: TfrmSales;
begin
  SalesForm := TfrmSales.Create(Self);
  try
    SalesForm.SetStoreID(dmDatabase.StoreID);
    SalesForm.ShowModal;
  finally
    SalesForm.Free;
  end;
end;

procedure TfrmMain.btnKitchenClick(Sender: TObject);
var
  KitchenForm: TfrmKitchenDisplay;
begin
  KitchenForm := TfrmKitchenDisplay.CreateKitchen(Self, dmDatabase.StoreID);
  try
    KitchenForm.ShowModal;
  finally
    KitchenForm.Free;
  end;
end;

procedure TfrmMain.btnTableClick(Sender: TObject);
var
  MasterForm: TfrmMasterData;
begin
  if not (SameText(FSession.RoleCode, 'OWNER') or
    SameText(FSession.RoleCode, 'MANAGER')) then
  begin
    MessageDlg('테이블 관리 권한이 없습니다.', mtWarning, [mbOK], 0);
    Exit;
  end;

  MasterForm := TfrmMasterData.Create(Self);
  try
    MasterForm.SetStoreID(dmDatabase.StoreID);
    MasterForm.ShowPage(0);
    MasterForm.ShowModal;
  finally
    MasterForm.Free;
  end;
end;

procedure TfrmMain.btnMenuClick(Sender: TObject);
var
  MasterForm: TfrmMasterData;
begin
  if not (SameText(FSession.RoleCode, 'OWNER') or
    SameText(FSession.RoleCode, 'MANAGER')) then
  begin
    MessageDlg('메뉴 관리 권한이 없습니다.', mtWarning, [mbOK], 0);
    Exit;
  end;

  MasterForm := TfrmMasterData.Create(Self);
  try
    MasterForm.SetStoreID(dmDatabase.StoreID);
    MasterForm.ShowPage(2);
    MasterForm.ShowModal;
  finally
    MasterForm.Free;
  end;
end;

procedure TfrmMain.btnEmployeeClick(Sender: TObject);
var
  EmployeeForm: TfrmEmployee;
begin
  if not (SameText(FSession.RoleCode, 'OWNER') or
    SameText(FSession.RoleCode, 'MANAGER')) then
  begin
    MessageDlg('직원 관리 권한이 없습니다.',
      mtWarning, [mbOK], 0);
    Exit;
  end;

  EmployeeForm := TfrmEmployee.Create(Self);
  try
    EmployeeForm.SetActor(FSession);
    EmployeeForm.ShowModal;
  finally
    EmployeeForm.Free;
  end;
end;

end.
