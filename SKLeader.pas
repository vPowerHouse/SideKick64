unit SKLeader;

interface

uses
  Controls, Forms;

type

TAuxSKBoss = class
  // using dependancy injection ie UI1 and Settings forms passed in
  // use later
  UI1,
  Settings: TControl;
  constructor InitiateBoss(AView, ASettings: TControl);
  class procedure RestoreViewSettings;
  class procedure SaveViewsOpen;
  class procedure AppendDatafile(const sData: string);

end;

// Snippet/code template/blog maker = class TList<pKnowledgeRef>;


implementation

uses
  classes, System.SysUtils, IniFiles,
  System.IOUtils;

{ TAuxSKBoss }

constructor TAuxSKBoss.InitiateBoss(AView, ASettings: TControl);
begin
  inherited Create;
  UI1 := Aview;
  Settings := ASettings;
end;

// following lifted from SO
procedure SaveFormInformation();
var
  i : Integer;
  form : TForm;
  iniFile : TIniFile;
begin
  iniFile := TIniFile.Create(ExtractFilePath(Application.ExeName) + 'FormInfo.ini');
  try
    for i := 0 to Screen.FormCount - 1 do
    begin
      form := Screen.Forms[i];
      if form.Visible then
      begin
        iniFile.WriteInteger(form.Name, 'Width', form.Width);
        iniFile.WriteInteger(form.Name, 'Height', form.Height);
        iniFile.WriteInteger(form.Name, 'Left', form.Left);
        iniFile.WriteInteger(form.Name, 'Top', form.Top);
        iniFile.WriteBool(form.Name, 'Visible', form.Visible);
        iniFile.WriteBool(form.Name, 'IsMaximized', form.WindowState = wsMaximized)
      end;
    end;
  finally
    iniFile.Free;
  end;
end;

procedure RestoreForms();
var
  i : Integer;
  iniFile : TIniFile;
  form : TForm;
//  FormClass : TFormClass;
  Sections : TStringList;
begin
  iniFile := TIniFile.Create(ExtractFilePath(Application.ExeName) + 'FormInfo.ini');
  Sections := TStringList.Create;

  try
    IniFile.ReadSections(Sections);
    for i := 0 to Sections.Count -1 do
    begin
      //this puts the current read form of the ini File in a TForm Object
      //to then change its properties
      form := Application.FindComponent(Sections[i]) as TForm;
      with form do
      begin
        form.Top := IniFile.ReadInteger(form.Name, 'Top', Top);
        form.Left := IniFile.ReadInteger(form.Name, 'Left', Left);
        form.Height := IniFile.ReadInteger(form.Name, 'Height', Height);
        form.Width := IniFile.ReadInteger(form.Name, 'Width', Width);
        if iniFile.ReadBool(form.Name, 'IsMaximized', WindowState = wsMaximized) then
          form.WindowState := wsMaximized
        else
          form.WindowState := wsNormal;
//        form.Position := poDesigned;
//        if not (Sections[i] = 'F_Main') then
//          form.Visible := IniFile.ReadBool(form.Name, 'Visible', Visible);
      end;
    end;
  finally
    Sections.Free;
//    form.Free;
    iniFile.Free;
  end;
end;

class procedure TAuxSKBoss.AppendDatafile(const sData: string);
begin
  Tfile.AppendAllText('c:\_tickers\sktextdata.txt', sdata, TEncoding.UTF8);
end;

class procedure TAuxSKBoss.RestoreViewSettings;
begin
  RestoreForms();
end;

class procedure TAuxSKBoss.SaveViewsOpen;
begin
  SaveFormInformation();
end;
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

(**
procedure TSideKick.Button1Click(Sender: TObject);
begin
  patTimerEX1:= TpatTimerEX.Create(Self);
  with patTimerEX1 do
  begin
    Parent := Panel1;
    SetBounds(0,0,245,245);
    Show;
  end;
end;




   object Memo1: TMemo
  Left = 258
  Top = 426
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

**)

end.
