object frmEmployee: TfrmEmployee
  Left = 0
  Top = 0
  Caption = 'InterPOS - '#$C9C1#$C6D0 #$AD00#$B9AC
  ClientHeight = 560
  ClientWidth = 900
  Font.Charset = DEFAULT_CHARSET
  Font.Height = -15
  Font.Name = #$B9D1#$C740 #$ACE0#$B515
  Position = poScreenCenter
  OnCreate = FormCreate
  object pnlTop: TPanel
    Align = alTop
    Height = 64
    TabOrder = 0
    object lblTitle: TLabel
      Left = 24
      Top = 18
      Width = 300
      Height = 28
      Caption = #$C9C1#$C6D0 #$AD00#$B9AC
      Font.Height = -20
      Font.Style = [fsBold]
      ParentFont = False
    end
  end
  object grdEmployees: TDBGrid
    Align = alClient
    DataSource = nil
    Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
    TabOrder = 1
  end
  object pnlButtons: TPanel
    Align = alBottom
    Height = 76
    TabOrder = 2
    object btnAdd: TButton
      Left = 20
      Top = 14
      Width = 170
      Height = 46
      Caption = #$C9C1#$C6D0 #$B4F1#$B85D
      TabOrder = 0
      OnClick = btnAddClick
    end
    object btnPassword: TButton
      Left = 204
      Top = 14
      Width = 190
      Height = 46
      Caption = #$BE44#$BC00#$BC88#$D638 #$BCC0#$ACBD
      TabOrder = 1
      OnClick = btnPasswordClick
    end
    object btnDeactivate: TButton
      Left = 408
      Top = 14
      Width = 170
      Height = 46
      Caption = #$C0AC#$C6A9 #$C911#$C9C0
      TabOrder = 2
      OnClick = btnDeactivateClick
    end
    object btnClose: TButton
      Left = 710
      Top = 14
      Width = 160
      Height = 46
      Caption = #$B2EB#$AE30
      TabOrder = 3
      OnClick = btnCloseClick
    end
  end
end
