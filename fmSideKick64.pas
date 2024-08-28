unit fmSideKick64;

//copyright 2024 Pat Foley

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Grids,
  Vcl.CheckLst, Vcl.Buttons;


type
  TSideKick = class(TForm)
    SG: TStringGrid;
    Log: TMemo;
    FlowPanel1: TFlowPanel;
    Load: TButton;
    More: TButton;
    ChkLB: TCheckListBox;
    Banner: TPanel;
    Memo1: TMemo;
    Less: TButton;
    Available: TButton;
    Run1: TButton;
    TrackAll: TButton;
    Show_Browser: TButton;
 // private
    procedure InitWinList(Sender: TObject; inScrackAll: Boolean);
 // public
    procedure AvailableClick(Sender: TObject);
    procedure LoadClick(Sender: TObject);
    procedure MoreClick(Sender: TObject);
    procedure Run1Click(Sender: TObject);
    procedure Show_BrowserClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  end;

var
  SideKick: TSideKick;

implementation

{$R *.dfm}

uses
  System.StrUtils,
  System.IOUtils,
  AppList,
  Shellapi;
var
  Exes: TptrWins;

// app launcher to be added someday
// alternate? https://en.delphipraxis.net/topic/3463-rzlauncher-vs-win-api-call/?tab=comments#comment-29107
// source https://stackoverflow.com/questions/38759198/open-external-application-with-passing-parameters-using-delphi-application
//function RunApplication(const AExecutableFile, AParameters: string;
//  const AShowOption: Integer = SW_SHOWNORMAL): NativeUInt;
//var
//  _SEInfo: TShellExecuteInfo;
//begin
//  Result := 0;
//  if not FileExists(AExecutableFile) then
//    Exit;
//
//  FillChar(_SEInfo, SizeOf(_SEInfo), 0);
//  _SEInfo.cbSize := SizeOf(TShellExecuteInfo);
//  _SEInfo.fMask := SEE_MASK_NOCLOSEPROCESS;
//  // _SEInfo.Wnd := Application.Handle;
//  _SEInfo.lpFile := PChar(AExecutableFile);
//  _SEInfo.lpParameters := PChar(AParameters);
//  _SEInfo.nShow := AShowOption;
//  if ShellExecuteEx(@_SEInfo) then
//  begin
//    WaitForInputIdle(_SEInfo.hProcess, 3000);
//    Result := GetProcessID(_SEInfo.hProcess);
//  end;
//end;

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
  if assigned(Exes)
     then begin
       Exes.StateChangeRequests([skSave]); // Oops!   was skstop
       Exes.Free;
     end;
  CanClose := True;
end;

procedure TSideKick.InitWinList(Sender: TObject; inScrackAll: Boolean);
var
  Commands: TaskStates;
begin
  //abort;
  if not assigned(Exes) then
  begin
    Exes := TptrWins.HookInUI(SG, memo1.Lines, log.Lines, ChkLB, Banner, inScrackAll);
  end;

  if inScrackAll then
    Commands := [skEverythingTrue, skEnumWindows, skRun]
  else
    Commands := [skEnumWindows, skRun];

  Exes.StateChangeRequests(Commands);

  Load.Enabled := False;
  Trackall.Enabled := False;
  More.Enabled := not inScrackAll;
  Less.Enabled := inScrackAll;
end;


procedure TSideKick.LoadClick(Sender: TObject);
var
  ListallWindows: Boolean;
  Lall: INteger;
begin
  with SG do
  with Log do
  begin
    Lall := Lef
  end;
  ListallWindows := (Sender as Tcomponent).Tag = 69;
  InitWinList(Sender, ListallWindows);
end;

procedure TSideKick.MoreClick(Sender: TObject);
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

procedure TSideKick.Run1Click(Sender: TObject);
begin
  if assigned(Exes)
    then Exes.StateChangeRequests([skRunStop]);
end;

procedure TSideKick.Show_BrowserClick(Sender: TObject);
begin
  // form2.Show;
  Banner.Caption := 'Browser window coming soon!';
end;
end.
