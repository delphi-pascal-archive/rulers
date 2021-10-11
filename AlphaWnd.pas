unit AlphaWnd;

{*******************************************************}
{                                                       }
{       Alpha Clock                                     }
{       32bpp window implementation                     }
{                                                       }
{       Copyright (c) 2006, Anton A. Drachev            }
{                        911.anton@gmail.com            }
{                                                       }
{       Distributed "AS IS" under BSD-like license      }
{       Full text of license can be found in            }
{         "License.txt" file attached                   }
{                                                       }
{*******************************************************}

interface

uses Classes, Graphics, Windows, Messages, GDIPAPI, GDIPOBJ;

type TMess = record
    Msg: Integer;
    WParam: Integer;
    LParam: Integer;
    Result: Integer;
  end;
  PMess = ^TMess;

type TAlphaWnd = class(TInterfacedObject)
  private
    h_Wnd: HWND;
    DC: HDC;
    PtSrc: Windows.TPoint;
    bf: TBlendFunction;
    WinSz: Windows.TSize;
    FHeight: integer;
    FTop: integer;
    FWidth: integer;
    FLeft: integer;
    FBitmap: TGPBitmap;
    procedure SetBitmap(const Value: TGPBitmap);

    class function WndProc(h_Wnd: HWND; Msg: UINT; w_Param: WPARAM;
      l_Param: LPARAM): LRESULT; stdcall; static;
  protected
    procedure OnCreate; virtual;
    function ProcessMsg(msg: PMess): boolean; virtual;
    procedure SetAlphaValue(const Value: byte); virtual;
    procedure SetHeight(const Value: integer); virtual;
    procedure SetLeft(const Value: integer); virtual;
    procedure SetTop(const Value: integer); virtual;
    procedure SetWidth(const Value: integer); virtual;
  public
    Parent: HWND;
    procedure Invalidate();
    procedure Redraw();
    procedure Show(); virtual;
    procedure Hide(); virtual;
    constructor Create(clsStyle: UINT; dwStyle, dwExStyle: DWORD;
      hMenu: HMENU; Caption, clsName: PChar; aParent: HWnd = 0;
      Icon: HIcon = 0); overload; virtual;
    property Handle: HWND read h_Wnd;
    property Left: integer read FLeft write SetLeft;
    property Top: integer read FTop write SetTop;
    property Width: integer read FWidth write SetWidth;
    property Height: integer read FHeight write SetHeight;
    property Bitmap: TGPBitmap read FBitmap write SetBitmap;
    property AlphaValue: byte read bf.SourceConstantAlpha write SetAlphaValue;
end;

implementation

function CreateWindowExA(dwExStyle: DWORD; lpClassName: PChar;
  lpWindowName: PChar; dwStyle: DWORD; X, Y, nWidth, nHeight: Integer;
  hWndParent: HWND; hMenu: HMENU; hInstance: HINST; lpParam: Pointer): HWND;
  stdcall; external user32 name 'CreateWindowExA';

type LPCREATESTRUCT = ^CREATESTRUCT;

{ TAlphaWnd }

class function TAlphaWnd.WndProc(h_Wnd: HWND; Msg: UINT; w_Param: WPARAM;
  l_Param: LPARAM): LRESULT; stdcall;
var
  lpcs: LPCREATESTRUCT;
  pThis: TAlphaWnd;
  amsg: TMess;
begin
  Result:=0;
  pThis:=TAlphaWnd(LPARAM(GetWindowLong(h_Wnd, GWL_USERDATA)));
  amsg.Msg:=Msg;
  amsg.WParam:=w_Param;
  amsg.LParam:=l_Param;
  case Msg of
    WM_CREATE: begin
      lpcs:=LPCREATESTRUCT(l_Param);
      pThis:=lpcs.lpCreateParams;
      SetWindowLong(h_Wnd, GWL_USERDATA, Longint(pThis));
      pThis.h_Wnd:=h_Wnd;
      pThis.DC:=GetDC(h_Wnd);
      pThis.OnCreate;
      Result:=DefWindowProc(h_Wnd, Msg, w_Param, l_Param);
    end
    else begin
      if pThis is TAlphaWnd then begin
        if Msg = WM_MOVE then begin
          pThis.FLeft:=SmallInt(Windows.LOWORD(l_Param));
          pThis.FTop:=SmallInt(Windows.HIWORD(l_Param));
        end;
        if pThis.ProcessMsg(@amsg) then Result:=amsg.Result
        else Result:=DefWindowProc(h_Wnd, Msg, w_Param, l_Param);
      end else
        Result:=DefWindowProc(h_Wnd, Msg, w_Param, l_Param);
    end;
  end;
end;

constructor TAlphaWnd.Create(clsStyle: UINT; dwStyle, dwExStyle: DWORD;
  hMenu: HMENU; Caption, clsName: PChar; aParent: HWnd = 0; Icon: HIcon = 0);
var
  wc: WndClass;
begin
  Parent:=aParent;
  FLeft:=0;
  FTop:=0;
  FHeight:=100;
  FWidth:=100;
  ZeroMemory(@wc, sizeof(WNDCLASS));
  wc.style:=clsStyle;
  wc.lpfnWndProc:=@TAlphaWnd.WndProc;
  wc.hInstance:=hInstance;
  wc.hbrBackground:=HBRUSH(GetStockObject(NULL_BRUSH));
  wc.lpszClassName:=clsName;
  wc.hIcon:=Icon;
  RegisterClass(wc);
  CreateWindowExA(dwExStyle or WS_EX_LAYERED, clsName, Caption, dwStyle,
    FLeft, FTop, FWidth, FHeight, Parent, hMenu, hInstance, Self);
end;

procedure TAlphaWnd.Hide;
begin
  ShowWindow(h_Wnd, 0);
end;

procedure TAlphaWnd.Invalidate;
var
  bmp, old_bmp: HBITMAP;
  BmpDC: HDC;
  PtPos: Windows.TPoint;
begin
  PtPos:=Point(left, top);
  bitmap.GetHBITMAP(0, bmp);
  BmpDC:=CreateCompatibleDC(DC);
  old_bmp:=SelectObject(BmpDC, bmp);
  UpdateLayeredWindow(Handle, DC, @PtPos, @WinSz, BmpDC,
    @PtSrc, 0, @bf, ULW_ALPHA);
  SelectObject(BmpDC, old_bmp);
  DeleteObject(bmp);
  DeleteDC(BmpDC);
end;

procedure TAlphaWnd.OnCreate;
begin
  bitmap:=TGPBitmap.Create();
  PtSrc:=Point(0, 0);
  bf.BlendOp:=AC_SRC_OVER;
  bf.BlendFlags:=0;
  bf.SourceConstantAlpha:=255;
  bf.AlphaFormat:=AC_SRC_ALPHA;
end;

function TAlphaWnd.ProcessMsg(msg: PMess): boolean;
begin
  Result:=False;
end;

procedure TAlphaWnd.Redraw;
begin
  Width:=bitmap.GetWidth;
  Height:=bitmap.GetHeight;
  WinSz.cx:=bitmap.GetWidth;
  WinSz.cy:=bitmap.GetHeight;
  Invalidate();
end;

procedure TAlphaWnd.SetAlphaValue(const Value: byte);
begin
  bf.SourceConstantAlpha:=Value;
  Invalidate();
end;

procedure TAlphaWnd.SetBitmap(const Value: TGPBitmap);
begin
  FBitmap.Free;
  FBitmap:=Value;
end;

procedure TAlphaWnd.SetHeight(const Value: integer);
begin
  FHeight:=Value;
  SetWindowPos(h_Wnd, 0, FLeft, FTop, FWidth, FHeight,
    SWP_NOZORDER or SWP_NOMOVE or SWP_NOACTIVATE);
end;

procedure TAlphaWnd.SetLeft(const Value: integer);
begin
  FLeft:=Value;
  SetWindowPos(h_Wnd, 0, FLeft, FTop, FWidth, FHeight,
    SWP_NOZORDER or SWP_NOSIZE or SWP_NOACTIVATE);
end;

procedure TAlphaWnd.SetTop(const Value: integer);
begin
  FTop:=Value;
  SetWindowPos(h_Wnd, 0, FLeft, FTop, FWidth, FHeight,
    SWP_NOZORDER or SWP_NOSIZE or SWP_NOACTIVATE);
end;

procedure TAlphaWnd.SetWidth(const Value: integer);
begin
  FWidth:=Value;
  SetWindowPos(h_Wnd, 0, FLeft, FTop, FWidth, FHeight,
    SWP_NOZORDER or SWP_NOMOVE or SWP_NOACTIVATE);
end;

procedure TAlphaWnd.Show;
begin
  ShowWindow(h_Wnd, 1);
end;

end.
