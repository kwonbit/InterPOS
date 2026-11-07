object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'InterPOS - #$C74C#$C2DD#$C810 POS'
  ClientHeight = 640
  ClientWidth = 1024
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -16
  Font.Name = #$B9D1#$C740 #$ACE0#$B515
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
      Caption = 'InterPOS | #$C74C#$C2DD#$C810 POS'
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
      Caption = 'POS #$D310#$B9E4'
      TabOrder = 0
      OnClick = btnSalesClick
    end
    object btnTable: TButton
      Left = 272
      Top = 32
      Width = 220
      Height = 100
      Caption = #$D14C#$C774#$BE14 #$AD00#$B9AC
      TabOrder = 1
    end
    object btnMenu: TButton
      Left = 512
      Top = 32
      Width = 220
      Height = 100
      Caption = #$BA54#$B274 #$AD00#$B9AC
      TabOrder = 2
    end
    object btnClose: TButton
      Left = 32
      Top = 160
      Width = 140
      Height = 48
      Caption = #$C885#$B8CC
      TabOrder = 3
      OnClick = btnCloseClick
    end
    object lblStatus: TLabel
      Left = 32
      Top = 560
      Width = 300
      Height = 24
      Caption = #$B370#$C774#$D130#$BCA0#$C774#$C2A4 #$BBF8#$C5F0#$ACB0
    end
  end
end
