unit CompressZip;

interface

uses System.SysUtils, System.Classes, Generics.Collections, System.Zip;


function CompressZipFile(const AFileName: TFileName; const AZipFile: TFileName;
  const AOnProgress: TZipProgressEvent = nil): Boolean; overload;

// Распаковка в разные каталоги или сохранение вложения каталогов - не предусмотрено.
function CompressZipFile(const AFileNameList: TStringList;
  const AZipFile: TFileName;
  const AOnProgress: TZipProgressEvent = nil): Boolean; overload;

function DecompressZipFile(const AZipFile: TFileName; const AExtractDir: string;
  const AOnProgress: TZipProgressEvent = nil): Boolean;

implementation

uses System.IOUtils;

function Files_Exists(const AFileNameList: TStringList): Boolean; // Такое имя что бы не перепутать с FileExists
var
  i: Integer;
  FName: TFileName;
Begin
  Result := False;
  if not Assigned(AFileNameList) then
    Exit;

  for i := 0 to AFileNameList.Count - 1 do
  Begin
    FName := AFileNameList.Strings[i];
    Result := FileExists(FName);
    if not Result then
      Break;
  End;

End;

function CompressZipFile(const AFileName: TFileName;
  const AZipFile: TFileName;
  const AOnProgress: TZipProgressEvent = nil): Boolean;
var
  ZF: TZipFile;
Begin
  Result := False;
  if not FileExists(AFileName) or
     not TPath.HasValidFileNameChars(ExtractFileName(AZipFile), False)
  then
    Exit;

  ZF := TZipFile.Create;
  try
    if Assigned(AOnProgress) then
      ZF.OnProgress := AOnProgress;

    ZF.Open(AZipFile, zmWrite);
    ZF.Add(AFileName, '', zcDeflate);
    ZF.Close;
  finally
    ZF.Free;
  end; // try

End;

function CompressZipFile(const AFileNameList: TStringList;
  const AZipFile: TFileName;
  const AOnProgress: TZipProgressEvent = nil): Boolean; overload;
var
  ZF: TZipFile;
  i: Integer;
Begin
  Result := False;
  if not Assigned(AFileNameList) or
     not Files_Exists(AFileNameList) or
     not TPath.HasValidFileNameChars(AZipFile, False)
  then
   Exit;

  ZF := TZipFile.Create;
  try
    if Assigned(AOnProgress) then
      ZF.OnProgress := AOnProgress;

    ZF.Open(AZipFile, zmWrite);
    for i := 0 to AFileNameList.Count - 1 do
     ZF.Add(AFileNameList.Strings[i], '', zcDeflate);
    ZF.Close;
  finally
    ZF.Free;
  end; // try

end;

function DecompressZipFile(const AZipFile: TFileName;
  const AExtractDir: string;
  const AOnProgress: TZipProgressEvent): Boolean;
Begin
  Result := False;
  if not TZipFile.IsValid(AZipFile) or
     not DirectoryExists(AExtractDir) or
     not TPath.HasValidPathChars(ExtractFileDir(AExtractDir), False)
  then
   Exit;

  TZipFile.ExtractZipFile(AZipFile, AExtractDir, AOnProgress);
  Result := True;
end;

end.
