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
    FSupplierButton: TButton;
    FPurchaseButton: TButton;
    FPayablesButton: TButton;
    FExpenseButton: TButton;
    FFinancialButton: TButton;
    FIngredientRecipeButton: TButton;
    FIngredientPurchaseButton: TButton;
    procedure UpdateDatabaseStatus;
    procedure btnInventoryClick(Sender: TObject);
    procedure btnShiftClick(Sender: TObject);
    procedure btnBackupClick(Sender: TObject);
    procedure btnSupplierClick(Sender: TObject);
    procedure btnPurchaseClick(Sender: TObject);
    procedure btnPayablesClick(Sender: TObject);
    procedure btnExpenseClick(Sender: TObject);
    procedure btnFinancialClick(Sender: TObject);
    procedure btnIngredientsClick(Sender: TObject);
    procedure btnIngredientPurchaseClick(Sender: TObject);
  public
    procedure SetSession(const ASession: TEmployeeSession);
  end;

var
  frmMain: TfrmMain;

implementation

uses
  uDatabase, uEmployeeForm, uMasterDataForm, uSalesForm, uKitchenDisplayForm, uSalesReportForm, uShiftForm, uInventoryForm, uBackupForm, uSupplierForm, uPurchaseForm, uPayableForm, uExpenseForm, uFinancialSummaryForm, uIngredientRecipeForm, uIngredientPurchaseForm;

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
    FBackupButton.Visible := SameText(FSession.RoleCode, 'OWNER');
  if Assigned(FSupplierButton) then
    FSupplierButton.Visible := SameText(FSession.RoleCode, 'OWNER') or
      SameText(FSession.RoleCode, 'MANAGER');
  if Assigned(FPurchaseButton) then
    FPurchaseButton.Visible := SameText(FSession.RoleCode, 'OWNER') or
      SameText(FSession.RoleCode, 'MANAGER');
  if Assigned(FPayablesButton) then
    FPayablesButton.Visible := SameText(FSession.RoleCode, 'OWNER') or
      SameText(FSession.RoleCode, 'MANAGER');
  if Assigned(FExpenseButton) then
    FExpenseButton.Visible := SameText(FSession.RoleCode, 'OWNER') or
      SameText(FSession.RoleCode, 'MANAGER');
  if Assigned(FFinancialButton) then
    FFinancialButton.Visible := SameText(FSession.RoleCode, 'OWNER') or
      SameText(FSession.RoleCode, 'MANAGER');
  if Assigned(FIngredientRecipeButton) then
    FIngredientRecipeButton.Visible := SameText(FSession.RoleCode, 'OWNER') or
      SameText(FSession.RoleCode, 'MANAGER');
  if Assigned(FIngredientPurchaseButton) then
    FIngredientPurchaseButton.Visible := SameText(FSession.RoleCode, 'OWNER') or
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

  FSupplierButton := TButton.Create(Self);
  FSupplierButton.Parent := pnlWork;
  FSupplierButton.SetBounds(672, 352, 300, 48);
  FSupplierButton.Caption := '거래처 관리';
  FSupplierButton.Font.Name := Font.Name;
  FSupplierButton.Visible := False;
  FSupplierButton.OnClick := btnSupplierClick;

  FPurchaseButton := TButton.Create(Self);
  FPurchaseButton.Parent := pnlWork;
  FPurchaseButton.SetBounds(672, 416, 300, 48);
  FPurchaseButton.Caption := '구매관리 / 입고처리';
  FPurchaseButton.Font.Name := Font.Name;
  FPurchaseButton.Visible := False;
  FPurchaseButton.OnClick := btnPurchaseClick;

  FPayablesButton := TButton.Create(Self);
  FPayablesButton.Parent := pnlWork;
  FPayablesButton.SetBounds(672, 480, 300, 48);
  FPayablesButton.Caption := '거래처 매입현황 / 미지급금';
  FPayablesButton.Font.Name := Font.Name;
  FPayablesButton.Visible := False;
  FPayablesButton.OnClick := btnPayablesClick;

  FExpenseButton := TButton.Create(Self);
  FExpenseButton.Parent := pnlWork;
  FExpenseButton.SetBounds(672, 528, 300, 36);
  FExpenseButton.Caption := '영업비용 관리';
  FExpenseButton.Font.Name := Font.Name;
  FExpenseButton.Visible := False;
  FExpenseButton.OnClick := btnExpenseClick;

  FFinancialButton := TButton.Create(Self);
  FFinancialButton.Parent := pnlWork;
  FFinancialButton.SetBounds(32, 232, 300, 48);
  FFinancialButton.Caption := '기간별 수입 / 지출 현황';
  FFinancialButton.Font.Name := Font.Name;
  FFinancialButton.Visible := False;
  FFinancialButton.OnClick := btnFinancialClick;

  FIngredientRecipeButton := TButton.Create(Self);
  FIngredientRecipeButton.Parent := pnlWork;
  FIngredientRecipeButton.SetBounds(32, 296, 300, 48);
  FIngredientRecipeButton.Caption := '원재료 / 메뉴 레시피 관리';
  FIngredientRecipeButton.Font.Name := Font.Name;
  FIngredientRecipeButton.Visible := False;
  FIngredientRecipeButton.OnClick := btnIngredientsClick;

  FIngredientPurchaseButton := TButton.Create(Self);
  FIngredientPurchaseButton.Parent := pnlWork;
  FIngredientPurchaseButton.SetBounds(32, 360, 300, 48);
  FIngredientPurchaseButton.Caption := '원재료 구매 등록';
  FIngredientPurchaseButton.Font.Name := Font.Name;
  FIngredientPurchaseButton.Visible := False;
  FIngredientPurchaseButton.OnClick := btnIngredientPurchaseClick;
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

procedure TfrmMain.btnSupplierClick(Sender: TObject);
var
  SupplierForm: TfrmSupplier;
begin
  if not (SameText(FSession.RoleCode, 'OWNER') or
    SameText(FSession.RoleCode, 'MANAGER')) then
  begin
    MessageDlg('거래처 관리 권한이 없습니다.', mtWarning, [mbOK], 0);
    Exit;
  end;

  SupplierForm := TfrmSupplier.Create(Self);
  try
    try
      SupplierForm.SetStoreID(dmDatabase.StoreID);
      SupplierForm.ShowModal;
    except
      on E: Exception do
        MessageDlg('거래처 관리 화면을 열지 못했습니다: ' + E.Message +
          sLineBreak + 'database/10_supplier_management.sql 적용 여부를 확인해 주세요.',
          mtError, [mbOK], 0);
    end;
  finally
    SupplierForm.Free;
  end;
end;

procedure TfrmMain.btnPurchaseClick(Sender: TObject);
var
  PurchaseForm: TfrmPurchase;
begin
  if not (SameText(FSession.RoleCode, 'OWNER') or
    SameText(FSession.RoleCode, 'MANAGER')) then
  begin
    MessageDlg('구매관리 권한이 없습니다.', mtWarning, [mbOK], 0);
    Exit;
  end;

  PurchaseForm := TfrmPurchase.Create(Self);
  try
    try
      PurchaseForm.SetContext(dmDatabase.StoreID, FSession.EmployeeID);
      PurchaseForm.ShowModal;
    except
      on E: Exception do
        MessageDlg('구매관리 화면을 열지 못했습니다: ' + E.Message +
          sLineBreak + 'database/15_ingredient_purchasing.sql 적용 여부를 확인해 주세요.',
          mtError, [mbOK], 0);
    end;
  finally
    PurchaseForm.Free;
  end;
end;

procedure TfrmMain.btnPayablesClick(Sender: TObject);
var
  PayablesForm: TfrmPayables;
begin
  if not (SameText(FSession.RoleCode, 'OWNER') or
    SameText(FSession.RoleCode, 'MANAGER')) then
  begin
    MessageDlg('미지급금 관리 권한이 없습니다.', mtWarning, [mbOK], 0);
    Exit;
  end;

  PayablesForm := TfrmPayables.Create(Self);
  try
    try
      PayablesForm.SetContext(dmDatabase.StoreID, FSession.EmployeeID);
      PayablesForm.ShowModal;
    except
      on E: Exception do
        MessageDlg('매입현황 / 미지급금 화면을 열지 못했습니다: ' + E.Message +
          sLineBreak + 'database/12_supplier_payables.sql 적용 여부를 확인해 주세요.',
          mtError, [mbOK], 0);
    end;
  finally
    PayablesForm.Free;
  end;
end;

procedure TfrmMain.btnExpenseClick(Sender: TObject);
var
  ExpenseForm: TfrmExpense;
begin
  if not (SameText(FSession.RoleCode, 'OWNER') or
    SameText(FSession.RoleCode, 'MANAGER')) then
  begin
    MessageDlg('영업비용 관리 권한이 없습니다.', mtWarning, [mbOK], 0);
    Exit;
  end;

  ExpenseForm := TfrmExpense.Create(Self);
  try
    try
      ExpenseForm.SetContext(dmDatabase.StoreID, FSession.EmployeeID);
      ExpenseForm.ShowModal;
    except
      on E: Exception do
        MessageDlg('영업비용 화면을 열지 못했습니다: ' + E.Message +
          sLineBreak + 'database/13_operating_expenses.sql 적용 여부를 확인해 주세요.',
          mtError, [mbOK], 0);
    end;
  finally
    ExpenseForm.Free;
  end;
end;


procedure TfrmMain.btnIngredientPurchaseClick(Sender: TObject);
var
  IngredientPurchaseForm: TfrmIngredientPurchase;
begin
  if not (SameText(FSession.RoleCode, 'OWNER') or
    SameText(FSession.RoleCode, 'MANAGER')) then
  begin
    MessageDlg('원재료 구매 등록 권한이 없습니다.', mtWarning, [mbOK], 0);
    Exit;
  end;

  IngredientPurchaseForm := TfrmIngredientPurchase.Create(Self);
  try
    try
      IngredientPurchaseForm.SetContext(dmDatabase.StoreID, FSession.EmployeeID);
      if IngredientPurchaseForm.ShowModal = mrOk then
      begin
        MessageDlg('구매관리 / 입고처리에서 해당 구매를 선택하고 입고 확정해 주세요.',
          mtInformation, [mbOK], 0);
      end;
    except
      on E: Exception do
        MessageDlg('원재료 구매 등록 화면을 열지 못했습니다: ' + E.Message +
          sLineBreak + 'database/15_ingredient_purchasing.sql 적용 여부를 확인해 주세요.',
          mtError, [mbOK], 0);
    end;
  finally
    IngredientPurchaseForm.Free;
  end;
end;

procedure TfrmMain.btnFinancialClick(Sender: TObject);
var
  FinancialForm: TfrmFinancialSummary;
begin
  if not (SameText(FSession.RoleCode, 'OWNER') or
    SameText(FSession.RoleCode, 'MANAGER')) then
  begin
    MessageDlg('수입·지출 현황 조회 권한이 없습니다.', mtWarning, [mbOK], 0);
    Exit;
  end;

  FinancialForm := TfrmFinancialSummary.Create(Self);
  try
    try
      FinancialForm.SetStoreID(dmDatabase.StoreID);
      FinancialForm.ShowModal;
    except
      on E: Exception do
        MessageDlg('수입·지출 현황 화면을 열지 못했습니다: ' + E.Message +
          sLineBreak + 'database/13_operating_expenses.sql 적용 여부를 확인해 주세요.',
          mtError, [mbOK], 0);
    end;
  finally
    FinancialForm.Free;
  end;
end;

procedure TfrmMain.btnIngredientsClick(Sender: TObject);
var
  IngredientForm: TfrmIngredientRecipe;
begin
  if not (SameText(FSession.RoleCode, 'OWNER') or
    SameText(FSession.RoleCode, 'MANAGER')) then
  begin
    MessageDlg('원재료 및 레시피 관리 권한이 없습니다.', mtWarning, [mbOK], 0);
    Exit;
  end;

  IngredientForm := TfrmIngredientRecipe.Create(Self);
  try
    try
      IngredientForm.SetContext(dmDatabase.StoreID, FSession.EmployeeID);
      IngredientForm.ShowModal;
    except
      on E: Exception do
        MessageDlg('원재료 / 메뉴 레시피 화면을 열지 못했습니다: ' + E.Message +
          sLineBreak + 'database/14_ingredient_recipe_management.sql 적용 여부를 확인해 주세요.',
          mtError, [mbOK], 0);
    end;
  finally
    IngredientForm.Free;
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
