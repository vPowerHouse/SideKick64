{SideKick64 copyright 2024 Patrick Foley
       All rights reserved
}

program SideKick64;
{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}

uses
  Vcl.Forms,
  Winapi.Windows,
  fmSideKick64 in 'fmSideKick64.pas' {SideKick},
  Vcl.Themes,
  Vcl.Styles;
//  Unit2 in 'Unit2.pas' {Form2};

{$R *.res}

var
  Hnd: THandle = 0;
begin

  Hnd := FindWindow('TSideKick', pchar('SideKick'));
  if Hnd <> 0 then
  begin
    if IsIconic(Hnd) then
      ShowWindow(Hnd, SW_RESTORE);
    SetForegroundWindow(Hnd);
    exit;
  end;

  ReportMemoryLeaksOnShutdown := DEBUG_PROCESS > 0;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Windows10 Dark');
  Application.CreateForm(TSideKick, SideKick);
//  Application.CreateForm(TForm2, Form2);
  SideKick.ScaleBy(96, 72);
  Application.Run;
end.
