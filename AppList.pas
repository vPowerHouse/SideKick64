{ SideKick64 copyright 2024 Patrick Foley
  All rights reserved
9/1/2024 }

unit AppList;

interface

uses
  Classes, Winapi.Windows, System.Generics.Collections, System.SysUtils,
  System.Generics.Defaults,

  Vcl.Grids, Vcl.Controls, Vcl.StdCtrls, Vcl.CheckLst, Graphics, Vcl.ExtCtrls,
  System.IniFiles;

const
  ZeroHandle = 0;
  // set to your language terms here
  cSkrack = ' on top.';   //using
  //cSkFound = ' found open'
  cSkracking = ' tracking.'; //started
  cskracked = ' closed.';  //closed
  //cskRetitled = ' tichnd.';
  cTB = 'Click me... goto %s';
  hour2dot3 = '%2.3f '; //'hr 2.3f
  hour2dot3wS = '%2.3f %s';
  WinHeader: TArray<string> = ['Name', 'Title', 'Class', 'Used', 'Hours',
    'Version'];
  //if updated old data needs fixed 2024Sept
  GoodWinClasses: TArray<string> = ['Shell_TrayWnd', 'Notepad++', 'TAppBuilder',
    'Window', 'Chrome_WidgetWin_1', 'Notepad', 'CabinetWClass', 'TSideKick'];
  ShortNames = '+DWCNEK';


type // 0        1     2        3            4           5       6
  TskState = (skStartPoint, skRun, skStop, skRunStop, skEverythingTrue,
    skEverythingFalse, skEnumWindows, skOpen, skSave, skViewsSettingsSave,
    //opens data in SG
    skDataOpen,
    //saves data from Memo
    sKDataSave,
    skViewsSettingsRestore, skEndPoint);

  TaskStates = TArray<TskState>;
  TpatAM = reference to procedure;
  TpatProc = procedure of object;
  TmyProc = TProc;
  TaskCommands = TList<TpatProc>;
  TWinHandles = TList<HWND>; //NativeUInt// was Unsigned

  ptrWin = ^TWin;
  TWin = record
    Handle: HWnd;
    ClassName: string;
    Name: string;
    sVersion: string;
    Title: string;
    Hours: string;
    ShortName, // assigned when loaded first its the index of desired
    Job: Char; // 'A'..'Z';
    fixUP: TFunc<ptrWin, Boolean, string>;
    Task3: TProc<ptrWin, TStrings>;
    // TpatAM: reference to procedure;//Procedure of object;//            TProc;
    Used, MarkTick, AcculmTick: Uint64;
    Icon: TIcon;
    // procedure setptrAppTitle;
  end;
Type
  TptrWins = class(TList<ptrWin>)
  private
    // Could have used New(pointer) This way lets the cacheapp fields to be set as needed so
    // focused app routines do not a init for first pass.
    // allocates mem for last focusedApp ptr
    // and to let lastapp row to be set at start for hour meters to work and reduced overwrites
    // cacheApp updates when the active or focused window changes
    // perhaps needed if code needs debugged the cache keeps old value before overwritten in update coding
    cacheWin: TWin;
    focusedWin: ptrWin;

    DeltaTicks: Uint64;
    LastErrMessage: string;

    Counter: Integer; // = 0;
    PastTick: Uint64; // = 0;

    WinTimer: TTimer;
    bEverything: Boolean;
    sgGrid: TStringGrid;
    slData,
    slLog: TStrings;
    SB: TPanel;
    SBSubject: TCaption;
    ChBxs: TCheckListBox;
    DesiredExes: TArray<string>;
    // AppBuilderCount: Integer;   used if want First started last out
    // popup: TPopupMenu;
    // IconList: TImageList;
    Handles: TWinHandles;
    procedure AddWinlaunchers(someWins: TStrings);
    procedure AddNewExe(const aHndl: HWnd; const aClassName, aTitle,
      aHour: string; inInsert: Boolean);
    procedure ChangeExeChoices(Sender: TObject);
    procedure CheckForeGroundWindows(const inHandle: HWnd);
    procedure GetWindows(Sender: TObject);
    function getVersionasString(inWinName: string): string;
    procedure KeepItemsCurrent;
    procedure Pulse(Sender: TObject);
    procedure SetGetLogFile(AOperation: TskState);
    procedure SGdrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect;
      State: TGridDrawState);
    procedure UpdateFocusedWin(const inRow: Integer);
  public

    destructor Destroy; override;
    class function HookInUI(inSG: TStringGrid; inDB, inWinStrs, inLog: TStrings;
      inChBxs: TCheckListBox; inBanner: TPanel; const bAll: Boolean): TptrWins;
    // class procedure OpenLocalFile(Path, Params: String);
    procedure sgViewWinClick(Sender: TObject);
    procedure StateChangeRequests(Directives: TaskStates);
  end;

implementation

uses
  System.StrUtils,
  System.DateUtils,
  System.IOUtils,
  Winapi.Messages,
  Winapi.PsAPI,
  Winapi.ShellAPI,
  Winapi.ShlObj,
  SKLeader;

const
  GCstring = ' - Google Chrome';
  GCstringLength = Length(' - Google Chrome');

procedure DeleteAppendage(var ATitle: string; Appendages: TArray<string>);
begin
  var junkLength := length(ATitle);
  var Offset := 1 + junkLength - GCstringLength;
  if Offset > 0 then

  if posEX(GCstring, Atitle, Offset) > 0 then
  Delete(Atitle,Offset,junkLength);
end;

procedure AddCSVLine(WindO: ptrWin; Strs: TStrings);
begin
  var R := 'Broke';
  var title := WindO.Title;
  DeleteAppendage(title, nil);
  R := format('%2.5f, %s, %s',[Now, WindO.ShortName, title]);
  Strs.Add(R);
end;

function FixupBlankTitle(WindO: ptrWin; inFocused: Boolean): string;
begin
  If inFocused then
      Result := format('%s showing',[WindO.Name])
  else
      Result := format(cTB, [WindO.Name]);
end;

function WinActivate(WindowHandle: HWnd): Boolean;
begin
  var WindowRect: TRect;
  try
    SendMessage(WindowHandle, WM_SYSCOMMAND, SC_HOTKEY, WindowHandle);
    SendMessage(WindowHandle, WM_SYSCOMMAND, SC_ARRANGE, WindowHandle);
    Result := SetForegroundWindow(WindowHandle);
    Sleep(2);
    GetWindowRect(WindowHandle, WindowRect);
    // SystemParametersInfo() with SPI_GETSNAPTODEFBUTTON
    With WindowRect do SetCursorPos(Left + Width div 2, Top + Height div 2);
  except
    on Exception do
      Result := False;
  end;
end;

function EnumWindowsCallBack64(aHandle: HWnd; Hs: TWinHandles): BOOL; stdcall;
const
  C_FileNameLength = 256;
var
  WinFileName: string;
  PID, hProcess: DWORD;
  Len: Byte;
begin
  SetLength(WinFileName, C_FileNameLength);
  GetWindowThreadProcessId(aHandle, PID);
  hProcess := OpenProcess(PROCESS_ALL_ACCESS, false, PID);
  begin
    Len := GetModuleFileNameEx(hProcess, 0, PChar(WinFileName),
      C_FileNameLength);
    if Len > 0 then
      Hs.add(aHandle);
  end;
  Result := True;
end;

function EnumWindowsProc32(wHandle: HWnd; var Hs: TWinHandles): BOOL; stdcall;
begin
  if IsWindowVisible(wHandle) then
    Hs.add(wHandle);
  Result := True;
end;

  type
    PHICON = ^HICON;

  function ExtractIconEx(lpszFile: LPCWSTR; nIconIndex: Integer;
    phiconLarge, phiconSmall: PHICON; nIcons: UINT): UINT; stdcall;
    external 'shell32.dll' name 'ExtractIconExW';

/// <remarks> SO answer David Heffernan May 20, 2013 at 17:15 </remarks>
/// added 32 check pf
function GetSmallIconFromExecutableFile(const FileName: string): TIcon;
var
  Icon: HICON;
  ExtractedIconCount: UINT;
begin
  Result := nil;
  try
    ExtractedIconCount := ExtractIconEx(PChar(FileName), 0, nil, @Icon, 1);
    if
{$IFDEF CPU32BITS}
      Win32Check(ExtractedIconCount = 1)
{$ELSE}
      (ExtractedIconCount > 0)
{$ENDIF}
    then
    begin
      Result := TIcon.Create;
      Result.Handle := Icon;
      // Result.SaveToFile(Filename + '.bmp');
    end
  except
    Result.Free;
    Result := nil;
  end;
end;

/// <remarks> source aehimself uBdsLauncher2.pas</remarks>
function GetWindowExeName(wHandle: HWnd): string;
var
  PID: DWORD;
  hProcess: THandle;
  nTemp: Cardinal;
  Modules: array [0 .. 255] of THandle;
  Buffer: array [0 .. 4095] of Char;
begin
  Result := '';
  if GetWindowThreadProcessId(wHandle, PID) <> 0 then
  begin
    hProcess := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ,
      false, PID);
    if hProcess <> 0 then
      if EnumProcessModules(hProcess, @Modules[0], Length(Modules), nTemp) then
        if GetModuleFileNameEx(hProcess, 0, Buffer, SizeOf(Buffer)) > 0 then
          Result := Buffer;
  end;
end;

{ TptrWins }

destructor TptrWins.Destroy;
begin
  WinTimer.Free;
  Handles.Free;
  for var Win: ptrWin in list do
    if Assigned(Win) then
    begin
      if Win.Icon <> nil then
        Win.Icon.Free;
      Dispose(Win);
    end;
  inherited;
end;

class function TptrWins.HookInUI(inSG: TStringGrid; inDB, inWinStrs, inLog: TStrings;
  inChBxs: TCheckListBox; inBanner: TPanel; const bAll: Boolean): TptrWins;
begin
  var
  R := TptrWins.Create;
  R.bEverything := bAll;
  R.cacheWin.AcculmTick := GetTickCount64;  //zero's hourmeter otherwise use to show windows uptime! when setting to zero
  R.focusedWin := @R.cacheWin;
  R.Handles := TWinHandles.Create;
  R.WinTimer := TTimer.Create(nil);
  R.WinTimer.OnTimer := R.Pulse;
  R.WinTimer.Interval := 600;
  R.WinTimer.Enabled := false;
  R.ChBxs := inChBxs;
  R.ChBxs.OnClick := R.ChangeExeChoices;
  R.ChBxs.Items.Clear;
  for var I := Low(GoodWinClasses) to High(GoodWinClasses) do
  begin
    R.ChBxs.Items.add(GoodWinClasses[I]);
    R.ChBxs.Checked[I] := True;
    { TODO -oPat :    +1 was needed to hard switch the Everything checkbox may
      add a freeze or snapshoot or pause to get more windows
      add checked to list
      ie saved good list with saveable checked.
    }
  end;
  R.ChangeExeChoices(R.ChBxs);
  R.SB := inBanner;
  R.SBSubject :=  'Initiated';//inBanner.Caption;//      'Initiated';
  R.slData := inDB;
  R.slLog := inLog;
  R.sgGrid := inSG;
  R.sgGrid.OnClick := R.sgViewWinClick;
  R.sgGrid.OnEnter := R.sgViewWinClick;
  R.sgGrid.OnDrawCell := R.SGdrawCell;
  // moved to drawcell
  // R.sgGrid.Rows[0].CommaText := 'Name, Title, Class, Used, Hours, Version';
  R.sgGrid.ColWidths[0] := Round(180 * inSG.ScaleFactor);
  R.sgGrid.ColWidths[1] := Round(236 * inSG.ScaleFactor);
  R.sgGrid.ColWidths[2] := Round(160 * inSG.ScaleFactor);
  R.sgGrid.ColWidths[3] := Round(60 * inSG.ScaleFactor);
  R.sgGrid.ColWidths[4] := Round(90 * inSG.ScaleFactor);
  Result := R;
end;


procedure TptrWins.AddWinlaunchers(someWins: TStrings);
var
  lpDummy: ptrWin;
begin
  for var ii := 0 to someWins.Count - 1 do
  begin
    New(lpDummy);
    with lpDummy^ do
    begin
      Job  := 'A';//splitString(someWins[ii], ',')[0];
      Name  :=      splitString(someWins[ii], ',')[1];
      Hours :=      splitString(someWins[ii], ',')[2];
      Icon := nil;
      if lpDummy.Name <> '' then
        try
          lpDummy.Icon := GetSmallIconFromExecutableFile(lpDummy.Name);
        except
          lpDummy.Icon := nil;
        end;
      sVersion := getVersionasString(Name);
      Name := ExtractFileName(Name);
      Title := { Kind } Job + ' Skracker';
      Used := 0;
    end;

    Add(lpDummy);
    sgGrid.RowCount := Count + 1;
    slLog.add(lpDummy.Name + ' skrackable');
  end;
end;

procedure TptrWins.AddNewExe(const aHndl: HWnd;
  const aClassName, aTitle, aHour: string; inInsert: Boolean);
var
  lpWin: ptrWin;
//  PID: DWORD;
begin
  New(lpWin);
  lpWin.Name := GetWindowExeName(aHndl);
  lpWin.Icon := nil;
  if lpWin.Name <> '' then
    try
      lpWin.Icon := GetSmallIconFromExecutableFile(lpWin.Name);
    except
      lpWin.Icon := nil;
    end;
  // to build inifile
  // SL.Add(lpWin.Name);
  // lpWin.Job := 'R';
  lpWin.sVersion := getVersionasString(lpWin.Name);
  lpWin.Name := ExtractFileName(lpWin.Name);
  lpWin.Name := ChangeFileExt(lpWin.Name, '');
  lpWin.Handle := aHndl;
  lpWin.AcculmTick := 0;
  lpWin.MarkTick := GetTickCount64;
  lpWin.Used := 1;
  lpWin.Title := aTitle;
  lpWin.ClassName := aClassName;
  //GetWindowThreadProcessId(aHndl, PID);
  //lpWin.Hours := PID.ToString;
  // Data Driven Design functions and procedures attached to needy data that would other be edge case!
  // rather than complex heirarchy code simply assigned as data loads loseing many if edge case tests.
  var ShortNu := IndexText(aClassName, GoodWinClasses);
  case ShortNu of
    0:
      begin
        lpWin.Title := cTB; { TODO -oPat : add to title check too
          when loses focus title change to hide }
        lpWin.Name := 'Taskbar';
        // lpWin.Kind := 'T';
        lpWin.fixUP := FixupBlankTitle;
      end;
    1 .. 7:
      begin
        lpWin.ShortName := ShortNames[ShortNu];
        lpWin.Task3 := AddCSVLine;//(lpWin, slData);
        AddCSVLine(lpWin,slData);
      end;
    else
        lpWin.fixUP := nil;

  end;
  if inInsert then
  begin
    Insert(0, lpWin);
    lpWin.Job := 'I'
  end
  else
  begin
    add(lpWin);
    lpWin.Job := 'W';
  end;
  SBSubject := lpWin.Name + ' running.';
  slLog.add(aHour + ' ' + lpWin.Name + ' ' + aTitle + cSkracking);
  sgGrid.RowCount := Count + 1;
  focusedWin := lpWin;
end;

procedure TptrWins.ChangeExeChoices(Sender: TObject);
var
  ChkLB: TCheckListBox;
  NameCount: Integer;
  I: Integer;
begin
  NameCount := 0;
  ChkLB := Sender as TCheckListBox;
  SetLength(DesiredExes, ChkLB.Items.Count);
  for I := 0 to ChkLB.Items.Count - 1 do
    if ChkLB.Checked[I] then
    begin
      DesiredExes[NameCount] := ChkLB.Items[I];
      Inc(NameCount);
    end;
  SetLength(DesiredExes, NameCount);
end;

procedure TptrWins.CheckForeGroundWindows(const inHandle: HWnd);
const
  max_size = 255; // 255 * 4;
var
  awn: HWnd;
  sHour: string;
  Title, ClassName: Array [0 .. max_size] Of Char;
  sClassName: string;
  ii: Integer;
  lpWin: ptrWin;
  bInsertList: Boolean;
begin

  If inHandle > ZeroHandle then
    awn := inHandle
  else
    awn := GetForegroundWindow;

  if awn = 0 then
    SBSubject := 'Not a foreground window'
  else if awn <> focusedWin.Handle then
    Try
      cacheWin.Handle := awn;
      GetClassName(awn, ClassName, max_size);
      GetWindowText(awn, Title, max_size);
      cacheWin.Title := Title;

      sClassName := Trim(ClassName);
      sHour := Format(hour2dot3, [24 * Time]);

      bInsertList := IndexText(sClassName, DesiredExes) >= 0;

      // Xoring worked for seperate lists
      // if bEverything xor InsertWin would let a second sk make a complement list
      if bEverything or bInsertList then
      begin
        for ii := 0 to Count - 1 do
          if awn = Items[ii].Handle then
          begin
            lpWin := Items[ii];
            lpWin.Title := Title;
            Inc(lpWin.Used);

            slLog.Append(sHour + ' ' + lpWin.Name + ' ' + Title + cSkrack);
            SBSubject := lpWin.Name + ' focused.';
            focusedWin := lpWin;
            focusedWin.MarkTick := GetTickCount64;
            SB.Caption := sHour + ' ' + SBSubject;
            sgGrid.Row := ii + 1;
            Exit
          end;
        AddNewExe(awn, ClassName, Title, sHour, bInsertList);
      end
      else
        // mention the focused window not listed so program doesn't appear stuck.
        SB.Caption := ClassName + ' active';

    Except
      On E: Exception Do
      begin
        SBSubject := (E.ClassName + ': ' + E.Message); // begin
      end
      else
        SBSubject := 'Other error Timer stopped';
      WinTimer.Enabled := false;
    End;
end;

procedure TptrWins.GetWindows(Sender: TObject);
// (WantedWins: TArray<string>);
begin
{$IFDEF CPU32BITS}
  EnumWindows(@EnumWindowsProc32, LParam(@Handles));
{$ELSE}
  EnumWindows(@EnumWindowsCallBack64, LParam(Handles));
{$ENDIF}
  sgGrid.BeginUpdate;
  for var W in Handles do
    CheckForeGroundWindows(W);
  sgGrid.EndUpdate;
end;

function TptrWins.getVersionasString(inWinName: string): string;
var
  Major, Minor, Build: Cardinal;
begin
  Major := 0;
  Minor := 0;
  Build := 0;
  Try
    Result := 'NA';
    //                        Uwe's
    if inWinName = '' then // /
      GetProductVersion(GetModuleName(focusedWin.Handle), Major, Minor, Build)
    else
      begin
          // GetFileVersionInfo modifies the filename parameter data while parsing.
        // Copy the string const into a local variable to create a writeable copy.
        var FileName := inWinName;
        UniqueString(FileName);


         GetProductVersion(FileName, Major, Minor, Build);
      end;
    begin
      SBSubject := 'Needed?' + inWinName;
      Result := Format('%d.%d.%d', [Major, Minor, Build]);
    end;
  Except
    on E: Exception do
      Result := E.ClassName + ':' + E.Message
  End;
end;

/// Cull closed windows and update the foreground window.
procedure TptrWins.KeepItemsCurrent;
var
  TestItem: ptrWin;
  sRemoved: string;
  I: Integer;
  Keep: Boolean;
begin
  TestItem := nil;
  try
    for I := Count - 1 downto 0 do
    begin
      TestItem := list[I];
      if TestItem.Job = 'A' then
        Continue;

      Keep := IsWindow(TestItem.Handle);
      if Keep and not bEverything then
        Keep := (TestItem.Job = 'I');
      if not Keep then
      begin
        sRemoved := sRemoved + TestItem.ClassName + ' ';
        TestItem.Icon.Free;
        Remove(TestItem);
        Dispose(TestItem);
        sgGrid.RowCount := Count + 1;
      end
      else if TestItem.Handle = focusedWin.Handle then
             begin
               UpdateFocusedWin(I + 1);
             end
           else if assigned(TestItem.fixUP) then
             TestItem.Title := TestItem.fixUP(TestItem, False);
    end;

    if sRemoved <> '' then
    begin
      sRemoved := Format(hour2dot3, [Time * 24]) + sRemoved + cSkracked;
      SBSubject := sRemoved;
      slLog.add(sRemoved);
      sgGrid.Invalidate;
    end;
  except
    On E: Exception do
      if Assigned(TestItem) then
        slLog.Append(TestItem.Name + ' ' + E.ClassName + ': ' + E.Message);
  end;
end;

procedure TptrWins.Pulse(Sender: TObject);
begin
  WinTimer.Enabled := false;
  if Counter > 2 then
  begin
    Counter := 0;
    var
    Tick := GetTickCount64;
    DeltaTicks := Tick - PastTick;
    PastTick := Tick;
    KeepItemsCurrent;
    sgGrid.Invalidate;
  end
  else
    CheckForeGroundWindows(ZeroHandle);

  Inc(Counter);
  //SB.Caption := SBSubject;
  WinTimer.Enabled := True;
end;

procedure TptrWins.SetGetLogFile(AOperation: TskState);
begin
  var
  DayNu := DayOfTheYear(Date);
  var
  YearNu := YearOf(Date);
  var
  FileName := Format('%s %d day%4d%s', ['C:\_tickers\machinelog', YearNu,
    DayNu, '.txt']);

  Case AOperation of
    skOpen:
      begin
        if FileExists(FileName) then
          slLog.LoadFromFile(FileName)
        else
          slLog.add(FileName);
      end;
    skSave:
      slLog.SaveToFile(FileName);
  end;
end;

procedure TptrWins.SGdrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect;
  State: TGridDrawState);
var
  bgColor: TColor;
  Kind: 'A' .. 'Z';
begin
  if ARow = 0 then
    Kind := 'Z'
  else if
    Arow - 1 = IndexOf(focusedWin) then Kind := 'X'
  else
    Kind := Items[ARow - 1].Job;
  begin
    case Kind of
      'A':
        bgColor := clWebLightSkyBlue; // clWebCornFlowerBlue;
      'I':
        bgColor := clcream;
      'W':
        bgColor := clWebCornSilk;
      'Z':
        bgColor := clAqua;
    else
        bgColor := clMoneyGreen;
    end;
    var
    Cnvs := TStringGrid(Sender).Canvas;
    Cnvs.Brush.Color := bgColor;
    Cnvs.FillRect(Rect);
    if ARow = 0 then
      Cnvs.TextOut(Rect.Left + 5, Rect.Top + 3, WinHeader[ACol])
    else
    begin
      var
      Win := Items[ARow - 1];
      Case ACol of
        0:
          begin
            Cnvs.Draw(Rect.Left + 5, Rect.Top + 3, Win.Icon);
            Cnvs.TextOut(Rect.Left + 32, Rect.Top + 2, Win.Name);
          end;
        1:
          Cnvs.TextOut(Rect.Left + 2, Rect.Top + 2, Win.Title);
        2:
          Cnvs.TextOut(Rect.Left + 2, Rect.Top + 2, Win.ClassName);
        3:
          begin
            Cnvs.TextOut(Rect.Left + 43, Rect.Top + 2, Win.Used.ToString);
          end;
        4:
          Cnvs.TextOut(Rect.Left + 2, Rect.Top + 2, Win.Hours);
        5:
          Cnvs.TextOut(Rect.Left + 2, Rect.Top + 2, Win.sVersion);
      end;
    end;
  end;
end;

/// Return and DblClick assigned here
procedure TptrWins.sgViewWinClick(Sender: TObject);
begin
  var
  Idx := sgGrid.Selection.Top - 1;

  if (Idx > -1) and (list[Idx].Job = 'I') then
    WinActivate(list[Idx].Handle);
end;

procedure TptrWins.StateChangeRequests(Directives: TaskStates);
var
  Step: TskState;
begin
  for Step in Directives do
  begin
    case Step of
      skRun:
        WinTimer.Enabled := True;
      skStop:
        WinTimer.Enabled := False;
      skRunStop:
        WinTimer.Enabled := not WinTimer.Enabled;
      skEverythingTrue:
        bEverything := True;
      skEverythingFalse:
        bEverything := False;
      skEnumWindows:
        GetWindows(nil);
      skOpen:
        SetGetLogFile(skOpen);
      skSave:
        SetGetLogFile(skSave);
      skViewsSettingsSave:
        TAuxSKBoss.SaveViewsOpen;
      skViewsSettingsRestore:
        TAuxSKBoss.RestoreViewSettings;
      sKDataSave:
        TAuxSKBoss.AppendDatafile(slData.Text);
    end;
  end;
  if not WinTimer.Enabled then
    SB.Caption := 'SK Stopped use RunStop to restart.';
end;

procedure TptrWins.UpdateFocusedWin(const inRow: Integer);
var
  Title: Array [0 .. 255] Of Char;
  S, sErr, sMeg, sTitle, sFixUp: string;
begin
  // increment Hours and run a task on the focused Win
  with focusedWin^ do
  begin
    Inc(AcculmTick, DeltaTicks);
    // sgGrid.Cells[4, inRow] := Format('%3.4f', [AcculmTick / 3600_000]);
    Hours := Format('%3.4f', [AcculmTick / 3600_000]);
    /// sgGrid.Invalidate;  do in UI

    /// if sametext(focusedWin.ClassName,'Shell_TrayWnd')
    /// Incoming title is '' on Shell_TrayWnd we generate ptrApp.title by
    /// assigning a task to the ptrApp.fixup could perhaps assign default fixup
    if Assigned(FixUp) then
    begin
      Sfixup := Fixup(focusedWin, True);
      title := sfixup;
    end;
  end;

  /// change Title when form's caption changed.
  GetWindowText(focusedWin.Handle, Title, 255);

  sTitle := Trim(Title) + sFixup;  // moved here Aye~lets sfixup text show when title = '' fix right later
  if focusedWin.Title <> sTitle then
  begin
    focusedWin.Title := sTitle;// + sFixUp; Boo
    S := Format(hour2dot3wS, [24 * Time, sTitle]);
    slLog.add(S);
    SB.Caption := S;
    if Assigned(focusedWin.Task3) then
      focusedWin.Task3(focusedWin, self.slData);
  end;

  sErr := SysErrorMessage(GetLastError);  // catch BDS dialogs here?
  //            'Success' no worky
  if not(PosEX('success', sErr, 1) > 0) then
  begin
    if sErr <> LastErrMessage then
      begin
        sMeg := format('%2.3f Error: %s %s',
          [24 * Time, sErr, focusedWin.ClassName]);
        slLog.add(sMeg);
        LastErrMessage := sErr
      end
    else
        Exit;
  end;
end;

end.
