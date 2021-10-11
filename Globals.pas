unit Globals;
           //sourceforge.net/projects/dclx
interface

uses Classes, SysUtils, Windows, Messages, Guide, RulersWnd;

var
  isControl: boolean;
  running: boolean;
  mainWnd: TRulersWnd;

  sizeHCursor, sizeVCursor: HCURSOR;

  displayMode: integer;
  

procedure Init;

procedure Run;

procedure AddGuide(g: TGuide);

procedure RemoveGuide(g: TGuide);

procedure RemoveAllGuides();

procedure BringToFrontAll();

procedure DumpGuides(list: TStringList);

function GetDistance(g: TGuide): integer;

procedure NotifyAll();

implementation

uses AlphaWnd;

type
  KBDLLHOOKSTRUCT = record
    vkCode: DWORD;
    scanCode: DWORD;
    flags: DWORD;
    time: DWORD;
    dwExtraInfo: LongWord;
  end;
  LPKBDLLHOOKSTRUCT = ^KBDLLHOOKSTRUCT;

  TGuideArray = array of TGuide;
  PGuideArray = ^TGuideArray;

const
  WH_KEYBOARD_LL  = 13;

var
  HOOK: HHOOK;
  vGuides, hGuides: TGuideArray;

procedure AddGuide(g: TGuide);
var
  i: integer;
  l: PGuideArray;
begin
  if g.Vertical then
    l:=@vGuides
  else
    l:=@hGuides;
  i:=Length(l^);
  SetLength(l^, i + 1);
  l^[i]:=g;
  g.Show();
end;

procedure doRemoveGuide(g: TGuide; allGuides: PGuideArray);
var
  i, c: integer;
begin
  for i:=0 to Length(allGuides^) - 1 do begin
    if allGuides^[i] = g then begin
      c := Length(allGuides^) - 1;
      allGuides^[i] := allGuides^[c];
      SetLength(allGuides^, c);
      g.Hide;
      g.Free();
    end;
  end;
end;

procedure RemoveGuide(g: TGuide);
begin
  if g.Vertical then
    doRemoveGuide(g, @vGuides)
  else
    doRemoveGuide(g, @hGuides);
end;

procedure RemoveAllGuides();
var
  i: integer;
begin
  for i:=0 to Length(vGuides) - 1 do begin
    vGuides[i].Hide;
    vGuides[i].Free();
  end;
  SetLength(vGuides, 0);
  for i:=0 to Length(hGuides) - 1 do begin
    hGuides[i].Hide;
    hGuides[i].Free();
  end;
  SetLength(hGuides, 0);
end;

procedure DumpGuides(list: TStringList);
var
  i: integer;
begin
  for i := 0 to Length(hGuides) - 1 do
    list.Add('H' + IntToStr(i) + '=' + IntToStr(hGuides[i].Top));
  for i := 0 to Length(vGuides) - 1 do
    list.Add('V' + IntToStr(i) + '=' + IntToStr(vGuides[i].Left));
end;

function GetDistance(g: TGuide): integer;
var
  i: integer;
  l: PGuideArray;
begin
  Result:=-2;
  if g.Vertical then begin
    l:=@vGuides;
    for i:=0 to Length(l^) - 1 do
      if (l^[i].Left < g.Left) and (l^[i].Left > Result) then
        Result:=l^[i].Left;
  end else begin
    l:=@hGuides;
    for i:=0 to Length(l^) - 1 do
      if (l^[i].Top < g.Top) and (l^[i].Top > Result) then
        Result:=l^[i].Top;
  end;
end;

procedure BringToFrontAll();
var
  i: integer;
begin
  for i:=0 to Length(vGuides) - 1 do
    SetForegroundWindow(vGuides[i].Handle);
  for i:=0 to Length(hGuides) - 1 do
    SetForegroundWindow(hGuides[i].Handle);
  SetForegroundWindow(mainWnd.Handle);
  {SetWindowPos(mainWnd.Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or
    SWP_NOSIZE or SWP_NOACTIVATE);  }
end;

procedure NotifyAll();
var
  i: integer;
begin
  for i:=0 to Length(vGuides) - 1 do
      vGuides[i].Notify();
  for i:=0 to Length(hGuides) - 1 do
      hGuides[i].Notify();
end;

// Keyboard Hook
function LowLevelKeyboardProc(nCode: integer; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
var
  pkb: LPKBDLLHOOKSTRUCT;
  i: integer;
begin
try
  pkb:=LPKBDLLHOOKSTRUCT(lParam);
  if pkb.vkCode = 162 then
    if isControl <> (wParam = WM_KEYDOWN) then begin
       isControl:= wParam = WM_KEYDOWN;  //WM_SYSKEYDOWN
       NotifyAll();
       //MessageBox(0, PChar(BoolToStr(isControl, true)), nil, 0);
    end;
  Result:=CallNextHookEx(HOOK, nCode, wParam, lParam);
except
  Result:=CallNextHookEx(HOOK, nCode, wParam, lParam);
  MessageBeep(MB_ICONSTOP);
  end;
end;

function ProcessMessage: boolean;
var
  AMessage: TMsg;
begin
  Result:=False;
  if PeekMessage(AMessage, 0, 0, 0, PM_REMOVE) then
  begin
    if AMessage.Message <> WM_QUIT then
    begin
      TranslateMessage(AMessage);
      DispatchMessage(AMessage);
    end else running:=False;
    Result:=True;
  end;
end;

procedure Init;
begin
  sizeHCursor:=LoadCursor(HInstance, 'SIZEH');
  sizeVCursor:=LoadCursor(HInstance, 'SIZEV');
  isControl:=false;
  HOOK:=SetWindowsHookEx(WH_KEYBOARD_LL, @LowLevelKeyboardProc,
    hinstance, 0);
  running:=true;
  mainWnd:=TRulersWnd.Create();
  mainWnd.Show();
end;

procedure Run;
begin
  while running do if not ProcessMessage then WaitMessage;
  if HOOK <> 0 then UnhookWindowsHookEx(HOOK);
  mainWnd.Free();
end;

end. 

