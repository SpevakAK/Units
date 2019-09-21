{

  Вспомогательные функции для работа с файлами

}

unit uFiles;

interface

uses System.SysUtils, System.Classes;

const
  // Форматы изображений поддерживаемые стандартным TImage
  cPopularImageExts: array [0 .. 4] of string = ('.BMP', '.JPG', '.JPEG',
    '.GIF', '.PNG');

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
    '.MP3', // Один из самых распространённых
    '.WAVE', // Аудио файл WAVE
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

function SplitDirAndName(const AFullFileName: string;
  out ADirPath, AFileName: string): Boolean;

// Создаёт список файлов AFileList и катологов ADirList в папке ADirectory
// если AFileList или ADirList не нужны, можно поставить nil.
// Не рекурсивная функция !!!
Function BuildFileList(const ADirectory: string;
  const AFileList, ADirList: TStrings; const ARecursive: Boolean = False;
  const ANotifyEvent: TFileListNotifyEvent = nil): Boolean;

// AExts - возможные расширения файл AFileName
Function CheckType(const AFileName: TFileName;
  const AExts: array of string): Integer;

Function IsFileImage(const AFileName: TFileName): Boolean; inline;
Function IsFileVideo(const AFileName: TFileName): Boolean; inline;
Function IsFileAudio(const AFileName: TFileName): Boolean; inline;

function FileNameValidate(const AFileName: string): Boolean;

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

  Result := (Trim(AFullFileName) <> '') and (i > -1);
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
  Result := DirectoryExists(ADirectory);
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

// function FileNameValidate(const AFileName: string): Boolean;
// var
// c: Char;
// i: Integer;
// begin
// // Name length
// if Trim(AFileName) = '' then
// begin
// Result := False;
// Exit;
// end;
// // Special characters
// for i := 1 to Length(AFileName) do
// begin
// c := AFileName[i];
// if (c in ['\', '/',':', '*', '?', '''', '<', '>', '|'])
// then
// begin
// Result := False;
// Exit;
// end;
// end;
// // Reserved names
// if (AFileName = 'AUX') or (AFileName = 'PRN') or (AFileName = 'CON')
// then
// begin
// Result := False;
// Exit;
// end;
// // Complex reserved names
// if (Copy(AFileName, 1, 3) = 'COM') or (Copy(AFileName, 1, 3) = 'LPT') then
// begin
// Result := False;
// Exit;
// end;
// Result := True;
// end;

function FileNameValidate(const AFileName: string): Boolean;
const
  cMAX_PATH = 255;
  cReservedNames: array [0 .. 21] of string = ('CON', 'PRN', 'AUX', 'NUL',
    'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9',
    'LPT1', 'LPT2', 'LPT3', 'LPT4', 'LPT5', 'LPT6', 'LPT7', 'LPT8', 'LPT9');

var
  i, L: Integer;
Begin
  Result := AnsiIndexText(UpperCase(AFileName), cReservedNames) = -1;

  L := Length(AFileName);
  if Result then
    Result := L <= cMAX_PATH;

  i := 1;
  while Result and (i < L) do
  Begin
    Result := CharInSet(AFileName[i], ['\', '/', ':', '*', '?', '"', '<', '>', '|']);
    Inc(i);
  End; // while

End;

end.
