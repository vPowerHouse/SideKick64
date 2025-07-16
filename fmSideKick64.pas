unit fmSideKick64;

//copyright 2024 Pat Foley

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils,// System.Variants,
   System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,// Vcl.Dialogs,
    Vcl.Buttons, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Grids, Vcl.CheckLst;

type

  TSideKick = class(TForm)

    btnLoad: TButton;
    More: TButton;
    Banner: TPanel;
    Less: TButton;
    Available: TButton;
    Run1: TButton;
    TrackAll: TButton;
    SG: TStringGrid;
    Log: TMemo;
    FlowPanel1: TFlowPanel;

    Show_Browser: TButton;
    Save_Settings: TButton;
    Restore_Settings: TButton;
    LogCSV: TMemo;

    procedure AvailableClick(Sender: TObject);
    procedure btnLoadClick(Sender: TObject);

    procedure Save_SettingsClick(Sender: TObject);
//  protected
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
//  public  //damaged these somehow

    procedure InitWinList(Sender: TObject; inScrackAll: Boolean);
    procedure MoreLessClick(Sender: TObject);
    procedure Restore_SettingsClick(Sender: TObject);
    procedure Run1Click(Sender: TObject);

    procedure Show_BrowserClick(Sender: TObject);
//    public  //damaged these somehow fixed by renaming Load button to btnLoad was Load
//  still damaged 20224 sept 16

  private
      ChkLB: TCheckListBox;

   // var
  end;

var
  SideKick: TSideKick;
implementation

{$R *.dfm}

uses
  System.StrUtils,
  System.IOUtils,
//  ganttt,
  AppList;
//  Shellapi;
var
  Exes: TptrWins;


procedure TSideKick.AvailableClick(Sender: TObject);
begin
  ChkLB.Left := Available.Left;
  ChkLB.Top := Available.Top + Available.Height + 50 { MN for titlebar height };
  ChkLB.Visible := not ChkLb.Visible;
end;

procedure TSideKick.btnLoadClick(Sender: TObject);
var
  ListallWindows: Boolean;
begin
  ListallWindows := (Sender as Tcomponent).Tag = 69;
  InitWinList(Sender, ListallWindows);
end;

procedure TSideKick.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if assigned(Exes) then
    begin
      Exes.StateChangeRequests([skDataSave]);// , sKDataSave]); // Oops!   was skstop
      Exes.Free;
    end;
  CanClose := True;
end;

procedure TSideKick.FormCreate(Sender: TObject);
begin
  ChkLB := TCheckListBox.Create(Self);
  with ChkLB do begin
      Left := 100;
      Top := 50;
      ItemHeight := 27;
      TabOrder := 5;
      ChkLB.Visible := False;
      ChkLB.Parent := Self;
    end;
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

procedure TSideKick.MoreLessClick(Sender: TObject);
var
  localInstruction: TskState;
  bMore: Boolean;
begin
  bMore := (Sender as tcontrol).Name = 'More';
  if bMore
  then
    localInstruction := skEverythingTrue
  else
    localInstruction := skEverythingFalse;

  Exes.StateChangeRequests([localInstruction]);
  More.Enabled := not bMore;
  Less.Enabled := bMore;
end;

procedure TSideKick.Restore_SettingsClick(Sender: TObject);
begin
  Exes.StateChangeRequests([skViewsSettingsRestore]);
end;

procedure TSideKick.Run1Click(Sender: TObject);
begin
  if assigned(Exes)
    then Exes.StateChangeRequests([skRunStop]);
end;

procedure TSideKick.Save_SettingsClick(Sender: TObject);
begin
  if assigned(Exes) then
    Exes.StateChangeRequests([skViewsSettingsSave]);
end;

procedure TSideKick.Show_BrowserClick(Sender: TObject);
begin
//  form1.show;
  //form2.Show;
  Banner.Caption := 'Browser window coming soon!';
end;

end.
