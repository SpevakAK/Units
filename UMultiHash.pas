unit UMultiHash;

interface

uses System.Classes, System.SysUtils, Generics.Collections, System.Hash;

type
  TAlgoHash = (ahMD5, ahSHA1, ahSHA224, ahSHA256, ahSHA384, ahSHA512,
    ahBobJenkins);
  // ahStreebog {GOST R 34.11-2012},
  // ahGOST94 {√Œ—“ – 34.11-94} );

  TAlgoHashs = set of TAlgoHash;

  THashsDictionary = TDictionary<TAlgoHash, TBytes>;
  TProgress = procedure(const Position, Max: UInt64; var Abort: Boolean)
    of object;

Function CalcHash(const AFileName: TFileName; const AAlgoHashs: TAlgoHashs;
  out AHashs: THashsDictionary; const AProgress: TProgress = nil;
  const ABufferSize: Cardinal = $FFFF): Boolean; overload;

Function CalcHash(const AStream: TStream; const AAlgoHashs: TAlgoHashs;
  out AHashs: THashsDictionary; const AProgress: TProgress = nil;
  const ABufferSize: Cardinal = $FFFF): Boolean; overload;

function HashsDictionaryToText(const ASource: THashsDictionary;
  Var AText: string): Boolean;

procedure HashsList(const AList: TStrings);

const
  cAlgoHashName: array [TAlgoHash] of string = ('MD5', 'SHA1', 'SHA224',
    'SHA256', 'SHA384', 'SHA512', 'BobJenkins');

implementation

uses System.TypInfo;

Function CalcHash(const AFileName: TFileName; const AAlgoHashs: TAlgoHashs;
  out AHashs: THashsDictionary; const AProgress: TProgress = nil;
  const ABufferSize: Cardinal = $FFFF): Boolean;
var
  F: TFileStream;
Begin
  F := TFileStream.Create(AFileName, fmOpenRead);
  try
    Result := CalcHash(F, AAlgoHashs, AHashs, AProgress, ABufferSize);
  finally
    FreeAndNil(F);
  end;
End;

Function CalcHash(const AStream: TStream; const AAlgoHashs: TAlgoHashs;
  out AHashs: THashsDictionary; const AProgress: TProgress;
  const ABufferSize: Cardinal): Boolean;

var
  LMD5: THashMD5;
  LSHA1: THashSHA1;
  LSHA224: THashSHA2;
  LSHA256: THashSHA2;
  LSHA384: THashSHA2;
  LSHA512: THashSHA2;
  LBobJenkins: THashBobJenkins;

  LBuffer: TBytes;
  LBytesRead: LongInt;
  LSize: Int64;
  LAbort: Boolean;

  procedure InitHash;
  Begin
    if ahMD5 in AAlgoHashs then
      LMD5 := THashMD5.Create;
    if ahSHA1 in AAlgoHashs then
      LSHA1 := THashSHA1.Create.Create;
    if ahSHA224 in AAlgoHashs then
      LSHA224 := THashSHA2.Create(SHA224);
    if ahSHA256 in AAlgoHashs then
      LSHA256 := THashSHA2.Create(SHA256);
    if ahSHA384 in AAlgoHashs then
      LSHA384 := THashSHA2.Create(SHA384);
    if ahSHA512 in AAlgoHashs then
      LSHA512 := THashSHA2.Create(SHA512);
    if ahBobJenkins in AAlgoHashs then
      LBobJenkins := THashBobJenkins.Create;
  End;

  procedure UpdateHash(AData: TBytes; ALength: Cardinal = 0);
  Begin
    if ahMD5 in AAlgoHashs then
      LMD5.Update(AData, ALength);
    if ahSHA1 in AAlgoHashs then
      LSHA1.Update(AData, ALength);
    if ahSHA224 in AAlgoHashs then
      LSHA224.Update(AData, ALength);
    if ahSHA256 in AAlgoHashs then
      LSHA256.Update(AData, ALength);
    if ahSHA384 in AAlgoHashs then
      LSHA384.Update(AData, ALength);
    if ahSHA512 in AAlgoHashs then
      LSHA512.Update(AData, ALength);
    if ahBobJenkins in AAlgoHashs then
      LBobJenkins.Update(AData, ALength);
  End;

  procedure FinishHash;
  Begin
    if not LAbort then
    Begin
      if ahMD5 in AAlgoHashs then
        AHashs.Add(ahMD5, LMD5.HashAsBytes);
      if ahSHA1 in AAlgoHashs then
        AHashs.Add(ahSHA1, LSHA1.HashAsBytes);
      if ahSHA224 in AAlgoHashs then
        AHashs.Add(ahSHA224, LSHA224.HashAsBytes);
      if ahSHA256 in AAlgoHashs then
        AHashs.Add(ahSHA256, LSHA256.HashAsBytes);
      if ahSHA384 in AAlgoHashs then
        AHashs.Add(ahSHA384, LSHA384.HashAsBytes);
      if ahSHA512 in AAlgoHashs then
        AHashs.Add(ahSHA512, LSHA512.HashAsBytes);
      if ahBobJenkins in AAlgoHashs then
        AHashs.Add(ahBobJenkins, LBobJenkins.HashAsBytes);
    End
    else
    Begin
      LMD5.Reset;
      LSHA1.Reset;
      LSHA224.Reset;
      LSHA256.Reset;
      LSHA384.Reset;
      LSHA512.Reset;
      LBobJenkins.Reset;
    End; // if

  End;

  procedure Progress(APosition, AMax: UInt64; var AAbort: Boolean);
  Begin
    if Assigned(AProgress) then
      AProgress(APosition, AMax, AAbort);
  End;

Begin
  LAbort := False;
  Result := Assigned(AStream) and (Assigned(AHashs) and (AHashs.Count = 0)) and
    (AAlgoHashs <> []);

  if not Result then
    Exit;

  try
    LSize := AStream.Size;
    AStream.Position := 0;

    InitHash;
    SetLength(LBuffer, ABufferSize);
    while True do
    begin
      LBytesRead := AStream.ReadData(LBuffer, ABufferSize);
      if (LBytesRead = 0) or LAbort then
        Break;
      UpdateHash(LBuffer, LBytesRead);

      Progress(AStream.Position, LSize, LAbort);
    end; // while
    FinishHash;
    SetLength(LBuffer, 0);

  except
    Result := False;
  end; // try

End;

function HashsDictionaryToText(const ASource: THashsDictionary;
  Var AText: string): Boolean;

  procedure AddString(const AStr: string);
  Begin
    AText := AText + AStr + sLineBreak;
  End;

var
  i: TAlgoHash;
Begin
  AText := '';
  Result := ASource.Count <> 0;
  if not Result then
    Exit;

  for i := Low(TAlgoHash) to High(TAlgoHash) do
    if ASource.ContainsKey(i) then
      AddString(GetEnumName(TypeInfo(TAlgoHash), Ord(i)) + ': ' +
        THash.DigestAsString(ASource.Items[i]));

End;

procedure HashsList(const AList: TStrings);
var
  i: TAlgoHash;
Begin
  if not Assigned(AList) then
    Exit;

  for i := Low(cAlgoHashName) to High(cAlgoHashName) do
    AList.AddObject(cAlgoHashName[i], TObject(i));
End;

end.
