unit fmSideKick64;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Grids,
  Vcl.CheckLst;

type
  TSideKick = class(TForm)
    SG: TStringGrid;
    Banner: TPanel;
    Log: TMemo;
    FlowPanel1: TFlowPanel;
    Load: TButton;
    Other: TButton;
    ChkLB: TCheckListBox;
    SG2: TStringGrid;
    Run1: TButton;
    Run_2: TButton;
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure OtherClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure LoadClick(Sender: TObject);
    procedure Run1Click(Sender: TObject);
    procedure Run_2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  SideKick: TSideKick;

implementation

{$R *.dfm}

uses
  System.StrUtils,
  AppList;

var
  Exes: TptrApps;
  ExtraExes: TptrApps;

procedure TSideKick.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  Tag := IndexText('skSave', GoodStates);

  If assigned(Exes)
     then begin
       Exes.ChangeState(Sender);
     end;
  If assigned(ExtraExes)
     then begin
       ExtraExes.ChangeState(Sender);
     end;

  CanClose := True;

end;

procedure TSideKick.FormCreate(Sender: TObject);
begin
  Load.Tag :=       IndexText('skEverything', goodStates);
  Other.Tag :=      IndexText('skEverything', goodStates);
  Run1.Tag := Ord(skRun);
  Run_2.Tag := Ord(skRun);
end;

procedure TSideKick.LoadClick(Sender: TObject);
begin
  if not assigned(Exes) then
  begin
    Exes := TptrApps.HookInUI(SG, log.Lines, ChkLB, Banner, False);
  end;

  Exes.ChangeState(Sender);

end;
procedure TSideKick.OtherClick(Sender: TObject);
begin
  if not assigned(ExtraExes) then
  begin
    ExtraExes := TptrApps.HookInUI(SG2, log.Lines, ChkLB, Banner, True);
  end;

  ExtraExes.ChangeState(Sender);

  end;

procedure TSideKick.Run1Click(Sender: TObject);
begin
  Exes.ChangeState(Sender);
end;

procedure TSideKick.Run_2Click(Sender: TObject);
begin
  ExtraExes.ChangeState(Sender);
end;

end.
