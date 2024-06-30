unit AppList;

interface
uses
  Classes, Menus, Winapi.Windows, System.Generics.Collections, Vcl.Grids,
  Vcl.Controls, Vcl.StdCtrls, Vcl.CheckLst, StrUtils, Graphics, ExtCtrls;
const
  hour2dot3 ='hr %2.3f ';
  //hour2dot3wS ='hr %2.3f %s';

  selfClass = 'TDesksKick';
  //Not necessary bds shows it in 64 and tailwind on simple apps
  //TAppClass = 'TApplication';
   {TAppClass,'TfmGrepResult','TfmPeInformation',}
  GoodApps: Tarray<string> = ['Shell_TrayWnd','Notepad++', 'TAppBuilder', 'Window',
   'Chrome_WidgetWin_1','Notepad','CabinetWClass',selfClass ];

  GoodStates: TArray<string> = ['skStartPoint','skRun','skStop','skShowchkLB', 'skEverything', 'skSave', 'skEndPoint'];

type              // 0        1     2        3            4           5       6
  TskState = (skStartPoint,skRun,skStop,skShowchkLB, skEverthing, skSave, skEndPoint);
  TAppHandles = Tlist<NativeUInt>;

  ptrApp = ^TApp;
  TApp = record
    Handle: HWnd;
    ClassName: string;
    Name: string;
    sVersion: string;
    Title: string;
//    sgRow: Integer;
    Used,
    MarkTick,
    AcculmTick : Uint64;
    Icon: TIcon;
  end;

  TptrApps = class(Tlist<ptrApp>)
  private
    AppTimer: TTimer;
    bEverything: Boolean;
    ChBxs: TCheckListBox;

    DesiredExes: TArray<string>;
//    AppBuilderCount: Integer;   used if want First started last out
//    popup: TPopupMenu;
//    IconList: TImageList;
    Handles: TAppHandles;
    SB: TPanel;
    SBSubject: string;

    procedure SGdrawCell(Sender: TObject; ACol, ARow: Integer;
                                    Rect: TRect; State: TGridDrawState);
  public
    sgGrid: TStringGrid;
    slLog: TStrings;
    procedure AddNewExe(aSG: TStringGrid; const aHndl: Hwnd; const aClassName, aTitle, aHour: string);
    procedure ChangeExesList(Sender: TObject);
    procedure ChangeState(Sender: TObject);
    destructor Destroy; override;
    procedure RemoveStaleItems;
    procedure CheckForeGroundWindows(const inHandle: Hwnd);
    procedure CheckforActiveAppTitleChange(const ARow: Integer);
    function getVersionasString(inAppName: string): string;

class function HookInUI(inSG: TStringGrid; inLog: TStrings; inChBxs: TcheckListBox; inBanner: TPanel; const bAll: Boolean): TptrApps;
//class procedure OpenLocalFile(Path, Params: String);
    procedure GetSomeWindows(Sender: TObject);//(WantedApps: TArray<string>);
    procedure Pulse(Sender: TObject);
    procedure sgViewAppClick(Sender: Tobject);
    procedure updateSG(inTool: ptrApp; inRow: Integer); //overload;
//    procedure UpdateSG(inTool: ptrApp); overload;
  end;

implementation

uses
  System.SysUtils, Winapi.Messages, Winapi.PsAPI, ShellAPI, WinApi.ShlObj;
var
  //allocate mem for last focusedApp ptr to let lastapp row to be set at start         for hour meters to work and reduced overwrites
  // cacheApp updates when the active or focused window changes
  cacheApp : TApp;

  focusedApp: ptrApp;

function AppActivate(WindowHandle: HWND): boolean;// overload;
begin
   try
      SendMessage(WindowHandle, WM_SYSCOMMAND, SC_HOTKEY, WindowHandle);
      SendMessage(WindowHandle, WM_SYSCOMMAND, SC_ARRANGE, WindowHandle);
      result := SetForegroundWindow(WindowHandle);
   except
      on Exception do Result := false;
   end;
end;


  type
    PHICON = ^HICON;

  function ExtractIconEx(lpszFile: LPCWSTR; nIconIndex: Integer;
    phiconLarge, phiconSmall: PHICON; nIcons: UINT): UINT; stdcall; external 'shell32.dll' name 'ExtractIconExW';

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
      0,   //was 0
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

{ TptrApps }

procedure TptrApps.AddNewExe(aSG: TStringGrid; const aHndl: HWnd; const aClassName, aTitle, aHour: string);
var
  lpApp: ptrApp;
begin
  New(lpApp);
  Add(lpApp);
  lpApp.Name := GetWindowExeName(aHndl);
  lpApp.Icon := nil;
  if lpApp.Name <> '' then
    try
      lpApp.Icon := GetSmallIconFromExecutableFile(lpApp.Name);
    except
      lpApp.Icon := nil;
    end;

  lpApp.sVersion := getVersionasString(lpApp.Name);
  lpApp.Name := ExtractFileName(lpApp.Name);
//  if lpApp.Icon <> nil then
//
//  lpApp.icon.SaveToFile(lpApp.Name + '.bmp');

  lpApp.Handle := aHndl;
  lpApp.AcculmTick := 0;
  lpApp.MarkTick := GetTickCount64;
  lpApp.Used := 1;
  lpApp.Title := aTitle;
//  lpApp.sg := aSG;
  //lpApp.sgRow := Count;//aSG.RowCount;
  lpApp.ClassName := aClassName;
  if aClassName = 'Shell_TrayWnd'
     then begin
            lpApp.Title := 'Show';   { TODO -oPat : add to title check too }
            lpApp.Name := 'Taskbar';
          end;
  // UX here
  updateSG(lpApp, Count);
  SBSubject := lpApp.Name + ' running.';
  slLog.add(aHour + ' '  + lpApp.Name + ' ' +
    aTitle  + ' ' + ' added.');//lpApp.AcculmTick.ToString);
end;

procedure TptrApps.ChangeExesList(Sender: TObject);
var
  ChkLB: TCheckListBox;
  de: Integer;
  I: Integer;
begin
  de := 0;
  ChkLB := Sender as TCheckListBox;
  setlength(DesiredExes, ChkLB.Items.Count);
  for I := 0 to ChkLB.Items.Count - 1 do
    if ChkLB.Checked[I] then  //
      begin
        DesiredExes[de] := ChkLB.Items[I];
        Inc(de);
      end;

  SetLength(DesiredExes, de);
end;

procedure TptrApps.CheckForeGroundWindows(const inHandle: Hwnd);
const
  max_size = 255;//255 * 4;
var
  awn: HWnd;
  sHour: string;
  Title, ClassName: Array [0..max_size] Of char;
  sClassName: string;
  ii: Integer;
  lpApp: ptrApp;
  ChosenApp: Boolean;
  //targetSG: TStringGrid;
begin

  If inHandle > 0 then
      awn  := inHandle
  else
      awn  := GetForegroundWindow;

  if awn = 0 then
    SBSubject := 'Not a foreground window'
  else if awn <> focusedApp.Handle then
    Try
      cacheApp.Handle := awn;
      GetClassName(awn, ClassName, max_size);
      GetWindowText(awn, Title, max_size);
      cacheApp.Title := Title;
      sHour := Format (hour2dot3, [24 * Time]);
      sClassName := Trim(ClassName);

      chosenApp := IndexText(sClassName, DesiredExes) >= 0;

//      if (bEverything and not ChosenApp)
//      or (chosenApp and not bEverything)
      if bEverything xor chosenApp
      then
        begin
          for ii := 0 to Count - 1 do
            if awn = Items[ii].Handle then
              begin
                lpApp := items[ii];
                lpApp.Title := Title;
                Inc(lpApp.Used);
                updateSG (lpApp, ii + 1);
                slLog.Append(sHour + ' ' + Title);
                SBsubject := lpApp.Name + ' focused.';
                focusedApp := lpApp;
                focusedApp.MarkTick := GetTickCount64;
                SB.Caption := sHour + ' ' + SBSubject;// + ' ' + copy(SB.Caption,8,length(SB.Caption));
                Exit
              end;
          AddNewExe(nil, awn, classname, Title, sHour);
        end;
    Except
      On E: Exception Do
      begin
        SBSubject := (E.ClassName + ': ' + E.Message); // begin
      end
      else
        SBsubject := 'Other error';
        AppTimer.Enabled := False;
    End;
end;

procedure TptrApps.ChangeState(Sender: TObject);
begin
    var
      Tag := TControl(Sender).Tag;
    Case Tag of
      1:
        AppTimer.Enabled := True;
      2:
        AppTimer.Enabled := False;
      3:
        begin
          bEverything := not bEverything;
          ChBxs.Visible := bEverything;
          if ChBxs.Showing then ChBxs.BringToFront;
        end;
      4:
        GetSomeWindows(Sender);
      5:
        begin
          AppTimer.Enabled := False;
          { TODO : Add force directory or leave off free version }
          slLog.SaveToFile('C:\_tickers\machinelog'   //todo use truncate(1/1/present year) some how
          + Format ('023.Dy%d.hr%2.3f%s', [Trunc(Date - 44926 + 365), 24 * Time, '.log']));
        end;
    end;
end;

procedure TptrApps.CheckforActiveAppTitleChange(const ARow: Integer);
var
  Title: Array [0 .. 255] Of char;
  S, sTitle: string;
  AppTotalHrTicks: Integer;

begin
  //increment Hours ran on the running App
  if not isWindow(focusedApp.Handle) then begin sllog.add('Trapped');exit; end;

  with focusedApp^ do begin
     AppTotalHrTicks := AcculmTick + GetTickCount64 - MarkTick;
     sgGrid.Cells[4, ARow] := Format('%1.5f', [AppTotalHrTicks / 3600_000]);
     if title = '' then begin
      sgGrid.Cells[1, ARow] := 'Not showing ' + Name;
      if IsWindowVisible(Handle) then sgGrid.Cells[1, ARow] := 'Showing ' + Name;
      exit
     end;
  end;
  begin
    GetWindowText(focusedApp.Handle, Title, 255);
    sTitle := Trim(Title);
    if focusedApp.Title <> sTitle then
      begin
        focusedApp.Title := sTitle;
        S := Format('hr %2.5f %s', [24 * Time, sTitle]);
        slLog.Add(S);
        //SB.Caption := S; //SBSubject
      end;
  end
end;

{ TODO -oPat :    Add logic to check done
   if the running programs are on the list when self is started or
   when a everthing is selected the self doesn't needed so
   uncheck or leave off list. 3/4 done

   save hourage icon and paths of desiredApps in DB
   }
destructor TptrApps.Destroy;
begin
  AppTimer.Enabled := False;
  Apptimer.Free;
  Handles.Free;
  for var App: ptrApp in list do
    if Assigned(App)  then
       begin
         if App.Icon <> nil then
           App.Icon.Free;
         Dispose(App);
       end;
  inherited;
end;

var lastWindowName:string = '';
function EnumWindowsCallBack64(Handle: hWnd; Hs:TAppHandles): BOOL; stdcall;
const
  C_FileNameLength = 256;
var
  WinFileName: string;
  PID, hProcess: DWORD;
  Len: Byte;
  style: DWORD;
  testS: string;
begin
  //Hides warning
//  Result := False;
  SetLength(WinFileName, C_FileNameLength);
  GetWindowThreadProcessId(Handle, PID);
  hProcess := OpenProcess(PROCESS_ALL_ACCESS, false, PID);
  style := GetWindowLongPtr(Handle, GWL_STYLE);
  if (style and WS_VISIBLE <> 0) then
  begin
    Len := GetModuleFileNameEx(hProcess, 0, PChar(WinFileName),
      C_FileNameLength);
    if Len > 0 then
    begin
      setlength(WinFileName, Len);
      testS := copy(WinfileName, len - 10, 10);
      if testS <> lastWindowName
        then begin
          lastWindowName := testS;
          Hs.add(handle);
        end;
    end;
  end;
  Result := True;
end;

function EnumWindowsProc32(wHandle: HWND; var Hs:TAppHandles): BOOL; stdcall;
begin
  if IsWindowVisible(wHandle) then
    Hs.Add(wHandle);
  Result := True;
end;

procedure TptrApps.GetSomeWindows(Sender: TObject);//(WantedApps: TArray<string>);
var
  i,j: NativeUInt;
begin
  {$IFDEF CPU32BITS}
      EnumWindows(@EnumWindowsProc32, LParam(@Handles));
  {$ELSE}
      EnumWindows(@EnumWindowsCallback64, LParam(Handles));
  {$ENDIF}

  with Handles do
  begin
    for  i := 0 to Count - 1 do
      for  j := Count - 1 downto i + 1 do
        if Items[j] = Items[i] then
            Remove(Items[j]);
  end;

  sgGrid.BeginUpdate;
  for var X := 0 to Handles.Count - 1 do
  CheckForeGroundWindows(Handles[X]);
  sgGrid.EndUpdate;
  // why not work DesiredExes := DesiredExes - [selfClass];
//  setLength(DesiredExes,Length(DesiredExes) - 1);
end;

function TptrApps.getVersionasString(inAppName: string): string;
var
  Major, Minor, Build: Cardinal;
begin
  Try
    Result := 'NA';
    if inAppName = '' then
      exit;

//      if GetProductVersion(GetModuleName(HInstance), major, minor, build) then begin
                             //   ^ Uwe's
    if GetProductVersion(inAppName, Major, Minor, Build) then
    begin
      SBSubject := inAppName;
      Result := Format('%d.%d.%d', [Major, Minor, Build]);
    end;
  Except
    on E: Exception do
      Result := E.ClassName + ':' + E.Message
      // else
      // Result := 'AbbyNormal Error';   //seen DP for use on other exceptions
  End;
end;

class function TptrApps.HookInUI(inSG: TStringGrid; inLog: TStrings; inChBxs: TcheckListBox;
     inBanner: TPanel; const bAll: Boolean): TptrApps;
begin
  //cacheApp.sgRow := 1;
  cacheApp.AcculmTick := GetTickCount64;
  focusedApp := @cacheApp;

  var R := TptrApps.Create;
  R.ChBxs := inChBxs;
  R.ChBxs.OnClick := R.changeExesList;
  R.ChBxs.Items.Clear;
  R.bEveryThing := bAll;
  R.Handles := TappHandles.Create;
  for var I := Low(goodApps) to High(goodApps) do
    begin
      R.ChBxs.Items.add(goodApps[I]);
      R.ChBxs.Checked[I] := True;
       { TODO -oPat :    +1 was needed to hard switch the Everything switch may
        add a freeze or snapshoot or pause to get more windows }
    end;
  R.changeExesList(R.ChBxs); //Checked adds items to desiredExes boo-->  pre-use or prime the Exelist with update procedure
  R.SB := inBanner;
  R.SBSubject := 'Initiated';
  R.slLog := inLog;
  R.sgGrid := inSG;
//  R.sgFish := inSG2;// add comment todo
//  R.sgFish.OnDrawCell := R.SGdrawCell;
  R.sgGrid.OnClick := R.sgViewAppClick;
  R.sgGrid.OnEnter := R.sgViewAppClick;
  R.sgGrid.OnDrawCell := R.SGdrawCell;
  R.sgGrid.Rows[0].CommaText := 'Name, Title, Class, Used, Hours, Version';
  R.sgGrid.ColWidths[0] := 180;
  R.sgGrid.ColWidths[1] := 236;
  R.sgGrid.ColWidths[2] := 160;
  R.sgGrid.ColWidths[3] :=  60;
  R.sgGrid.ColWidths[4] :=  90;

//  R.bAllWindows := False;
//  R.phState:= 'Starting';
  R.AppTimer := TTimer.Create(nil);
  R.appTimer.OnTimer := R.Pulse;
  R.AppTimer.Interval := 600;
  R.appTimer.Enabled := True;
  Result := R;
end;

var Counter: Integer = 0;
//var CacheLine: string;
procedure TptrApps.Pulse(Sender: TObject);
begin
  AppTimer.Enabled := False;
  if Counter > 5 then
    begin
      Counter := 0;
      RemoveStaleItems;
      // CheckforActiveAppTitleChange;
    end
  else
    CheckForeGroundWindows(0);

  Inc(Counter);
  AppTimer.Enabled := True;

  //old Combobox was using text and insert[0]here.
  //slLog.Strings[sllog.Count -1] := sHour + ' - ' + SB.Caption;//     ptrS^;
  //if sameText(CacheLine,SbSubject) then exit;
  //Need a focused flag
//  SB.Caption := sHour + ' ' + SBSubject;// + ' ' + copy(SB.Caption,8,length(SB.Caption));
  //cacheLine := SbSubject;
end;

Type
  TKrackSG = class (TcustomGrid)
end;

procedure TptrApps.RemoveStaleItems;
var
  isStaleQ: ptrApp;
  sRemoved: string;
  i: Integer;
  bWindow: Boolean;
begin
  isStaleQ := nil;
  try
    for i := Count - 1 downto 0 do
    begin
      isStaleQ := List[i];
      bWindow := IsWindow(isStaleQ.Handle);
      if not bWindow then
        begin
          TKrackSG(sgGrid).DeleteRow(i + 1);     //Remy
          sRemoved := sRemoved + isStaleQ.Name + ' ';
          isStaleQ.Icon.Free;
          Remove(isStaleQ);
          Dispose(isStaleQ);
        end
      else if IsStaleQ.Handle = focusedApp.Handle then
        begin
          CheckforActiveAppTitleChange(i + 1);
//          if not sametext(IsStaleQ.Title, focusedApp.Title) then

        end;
    end;
    if SRemoved <> '' then
      begin
        sRemoved := Format(hour2dot3,[Time*24]) + sRemoved + ' closed';
        SBSubject := sRemoved;
        slLog.Add(sRemoved);
      end;
  except
    On E: Exception do if assigned(isStaleQ) then
        slLog.Append(isStaleQ.Name + ' ' + E.ClassName + ': ' + E.Message); // begin
//    else
//        slLog.Append('Frittle Fraddle');
  end;
end;

procedure TptrApps.SGdrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect;
  State: TGridDrawState);
var
  SG1: TStringgrid;
begin
  if (ACol = 0) and (ARow > 0) then
  begin
    SG1 := TStringGrid(Sender);// as TStringGrid;
//    SG1.Canvas.Brush.Color := clWindowFrame;
//    SG1.Canvas.font.Color := clLime;
//
//    if focusedApp.sgRow = ARow
//      then SG1.Canvas.Brush.Color := clWindowText;
    SG1.Canvas.FillRect(Rect);
    if Count >= ARow then
      begin
        SG1.Canvas.TextRect(Rect,Items[Arow-1].Name,[tfRight]);  //tfCenter,
        SG1.Canvas.Draw(Rect.Left+3,Rect.Top+3, Items[Arow-1].Icon);
      end;
  end;
end;

procedure TptrApps.sgViewAppClick(Sender: Tobject);
begin
  var Idx :=  sgGrid.Selection.Top - 1;
  if Idx < Count then
  AppActivate (List[Idx].Handle);
end;

//procedure TptrApps.updateSG(inTool: ptrApp);
//var
//  lSG: TStringGrid;
//  i: Integer;
//begin
//  i := inTool.sgRow;
//  lSG := inTool.sg;
//  if i > lSG.RowCount then
//    lSG.RowCount := i;
//  lSG.Cells[1, i] := inTool.Title;
//  lSG.Cells[2, i] := inTool.ClassName;
//  lSG.Cells[0, i] := inTool.Name;
//  lSG.Cells[3, i] := inTool.Used.ToString;
//  lSG.Cells[5, i] := inTool.sVersion;
//
//end;

procedure TptrApps.updateSG(inTool: ptrApp; inRow: Integer);
begin
  if inRow > sgGrid.RowCount then
  sgGrid.RowCount := inRow + 1;
  var
    i := InRow;
  sgGrid.Cells[0, i] := inTool.Name;
  sgGrid.Cells[1, i] := inTool.Title;
  sgGrid.Cells[2, i] := inTool.ClassName;
  sgGrid.Cells[3, i] := inTool.Used.ToString;
  sgGrid.Cells[5, i] := inTool.sVersion;
end;

// additional UI for smaller jobs 16 put overlay on check group

//  R.popup := inPopup;
//  inPopUpParent.popupMenu := R.Popup;

//        for var m := popup.items.Count - 1 downto 0 do
//        begin
//          MItem := popup.items[m];
//          if MItem.Tag = isStaleQ.Handle then
//          begin
//            //if assigned(mItem.Bitmap) then MItem.Bitmap.Free;
//            MItem.Free;
//            // Freeandnil(mitem);
//            break;
//          end;
//        end;


//var AppBuilderCount: Integer = 0;
(***
procedure TptrApps.AddToolUpdateUI(inApp: ptrApp; aMenuItemClick: TnotifyEvent);
var
 // i: Integer;
  Icon: TIcon;
begin
  //if inApp.ClassName = 'TAppBuilder' then
  begin
    Inc(AppBuilderCount);
    inApp.MenuItem := TMenuItem.Create(popup);
//    inApp.menu.Caption := AppBuilderCount.ToString + '_Delphi' + ' ' +
//      inApp.sVersion;
    inApp.MenuItem.Caption := inApp.Name + ' ' + inApp.sVersion;
    inApp.MenuItem.Tag := inApp.Handle;
    inApp.MenuItem.OnClick := aMenuItemClick;
    popup.items.Add(inApp.MenuItem);
//    icon := GetSmallIconFromExecutableFile(inApp.Name);
//    inApp.MenuItem.Bitmap.Assign(icon);
//    IconList.Add(inApp.MenuItem.Bitmap,nil);
//    inApp.MenuItem.Bitmap.SaveToFile(ExtractFileName(inApp.Name)+'.Bmp');
  end;
end;
***)
(***
procedure TptrApps.appsMenuclick(Sender: TObject);
var
  Hndl: HWnd;
begin
  Hndl := (Sender as TMenuItem).Tag;
  AppActivate(Hndl);
end;
***)

end.
