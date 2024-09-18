unit fmSideKick64;

//copyright 2024 Pat Foley

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
   System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
    Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Grids, Vcl.CheckLst, Vcl.Buttons, patTimerEX;

type
  TSideKick = class(TForm)
    SG: TStringGrid;
    Log: TMemo;
    FlowPanel1: TFlowPanel;
    btnLoad: TButton;
    More: TButton;
    ChkLB: TCheckListBox;
    Banner: TPanel;
    Less: TButton;
    Available: TButton;
    Run1: TButton;
    TrackAll: TButton;
    Show_Browser: TButton;
    SaveSettings: TButton;
    RestoreSettings: TButton;
    LogCSV: TMemo;
//  private
    procedure SaveSettingsClick(Sender: TObject);
//  protected
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
//  public  //damaged these somehow
    procedure AvailableClick(Sender: TObject);
    procedure InitWinList(Sender: TObject; inScrackAll: Boolean);
    procedure btnLoadClick(Sender: TObject);
    procedure MoreLessClick(Sender: TObject);
    procedure RestoreSettingsClick(Sender: TObject);
    procedure Run1Click(Sender: TObject);

    procedure Show_BrowserClick(Sender: TObject);
//    public  //damaged these somehow fixed by renaming Load button to btnLoad was Load
//  still damaged 20224 sept 16
  end;

var
  SideKick: TSideKick;
  patTimerEX1: TpatTimerEX;
implementation

{$R *.dfm}

uses
  System.StrUtils,
  System.IOUtils,
  AppList;
//  Shellapi;
var
  Exes: TptrWins;

procedure TSideKick.AvailableClick(Sender: TObject);
begin
  with ChkLB do
  begin
    Visible := not Visible;
    Left := Available.Left;
    Top := Available.Top + Available.Height + 50{MN for titlebar height};
  end;
end;

procedure TSideKick.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if assigned(Exes) then
    begin
      Exes.StateChangeRequests([skSave, sKDataSave]); // Oops!   was skstop
      Exes.Free;
    end;
  CanClose := True;
end;

procedure TSideKick.InitWinList(Sender: TObject; inScrackAll: Boolean);
var
  Commands: TaskStates;
begin

  if not assigned(Exes) then
    begin
      Exes := TptrWins.HookInUI(SG,LogCSV.Lines, nil, log.Lines, ChkLB, Banner, inScrackAll);
    end;

  if inScrackAll then
    Commands := [skEverythingTrue, skOpen, skEnumWindows, skRun]
  else
    Commands := [skOpen, skEnumWindows, skRun];

  Exes.StateChangeRequests(Commands);

  btnLoad.Enabled := False;
  Trackall.Enabled := False;
  More.Enabled := not inScrackAll;
  Less.Enabled := inScrackAll;
end;

procedure TSideKick.btnLoadClick(Sender: TObject);
var
  ListallWindows: Boolean;
begin
  ListallWindows := (Sender as Tcomponent).Tag = 69;
  InitWinList(Sender, ListallWindows);
end;

procedure TSideKick.MoreLessClick(Sender: TObject);
var
  localInstruction: TskState;
  bMore: Boolean;
begin
  bMore := (Sender as tcontrol).Name = 'More';
  If bMore
  then
    localInstruction := skEverythingTrue
  else
    localInstruction := skEverythingFalse;

  Exes.StateChangeRequests([localInstruction]);
  More.Enabled := not bMore;
  Less.Enabled := bMore;
end;

procedure TSideKick.RestoreSettingsClick(Sender: TObject);
begin
  Exes.StateChangeRequests([skViewsSettingsRestore]);
end;

procedure TSideKick.Run1Click(Sender: TObject);
begin
  if assigned(Exes)
    then Exes.StateChangeRequests([skRunStop]);
end;

procedure TSideKick.SaveSettingsClick(Sender: TObject);
begin
  if assigned(Exes) then
    Exes.StateChangeRequests([skViewsSettingsSave]);

end;

procedure TSideKick.Show_BrowserClick(Sender: TObject);
begin
  //form2.Show;
  Banner.Caption := 'Browser window coming soon!';
end;

end.
