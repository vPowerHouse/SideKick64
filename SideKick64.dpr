program SideKick64;

uses
  Vcl.Forms,
  fmSideKick64 in 'fmSideKick64.pas' {SideKick},
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

{SideKick64 copyright 2024 Patrick Foley USA}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Windows10 Dark');
  Application.CreateForm(TSideKick, SideKick);
  Application.Run;
end.
