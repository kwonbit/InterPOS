object frmLogin: TfrmLogin
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'InterPOS - '#$B85C#$ADF8#$C778
  ClientHeight = 520
  ClientWidth = 760
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -15
  Font.Name = #$B9D1#$C740' '#$ACE0#$B515
  Position = poScreenCenter
  OnCreate = FormCreate
  object pnlLogin: TPanel
    Left = 110
    Top = 75
    Width = 540
    Height = 360
    TabOrder = 0
    Visible = False
    object lblLoginTitle: TLabel
      Left = 32
      Top = 28
      Width = 470
      Height = 42
      Alignment = taCenter
      Caption = 'InterPOS - '#$B9E4#$C7A5' '#$B85C#$ADF8#$C778
      Font.Height = -24
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblLoginID: TLabel
      Left = 78
      Top = 112
      Width = 90
      Height = 24
      Caption = #$C544#$C774#$B514
    end
    object edtLoginID: TEdit
      Left = 180
      Top = 106
      Width = 280
      Height = 32
      TabOrder = 0
    end
    object lblPassword: TLabel
      Left = 78
      Top = 164
      Width = 90
      Height = 24
      Caption = #$BE44#$BC00#$BC88#$D638
    end
    object edtPassword: TEdit
      Left = 180
      Top = 158
      Width = 280
      Height = 32
      PasswordChar = '*'
      TabOrder = 1
    end
    object btnLogin: TButton
      Left = 180
      Top = 226
      Width = 280
      Height = 54
      Caption = #$B85C#$ADF8#$C778
      Default = True
      TabOrder = 2
      OnClick = btnLoginClick
    end
  end
  object pnlSetup: TPanel
    Left = 70
    Top = 30
    Width = 620
    Height = 460
    TabOrder = 1
    Visible = False
    object lblSetupTitle: TLabel
      Left = 32
      Top = 20
      Width = 550
      Height = 38
      Alignment = taCenter
      Caption = #$CD5C#$CD08' '#$B9E4#$C7A5' '#$BC0F #$C810#$C8FC' '#$ACC4#$C815' '#$B4F1#$B85D
      Font.Height = -21
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblStoreName: TLabel
      Left = 70
      Top = 86
      Width = 120
      Height = 24
      Caption = #$B9E4#$C7A5' '#$C774#$B984
    end
    object edtStoreName: TEdit
      Left = 220
      Top = 80
      Width = 320
      Height = 30
      TabOrder = 0
    end
    object lblOwnerName: TLabel
      Left = 70
      Top = 132
      Width = 120
      Height = 24
      Caption = #$C810#$C8FC' '#$C774#$B984
    end
    object edtOwnerName: TEdit
      Left = 220
      Top = 126
      Width = 320
      Height = 30
      TabOrder = 1
    end
    object lblSetupLoginID: TLabel
      Left = 70
      Top = 178
      Width = 120
      Height = 24
      Caption = #$B85C#$ADF8#$C778' '#$C544#$C774#$B514
    end
    object edtSetupLoginID: TEdit
      Left = 220
      Top = 172
      Width = 320
      Height = 30
      TabOrder = 2
    end
    object lblSetupPassword: TLabel
      Left = 70
      Top = 224
      Width = 120
      Height = 24
      Caption = #$BE44#$BC00#$BC88#$D638
    end
    object edtSetupPassword: TEdit
      Left = 220
      Top = 218
      Width = 320
      Height = 30
      PasswordChar = '*'
      TabOrder = 3
    end
    object lblConfirmPassword: TLabel
      Left = 70
      Top = 270
      Width = 120
      Height = 24
      Caption = #$BE44#$BC00#$BC88#$D638' '#$D655#$C778
    end
    object edtConfirmPassword: TEdit
      Left = 220
      Top = 264
      Width = 320
      Height = 30
      PasswordChar = '*'
      TabOrder = 4
    end
    object btnCreateOwner: TButton
      Left = 220
      Top = 318
      Width = 320
      Height = 48
      Caption = #$C810#$C8FC' '#$ACC4#$C815' '#$C0DD#$C131
      TabOrder = 5
      OnClick = btnCreateOwnerClick
    end
    object lblMessage: TLabel
      Left = 32
      Top = 390
      Width = 550
      Height = 42
      Alignment = taCenter
      AutoSize = False
      Caption = ''
      Font.Color = clNavy
      ParentFont = False
      WordWrap = True
    end
  end
end
