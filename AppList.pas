
{SideKick64 copyright 2024 Patrick Foley
       All rights reserved
}


unit AppList;

interface
uses
  Classes, Winapi.Windows, System.Generics.Collections,   System.SysUtils, System.Generics.Defaults,
  Vcl.Grids, Vcl.Controls, Vcl.StdCtrls, Vcl.CheckLst,  Graphics, Vcl.ExtCtrls,
  System.IniFiles;
const
  UnknownHandle = 0;
  cTB = 'Task bar';
  hour2dot3 ='hr %2.3f ';
  hour2dot3wS ='hr %2.3f %s';
  WinHeader: TArray<string> = ['Name', 'Title', 'Class', 'Used', 'Hours', 'Version'];
  GoodWins: Tarray<string> = ['Delphi11','Notepad++', 'Explorer', 'Chrome', 'Notepad','Delphi12', 'TaskBar', 'GE_Grep'];
  GoodWinClasses: Tarray<string> = ['Shell_TrayWnd','Notepad++', 'TAppBuilder', 'Window',
   'Chrome_WidgetWin_1','Notepad','CabinetWClass'{,selfClass} ];

  RoleIdx: TArray<string> = ['I','O','W','A']; //Insert, other, window, Accumulator;

  //selfClass = 'TDesksKick';
  //Not necessary bds shows it in 64 and tailwind on simple apps
  //TAppClass = 'TApplication';
   {TAppClass,'TfmGrepResult','TfmPeInformation',}

//  GoodStates: TArray<string> = ['skStartPoint','skRun','skStop','skShowchkLB', 'skEverything', 'skSave', 'skEndPoint'];
//  TroleStates = set of RoleIdx;
//  TkindKind = (kkLauncher, kkPreferred, kkGeneral, kkOther);
//  TKindIndex = (kiDelphi11, kiNotepadPlusPlus, kiExplorer, kiChrome, kiNotepad,kiDelphi12);
//  TDuty = (dutyMeterlauncher, dutyshowProgramRunning, dutyshowOtherwindows);

type              // 0        1     2        3            4           5       6
  TskState = (skStartPoint,skRun,skStop,skRunStop, skEverythingTrue, skEverythingFalse, skEnumWindows, skSave, skEndPoint);

  TaskStates = TArray<TskState>;
  TpatProc = procedure of object;
  TmyProc = TProc;
  TaskCommands = TList<TpatProc>;

//  PWin32Handles = ^TWin32Handles;
//  TWin32Handles =  TArray<NativeInt>;
  TWinHandles =  Tlist<NativeInt>;  //was Unsigned
  TpatAM = reference to procedure;

  ptrWin = ^TWin;
  TWin = record
    Handle: HWnd;
    ClassName: string;
    Name: string;
    sVersion: string;
    Title: string;

    Hours: string;
    Job: Char;//'A'..'Z';
//    Kind: string;
    //TKindIndex;//'A'..'Z' ;//string;  //  used with      InsertionPoint,
//    sgRow: Integer;
    //Used = Inc on load and focused

//    Task: procedure of object;
//      TpatProc = procedure of object;
//  TmyProc = TProc;

  //  Task: TFunc<Boolean>;//TProc;//      TmyProc;
  //  fixup: procedure of object;
    //Task: TFunc<ptrWin, Boolean>;
    Task: TProc<ptrWin>;
    // Task: Procedure of Object;
    //Task: Tfunc<Boolean>;
    //TpatAM: reference to procedure;//Procedure of object;//            TProc;
    Used,    MarkTick,    AcculmTick : Uint64;
    Icon: TIcon;
  //  procedure setptrAppTitle;
  end;

  TptrWins = class(TList<ptrWin>)
  private
    //
    // allocate mem for last focusedApp ptr to let lastapp row to be set at start         for hour meters to work and reduced overwrites
    // cacheApp updates when the active or focused window changes
    cacheWin: TWin;
    focusedWin: ptrWin;

    DeltaTicks: UInt64;
    LastErrMessage: string;
    SameErrCount: Integer;

    Counter: Integer; // = 0;
    PastTick: Uint64; // = 0;

    WinTimer: TTimer;
    bEverything: Boolean;
    //Instructions: TaskStates;
    sgGrid: TStringGrid;
    slLog: TStrings;
    SB: TPanel;
    SBSubject: string;
    ChBxs: TCheckListBox;
    DesiredExes: TArray<string>;
    //    WinBuilderCount: Integer;   used if want First started last out
//    popup: TPopupMenu;
//    IconList: TImageList;
    Handles: TWinHandles;
//    Handle32s: PWin32Handles;
 //   SB: TPanel;
 //    SBSubject: string;
//Class var   FSavings: TCustomIniFile;
//    FSavingsPathed: string;
    //SL: TStrings;
    procedure &With(a,b,c: Integer);
    procedure AddWinlaunchers(someWins: TStrings);
    procedure AddNewExe(const aHndl: Hwnd; const aClassName, aTitle, aHour: string; InFront: Boolean);
    procedure ChangeExeChoices(Sender: TObject);
    procedure CheckForeGroundWindows(const inHandle: Hwnd);
    function GetSpecialNeed(Need: Variant): Variant;
    function GetSpecialNeedB: Boolean;
    procedure GetSomeWindows(Sender: TObject);
    function getVersionasString(inWinName: string): string;
    procedure KeepItemsCurrent;
    procedure Pulse(Sender: TObject);
    procedure SetTaskBarTitle;
    procedure SGdrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
    procedure UpdateFocusedWin(const inRow: Integer);
  public

    destructor Destroy; override;
    class function HookInUI(inSG: TStringGrid; inWinStrs, inLog: TStrings; inChBxs: TcheckListBox; inBanner: TPanel; const bAll: Boolean): TptrWins;
    //class procedure OpenLocalFile(Path, Params: String);
    procedure sgViewWinClick(Sender: Tobject);
    procedure StateChangeRequests(Directives:TaskStates);
  end;

implementation

uses
  System.StrUtils,
  System.DateUtils,
  System.IOUtils,
  Winapi.Messages,
  Winapi.PsAPI,
  WinApi.ShellAPI,
  WinApi.ShlObj;

function GetSpecialNeedW(WindO: ptrWin): Boolean;
begin
  WindO.Title := 'Special Need W';
  Result := True;
end;

procedure GetSpecialNeedX(WindO: ptrWin);
begin
  WindO.Title := 'Special Need X';
end;


function WinActivate(WindowHandle: HWND): boolean;
begin
   try
      SendMessage(WindowHandle, WM_SYSCOMMAND, SC_HOTKEY, WindowHandle);
      SendMessage(WindowHandle, WM_SYSCOMMAND, SC_ARRANGE, WindowHandle);
      result := SetForegroundWindow(WindowHandle);
   except
      on Exception do Result := false;
   end;
end;

function EnumWindowsCallBack64(aHandle: hWnd; Hs:TWinHandles): BOOL; stdcall;
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

function EnumWindowsProc32(wHandle: HWND; var Hs: TWinHandles): BOOL; stdcall;
begin
  if IsWindowVisible(wHandle) then
    Hs.Add(wHandle);
  Result := True;
end;

  type
    PHICON = ^HICON;

  function ExtractIconEx(lpszFile: LPCWSTR; nIconIndex: Integer; phiconLarge, phiconSmall: PHICON; nIcons: UINT): UINT; stdcall; external 'shell32.dll' name 'ExtractIconExW';

/// <remarks> SO answer David Heffernan May 20, 2013 at 17:15 </remarks>
function GetSmallIconFromExecutableFile(const FileName: string): TIcon;
var
  Icon: HICON;
  ExtractedIconCount: UINT;
begin
  Result := nil;
  try
    ExtractedIconCount := ExtractIconEx(
      PChar(FileName),
      0,
      nil,
      @Icon,
      1
    );
    if
      {$IFDEF CPU32BITS}
            Win32Check(ExtractedIconCount=1)
      {$ELSE}
       (ExtractedIconCount > 0)
      {$ENDIF}

    then begin
      Result := TIcon.Create;
      Result.Handle := Icon;
      //Result.SaveToFile(Filename + '.bmp');
    end
  except
    Result.Free;
    Result := nil;
  end;
end;

/// <remarks> source aehimself uBdsLauncher2.pas</remarks>
function GetWindowExeName(wHandle: HWND): string;
var
  PID: DWORD;
  hProcess: THandle;
  nTemp: Cardinal;
  Modules: array [0 .. 255] of THandle;
  Buffer: array [0 .. 4095] of char;
begin
  Result := '';
  if GetWindowThreadProcessId(wHandle, PID) <> 0 then
  begin
    hProcess := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, False, PID);
    if hProcess <> 0 then
      if EnumProcessModules(hProcess, @Modules[0], Length(Modules), nTemp) then
        if GetModuleFileNameEx(hProcess, 0, Buffer, SizeOf(Buffer)) > 0 then
          Result := Buffer;
  end;
end;

destructor TptrWins.Destroy;
begin
  Wintimer.Free;
  Handles.Free;
  for var Win: ptrWin in list do
    if Assigned(Win)  then
       begin
         if Win.Icon <> nil then
           Win.Icon.Free;
         Dispose(Win);
       end;
  inherited;
end;

class function TptrWins.HookInUI(inSG: TStringGrid; inWinStrs, inLog: TStrings; inChBxs: TcheckListBox; inBanner: TPanel; const bAll: Boolean): TptrWins;
begin
  var R := TptrWins.Create;
  R.bEveryThing := bAll;
  R.cacheWin.AcculmTick := GetTickCount64;
  R.focusedWin := @R.cacheWin;
  R.Handles := TWinHandles.Create;

  // By not using Vcl.Forms is where the application hides
  //
  R.WinTimer := TTimer.Create(nil);
  R.WinTimer.OnTimer := R.Pulse;
  R.WinTimer.Interval := 600;
  R.WinTimer.Enabled := False;
  R.ChBxs := inChBxs;
  R.ChBxs.OnClick := R.ChangeExeChoices;
  R.ChBxs.Items.Clear;
  for var I := Low(GoodWinClasses) to High(GoodWinClasses) do
    begin
      R.ChBxs.Items.add(GoodWinClasses[I]);
      R.ChBxs.Checked[I] := True;
       { TODO -oPat :    +1 was needed to hard switch the Everything switch may
        add a freeze or snapshoot or pause to get more windows }
    end;
  R.ChangeExeChoices(R.ChBxs);
//  R.Parentform := R.chBxs.Parent;
  R.SB := inBanner;
  R.SBSubject := 'Initiated';
  R.slLog := inLog;
  R.sgGrid := inSG;
  R.sgGrid.OnClick := R.sgViewWinClick;
  R.sgGrid.OnEnter := R.sgViewWinClick;
  R.sgGrid.OnDrawCell := R.SGdrawCell;
//  R.sgGrid.Rows[0].CommaText := 'Name, Title, Class, Used, Hours, Version';
  R.sgGrid.ColWidths[0] := 180;
  R.sgGrid.ColWidths[1] := 236;
  R.sgGrid.ColWidths[2] := 160;
  R.sgGrid.ColWidths[3] :=  60;
  R.sgGrid.ColWidths[4] :=  90;

  Result := R;
end;

{ TptrWins }

procedure TptrWins.AddWinlaunchers(someWins: TStrings);
var
  lpDummy: ptrWin;
begin

  for var ii := 0 to someWins.Count -1 do
  begin
    New(lpDummy);
    with lpDummy^ do
    begin
      Job := 'A';////splitString(someWins[ii], ',')[0][1];
      Name := splitString(someWins[ii], ',')[1]; // 'Dummy' + (ii+1).ToString;
      Hours := splitString(someWins[ii], ',')[2];//.ToSingle();
      Icon := nil;
      if lpDummy.Name <> '' then
        try
          lpDummy.Icon := GetSmallIconFromExecutableFile(lpDummy.Name);
        except
          lpDummy.Icon := nil;
        end;
      sVersion := getVersionasString(Name);
      Name := ExtractFileName(Name);
      Title := {Kind}job + ' launch';
      Used := 0;
    end;

    Add(lpDummy);
    sgGrid.RowCount := count + 1;
    slLog.add(lpDummy.Name + ' skrackers');
    ///UpdateSG(lpDummy, ii + 1);
  end;
end;

procedure TptrWins.&With(a, b, c: Integer);
begin
  c := a + b;
end;

procedure TptrWins.AddNewExe(const aHndl: HWnd; const aClassName, aTitle, aHour: string; InFront: Boolean);
var
  lpWin: ptrWin;
  PID: DWord;
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
  //SL.Add(lpWin.Name);
  //lpWin.Job := 'R';
  lpWin.sVersion := getVersionasString(lpWin.Name);
  lpWin.Name := ExtractFileName(lpWin.Name);
  lpWin.Handle := aHndl;
  lpWin.AcculmTick := 0;
  lpWin.MarkTick := GetTickCount64;
  lpWin.Used := 1;
  lpWin.Title := aTitle;
  lpWin.ClassName := aClassName;
  GetWindowThreadProcessId(aHndl, PID);
  lpWin.Hours := PID.ToString;
  if aClassName = 'Shell_TrayWnd'
      then begin
            lpWin.Title := cTB;   { TODO -oPat : add to title check too
                                          when loses focus title change to hide}
            lpWin.Name := 'Taskbar';
            //lpWin.Kind := 'T';
            //GetSpecialNeedW(lpWin);
            lpWin.Task := GetSpecialNeedX;//   //getSpecialNeedB;//SetTaskBarTitle;
          end
      else
        lpWin.Task := nil;
  // UX was updated here now the index of changed item in Winlist is noted and the
  //SG
  if InFront then
  begin
    Insert(0, lpWin);
    lpWin.Job := 'I'
  end
  else
  begin
    Add(lpWin);
    lpWin.Job := 'W';
  end;
  SBSubject := lpWin.Name + ' running.';
  slLog.add(aHour + ' '  + lpWin.Name + ' ' +
    aTitle + ' skracking.');//lpWin.AcculmTick.ToString);
  sgGrid.RowCount := count + 1;
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

procedure TptrWins.CheckForeGroundWindows(const inHandle: Hwnd);
const
  max_size = 255;//255 * 4;
var
  awn: HWnd;
  sHour: string;
  Title, ClassName: Array [0..max_size] Of char;
  sClassName: string;
  ii: Integer;
  lpWin: ptrWin;
  InsertWin: Boolean;
begin

  If inHandle > UnknownHandle then
      awn  := inHandle
  else
      awn  := GetForegroundWindow;

  if awn = 0 then
    SBSubject := 'Not a foreground window'
  else if awn <> focusedWin.Handle then
    Try
      cacheWin.Handle := awn;
      GetClassName(awn, ClassName, max_size);
      GetWindowText(awn, Title, max_size);
      cacheWin.Title := Title;
      sHour := Format (hour2dot3, [24 * Time]);
      sClassName := Trim(ClassName);

      InsertWin := IndexText(sClassName, DesiredExes) >= 0;

      // Xoring cool for seperate lists
      //if bEverything xor InsertWin
      if bEverything or InsertWin
        then begin
          for ii := 0 to Count - 1 do
              if awn = Items[ii].Handle then
                begin
                  lpWin := items[ii];
                  lpWin.Title := Title;
                  Inc(lpWin.Used);
                  //updateSG (lpWin, ii + 1);
                  slLog.Append(sHour + ' ' + lpWin.Name + ' ' + Title + ' skrack.');
                  SBsubject := lpWin.Name + ' focused.';
                  focusedWin := lpWin;
                  focusedWin.MarkTick := GetTickCount64;
                  SB.Caption := sHour + ' ' + SBSubject;// + ' ' + copy(SB.Caption,8,length(SB.Caption));
                  sgGrid.Row := ii + 1;
                  Exit
                end;
            AddNewExe(awn, classname, Title, sHour, InsertWin);
        end
      else
        // mention the focused window not listed
        SB.Caption := ClassName + ' active';

    Except
      On E: Exception Do
      begin
        SBSubject := (E.ClassName + ': ' + E.Message); // begin
      end
      else
        SBsubject := 'Other error Timer stopped';
      WinTimer.Enabled := False;
    End;
end;

procedure TptrWins.GetSomeWindows(Sender: TObject);//(WantedWins: TArray<string>);
//var
//  i,j: NativeInt; //U gone
begin
  {$IFDEF CPU32BITS}
      EnumWindows(@EnumWindowsProc32, LParam(@Handles));
  {$ELSE}
      EnumWindows(@EnumWindowsCallback64, LParam(Handles));
  {$ENDIF}

  sgGrid.BeginUpdate;
  for var W in Handles do
    CheckForeGroundWindows(W);
  sgGrid.EndUpdate;

end;

function TptrWins.GetSpecialNeed(Need: Variant): Variant;
begin
  //Result := Need * Need;
end;

function TptrWins.GetSpecialNeedB: Boolean;
begin
  focusedWin.Title := 'Special Need 2';
  Result := True;
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
                               //  Uwe's
    if inWinName = '' then    //   /
      GetProductVersion(GetModuleName(focusedWin.Handle), major, minor, build)
    else
      GetProductVersion(inWinName, Major, Minor, Build);

    begin
      SBSubject := inWinName;
      Result := Format('%d.%d.%d', [Major, Minor, Build]);
    end;
  Except
    on E: Exception do
      Result := E.ClassName + ':' + E.Message
  End;
end;

procedure TptrWins.KeepItemsCurrent;
var
  TestItem: ptrWin;
  sRemoved: string;
  i: Integer;
  Keep: Boolean;
begin
  TestItem := nil;
  try
    for i := Count - 1 downto 0 do
    begin
      TestItem := List[i];
      if TestItem.Job = 'A' then Continue;

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
          UpdateFocusedWin(i + 1);
        end;
    end;
    if SRemoved <> '' then
      begin
        //var X: Integer := GetSpecialNeed(2*2);
        sRemoved := Format(hour2dot3,[Time*24]) + sRemoved + { culled/closed?}' Skracked';// + X.ToString;
        SBSubject := sRemoved;
        slLog.Add(sRemoved);
        sgGrid.Invalidate;
      end;
  except
    On E: Exception do if assigned(TestItem) then
        slLog.Append(TestItem.Name + ' ' + E.ClassName + ': ' + E.Message); // begin
  end;
end;

procedure TptrWins.Pulse(Sender: TObject);
begin
  WinTimer.Enabled := False;
  if Counter > 2 then
    begin
      Counter := 0;
      var Tick := GetTickCount64;
      DeltaTicks := Tick - PastTick;
      PastTick := Tick;
      KeepItemsCurrent;
    end
  else
    CheckForeGroundWindows(UnknownHandle);

  Inc(Counter);
  WinTimer.Enabled := True;
end;

procedure TptrWins.SetTaskBarTitle;
begin
//if focusedWin.ClassName = 'Shell' then
  focusedWin.Title := 'TB skrack assist';
end;

procedure TptrWins.SGdrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
var
  bgColor: TColor;
  Kind: 'A'..'Z';
begin
  if ARow = 0 then
    Kind := 'Z'
  else
    Kind := Items[ARow - 1].Job;
  begin
    case Kind of
      'A':
        bgColor := clWebLightSkyBlue;//clWebCornFlowerBlue;
      'I':
        bgColor := clcream;
      'W':
        bgColor := clWebCornSilk;
      'Z':
        bgColor := clAqua;
      else
        bgColor := clRed;
    end;
    var Cnvs :=  TStringGrid(Sender).Canvas;
    Cnvs.Brush.Color := bgColor;
    Cnvs.FillRect(Rect);
    if ARow = 0 then
      Cnvs.TextOut(Rect.Left+5, Rect.Top+3, WinHeader[ACol])
    else
    begin
      var Win := Items[ARow - 1];
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
////             procedure TForm1.DBGrid1DrawColumnCell(Sender: TObject; const Rect: TRect;
//            // DataCol: Integer;      Column: TColumn; State: TGridDrawState);
//            // const
//            // CtrlState: array[Boolean] of integer = (DFCS_BUTTONCHECK, DFCS_BUTTONCHECK or DFCS_CHECKED) ;
//            // begin
//            // if (Column.Field.DataType=ftBoolean) then
//            // begin
//            // DBGrid1.Canvas.FillRect(Rect) ;
//            // if (VarIsNull(Column.Field.Value)) then
//
//            // DrawFrameControl(DBGrid1.Canvas.Handle,Rect, DFC_BUTTON, DFCS_BUTTONCHECK or DFCS_INACTIVE)
//            if Win.Used < 2 then
//
//              DrawFrameControl(Cnvs.Handle, Rect, DFC_BUTTON,
//                DFCS_BUTTONCHECK or DFCS_INACTIVE)
//
//            else
//              DrawFrameControl(Cnvs.Handle, Rect, DFC_BUTTON, DFCS_CHECKED);
//            // CtrlState[Column.Field.AsBoolean]);
//            // end
//            // else
//            // DBGrid1.DefaultDrawColumnCell?(Rect, DataCol, Column, State);
//            // end;
            Cnvs.TextOut(Rect.Left + 43, Rect.Top + 2, Win.Used.ToString);
          end;
        4:
          Cnvs.TextOut(Rect.Left + 2, Rect.Top + 2,
            Win.hours);
        5:
          Cnvs.TextOut(Rect.Left + 2, Rect.Top + 2,
            Win.sVersion);
      end;
    end;
  end;
end;

procedure TptrWins.sgViewWinClick(Sender: Tobject);
begin
  var Idx :=  sgGrid.Selection.Top - 1;

  if (Idx > -1) and (List[Idx].Job = 'I') then
  WinActivate (List[Idx].Handle);
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
            GetSomeWindows(nil);
        skSave:
          begin
            WinTimer.Enabled := False;
            { TODO : Add force directory or leave off free version }
            var DayNu:=DayOfTheYear(Date);
            var YearNu := YearOf(Date);
            var FileName := Format ('%s %D day%4d%s', ['C:\_tickers\machinelog',YearNu,DayNu, '.log']);
            //var logFile := TFile.Create(FileName,fmOpenWrite);
            Tfile.AppendAllText(FileName, slLog.Text);
            //slLog.SaveToFile(''   //todo use truncate(1/1/present year) some how
            //+
          end;
      end;
      //Instructions := Instructions - [Step];
      //Exclude(Instructions,Step);
    end;
  if not WinTimer.Enabled then SB.Caption := 'SK Stopped use RunStop to restart.';
end;

procedure TptrWins.UpdateFocusedWin(const inRow: Integer);
var
  Title: Array [0 .. 255] Of char;
  S, sErr, sMeg, sTitle: string;
begin
  //increment Hours and run a task on the focused Win
  with focusedWin^ do
    begin
      Inc(AcculmTick, DeltaTicks);
      //sgGrid.Cells[4, inRow] := Format('%3.4f', [AcculmTick / 3600_000]);
      Hours := Format('%3.4f', [AcculmTick / 3600_000]);
//      sgGrid.Invalidate;  do in UI
//      if sametext(focusedWin.ClassName,'Shell_TrayWnd')
      if assigned(Task) then
        begin
          Task(FocusedWin);
          Exit;
        end;
    end;


  GetWindowText(focusedWin.Handle, Title, 255);
  sTitle := Trim(Title);
  if focusedWin.Title <> sTitle then
      begin
        focusedWin.Title := sTitle;
        S := Format(hour2dot3wS, [24 * Time,focusedWin.Name + ' ' + sTitle]);
        slLog.Add(S);
        SB.Caption := S;
      end;

  sErr := SysErrorMessage(GetLastError);
  if not(PosEX('success', sErr, 1) > 0)
    then begin
      if sErr = LastErrMessage then
        begin
          Exit;
//          Inc(SameErrCount);
//          sMeg := Format('hr %2.3f %s err:%s %d', [24 * Time, focusedWin.ClassName,
//            sErr, SameErrCount]);
//          slLog[slLog.Count - 1] := sMeg;
        end
      else
        begin
          sMeg := Format('hr %2.3f %s err:%s',
            [24 * Time, focusedWin.ClassName, sErr]);
          slLog.add(sMeg);
          SameErrCount := 1;
          LastErrMessage := sErr;
        end;
    end;
end;

end.
