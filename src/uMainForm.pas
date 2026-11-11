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
    btnReports: TButton;
    lblStatus: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure btnKitchenClick(Sender: TObject);
    procedure btnReportsClick(Sender: TObject);
    procedure btnSalesClick(Sender: TObject);
    procedure btnTableClick(Sender: TObject);
    procedure btnMenuClick(Sender: TObject);
    procedure btnEmployeeClick(Sender: TObject);
  private
    FSession: TEmployeeSession;
    FShiftButton: TButton;
    FInventoryButton: TButton;
    FBackupButton: TButton;
    procedure UpdateDatabaseStatus;
    procedure btnInventoryClick(Sender: TObject);
    procedure btnShiftClick(Sender: TObject);
    procedure btnBackupClick(Sender: TObject);
  public
    procedure SetSession(const ASession: TEmployeeSession);
  end;

var
  frmMain: TfrmMain;

implementation

uses
  uDatabase, uEmployeeForm, uMasterDataForm, uSalesForm, uKitchenDisplayForm, uSalesReportForm, uShiftForm, uInventoryForm, uBackupForm;

{$R *.dfm}

procedure TfrmMain.SetSession(const ASession: TEmployeeSession);
begin
  FSession := ASession;
  btnEmployee.Visible := SameText(FSession.RoleCode, 'OWNER') or
    SameText(FSession.RoleCode, 'MANAGER');
  btnTable.Visible := btnEmployee.Visible;
  btnMenu.Visible := btnEmployee.Visible;
  btnReports.Visible := btnEmployee.Visible;
  if Assigned(FShiftButton) then FShiftButton.Visible := True;
  if Assigned(FInventoryButton) then
    FInventoryButton.Visible := SameText(FSession.RoleCode, 'OWNER') or
      SameText(FSession.RoleCode, 'MANAGER');
  if Assigned(FBackupButton) then
    FBackupButton.Visible := SameText(FSession.RoleCode, 'OWNER') or
      SameText(FSession.RoleCode, 'MANAGER');
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
  btnReports.Font.Name := Font.Name;
  btnReports.Caption := '매출관리 / 영업마감';
  FShiftButton := TButton.Create(Self);
  FShiftButton.Parent := pnlWork;
  FShiftButton.SetBounds(672, 224, 300, 48);
  FShiftButton.Caption := '영업 개점 / 마감 및 현금시재';
  FShiftButton.Font.Name := Font.Name;
  FShiftButton.OnClick := btnShiftClick;

  FInventoryButton := TButton.Create(Self);
  FInventoryButton.Parent := pnlWork;
  FInventoryButton.SetBounds(672, 160, 300, 48);
  FInventoryButton.Caption := '재고관리';
  FInventoryButton.Font.Name := Font.Name;
  FInventoryButton.Visible := False;
  FInventoryButton.OnClick := btnInventoryClick;

  FBackupButton := TButton.Create(Self);
  FBackupButton.Parent := pnlWork;
  FBackupButton.SetBounds(672, 288, 300, 48);
  FBackupButton.Caption := '데이터 백업 / 복구 검증';
  FBackupButton.Font.Name := Font.Name;
  FBackupButton.Visible := False;
  FBackupButton.OnClick := btnBackupClick;
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
  ShiftForm: TfrmShiftManagement;
begin
  try
    ShiftForm := TfrmShiftManagement.Create(Self);
    try
      ShiftForm.SetContext(dmDatabase.StoreID, dmDatabase.TerminalID,
        FSession.EmployeeID);
      if not TfrmShiftManagement.HasOpenShift(dmDatabase.Connection,
        dmDatabase.StoreID, dmDatabase.TerminalID) then
        ShiftForm.ShowModal;
    finally
      ShiftForm.Free;
    end;

    if not TfrmShiftManagement.HasOpenShift(dmDatabase.Connection,
      dmDatabase.StoreID, dmDatabase.TerminalID) then
    begin
      MessageDlg('POS 판매를 시작하려면 먼저 영업 개점을 해주세요.',
        mtWarning, [mbOK], 0);
      Exit;
    end;

    SalesForm := TfrmSales.Create(Self);
    try
      SalesForm.SetContext(dmDatabase.StoreID, dmDatabase.TerminalID,
        FSession.EmployeeID);
      SalesForm.ShowModal;
    finally
      SalesForm.Free;
    end;
  except
    on E: Exception do
      MessageDlg('POS 판매 화면을 열지 못했습니다: ' + E.Message +
        sLineBreak + 'database/08_operational_foundation.sql 적용 여부를 확인해 주세요.',
        mtError, [mbOK], 0);
  end;
end;

procedure TfrmMain.btnInventoryClick(Sender: TObject);
var
  InventoryForm: TfrmInventory;
begin
  if not (SameText(FSession.RoleCode, 'OWNER') or
    SameText(FSession.RoleCode, 'MANAGER')) then
  begin
    MessageDlg('재고관리 권한이 없습니다.', mtWarning, [mbOK], 0);
    Exit;
  end;

  InventoryForm := TfrmInventory.Create(Self);
  try
    try
      InventoryForm.SetContext(dmDatabase.StoreID, FSession.EmployeeID);
      InventoryForm.ShowModal;
    except
      on E: Exception do
        MessageDlg('재고관리 화면을 열지 못했습니다: ' + E.Message +
          sLineBreak + 'database/09_inventory_management.sql 적용 여부를 확인해 주세요.',
          mtError, [mbOK], 0);
    end;
  finally
    InventoryForm.Free;
  end;
end;

procedure TfrmMain.btnShiftClick(Sender: TObject);
var
  ShiftForm: TfrmShiftManagement;
begin
  ShiftForm := TfrmShiftManagement.Create(Self);
  try
    try
      ShiftForm.SetContext(dmDatabase.StoreID, dmDatabase.TerminalID,
        FSession.EmployeeID);
      ShiftForm.ShowModal;
    except
      on E: Exception do
        MessageDlg('영업 개점/마감 화면을 열지 못했습니다: ' + E.Message +
          sLineBreak + 'database/08_operational_foundation.sql 적용 여부를 확인해 주세요.',
          mtError, [mbOK], 0);
    end;
  finally
    ShiftForm.Free;
  end;
end;

procedure TfrmMain.btnBackupClick(Sender: TObject);
var
  BackupForm: TfrmBackup;
begin
  if not SameText(FSession.RoleCode, 'OWNER') then
  begin
    MessageDlg('데이터 백업 및 복구 검증은 점주 권한이 필요합니다.',
      mtWarning, [mbOK], 0);
    Exit;
  end;

  BackupForm := TfrmBackup.Create(Self);
  try
    BackupForm.ShowModal;
  finally
    BackupForm.Free;
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

procedure TfrmMain.btnReportsClick(Sender: TObject);
var
  ReportForm: TfrmSalesReport;
begin
  if not (SameText(FSession.RoleCode, 'OWNER') or
    SameText(FSession.RoleCode, 'MANAGER')) then
  begin
    MessageDlg('매출관리 권한이 없습니다.', mtWarning, [mbOK], 0);
    Exit;
  end;

  ReportForm := TfrmSalesReport.Create(Self);
  try
    try
      ReportForm.SetContext(dmDatabase.StoreID, FSession.EmployeeID);
      ReportForm.ShowModal;
    except
      on E: Exception do
        MessageDlg('매출관리 화면을 열지 못했습니다: ' + E.Message +
          sLineBreak + 'database/07_sales_closing.sql 적용 여부를 확인해 주세요.',
          mtError, [mbOK], 0);
    end;
  finally
    ReportForm.Free;
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
