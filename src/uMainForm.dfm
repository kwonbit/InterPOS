object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'InterPOS - 음식점 POS'
  ClientHeight = 640
  ClientWidth = 1024
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -16
  Font.Name = 'Arial'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 16
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 1024
    Height = 72
    Align = alTop
    TabOrder = 0
    object lblTitle: TLabel
      Left = 24
      Top = 20
      Width = 300
      Height = 24
      Caption = 'InterPOS | 음식점 POS'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
    end
  end
  object pnlWork: TPanel
    Left = 0
    Top = 72
    Width = 1024
    Height = 568
    Align = alClient
    TabOrder = 1
    object lblStatus: TLabel
      Left = 32
      Top = 560
      Width = 240
      Height = 16
      Caption = '데이터베이스 미연결'
      Font.Charset = DEFAULT_CHARSET
      Font.Name = 'Arial'
    end
    object btnSales: TButton
      Left = 32
      Top = 32
      Width = 220
      Height = 100
      Caption = 'POS 판매'
      Font.Charset = DEFAULT_CHARSET
      Font.Name = 'Arial'
      TabOrder = 0
      OnClick = btnSalesClick
    end
    object btnTable: TButton
      Left = 272
      Top = 32
      Width = 220
      Height = 100
      Caption = '테이블 관리'
      Font.Charset = DEFAULT_CHARSET
      Font.Name = 'Arial'
      TabOrder = 1
      OnClick = btnTableClick
    end
    object btnMenu: TButton
      Left = 512
      Top = 32
      Width = 220
      Height = 100
      Caption = '메뉴 관리'
      Font.Charset = DEFAULT_CHARSET
      Font.Name = 'Arial'
      TabOrder = 2
      OnClick = btnMenuClick
    end
    object btnEmployee: TButton
      Left = 752
      Top = 32
      Width = 220
      Height = 100
      Caption = '직원 관리'
      Font.Charset = DEFAULT_CHARSET
      Font.Name = 'Arial'
      TabOrder = 3
      OnClick = btnEmployeeClick
    end
    object btnClose: TButton
      Left = 32
      Top = 160
      Width = 140
      Height = 48
      Caption = '로그아웃'
      Font.Charset = DEFAULT_CHARSET
      Font.Name = 'Arial'
      TabOrder = 4
      OnClick = btnCloseClick
    end
    object btnReports: TButton
      Left = 432
      Top = 160
      Width = 220
      Height = 48
      Caption = 'Sales Reports'
      Font.Charset = DEFAULT_CHARSET
      Font.Name = 'Arial'
      TabOrder = 6
      OnClick = btnReportsClick
    end
    object btnKitchen: TButton
      Left = 192
      Top = 160
      Width = 220
      Height = 48
      Caption = 'Kitchen Orders'
      Font.Charset = DEFAULT_CHARSET
      Font.Name = 'Arial'
      TabOrder = 5
      OnClick = btnKitchenClick
    end
  end
end
