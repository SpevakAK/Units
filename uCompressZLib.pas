{ Использовались материалы https://k210.org/delphi/main/4/ }

unit uCompressZLib;

interface

uses System.SysUtils, System.Classes, System.ZLib, System.Hash;

const
  cHashSize = 32;

type
  TBytes32 = packed array [0 .. cHashSize-1] of Byte;
  THeaderStream = packed record
    Size: Int64;
    Sha256_Source: TBytes32;
  end;
  TProgressProc = procedure(APos, ASize: Int64) of object;


function CompressZLib(const ASource, ADest: TStream;
  const ALevel: TCompressionLevel = clDefault;
  const AProgress: TProgressProc = nil;
  const ABufSize: Cardinal = $FFFF): Boolean; overload;

function CompressZLib(const SourceFile, DestFile: String;
  const ALevel: TCompressionLevel = clDefault;
  const AProgress: TProgressProc = nil;
  const ABufSize: Cardinal = $FFFF): Boolean; overload;

function DecompressZLib(const ASource, ADest: TStream;
  const AProgress: TProgressProc = nil;
  const ABufSize: Cardinal = $FFFF): Boolean; overload;

function DecompressZLib(const SourceFile, DestFile: String;
  const AProgress: TProgressProc = nil;
  const ABufSize: Cardinal = $FFFF): Boolean; overload;


implementation


function CopyBytes(const ASource: TBytes; var ADest: TBytes32): Boolean;
Var L: Integer;
Begin
  L := Length(ASource);
  Result := False;
  if L <> cHashSize then Exit;

  Move(ASource[0], ADest[0], cHashSize);
  Result := True;
End;

procedure NullHeaderStream(var ADest: THeaderStream); inline;
Begin
  FillChar(ADest, SizeOf(THeaderStream), 0);
End;

Function HeaderStream(const ASize: Int64; ASha256: TBytes;
  var AHeader: THeaderStream): Boolean;   inline;
Begin
  Result:= CopyBytes(ASha256, AHeader.Sha256_Source);
  if not Result then Exit;
  AHeader.Size := ASize;
End;

function CompressZLib(const ASource, ADest: TStream;
  const ALevel: TCompressionLevel;
  const AProgress: TProgressProc;
  const ABufSize: Cardinal): Boolean;

var
  SHA2: THashSHA2;
  Pack: TCompressionStream;
  Header: THeaderStream;
  BufSize, N: Cardinal;
  Buffer: TBytes;
  Count, iSize: Int64;

  procedure Progress(const APos, ASize: Int64);
  Begin
    if Assigned(AProgress) then
      AProgress(APos, ASize);
  end;

  procedure InitHash;
  Begin
   SHA2 := THashSHA2.Create;
  End;

  procedure UpdateHash(const AData: TBytes; ALength: Cardinal);
  Begin
   SHA2.Update(AData, ALength);
  End;

  function FinalHash: TBytes;
  Begin
    Result:= SHA2.HashAsBytes;
  End;

begin
  Result := False;
  if not Assigned(ASource) or not Assigned(ADest) then Exit;

  ASource.Position := 0;
  iSize := ASource.Size;
  Count := iSize;
  if Count > ABufSize then
   BufSize := ABufSize
  else
   BufSize := Count;

  SetLength(Buffer, BufSize);
  NullHeaderStream(Header);
  ADest.Write(Header, SizeOf(Header)); // <-- "Занял место" для заголовка.

  InitHash;
  Pack := TCompressionStream.Create(clMax, ADest);
  try
    while Count <> 0 do
    begin
     if Count > BufSize then
      N := BufSize
     else
      N := Count;

     ASource.ReadBuffer(Buffer, N);

     UpdateHash(Buffer, N);;
     Progress(ASource.Position, Count);

     Pack.WriteBuffer(Buffer, 0, N);
     Dec(Count, N);
    end; // while

    //Result:= HeaderStream(iSize, SHA2.HashAsBytes, Header);
    Result:= HeaderStream(iSize, FinalHash, Header);
    if not Result then
     Exit;

    ADest.Position := 0;                        // Вернулся в начало
    ADest.WriteBuffer(Header, SizeOf(Header));  // Перезаписал заголовок
  finally
//     SetLength(Buffer, 0);
    Pack.Free;
  end; // try

end;

function CompressZLib(const SourceFile, DestFile: String;
  const ALevel: TCompressionLevel;
  const AProgress: TProgressProc;
  const ABufSize: Cardinal): Boolean;
var SourceStream, DestStream : TFileStream;
Begin
 Result:= False;
 if not FileExists(SourceFile) or (Trim(DestFile) = '') or (ABufSize = 0) then
  Exit;

 SourceStream:= TFileStream.Create(SourceFile, fmOpenRead);
 DestStream:= TFileStream.Create(DestFile, fmCreate or fmOpenWrite);
 try
  Result:= CompressZLib(SourceStream, DestStream, ALevel, AProgress, ABufSize);
 finally
  SourceStream.Free;
  DestStream.Free;
 end;

End;

function DecompressZLib(const ASource, ADest: TStream;
  const AProgress: TProgressProc;
  const ABufSize: Cardinal): Boolean;

  procedure Progress(const APos, ASize: Int64);
  Begin
    if Assigned(AProgress) then
      AProgress(APos, ASize);
  end;

var
  SHA2: THashSHA2;
  UnPack: TDecompressionStream;
  Header: THeaderStream;
  BufSize, N: Cardinal;
  Buffer: TBytes;
  Count: Int64;
begin
  Result := False;
  if not Assigned(ASource) or not Assigned(ADest) then Exit;

  ASource.Position := 0;
  ASource.Read(Header, SizeOf(Header));
  Count:= Header.Size;
  if Count > ABufSize then
   BufSize := ABufSize
  else
   BufSize := Count;

  SetLength(Buffer, BufSize);
  SHA2 := THashSHA2.Create;
  UnPack := TDecompressionStream.Create(ASource);
  try
    while Count <> 0 do
    begin
     if Count > BufSize then
      N := BufSize
     else
      N := Count;

     UnPack.ReadBuffer(Buffer, N);

     SHA2.Update(Buffer, N);
     Progress(ASource.Position, Count);

     ADest.WriteBuffer(Buffer, 0, N);
     Dec(Count, N);
    end; // while

    Result := CompareMem( @Header.Sha256_Source[0],
                          @SHA2.HashAsBytes[0],
                          Length(Header.Sha256_Source) );
  finally
//     SetLength(Buffer, 0);
    FreeAndNil(UnPack);
  end; // try


end;


function DecompressZLib(const SourceFile, DestFile: String;
  const AProgress: TProgressProc;
  const ABufSize: Cardinal): Boolean;
var SourceStream, DestStream : TFileStream;
Begin
 Result:= False;
 if not FileExists(SourceFile) or (Trim(DestFile) = '') or (ABufSize = 0) then
  Exit;

 SourceStream:= TFileStream.Create(SourceFile, fmOpenRead);
 DestStream:= TFileStream.Create(DestFile, fmCreate or fmOpenWrite);
 try
  Result:= DecompressZLib(SourceStream, DestStream, AProgress, ABufSize);
 finally
  SourceStream.Free;
  DestStream.Free;
 end;

End;


end.
