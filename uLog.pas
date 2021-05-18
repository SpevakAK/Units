{
 Очень простой способ ведения логов, НЕ(!) годиться при падении приложения
}

unit uLog;

interface

uses System.Classes;

Procedure BufferLog(const AMsg: string);

implementation

uses System.SysUtils;

{.$IFDEF DEBUG}
var gLog: TStringList;
    gEncoding: TEncoding;
{.$ENDIF}

Procedure BufferLog(const AMsg: string);
Begin
 {.$IFDEF DEBUG}
  if Assigned(gLog) then
   gLog.Add( Concat( DateTimeToStr(Now), '   ', AMsg ) );
 {.$ENDIF}
End;


{.$IFDEF DEBUG}
initialization
 gLog:= TStringList.Create;
 gEncoding := TUTF8Encoding.Create;

finalization
 gEncoding.Free;
 if gLog.Count > 0 then
   gLog.SaveToFile( ChangeFileExt(ParamStr(0), '.log'), gEncoding);
 gLog.Free;
{.$ENDIF}

end.
