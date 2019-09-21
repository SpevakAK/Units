unit CompressZip;

interface

uses System.SysUtils, System.Classes, Generics.Collections, System.Zip;

type
  TFileNameList = TList<TFileName>;

function CompressZipFile(const AZipFile: TFileName;
  const AFileNameList: TFileNameList;
  const AOnProgress: TZipProgressEvent = nil): Boolean; overload;

function CompressZipFile(const AZipFile: TFileName;
  const AFileNameList: TStringList;
  const AOnProgress: TZipProgressEvent = nil): Boolean; overload;

function DecompressZipFile(const AZipFile: TFileName; const AExtractDir: string;
  const AOnProgress: TZipProgressEvent = nil): Boolean;

implementation

function CompressZipFile(const AZipFile: TFileName;
  const AFileNameList: TFileNameList;
  const AOnProgress: TZipProgressEvent): Boolean;
var
  ZF: TZipFile;
  i: UInt32;
Begin
  Result := (Trim(AZipFile) <> '') and
    (Assigned(AFileNameList) and (AFileNameList.Count > 0));
  if not Result then
    Exit;

  ZF := TZipFile.Create;
  try
    try
      if Assigned(AOnProgress) then
        ZF.OnProgress := AOnProgress;
      ZF.Open(AZipFile, zmWrite);
      for i := 0 to AFileNameList.Count - 1 do
        if AFileNameList.Items[i] <> '' then
          ZF.Add(AFileNameList.Items[i], '', zcDeflate);
      ZF.Close;
    except
      Result := False;
    End; // try

  finally
    ZF.Free;
  end; // try

end;

function CompressZipFile(const AZipFile: TFileName;
  const AFileNameList: TStringList; const AOnProgress: TZipProgressEvent = nil)
  : Boolean; overload;
var
  ZF: TZipFile;
  i: UInt32;
Begin
  Result := (Trim(AZipFile) <> '') and
    (Assigned(AFileNameList) and (AFileNameList.Count > 0));
  if not Result then
    Exit;

  ZF := TZipFile.Create;
  try

    try
      if Assigned(AOnProgress) then
        ZF.OnProgress := AOnProgress;
      ZF.Open(AZipFile, zmWrite);
      for i := 0 to AFileNameList.Count - 1 do
        if AFileNameList.Strings[i] <> '' then
          ZF.Add(AFileNameList.Strings[i], '', zcDeflate);
      ZF.Close;
    except
      Result := False;
    End; // try

  finally
    ZF.Free;
  end; // try

end;

function DecompressZipFile(const AZipFile: TFileName; const AExtractDir: string;
  const AOnProgress: TZipProgressEvent): Boolean;
Begin
  Result := TZipFile.IsValid(AZipFile) and (Trim(AExtractDir) <> '');
  if Result then
    try
      TZipFile.ExtractZipFile(AZipFile, AExtractDir, AOnProgress);
    except
      Result := False;
    end; // try

end;

end.
