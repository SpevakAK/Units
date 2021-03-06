{ Использовались материалы https://k210.org/delphi/main/4/ }

unit CompressZLib;

interface

uses System.SysUtils, System.Classes, System.ZLib, System.Hash;

const
  cHashSize = 32;
  cDefaultBufSize = $FFFF;

type
  TBytes32 = packed array [0 .. cHashSize-1] of Byte;
  THeaderStream = packed record
    Size: Int64;
    Sha256_Source: TBytes32;
  end;
  TProgressProc = procedure(APos, ASize: Int64) of object;

function CompressZLibFile(const SourceFile, DestFile: String;
  const ALevel: TCompressionLevel = clMax;
  const AProgress: TProgressProc = nil;
  const AMaxBufSize: Cardinal = cDefaultBufSize): Boolean;

function DecompressZLibFile(const SourceFile, DestFile: String;
  const AProgress: TProgressProc = nil;
  const AMaxBufSize: Cardinal = cDefaultBufSize): Boolean;

function CompressZLibStream(const ASource, ADest: TStream;
  const ALevel: TCompressionLevel = clMax;
  const AProgress: TProgressProc = nil;
  const AMaxBufSize: Cardinal = cDefaultBufSize): Boolean;

function DecompressZLibStream(const ASource, ADest: TStream;
  const AProgress: TProgressProc = nil;
  const AMaxBufSize: Cardinal = cDefaultBufSize): Boolean;

implementation


function CopyBytes(const ASource: TBytes; var ADest: TBytes32): Boolean;
Var L: Integer;
Begin
  L := Length(ASource);
  Result := L = cHashSize;
  if not Result then Exit;
  Move(ASource[0], ADest[0], cHashSize);
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

function CompressZLibStream(const ASource, ADest: TStream;
  const ALevel: TCompressionLevel;
  const AProgress: TProgressProc;
  const AMaxBufSize: Cardinal): Boolean;

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
  Result := Assigned(ASource) and Assigned(ADest);
  if not Result then Exit;

  ASource.Position := 0;
  iSize := ASource.Size;
  Count := iSize;
  if Count > AMaxBufSize then BufSize := AMaxBufSize else BufSize := Count;

  SetLength(Buffer, BufSize);
  NullHeaderStream(Header);
  ADest.Write(Header, SizeOf(Header)); // <-- "Занял место" для заголовка.

  InitHash;
  Pack := TCompressionStream.Create(clMax, ADest);
  try
    try
      while Count <> 0 do
      begin
        if Count > BufSize then N := BufSize else N := Count;
        ASource.ReadBuffer(Buffer, N);

        UpdateHash(Buffer, N);;
        Progress(ASource.Position, Count);

        Pack.WriteBuffer(Buffer, 0, N);
        Dec(Count, N);
      end; // while

      //Result:= HeaderStream(iSize, SHA2.HashAsBytes, Header);
      Result:= HeaderStream(iSize, FinalHash, Header);
      if not Result then Exit;
      ADest.Position := 0;                        // Вернулся в начало
      ADest.WriteBuffer(Header, SizeOf(Header));  // (Пере)Записал заголовок
    finally
      SetLength(Buffer, 0);
      FreeAndNil(Pack);
    end; // try

  except
   Result:= False;
  end;

end;

function DecompressZLibStream(const ASource, ADest: TStream;
  const AProgress: TProgressProc;
  const AMaxBufSize: Cardinal): Boolean;

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
  ASource.Position := 0;
  ASource.Read(Header, SizeOf(Header));
  Count:= Header.Size;
  if Count > AMaxBufSize then BufSize := AMaxBufSize else BufSize := Count;

  SetLength(Buffer, BufSize);
  SHA2 := THashSHA2.Create;
  UnPack := TDecompressionStream.Create(ASource);
  try
    try
      while Count <> 0 do
      begin
        if Count > BufSize then N := BufSize else N := Count;
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
      SetLength(Buffer, 0);
      FreeAndNil(UnPack);
    end; // try

  except
   Result:= False;
  end;

end;


function CompressZLibFile(const SourceFile, DestFile: String;
  const ALevel: TCompressionLevel;
  const AProgress: TProgressProc;
  const AMaxBufSize: Cardinal): Boolean;
var iSourceFile, iDestFile : TFileStream;
Begin
 Result:= FileExists(SourceFile) and (Trim(DestFile)<>'');
 if not Result then Exit;

 iSourceFile:= TFileStream.Create(SourceFile, fmOpenRead);
 iDestFile:= TFileStream.Create(DestFile, fmCreate or fmOpenWrite);

 Result:= CompressZLibStream(iSourceFile, iDestFile, ALevel, AProgress, AMaxBufSize);

 iSourceFile.Free;
 iDestFile.Free;
End;

function DecompressZLibFile(const SourceFile, DestFile: String;
  const AProgress: TProgressProc;
  const AMaxBufSize: Cardinal): Boolean;
var iSourceFile, iDestFile : TFileStream;
Begin
 Result:= FileExists(SourceFile) and (Trim(DestFile)<>'');
 if not Result then Exit;

 iSourceFile:= TFileStream.Create(SourceFile, fmOpenRead);
 iDestFile:= TFileStream.Create(DestFile, fmCreate or fmOpenWrite);

 Result:= DecompressZLibStream(iSourceFile, iDestFile, AProgress, AMaxBufSize);

 iSourceFile.Free;
 iDestFile.Free;
End;


end.
