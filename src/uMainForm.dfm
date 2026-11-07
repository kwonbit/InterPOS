object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'InterPOS - '#51020#49885#51216' POS'
  ClientHeight = 640
  ClientWidth = 1024
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -16
  Font.Name = #63949#47890'? '#24616#51338#48467
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
      Width = 222
      Height = 24
      Caption = 'InterPOS | ?'#46767#46471'??POS'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = #63949#47890'? '#24616#51338#48467
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
      Width = 197
      Height = 16
      Caption = '?'#44247#50464'?'#44245#53195'?'#45825#46250' '#35480#47748#49136#23491'?'
    end
    object btnSales: TButton
      Left = 32
      Top = 32
      Width = 220
      Height = 100
      Caption = 'POS ?'#47662#8467
      TabOrder = 0
      OnClick = btnSalesClick
    end
    object btnTable: TButton
      Left = 272
      Top = 32
      Width = 220
      Height = 100
      Caption = '?'#46767#50464#37321'?'#24895#128#30001'?'
      TabOrder = 1
    end
    object btnMenu: TButton
      Left = 512
      Top = 32
      Width = 220
      Height = 100
      Caption = #63950#48574#46065' '#24895#128#30001'?'
      TabOrder = 2
    end
    object btnClose: TButton
      Left = 32
      Top = 160
      Width = 140
      Height = 48
      Caption = #37291#45189#51642
      TabOrder = 3
      OnClick = btnCloseClick
    end
  end
end
