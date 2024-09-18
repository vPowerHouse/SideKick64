object SideKick: TSideKick
  Left = 0
  Top = 0
  Caption = 'SideKick64'
  ClientHeight = 832
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
  end
  object Log: TMemo
    Left = 0
    Top = 281
    Width = 815
    Height = 232
    Align = alTop
    TabOrder = 1
    WordWrap = False
    ExplicitLeft = 2
    ExplicitTop = 605
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
    object btnLoad: TButton
      Left = 2
      Top = 0
      Width = 64
      Height = 25
      Caption = 'Load'
      TabOrder = 0
      OnClick = btnLoadClick
    end
    object More: TButton
      Left = 66
      Top = 0
      Width = 64
      Height = 25
      Caption = 'More'
      TabOrder = 1
      OnClick = MoreLessClick
    end
    object Less: TButton
      Left = 130
      Top = 0
      Width = 64
      Height = 25
      Caption = 'Less'
      TabOrder = 2
      OnClick = MoreLessClick
    end
    object Available: TButton
      Left = 194
      Top = 0
      Width = 64
      Height = 25
      Caption = 'Available'
      TabOrder = 3
      OnClick = AvailableClick
    end
    object Run1: TButton
      Left = 258
      Top = 0
      Width = 64
      Height = 25
      Caption = 'RunStop'
      TabOrder = 4
      OnClick = Run1Click
    end
    object TrackAll: TButton
      Tag = 69
      Left = 322
      Top = 0
      Width = 64
      Height = 25
      Caption = 'List All'
      TabOrder = 5
      OnClick = btnLoadClick
    end
    object Show_Browser: TButton
      Left = 386
      Top = 0
      Width = 75
      Height = 25
      Caption = 'Show_Browser'
      TabOrder = 6
      OnClick = Show_BrowserClick
    end
    object SaveSettings: TButton
      Left = 461
      Top = 0
      Width = 75
      Height = 25
      Caption = 'SaveSettings'
      TabOrder = 7
      OnClick = SaveSettingsClick
    end
    object RestoreSettings: TButton
      Left = 536
      Top = 0
      Width = 75
      Height = 25
      Caption = 'RestoreSettings'
      TabOrder = 8
      OnClick = RestoreSettingsClick
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
  end
  object LogCSV: TMemo
    Left = 0
    Top = 513
    Width = 815
    Height = 319
    Align = alClient
    TabOrder = 5
  end
end
