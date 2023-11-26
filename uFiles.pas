{

  Вспомогательные функции для работа с файлами

}


unit uFiles;

interface

uses System.SysUtils, System.Classes;

const
  cPopularImageExts: array [0 .. 6] of string = ('.BMP', '.JPG', '.JPEG',
    '.GIF', '.PNG', '.TIFF', '.TIF');

  cAudioExts: array [0 .. 37] of string = ('.SRT', // Формат рингтона Sagem
    '.AIF', // Аудио-файл в формате AIFF
    '.M4A', // Аудио-файл MPEG-4
    '.MID', // Аудио-файл MIDI
    '.MP3', // Аудио файл MP3
    '.MPA', // Аудио файл MPEG-2
    '.RA', // Аудиофайл Real Audio
    '.WAV', // Цифровой аудио формат
    '.WMA', // Аудио файл Windows Media
    '.AAC', // Улучшенный кодированный аудио-файл
    '.AWB', // Аудио файл AMR-WB
    '.BWG', // Аудио файл BrainWave Generator
    '.MPP', // Аудиофайл Musepack
    '.MSV', // Файл звукозаписи Memory Stick
    '.SDF', // Аудио файл KAWAI Musical Instruments
    '.SRT', // Аудио файл мобильного телефона Siemens C60
    '.VB', // Аудио файл Grand Theft Auto
    '.WAV', // Файл DTS-WAV
    '.WM', // Аудио или видео Windows Media
    '.WPD', // Аудио файл обработки SAW Studio
    '.AIFF', // Аудио формат AIFF
    '.AOB', // Аудио файл DVD
    '.APE', // Сжатый аудио-файл Monkey's
    '.ASF', // Музыкальный файл Electronic Arts
    '.CDR', // Аудио-файл звуковой дорожки на CD
    '.ICS', // Аудио файл диктофона Sony IC
    '.M4P', // Защищенный аудио-файл iTunes Music Store
    '.MP3', '.WAVE', // Аудио файл WAVE
    '.XSB', // Аудио файл XACT
    '.AC3', // Файл аудио кодека 3
    '.AMR', // Файл адаптивного кодека с переменной скоростью
    '.AUD', // Звуковой формат сжатия потока DTS
    '.FLAC', // Аудио-файл в формате FLAC
    '.M4B', // Аудио-файл книги MPEG-4
    '.M4R', // Файл рингтона iPhone
    '.MIDI', // Аудио-файл MIDI
    '.OGG' // Аудио файл Ogg Vorbis
    );

  cVideioExts: array [0 .. 37] of string = ('.GTP', // Видео файл MultiFS
    '.3G2', // Файл мультимедиа 3GPP2
    '.3GP', // Файл мультимедиа 3GPP
    '.ASF', // Формат для потокового видео
    '.ASX', // Ярлык мультимедиа-файла ASF
    '.AVI', // Видео файл AVI
    '.FLV', // Видео-файл Flash
    '.MKV', // Видео-файл Matroska
    '.MOV', // Видео-файл Apple QuickTime
    '.MP4', // Видео файл в формате MPEG-4
    '.MPG', // Видео-файл MPEG
    '.RM', // Файл Real Media
    '.SRT', // Файл видео субтитров в формате SubRip
    '.SWF', // Flash-анимация
    '.VOB', // Видео файл DVD
    '.WMV', // Видео файл Windows Media
    '.3GPP2', // Файл мультимедиа 3GPP2
    '.MOOV', // Видео-файл Apple QuickTime
    '.SPL', // Файл анимации FutureSplash
    '.VCD', // Файл видео CD
    '.VID', // Видео файл SymbOS
    '.VID', // Видео файл DepoView
    '.WM', // Аудио или видео Windows Media
    '.3GP2', // Файл мультимедиа 3GPP2
    '.3GPP', // Файл мультимедиа 3GPP
    '.DRV', // Видео файлы
    '.H264', // Видео файл с кодировкой H.264
    '.STL', // Файл субтитров Spruce Technologies
    '.VID', // Видео файл
    '.F4V', // Видео файл Flash MP4
    '.M4V', // Видео файл iTunes
    '.MOD', // Видео файл в формате MPEG-2
    '.MPEG', // Видео-файл MPEG
    '.MTS', // Видеофайл AVCHD
    '.RMVB', // Видео-файл RealMedia с переменным битрейтом
    '.TS', // Видео-файл TS
    '.WEBM', // Видео-файл WebM
    '.YUV' // Видео файл YUV
    );

Type
  TFileListNotifyEvent = procedure(const ADirName, AFileName: TFileName;
    var AddFile: Boolean) of object;

  TEveryFileNotifyEvent = procedure(const AFileName: TFileName;
    var ACancel: Boolean) of object;

  TEveryFileProc = procedure(const ADir, AFileName: TFileName;
    var ACancel: Boolean) of object;

  TProgressProc = procedure(const ACurrent, AMax: Int64) of object;

  TDataProc = procedure(var ABuffer: TBytes; const ABufferSize: Integer)
    of object;

function SplitDirAndName(const AFullFileName: string;
  out ADirPath, AFileName: string): Boolean;

// Создаёт список файлов AFileList и катологов ADirList в папке ADirectory
// если AFileList или ADirList не нужны, можно поставить nil.
Function BuildFileList(const ADirectory: string; const AFileList: TStrings;
  const ADirList: TStrings = nil; const ARecursive: Boolean = True;
  const ANotifyEvent: TFileListNotifyEvent = nil): Boolean;

Function ScanDir(Dir: String; const AEveryFile: TEveryFileProc;
  const AMask: string = '*.*'): Boolean;

// AExts - возможные расширения файл AFileName
Function CheckType(const AFileName: TFileName;
  const AExts: array of string): Integer;

Function IsFileImage(const AFileName: TFileName): Boolean; inline;
Function IsFileVideo(const AFileName: TFileName): Boolean; inline;
Function IsFileAudio(const AFileName: TFileName): Boolean; inline;

// Блочная обработка потока, обработка должна происходить в ADataBlock
function StreamDataProcessing(const ASource, ADest: TStream;
  const ADataBlock: TDataProc = nil; ADataBlockSize: Int64 = $FFFF;
  AProgress: TProgressProc = nil): Boolean;

function StreamFileProcessing(const ASource, ADest: string;
  const ADataBlock: TDataProc = nil; ADataBlockSize: Integer = $FFFF;
  AProgress: TProgressProc = nil): Boolean;


implementation

uses System.StrUtils;

function SplitDirAndName(const AFullFileName: string;
  out ADirPath, AFileName: string): Boolean;
var
  i: Integer;
begin
  ADirPath := '';
  AFileName := '';
  i := AFullFileName.LastDelimiter(PathDelim + DriveDelim);

  // Result := (Trim(AFullFileName) <> '') and (i > -1);
  Result := (AFullFileName <> '') and (i > -1);
  if not Result then
    Exit;

  AFileName := AFullFileName.SubString(i + 1);
  Dec(i);
  ADirPath := AFullFileName.SubString(0, i + 1);
End;

function BuildListOneDir(const ADirectory: string;
  const AFileList, ADirList: TStrings;
  const ANotifyEvent: TFileListNotifyEvent = nil): Boolean; inline;
var
  SR: TSearchRec;
  iAddFile, iNext: Boolean;
Begin
  Result := DirectoryExists(ADirectory) and Assigned(AFileList);
  if not Result then
    Exit;

  try
    iNext := FindFirst(ADirectory + '\*.*', faAnyFile, SR) = 0;
    while iNext do
    begin
      if (SR.Name <> '.') and (SR.Name <> '..') then
      Begin
        iAddFile := True;

        if Assigned(ANotifyEvent) then
          ANotifyEvent(ADirectory, SR.Name, iAddFile);

        if (SR.Attr and faDirectory) = faDirectory then
        Begin
          if Assigned(ADirList) then
            ADirList.Add(Concat(ADirectory, '\', SR.Name));
        End
        else
        Begin
          if iAddFile and Assigned(AFileList) then
            AFileList.Add(Concat(ADirectory, '\', SR.Name));
        End; // if

      End; // if
      iNext := FindNext(SR) = 0;
    end; // while
    FindClose(SR);

  except
    Result := False;
  end; // try

End;

Function BuildFileList(const ADirectory: string;
  const AFileList, ADirList: TStrings; const ARecursive: Boolean;
  const ANotifyEvent: TFileListNotifyEvent): Boolean;
var
  i: Integer;
  iDirList: TStrings;
begin
  if Assigned(AFileList) then
    AFileList.BeginUpdate;

  if Assigned(ADirList) then
  Begin
    ADirList.BeginUpdate;

    iDirList := ADirList;
  End
  else
    iDirList := TStringList.Create;

  // ---------------------------------------
  try
    Result := BuildListOneDir(ADirectory, AFileList, iDirList, ANotifyEvent);
    i := 0;
    while ARecursive and Result and (i < iDirList.Count) do
    Begin
      Result := BuildListOneDir(iDirList.Strings[i], AFileList, iDirList,
        ANotifyEvent);
      Inc(i);
    end; // while

  except
    Result := False;
  end; // try
  // ---------------------------------------

  if Assigned(AFileList) then
    AFileList.EndUpdate;

  if Assigned(ADirList) then
    ADirList.EndUpdate
  else
    FreeAndNil(iDirList);
End;

Function ScanDir(Dir: String; const AEveryFile: TEveryFileProc;
  const AMask: string = '*.*'): Boolean;

  procedure CallBack(const ADir, AFileName: TFileName; var ACancel: Boolean);
  Begin
    if Assigned(AEveryFile) then
      AEveryFile(ADir, AFileName, ACancel);
  End;

Var
  SR: TSearchRec;
  FindRes: Integer;
  Cancel: Boolean;
begin
  Cancel := False;

  Result := DirectoryExists(Dir) and Assigned(AEveryFile) and
    (Trim(AMask) <> '');
  if not Result then
    Exit;

  Dir := IncludeTrailingPathDelimiter(Dir);

  FindRes := FindFirst(Dir + AMask, faAnyFile, SR);
  While FindRes = 0 do
  begin
    if // ((SR.Attr and faDirectory) = faDirectory) and
      ((SR.Name = '.') or (SR.Name = '..')) then
    begin
      FindRes := FindNext(SR);
      Continue;
    end;

    if ((SR.Attr and faDirectory) = faDirectory) then
    begin
      ScanDir(Dir + SR.Name + '\', AEveryFile, AMask);
      FindRes := FindNext(SR);
      Continue;
    end;

    CallBack(Dir, SR.Name, Cancel);
    if Cancel then
      Break;

    FindRes := FindNext(SR);
  end;
  FindClose(SR);
end;

Function CheckType(const AFileName: TFileName;
  const AExts: array of string): Integer;
var
  iExt: string;
Begin
  iExt := ExtractFileExt(AFileName);
  Result := AnsiIndexText(iExt, AExts);
End;

Function IsFileImage(const AFileName: TFileName): Boolean;
Begin
  Result := CheckType(AFileName, cPopularImageExts) > -1;
End;

Function IsFileVideo(const AFileName: TFileName): Boolean; inline;
Begin
  Result := CheckType(AFileName, cVideioExts) > -1;
End;

Function IsFileAudio(const AFileName: TFileName): Boolean; inline;
Begin
  Result := CheckType(AFileName, cAudioExts) > -1;
End;


function StreamDataProcessing(const ASource, ADest: TStream;
  const ADataBlock: TDataProc; ADataBlockSize: Int64;
  AProgress: TProgressProc): Boolean;

  procedure CallBack(var ABuffer: TBytes; const ASize: Integer);
  begin
    if Assigned(ADataBlock) then
      ADataBlock(ABuffer, ASize);
  end;

  procedure Progress(const ACurrent, AMax: Int64);
  begin
    if Assigned(AProgress) then
      AProgress(ACurrent, AMax);
  end;

var
  L: Integer;
  iSize: Int64;
  Buffer: TBytes;
Begin
  Result := False;
  if not Assigned(ASource) or
    (ASource.Size = 0) or
     not Assigned(ADest) or
    (ADest.Size = 0) or
     not Assigned(ADataBlock) or
    (ADataBlockSize = 0)
  then
    Exit;

  iSize := ASource.Size;
  ASource.Position := 0;
  repeat
    L := ASource.Read(Buffer, ADataBlockSize);
    CallBack(Buffer, L);

    ADest.Write(Buffer[0], L);
    Progress(ASource.Position, iSize);
  until L = 0;

  Result:= True;
End;

function StreamFileProcessing(const ASource, ADest: string;
  const ADataBlock: TDataProc; ADataBlockSize: Integer;
  AProgress: TProgressProc): Boolean;
var
  SourceFile, DestFile: TFileStream;
Begin
  SourceFile := TFileStream.Create(ASource, fmOpenRead);
  DestFile := TFileStream.Create(ADest, fmCreate or fmOpenWrite);
  try
   Result := StreamDataProcessing( SourceFile, DestFile,
                                   ADataBlock,
                                   ADataBlockSize,
                                   AProgress);
  finally
   FreeAndNil(DestFile);
   FreeAndNil(SourceFile);
  end;


End;


end.
