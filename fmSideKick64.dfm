object SideKick: TSideKick
  Left = 0
  Top = 0
  Caption = 'SideKick'
  ClientHeight = 599
  ClientWidth = 815
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCloseQuery = FormCloseQuery
  TextHeight = 15
  object SG: TStringGrid
    Left = 0
    Top = 59
    Width = 815
    Height = 222
    Align = alTop
    ColCount = 6
    DefaultColWidth = 86
    DefaultDrawing = False
    DrawingStyle = gdsClassic
    FixedCols = 0
    RowCount = 1
    FixedRows = 0
    TabOrder = 0
    ExplicitWidth = 809
  end
  object Log: TMemo
    Left = 0
    Top = 281
    Width = 815
    Height = 318
    Align = alClient
    Lines.Strings = (
      'Log')
    TabOrder = 1
    ExplicitWidth = 809
    ExplicitHeight = 301
  end
  object FlowPanel1: TFlowPanel
    Left = 0
    Top = 32
    Width = 815
    Height = 27
    Align = alTop
    BevelEdges = []
    BevelOuter = bvNone
    Padding.Left = 2
    TabOrder = 2
    ExplicitWidth = 809
    object Load: TButton
      Left = 2
      Top = 0
      Width = 75
      Height = 25
      Caption = 'Load'
      TabOrder = 0
      OnClick = LoadClick
    end
    object More: TButton
      Left = 77
      Top = 0
      Width = 75
      Height = 25
      Caption = 'More'
      TabOrder = 1
      OnClick = MoreClick
    end
    object Less: TButton
      Left = 152
      Top = 0
      Width = 75
      Height = 25
      Caption = 'Less'
      TabOrder = 2
      OnClick = MoreClick
    end
    object Available: TButton
      Left = 227
      Top = 0
      Width = 75
      Height = 25
      Caption = 'Available'
      TabOrder = 3
      OnClick = AvailableClick
    end
    object Run1: TButton
      Left = 302
      Top = 0
      Width = 75
      Height = 25
      Caption = 'RunStop'
      TabOrder = 4
      OnClick = Run1Click
    end
    object TrackAll: TButton
      Tag = 69
      Left = 377
      Top = 0
      Width = 75
      Height = 25
      Caption = 'List All'
      TabOrder = 5
      OnClick = LoadClick
    end
    object Show_Browser: TButton
      Left = 452
      Top = 0
      Width = 75
      Height = 25
      Caption = 'Show_Browser'
      TabOrder = 6
      OnClick = Show_BrowserClick
    end
  end
  object ChkLB: TCheckListBox
    Left = 0
    Top = 328
    Width = 145
    Height = 271
    ItemHeight = 15
    Style = lbOwnerDrawVariable
    TabOrder = 3
    Visible = False
  end
  object Banner: TPanel
    Left = 0
    Top = 0
    Width = 815
    Height = 32
    Align = alTop
    BevelOuter = bvNone
    Caption = 'Banner'
    Color = clSkyBlue
    Padding.Left = 12
    ParentBackground = False
    TabOrder = 4
    StyleElements = [seBorder]
    ExplicitWidth = 809
  end
  object Memo1: TMemo
    Left = 272
    Top = 376
    Width = 487
    Height = 129
    Lines.Strings = (
      'E,C:\Windows\explorer.exe, 50'
      
        'D12,C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\bds.exe, ' +
        '100'
      'Chrome,C:\Program Files\Google\Chrome\Application\chrome.exe,200'
      'E,C:\Windows\explorer.exe, 0'
      'Np++,C:\Program Files\Notepad++\notepad++.exe, 300'
      'GE_Grep,C:\Users\aspha\GExperts\Binaries\GExpertsGrep.exe, 100')
    TabOrder = 5
    Visible = False
  end
end
