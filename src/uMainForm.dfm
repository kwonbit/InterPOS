object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'InterPOS'
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
      Caption = 'InterPOS'
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
      Caption = 'Database status'
      Font.Charset = DEFAULT_CHARSET
      Font.Name = 'Arial'
    end
    object btnSales: TButton
      Left = 32
      Top = 32
      Width = 220
      Height = 100
      Caption = 'POS Sales'
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
      Caption = 'Table Management'
      Font.Charset = DEFAULT_CHARSET
      Font.Name = 'Arial'
      TabOrder = 1
    end
    object btnMenu: TButton
      Left = 512
      Top = 32
      Width = 220
      Height = 100
      Caption = 'Menu Management'
      Font.Charset = DEFAULT_CHARSET
      Font.Name = 'Arial'
      TabOrder = 2
    end
    object btnEmployee: TButton
      Left = 752
      Top = 32
      Width = 220
      Height = 100
      Caption = 'Employee Management'
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
      Caption = 'Logout'
      Font.Charset = DEFAULT_CHARSET
      Font.Name = 'Arial'
      TabOrder = 4
      OnClick = btnCloseClick
    end
  end
end
