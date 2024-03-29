{
  Использовались материалы https://delphihaven.wordpress.com/2011/01/22/tip-detecting-graphic-formats/
}

unit ImageGraphicDetect;

interface

uses System.SysUtils, System.Classes, Vcl.Graphics;

function FindGraphicClass(const Buffer; const BufferSize: Int64;
  out GraphicClass: TGraphicClass): Boolean; overload;

function FindGraphicClass(Stream: TStream; out GraphicClass: TGraphicClass)
  : Boolean; overload;

function FindGraphicClass(AFileName: string; out GraphicClass: TGraphicClass)
  : Boolean; overload;


implementation

uses AnsiStrings, Vcl.Imaging.GIFImg, Vcl.Imaging.jpeg, Vcl.Imaging.pngimage;

const
  MinGraphicSize = 44; // we may test up to & including the 11th longword


function FindGraphicClass(const Buffer; const BufferSize: Int64;
  out GraphicClass: TGraphicClass): Boolean; overload;
var
  LongWords: array [Byte] of LongWord absolute Buffer;
  Words: array [Byte] of Word absolute Buffer;
begin
  GraphicClass := nil;
  Result := False;

  if BufferSize < MinGraphicSize then
    Exit;
  case Words[0] of
    $4D42:
      GraphicClass := TBitmap;
    $D8FF:
      GraphicClass := TJPEGImage;
    $4949:
      if Words[1] = $002A then
        GraphicClass := TWicImage; // i.e., TIFF
    $4D4D:
      if Words[1] = $2A00 then
        GraphicClass := TWicImage; // i.e., TIFF
  else
    if Int64(Buffer) = $A1A0A0D474E5089 then
      GraphicClass := TPNGImage
    else if LongWords[0] = $9AC6CDD7 then
      GraphicClass := TMetafile
    else if (LongWords[0] = 1) and (LongWords[10] = $464D4520) then
      GraphicClass := TMetafile
    else if AnsiStrings.StrLComp(PAnsiChar(@Buffer), 'GIF', 3) = 0 then
      GraphicClass := TGIFImage
    else if Words[1] = 1 then
      GraphicClass := TIcon;
  end;
  Result := (GraphicClass <> nil);
end;

function FindGraphicClass(Stream: TStream; out GraphicClass: TGraphicClass)
  : Boolean; overload;
var
  Buffer: PByte;
  CurPos: Int64;
  BytesRead: Integer;
begin
  if Stream is TCustomMemoryStream then
  begin
    Buffer := TCustomMemoryStream(Stream).Memory;
    CurPos := Stream.Position;
    Inc(Buffer, CurPos);
    Result := FindGraphicClass(Buffer^, Stream.Size - CurPos, GraphicClass);
    Exit;
  end;

  GetMem(Buffer, MinGraphicSize);
  try
    BytesRead := Stream.Read(Buffer^, MinGraphicSize);
    Stream.Seek(-BytesRead, soCurrent);
    Result := FindGraphicClass(Buffer^, BytesRead, GraphicClass);
  finally
    FreeMem(Buffer);
  end;
end;

function FindGraphicClass(AFileName: string; out GraphicClass: TGraphicClass)
  : Boolean; overload;
var FS: TFileStream;
Begin
  Result:= False;
  GraphicClass:= nil;

  if not FileExists(AFileName) then Exit;

  FS:= TFileStream.Create(AFileName, fmOpenRead);
  try
   Result:= FindGraphicClass(FS, GraphicClass);
  finally
   FS.Free;
  end;

End;


end.
