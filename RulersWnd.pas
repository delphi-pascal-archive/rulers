unit RulersWnd;

{*******************************************************}
{                                                       }
{       On screen rulers                                }
{       Program main window (rulers)                    }
{                                                       }
{       Copyright (c) 2007, Anton A. Drachev            }
{                        anton@drachev.com              }
{                                                       }
{       Distributed "AS IS" under BSD-like license      }
{       Full text of license can be found in            }
{         "License.txt" file attached                   }
{                                                       }
{*******************************************************}

interface

uses
  Classes, GDIPAPI, GDIPOBJ, AlphaWnd, SysUtils, Windows, Messages, Guide,
  ShellApi;

type TRulersWnd = class(TAlphaWnd)
  private
    whitepen: TGPPen;
    nid: NotifyIconData;
    blackpen: TGPPen;
    g: TGuide;
  protected
    procedure OnCreate; override;
    function ProcessMsg(msg: PMess): boolean; override;
    procedure CreatNew();
  public
    constructor Create(); overload;
    destructor Destroy(); override;
  end;

implementation

uses Globals;

const
  FRAME_THICKNESS = 25;
  WM_TRAY = WM_USER + $01;

function min(a, b: smallint): smallint;
begin
  if a < b then Result:=a
  else Result:=b;
end;

const
  fontsize = 9;

{ TRulersWnd }

constructor TRulersWnd.Create();
var
  rect: TRect;
  brsh: TGPSolidBrush;
  tmp, i, j: integer;
  p: TPointF;
  s: string;
  Font: TGPFont;
  Graph: TGPGraphics;
begin
  Create(CS_DBLCLKS, WS_POPUP,
    WS_EX_TOOLWINDOW,
    0, 'Rulers Window', 'TRulersWndClass', Parent);

  GetWindowRect(GetDesktopWindow(), rect);
  Width:=rect.Right;
  Height:=rect.Bottom;
  Left:=0;
  Top:=0;

  Font:=TGPFont.Create('Arial', fontsize, FontStyleRegular, UnitPixel);

  Bitmap:=TGPBitmap.Create(Width, Height, $26200A); // Magic number ;)
  Graph:=TGPGraphics.Create(Bitmap);
  Graph.SetTextRenderingHint(TextRenderingHintSystemDefault);

  brsh:=TGPSolidBrush.Create(MakeColor(255,255,255));
  blackpen:=TGPPen.Create(TGPSolidBrush.Create(MakeColor(0,0,0)));
  whitepen:=TGPPen.Create(TGPSolidBrush.Create(MakeColor(255, 255, 255)));

  Graph.Clear(0);
  Graph.FillRectangle(brsh, 0, 0, 15, Height);
  Graph.FillRectangle(brsh, 0, 0, Width, 15);
  Graph.DrawLine(blackpen, 15, 16, 15, Height);
  Graph.DrawLine(blackpen, 16, 15, Width, 15);

  brsh:=TGPSolidBrush.Create(MakeColor(0, 0, 0));

  p.X:=0;
  for i := 0 to Round(Height / 50) do begin
    tmp:=i * 50;
    s:=IntToStr(i * 50);
    for j := 1 to Length(s) do begin
      p.Y:=tmp + j * fontsize - 8;
      Graph.DrawString(s[j], -1, Font, p, brsh);
    end;
    Graph.DrawLine(blackpen, 0, tmp, 15, tmp);
  end;

  for i := 0 to Round(Height / 5) do begin
    tmp:=i * 5;
    if i mod 2 = 1 then
       p.X:=11
    else
       p.X:=9;
    Graph.DrawLine(blackpen, p.X, tmp, 15, tmp);
  end;

  p.Y:=0;
  for i := 0 to Round(Width / 50) do begin
    tmp:=i * 50;
    p.X:=tmp;
    Graph.DrawLine(blackpen, tmp, 0, tmp, 15);
    Graph.DrawString(IntToStr(i * 50), -1, Font, p, brsh);
  end;

  for i := 0 to Round(Width / 5) do begin
    tmp:=i * 5;
    if i mod 2 = 1 then
       p.Y:=11
    else
       p.Y:=9;
    Graph.DrawLine(blackpen, tmp, p.Y, tmp, 15);
  end;

  Graph.FillRectangle(TGPSolidBrush.Create(MakeColor(255, 255, 255)), 0, 0, 16, 16);

  g:=nil;

  Graph.Free();

  Redraw();
  Invalidate();

  fillchar(nid, Sizeof(nid), 0);
  nid.cbSize:=Sizeof(nid);
  nid.Wnd:=Handle;
  nid.hIcon:=Loadicon(HInstance, 'MAINICON');
  nid.uFlags:=NIF_ICON or NIF_TIP or NIF_MESSAGE;
  nid.szTip:='Rulers';
  nid.uCallbackMessage:=WM_TRAY;
  Shell_NotifyIcon(NIM_ADD, @nid);
  Bitmap:=nil;
end;

procedure TRulersWnd.OnCreate;
begin
  inherited;
end;


procedure TRulersWnd.CreatNew;
var
  p: TPoint;
begin
  GetCursorPos(p);
  if (p.X < 20) and (p.Y > 18) then begin
    SetCursor(sizeHCursor);
    g:=TGuide.Create(true, Height);
    g.Left:=p.X - 6;
  end else if (p.Y < 20) and (p.X > 18) then begin
    SetCursor(sizeVCursor);
    g:=TGuide.Create(false, Width);
    g.Top:=p.Y - 6;
  end else
    ;
end;

destructor TRulersWnd.Destroy;
begin
  Shell_NotifyIcon(NIM_DELETE, @nid);
end;

function TRulersWnd.ProcessMsg(msg: PMess): boolean;
begin
  Result:=True;
  case msg.Msg of
    WM_NCHITTEST: msg.Result:=HTCAPTION;
    WM_ENTERSIZEMOVE: begin
      CreatNew();
      msg.Result:=0;
    end;
    WM_EXITSIZEMOVE: begin
      if g <> nil then
        PostMessage(g.Handle, WM_EXITSIZEMOVE, 0, 0);
      g:=nil;
      msg.Result:=0;
    end;
    WM_MOVING: begin
      if g <> nil then begin
        if g.Vertical then
          g.Left:=PRect(msg.LParam).Left + g.Left
        else
          g.Top:=PRect(msg.LParam).Top + g.Top;
      end;
      PRect(msg.LParam).Top:=Top;
      PRect(msg.LParam).Bottom:=Top + Height;
      PRect(msg.LParam).Left:=Left;
      PRect(msg.LParam).Right:=Left + Width;
      msg.Result:=0;
    end;
    WM_CLOSE, WM_NCMBUTTONUP: begin
      running:=false;
      msg.Result:=0;
    end;
    WM_NCRBUTTONDOWN: begin
      if isControl then
        RemoveAllGuides();
      msg.Result:=0;
    end;
    WM_SETCURSOR: begin
      SetCursor(LoadCursor(0, IDC_ARROW));
      msg.Result:=0;
    end;
    WM_TRAY: begin
      case msg.LParam of
        WM_MOUSEMOVE:;
        WM_LBUTTONDOWN: BringToFrontAll();
        WM_MBUTTONUP: begin
          running:=false;
          PostMessage(Handle, WM_TRAY, 0, 0)
        end;
        WM_RBUTTONDOWN: begin
          Inc(displayMode);
          if displayMode > 2 then
            displayMode:=0;
          NotifyAll();
        end;
        //else begin
        //  Inc(displayMode);
        //end;
      end;
      msg.Result:=0;
    end
    else
      Result:=false;
  end;
end;

end.


