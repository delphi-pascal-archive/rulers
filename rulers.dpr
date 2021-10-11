program rulers;

{*******************************************************}
{                                                       }
{       On screen rulers                                }
{       Program main file                               }
{                                                       }
{       Copyright (c) 2007, Anton A. Drachev            }
{                        anton@drachev.com              }
{                                                       }
{       Distributed "AS IS" under BSD-like license      }
{       Full text of license can be found in            }
{         "License.txt" file attached                   }
{                                                       }
{*******************************************************}

uses
  Windows,  SysUtils,   Classes,
  Messages,
  RulersWnd in 'RulersWnd.pas',
  Guide in 'Guide.pas',
  Globals in 'Globals.pas';

{$R rulers.res}


var
  Params: TStringList;
  SFileName: string;
  i, size: integer;

begin
  Init();

  SFileName:=ExpandFileName(ChangeFileExt(ExtractFilename(ParamStr(0)), '.ini'));
  Params:=TStringList.Create();
  if FileExists(SFileName) then begin
    Params.LoadFromFile(SFileName);
    for i := Params.Count - 1 downto 0 do begin
      if (Params.Names[i][1] = 'H') or (Params.Names[i][1] = 'V') then begin
        size:=StrToIntDef(Params.ValueFromIndex[i], 0);
        if size > 4 then begin
          if Params.Names[i][1] = 'V' then
            TGuide.Create(true, mainWnd.Height).Left:=size
          else
            TGuide.Create(false, mainWnd.Width).Top:=size;
        end;
        Params.Delete(i);
      end else begin
        MessageBox(0, PChar(Params.Names[i]), nil, 0);
      end;
    end;
  end else begin
  end;
  
  displayMode:=0;
  NotifyAll();
  
  Run();
  DumpGuides(Params);
  Params.SaveToFile(SFileName);
end.
