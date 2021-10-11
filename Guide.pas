unit Guide;

{*******************************************************}
{                                                       }
{       On screen rulers                                }
{       Window for each guide                           }
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
  Classes, GDIPAPI, GDIPOBJ, AlphaWnd, SysUtils, Windows, Messages, Math;

type TGuide = class(TAlphaWnd)
  private
    Graph: TGPGraphics;
    isVertical: boolean;
    size: integer;
    distance: integer;
    plusDist: integer;
    procedure Repaint;
  protected
    procedure OnCreate; override;
    function ProcessMsg(msg: PMess): boolean; override;
    procedure SetLeft(const Value: integer); override;
    procedure SetTop(const Value: integer); override;
    function OnMove(): boolean;
  public
    constructor Create(isVertical: boolean; size: integer); overload;
    procedure Notify();
    property Vertical: boolean read isVertical;
  end;

implementation

uses Globals, Types;

var xxx: integer = 0;
var transpBrush: TGPBrush;
var coordFont: TGPFont;
var coordBrush: TGPBrush;
var coordUnderColor: TColor;
var linePen: TGPPen;

function MakePoint(X, Y: integer): TPointF;
begin
  Result.X := X;
  result.Y := Y;
end;

{ TGuide }

procedure TGuide.Repaint;
begin
  Graph.Clear(MakeColor(0, 0, 0, 0));

  if isVertical then begin
    if isControl then
      Graph.FillRectangle(transpBrush, 0, 0, 5, size);
    Graph.DrawLine(linePen, 2, 0, 2, size);
  end else begin
    if isControl then
      Graph.FillRectangle(transpBrush, 0, 0, size, 5);
    Graph.DrawLine(linePen, 0, 2, size, 2);
  end;

  if not OnMove() then
    Invalidate();
end;

procedure TGuide.SetLeft(const Value: integer);
begin
  inherited;
  OnMove();
end;

procedure TGuide.SetTop(const Value: integer);
begin
  inherited;
  OnMove();
end;

constructor TGuide.Create(isVertical: boolean; size: integer);
var
  bounds: TRectF;
begin
  Create(CS_DBLCLKS, WS_POPUP,
    WS_EX_TOOLWINDOW or WS_EX_TOPMOST,
    0, 'Guide', 'GuideWndClass', Parent);

  self.isVertical:=isVertical;
  self.size:=size;

  if isVertical then begin
    Width:=50;
    Height:=size;
    Left:=0;
    Top:=0;
  end else begin
    Width:=size;
    Height:=50;
    Left:=0;
    Top:=0;
  end;

  Bitmap:=TGPBitmap.Create(Width, Height, $26200A); // Magic number ;)
  Graph:=TGPGraphics.Create(Bitmap);
  Graph.SetTextRenderingHint(TextRenderingHintAntiAliasGridFit);

  distance:=0;
  Graph.MeasureString('+', -1, coordFont, MakeRect(0, 0, 100.0, 100.0), bounds);
  plusDist:=Ceil(bounds.Width);

  Repaint();
  Redraw();
  AddGuide(self);
  Notify();
end;

procedure TGuide.Notify;
begin
  if isControl then
    SetWindowLong(Handle, GWL_EXSTYLE, GetWindowLong(Handle, GWL_EXSTYLE)
      and (not WS_EX_TRANSPARENT))
  else
    SetWindowLong(Handle, GWL_EXSTYLE, GetWindowLong(Handle, GWL_EXSTYLE)
      or WS_EX_TRANSPARENT);

  if displayMode = 0 then begin
    //if isVertical then
    //  Graph.SetClip(MakeRect(3, 15, 40, 10))
    //else
    //  Graph.SetClip(MakeRect(15, 3, 40, 10));
    Graph.Clear(MakeColor(0, 0, 0, 0));
    //Graph.ResetClip();
  end;

  Repaint();
  SetWindowPos(Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or
    SWP_NOSIZE or SWP_NOACTIVATE);
end;

procedure TGuide.OnCreate;
begin
  inherited;
end;

function TGuide.OnMove: boolean;
  procedure DoDraw(rect: GDIPAPI.TRect; val: integer);
  begin
    Graph.SetClip(rect);
    Graph.Clear(coordUnderColor);
    if displayMode = 1 then
      Graph.DrawString(IntToStr(val + 2), -1, coordFont, MakePoint(rect.X, rect.Y - 1), coordBrush)
    else if displayMode = 2 then begin
      Graph.DrawString('+', -1, coordFont, MakePoint(rect.X, rect.Y - 1), coordBrush);
      Graph.DrawString(IntToStr(val - distance), -1, coordFont, MakePoint(rect.X + plusDist, rect.Y - 1), coordBrush);
    end;
    Graph.ResetClip();
  end;
begin
  Result:=false;
  if (Graph = nil) or (displayMode = 0) then
    Exit;

  if displayMode = 2 then
    distance:=GetDistance(self);

  if isVertical then
    DoDraw(MakeRect(3, 16, 35, 12), Left)
  else
    DoDraw(MakeRect(16, 3, 35, 12), Top);

  Result:=true;
  Invalidate();
end;

function TGuide.ProcessMsg(msg: PMess): boolean;
begin
  Result:=True;
  case msg.Msg of
    WM_NCHITTEST: msg.Result:=HTCAPTION;
    WM_ENTERSIZEMOVE: begin
      BringToFrontAll();
      SetWindowPos(Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or
        SWP_NOSIZE or SWP_NOACTIVATE);
      msg.Result:=0;
    end;
    WM_MOVING: begin
      if isVertical then begin
        PRect(msg.LParam).Top:=Top;
        PRect(msg.LParam).Bottom:=Top + Height;
      end else begin
        PRect(msg.LParam).Left:=Left;
        PRect(msg.LParam).Right:=Left + Width;
      end;
      OnMove();
      msg.Result:=0;
    end;
    WM_EXITSIZEMOVE: begin
      if ((Left < 5) and isVertical) or ((Top < 5) and not isVertical) then
        RemoveGuide(self);
      OnMove();
      if displayMode = 2 then
        NotifyAll();
      msg.Result:=0;
    end;
    WM_SETCURSOR: begin
      if isVertical then
        SetCursor(sizeHCursor)//LoadCursor(0, IDC_SIZEWE))
      else
        SetCursor(sizeVCursor);//LoadCursor(0, IDC_SIZENS));
      msg.Result:=0;
    end 
    else
      Result:=false;
  end;
end;

initialization
  transpBrush:=TGPSolidBrush.Create(MakeColor(1, 130, 130, 130));
  coordFont:=TGPFont.Create('Calibri', 11, FontStyleRegular, UnitPixel);
  coordBrush:=TGPSolidBrush.Create(MakeColor(0, 0, 0));
  coordUnderColor:=MakeColor(190, 255, 255, 255);
  linePen:=TGPPen.Create(MakeColor(74, 255, 255));

end.


