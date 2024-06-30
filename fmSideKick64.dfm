object SideKick: TSideKick
  Left = 0
  Top = 0
  Caption = 'SideKick'
  ClientHeight = 441
  ClientWidth = 624
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  TextHeight = 15
  object SG: TStringGrid
    Left = 0
    Top = 68
    Width = 624
    Height = 120
    Align = alTop
    ColCount = 6
    DefaultColWidth = 86
    FixedCols = 0
    TabOrder = 0
  end
  object Banner: TPanel
    Left = 0
    Top = 0
    Width = 624
    Height = 41
    Align = alTop
    Caption = 'Banner'
    TabOrder = 1
  end
  object Log: TMemo
    Left = 121
    Top = 308
    Width = 503
    Height = 133
    Align = alClient
    Lines.Strings = (
      'Log')
    TabOrder = 2
  end
  object FlowPanel1: TFlowPanel
    Left = 0
    Top = 41
    Width = 624
    Height = 27
    Align = alTop
    Caption = 'FlowPanel1'
    TabOrder = 3
    object Load: TButton
      Left = 1
      Top = 1
      Width = 75
      Height = 25
      Caption = 'Load'
      TabOrder = 0
      OnClick = LoadClick
    end
    object Other: TButton
      Left = 76
      Top = 1
      Width = 75
      Height = 25
      Caption = 'Other'
      TabOrder = 1
      OnClick = OtherClick
    end
    object Run1: TButton
      Left = 151
      Top = 1
      Width = 75
      Height = 25
      Caption = 'Run1'
      TabOrder = 2
      OnClick = Run1Click
    end
    object Run_2: TButton
      Left = 226
      Top = 1
      Width = 75
      Height = 25
      Caption = 'Run_2'
      TabOrder = 3
      OnClick = Run_2Click
    end
  end
  object ChkLB: TCheckListBox
    Left = 0
    Top = 308
    Width = 121
    Height = 133
    Align = alLeft
    ItemHeight = 17
    TabOrder = 4
  end
  object SG2: TStringGrid
    Left = 0
    Top = 188
    Width = 624
    Height = 120
    Align = alTop
    Color = clBtnFace
    ColCount = 6
    DefaultColWidth = 86
    FixedCols = 0
    TabOrder = 5
  end
end
