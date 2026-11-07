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
  Font.Name = '맑은 고딕'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  object pnlHeader: TPanel
    Align = alTop
    Height = 72
    TabOrder = 0
    object lblTitle: TLabel
      Left = 24
      Top = 20
      Width = 240
      Height = 28
      Caption = 'InterPOS | 음식점 POS'
      Font.Height = -21
      Font.Style = [fsBold]
      ParentFont = False
    end
  end
  object pnlWork: TPanel
    Align = alClient
    TabOrder = 1
    object btnSales: TButton
      Left = 32
      Top = 32
      Width = 220
      Height = 100
      Caption = 'POS 판매'
      TabOrder = 0
      OnClick = btnSalesClick
    end
    object btnTable: TButton
      Left = 272
      Top = 32
      Width = 220
      Height = 100
      Caption = '테이블 관리'
      TabOrder = 1
    end
    object btnMenu: TButton
      Left = 512
      Top = 32
      Width = 220
      Height = 100
      Caption = '메뉴 관리'
      TabOrder = 2
    end
    object btnClose: TButton
      Left = 32
      Top = 160
      Width = 140
      Height = 48
      Caption = '종료'
      TabOrder = 3
      OnClick = btnCloseClick
    end
    object lblStatus: TLabel
      Left = 32
      Top = 560
      Width = 300
      Height = 24
      Caption = '데이터베이스 미연결'
    end
  end
end
