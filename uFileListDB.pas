{
 Use SQLite database
}

unit uFileListDB;

interface

uses Winapi.Windows, System.SysUtils, System.Classes, System.Types,
  generics.collections, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.VCLUI.Wait,
  FireDAC.Stan.ExprFuncs, FireDAC.Phys.SQLiteDef, FireDAC.Phys.SQLite,
  Data.DB, FireDAC.Comp.Client, FireDAC.Stan.Param, FireDAC.DatS,
  FireDAC.DApt.Intf, FireDAC.DApt, FireDAC.Comp.DataSet, System.SyncObjs,
  FireDAC.Phys.SQLiteWrapper;

Type
  TID = Cardinal;
  TFileNotifyEvent = procedure(AMax, APos: TID) of object;

  TFileListDB = class
  private
    FConn: TFDConnection;
    FQuery: TFDQuery;
    FMemTable: TFDMemTable;
    FTrans: TFDTransaction;
    FCollation: TFDSQLiteCollation;
    FDriverLink: TFDPhysSQLiteDriverLink;

    FUpper: TFDSQLiteFunction;
    FLower: TFDSQLiteFunction;
    FInStr: TFDSQLiteFunction;
    FStrLike: TFDSQLiteFunction;

    CS: TCriticalSection;
    FCurrentOnlyFileName: TFileName;
    FRecordCount, FRecNo: Integer;
    FAutoTransaction { , FBeforeAutoTransaction } : Boolean;

    function SQLInsert(const AQuery, ATable: string; out AID: TID;
      const AValues: array of const): Boolean;
    function SQLDelete(const AQuery: string; const AID: TID): Boolean; inline;

    Function DirInsert(const ADirectory: string; out aDirID: TID)
      : Boolean; inline;
    Function FileInsert(const aDirID: TID; const AOnlyFileName: string;
      out AFileID: TID): Boolean; inline;
    Function TagInsert(ATagName: string; out ATagID: TID): Boolean; inline;

    Function DirAdd(ADirectory: string; out aDirID: TID): Boolean;

    Function DirExists(const ADirectory: string; out aDirID: TID): Boolean;
    Function DirDelete(const ADirectory: string): Boolean; overload;
    Function DirDelete(const aDirID: TID): Boolean; overload;

    Function GetSequence(const AName: string; out AID: TID): Boolean;
    // inline;

    Function FieldFind(const ADataSet: TFDDataSet; const AField: string;
      out ARefField: TField): Boolean; inline;

    Function GetField(const AField: string; out AValue: TID): Boolean; overload;
    Function GetField(const AField: string; out AValue: string)
      : Boolean; overload;

    function GetMemField(const AField: string; out AValue: TID)
      : Boolean; overload;
    function GetMemField(const AField: string; out AValue: string)
      : Boolean; overload;

    procedure UpdateRecNo; inline;

    procedure OverloadFunc(AOwner: TComponent); inline;
    procedure UpperFunc(AFunc: TSQLiteFunctionInstance; AInputs: TSQLiteInputs;
      AOutput: TSQLiteOutput; var AUserData: TObject);
    procedure LowerFunc(AFunc: TSQLiteFunctionInstance; AInputs: TSQLiteInputs;
      AOutput: TSQLiteOutput; var AUserData: TObject);
    procedure InstrFunc(AFunc: TSQLiteFunctionInstance; AInputs: TSQLiteInputs;
      AOutput: TSQLiteOutput; var AUserData: TObject);
    procedure StrLikeFunc(AFunc: TSQLiteFunctionInstance;
      AInputs: TSQLiteInputs; AOutput: TSQLiteOutput; var AUserData: TObject);

  private
    FOnLog: TGetStrProc;
    function GetOnLog: TGetStrProc;
    procedure SetOnLog(const Value: TGetStrProc);
    procedure Log(const MSG: string);

  private
    function ExecSQL(const ASQL: string): Boolean; virtual;
    function OpenSQL(const ASQL: string; const AUseMemTable: Boolean = False)
      : Boolean; virtual;

    Function OpenSQLAndGetFirstID(const ASQL: string; const AField: string;
      out AValue: TID): Boolean; virtual;

    Function InitQueryParams: Boolean;
    procedure SetAutoTransaction(const Value: Boolean);
  public
    Constructor Create(AOwner: TComponent; const ALibFileName: TFileName = '');
    Destructor Destroy; override;

    Function Connected: Boolean; inline;

    Function CreateTablesIfNotExists: Boolean;
    Function isDatabaseIntegrityOK: Boolean; virtual;

    Function Connect(ADataBase: TFileName = '';
      const ACreateTables: Boolean = True): Boolean;
    Procedure Reconnect;
    Procedure Disconnect;

    procedure StartTransaction;
    procedure Commit;
    procedure Rollback;

    Function Vacuum: Boolean; inline;

    // -------------------------------------------------------------------------
    // AFullFileName - ïóòü + èìÿ ôàéëà
    // ACheckFileExists - ïðîâåðèòü ñóùåñòâóåò ëè ôàéë íà äèñêå
    Function FileAdd(const AFullFileName: TFileName; out AFileID: TID;
      const AFileExists: Boolean = True): Boolean; overload;
    Function FileAdd(const ADirName, AOnlyFileName: TFileName; out AFileID: TID;
      const AFileExists: Boolean = True): Boolean; overload;

    // @@@ Íàäî ïåðåäåëàòü ñ òðàíçàêöèÿìè
    // Ìàññîâîå äîáàâëåíèå ôàéëîâ èç ñïèñêà - AFullFileNames: TStrings;
    // â Objects[i] çàïèñûâàåòñÿ id ôàéëà â áàçå
    Function MultiFileAdd(const AFullFileNames: TStrings;
      const ACallBack: TFileNotifyEvent = nil;
      const ACheckFileExists: Boolean = True): Boolean;

    Function FileExists(const AFullFileName: TFileName; out AFileID: TID)
      : Boolean; overload;
    Function FileExists(const aDirID: TID; AOnlyFileName: TFileName;
      out AFileID: TID): Boolean; overload;
    Function FileExists(const AFileID: TID): Boolean; overload;

    Function FileDelete(const AFullFileName: TFileName): Boolean; overload;
    Function FileDelete(const AFileID: TID): Boolean; overload;

    // AFullFileName - ïóòü + èìÿ ôàéëà
    // ANewOnlyFileName - òîëüêî èìÿ áåç ïóòè
    // ARenameFile - ïåðåèìåíîâàòü ôàéë íà äèñêå
    Function FileReName(const AFullFileName, ANewOnlyFileName: TFileName;
      const ARenameFile: Boolean = True): Boolean; overload;
    // AFileID - id ôàéëà äëÿ ïåðåèìåíîâàíèÿ.
    Function FileReName(const AFileID: TID; const ANewOnlyFileName: TFileName;
      const ARenameFile: Boolean = True): Boolean; overload;

    // aStrs - ñëîâà äëÿ ïîèñêà. AUseLike - Èñïîëüçîâàòü "like" ïðè ñðàâíåíèè
    Function FileNameSearch(const aStrs: TStringDynArray;
      const AUseMasks: Boolean = False): Boolean;

    procedure First;
    procedure Next;
    procedure Prior;
    procedure Last;
    function Eof: Boolean;

    function CurrentFile(var AFileID: TID; var ADir, AFileName: string)
      : Boolean; overload;
    function CurrentFile(var AFileID: TID; var AFullFileName: string)
      : Boolean; overload;

    // -------------------------------------------------------------------------
    Function TagAdd(const ATagName: string; out ATagID: TID): Boolean;
    Function TagExists(const ATagName: string; out ATagID: TID)
      : Boolean; overload;
    Function TagExists(const ATagID: TID): Boolean; overload;

    Function TagDelete(const ATagName: string): Boolean; overload;
    Function TagDelete(const ATagID: TID): Boolean; overload;

    Function LinkFileTags(const AFileID, ATagID: TID): Boolean; overload;
    Function LinkFileTags(const AFileID: TID; ATagName: string)
      : Boolean; overload;
    Function UnLinkFileTags(const AFileID, ATagID: TID): Boolean; overload;

    Function FileTags(const AFileID: TID; const ATagList: TStrings): Boolean;
    Function TagsList(const ATagList: TStrings): Boolean;

    // -------------------------------------------------------------------------
    property AutoTransaction: Boolean read FAutoTransaction
      write SetAutoTransaction;
    property CurrentOnlyFileName: TFileName read FCurrentOnlyFileName;
    property RecordCount: Integer read FRecordCount;
    property RecNo: Integer read FRecNo;
    property OnLog: TGetStrProc read GetOnLog write SetOnLog;

  end;

implementation

uses System.StrUtils, System.Variants, Math, awMachMask,
  QueryConsts, uFiles;

const
  cCantLoadDll = 'can not load library %s';

function SpliitTrimString(const S, Delimiters: string): TStringDynArray; inline;
var
  i: Integer;
Begin
  Result := SplitString(S, Delimiters);
  for i := Low(Result) to High(Result) do
    Result[i] := Trim(Result[i])
End;

procedure SetError(const AErrorCode: Integer; const AErrorText: String;
  out AOut: TSQLiteOutput); inline;
Begin
  AOut.ErrorCode := AErrorCode;
  AOut.ErrorText := AErrorText;
End;

Function SQLiteFunction(AOwner: TComponent;
  const ADriverLink: TFDPhysSQLiteDriverLink; const AFunctionName: String;
  const ArgumentsCount: Integer;
  const AOnCalculate: TSQLiteFunctionCalculateEvent): TFDSQLiteFunction; inline;
Begin
  Result := TFDSQLiteFunction.Create(ADriverLink);
  try
    Result.DriverLink := ADriverLink;
    Result.FunctionName := AFunctionName;
    Result.ArgumentsCount := ArgumentsCount;
    Result.OnCalculate := AOnCalculate;
    Result.Active := True;
  except
    FreeAndNil(Result);
  end;
End;

{ TDBConnector }

constructor TFileListDB.Create(AOwner: TComponent;
  const ALibFileName: TFileName = '');
begin
  FAutoTransaction := True;
  CS := TCriticalSection.Create;

  FConn := TFDConnection.Create(AOwner);
  with FConn do
  Begin
    LoginPrompt := False;
    DriverName := 'SQLite';
    ConnectionName := 'SQLITECONNECTION';
    // FormatOptions.SortOptions := FormatOptions.SortOptions + [soNoCase];
    ResourceOptions.AutoReconnect := True;
    TxOptions.EnableNested := False;
    TxOptions.AutoCommit := False;
    TxOptions.AutoStart := False;
    TxOptions.AutoStop := False;
  End; // with

  FQuery := TFDQuery.Create(AOwner);
  with FQuery do
  Begin
    Connection := FConn;
    ResourceOptions.SilentMode := True;
    // FilterOptions := [foCaseInsensitive];
  End; // with

  FMemTable := TFDMemTable.Create(AOwner);

  FTrans := TFDTransaction.Create(AOwner);
  FTrans.Options.Isolation := xiReadCommitted;
  FTrans.Options.EnableNested := False;
  FConn.Transaction := FTrans;
  FQuery.Transaction := FTrans;

  FDriverLink := TFDPhysSQLiteDriverLink.Create(AOwner);
  if ALibFileName <> '' then
    if System.SysUtils.FileExists(ALibFileName) then
    Begin
      FDriverLink.VendorHome := ExtractFilePath(ALibFileName);
      FDriverLink.VendorLib := ALibFileName;
      FDriverLink.DriverID := 'SQLite';
    End
    else
      raise Exception.CreateFmt(cCantLoadDll, [ALibFileName]);

  OverloadFunc(AOwner);
end;

destructor TFileListDB.Destroy;
begin
  Disconnect;
  FreeAndNil(FTrans);
  FreeAndNil(FCollation);
  FreeAndNil(FDriverLink);
  FreeAndNil(FMemTable);
  FreeAndNil(FQuery);
  FreeAndNil(FConn);
  FreeAndNil(CS);
  inherited
end;

function TFileListDB.Connect(ADataBase: TFileName;
  const ACreateTables: Boolean): Boolean;

begin
  ADataBase := Trim(ADataBase);
  Log(Concat('Connect               ADataBase=', QuotedStr(ADataBase),
    ' ACreateTables=', BoolToStr(ACreateTables, True)));

  if ADataBase = '' then
    ADataBase := ChangeFileExt(ParamStr(0), '.sqlite');

  try
    FConn.Params.Values['Database'] := ADataBase;
    FConn.Online;
    Result := FConn.Connected;
    InitQueryParams;
    if Result and ACreateTables then
      Result := CreateTablesIfNotExists;
  except
    Result := False;
  end; // try

  // SELECT * FROM "Employees" ORDER BY LastName COLLATE NOCASE
  FCollation := TFDSQLiteCollation.Create(FDriverLink);
  FCollation.DriverLink := FDriverLink;
  FCollation.CollationKind := scCompareString;
  FCollation.CollationName := 'NOCASE';
  FCollation.Flags := [sfIgnoreCase];
  FCollation.Active := True;

  Log(Concat('Connect ', BoolToStr(Result, True)));
end;

procedure TFileListDB.Reconnect;
begin
  Log('Reconnect');
  FConn.Connected := False;
  FConn.Connected := True;
end;

procedure TFileListDB.Disconnect;
begin
  Log('Disconnect');
  FConn.Connected := False;
end;

procedure TFileListDB.StartTransaction;
begin
  // FBeforeAutoTransaction := AutoTransaction;
  // if FBeforeAutoTransaction then
  // AutoTransaction := False;

  if not FTrans.Active then
    FTrans.StartTransaction;
end;

procedure TFileListDB.Commit;
begin
  FTrans.Commit;
  // AutoTransaction := FBeforeAutoTransaction;
end;

procedure TFileListDB.Rollback;
begin
  FTrans.Rollback;
  // AutoTransaction := FBeforeAutoTransaction;
end;

Function TFileListDB.Vacuum: Boolean;
Begin
  Log('Vacuum ');
  Result := ExecSQL('Vacuum');
  Log(Concat('Vacuum ', BoolToStr(Result, True)));
End;

Function TFileListDB.InitQueryParams: Boolean;
var
  i: Integer;
begin
  Log('InitQueryParams');
  Result := Connected;

  i := Low(cPRAGMA_Settings);
  while Result and (i <= High(cPRAGMA_Settings)) do
  Begin
    Result := ExecSQL(cPRAGMA_Settings[i]);
    if not Result then
      Raise Exception.CreateFmt('Ïàðàìåòð "s%" íå êîððåêòåí',
        [cPRAGMA_Settings[i]]);
    Inc(i);
  End; // while
End;

Function TFileListDB.CreateTablesIfNotExists: Boolean;
begin
  Log('CreateTablesIfNotExists ');
  Result := Connected;

  if Result then
    Result := ExecSQL(cCreateTableCatalogs);

  if Result then
    Result := ExecSQL(cCreateTableFiles);

  if Result then
    Result := ExecSQL(cCreateTableTags);

  if Result then
    Result := ExecSQL(cCreateTableFilesTags);

  if Result then
    Result := ExecSQL(cCreateTableHashs);

  if Result then
    Result := ExecSQL(cCreateTableFilesHashs);

  Log(Concat('CreateTablesIfNotExists ', BoolToStr(Result, True)));
end;

function TFileListDB.FileAdd(const AFullFileName: TFileName; out AFileID: TID;
  const AFileExists: Boolean = True): Boolean;
var
  iOnlyDir, iOnlyFileName: string;
begin
  Result := SplitDirAndName(AFullFileName, iOnlyDir, iOnlyFileName);
  if Result then
    Result := FileAdd(iOnlyDir, iOnlyFileName, AFileID, AFileExists);
end;

function TFileListDB.FileAdd(const ADirName, AOnlyFileName: TFileName;
  out AFileID: TID; const AFileExists: Boolean = True): Boolean;
var
  iDirID: TID;
begin
  AFileID := 0;
  Log(Concat('FileAdd              ADirName=', QuotedStr(ADirName), '  ',
    'AOnlyFileName=', QuotedStr(AOnlyFileName), 'AFileExists=',
    BoolToStr(AFileExists)));

  Result := (ADirName <> '') and (AOnlyFileName <> '');

  if AFileExists and Result then
    Result := System.SysUtils.FileExists(ADirName + '\' + AOnlyFileName);

  if not Result then
    Exit;

  Result := DirExists(ADirName, iDirID);
  if not Result then
    Result := DirAdd(ADirName, iDirID);

  if not Result then
    Exit;

  Result := not FileExists(iDirID, AOnlyFileName, AFileID);
  if Result then
    Result := FileInsert(iDirID, AOnlyFileName, AFileID);
end;

function TFileListDB.MultiFileAdd(const AFullFileNames: TStrings;
  const ACallBack: TFileNotifyEvent; const ACheckFileExists: Boolean): Boolean;
var
  i, iCount: Integer;
  iFileID: TID;
  iAddOk: Boolean;
begin
  Log(Concat('MultiFileAdd         AFullFileNames.Count=',
    IntToStr(AFullFileNames.Count), '  ', 'Assigned(ACallBack)=',
    BoolToStr(Assigned(ACallBack), True), '  ', 'ACheckFileExists=',
    BoolToStr(ACheckFileExists, True)));

  iCount := AFullFileNames.Count;
  Result := Assigned(AFullFileNames) and (iCount > 0);
  if Result then
    try
      i := 0;
      StartTransaction;
      while i < iCount do
      Begin
        iAddOk := FileAdd(AFullFileNames[i], iFileID, ACheckFileExists);

        if iAddOk then
          AFullFileNames.Objects[i] := TObject(iFileID);

        if Assigned(ACallBack) then
          ACallBack(iCount, i);

        Inc(i);
      End; // while
      Commit;
    except
      Rollback;
      Result := False;
    end; // try
end;

function TFileListDB.FileDelete(const AFullFileName: TFileName): Boolean;
var
  iFileID: TID;
begin
  Log(Concat('FileDelete    AFullFileName=', QuotedStr(AFullFileName)));

  Result := FileExists(AFullFileName, iFileID);
  if Result then
    Result := FileDelete(iFileID);
end;

function TFileListDB.FileDelete(const AFileID: TID): Boolean;
begin
  Log(Concat('FileDelete           AFileID=', IntToStr(AFileID)));
  Result := SQLDelete(cFileDelete, AFileID);
end;

function TFileListDB.FileReName(const AFullFileName, ANewOnlyFileName
  : TFileName; const ARenameFile: Boolean): Boolean;
var
  iFileID: TID;
  iNewFile: TFileName;
begin
  Log(Concat('FileReName           AFullFileName=', QuotedStr(AFullFileName),
    '  ', 'ANewOnlyFileName=', QuotedStr(ANewOnlyFileName), '  ',
    'ARenameFile=', BoolToStr(ARenameFile)));

  Result := FileExists(AFullFileName, iFileID);
  if not Result then
    Exit;

  iNewFile := ExtractFilePath(AFullFileName) + ANewOnlyFileName;
  if ARenameFile then
    Result := not System.SysUtils.FileExists(iNewFile);

  if Result then
  Begin
    if ARenameFile then
      Result := RenameFile(AFullFileName, iNewFile);

    if Result then
      Result := FileReName(iFileID, ANewOnlyFileName, False);
  End;
end;

function TFileListDB.FileReName(const AFileID: TID;
  const ANewOnlyFileName: TFileName; const ARenameFile: Boolean): Boolean;
var
  iFileID: TID;
  iSQLQuery, iDir, iCurrentFile, iNewFile: string;
begin
  Log(Concat('FileReName           AFileID=', IntToStr(AFileID), '  ',
    'ANewOnlyFileName=', QuotedStr(ANewOnlyFileName), '  ', 'ARenameFile=',
    BoolToStr(ARenameFile)));

  Result := ANewOnlyFileName <> '';
  if not Result then
    Exit;

  if Result and ARenameFile then
  Begin
    iSQLQuery := Concat(cFileName, ' where ', cFid, ' = ', IntToStr(AFileID));
    Result := OpenSQL(iSQLQuery);
    if Result and CurrentFile(iFileID, iDir, iCurrentFile) then
    Begin
      iNewFile := Concat(iDir, '\', ANewOnlyFileName);
      if ARenameFile then
        Result := not System.SysUtils.FileExists(iNewFile);

      if Result then
        Result := RenameFile(Concat(iDir, '\', iCurrentFile), iNewFile);
    End;
  End; // if

  if not Result then
    Exit;

  iSQLQuery := Format(cFileNameUpdate, [QuotedStr(ANewOnlyFileName), AFileID]);
  Result := ExecSQL(iSQLQuery);
end;

// function TFileListDB.FileTags(const AFileID: TID;
// const ATagList: TStrings): Boolean;
// var
// iSQLQuery, { iWhere, } iTagName: string;
// iOK: Boolean;
// iTagID: TID;
// iList: TStringList;
// begin
// Log(Concat('FileTags             AFileID=%d', IntToStr(AFileID)));
// Result := Assigned(ATagList) and FileExists(AFileID);
// if not Result then
// Exit;
//
// iSQLQuery := Concat(cFileTagsLink, ' where ', cFid, ' = ', IntToStr(AFileID));
// // iWhere := IfThen(AFileID > 0, ' where ' + cFid + '=' + IntToStr(AFileID));
//
// // iWhere := IfThen(AFileID > 0, ' where ' + cFid + '=' + IntToStr(AFileID));
// // iSQLQuery := Concat(cFileTagsLink, iWhere);
// Result := OpenSQL(iSQLQuery);
// if not Result then
// Exit;
//
// iOK := True;
// iList := TStringList.Create;
// try
// FQuery.First;
// while not FQuery.Eof and iOK do
// Begin
// iOK := GetField(cTid, iTagID) and GetField(cTname, iTagName);
// Log(Format('FileTags   ->  TagID=%d  TagName=%s',
// [iTagID, QuotedStr(iTagName)]));
// iList.AddObject(iTagName, TObject(iTagID));
// FQuery.Next;
// End; // while
//
// ATagList.Assign(iList);
// finally
// FreeAndNil(iList);
// end; // try
//
// end;

function TFileListDB.FileTags(const AFileID: TID;
  const ATagList: TStrings): Boolean;
var
  iSQLQuery, iTagName: string;
  iTagID: TID;
  iList: TStringList;
begin
  Log(Concat('FileTags             AFileID=%d', IntToStr(AFileID)));
  Result := Assigned(ATagList) and FileExists(AFileID);
  if not Result then
    Exit;

  iSQLQuery := Concat(cFileTagsLink, ' where ', cFid, ' = ', IntToStr(AFileID));
  // iWhere := IfThen(AFileID > 0, ' where ' + cFid + '=' + IntToStr(AFileID));
  // iSQLQuery := Concat(cFileTagsLink, iWhere);
  Result := OpenSQL(iSQLQuery);
  if not Result then
    Exit;

  iList := TStringList.Create;
  try
    FQuery.First;
    while not FQuery.Eof and GetField(cTid, iTagID) and
      GetField(cTname, iTagName) do
    Begin
      Log(Format('FileTags   ->  TagID=%d  TagName=%s',
        [iTagID, QuotedStr(iTagName)]));
      iList.AddObject(iTagName, TObject(iTagID));
      FQuery.Next;
    End; // while

    ATagList.Assign(iList);
  finally
    FreeAndNil(iList);
  end; // try

end;

Function TFileListDB.TagsList(const ATagList: TStrings): Boolean;
var
  iTagID: TID;
  iTagName: string;
  iList: TStringList;
Begin
  Log('TagsList');

  Result := Assigned(ATagList) and OpenSQL(cFileTagsList);
  if not Result then
    Exit;

  iList := TStringList.Create;
  try
    FQuery.First;
    while not FQuery.Eof and GetField(cTid, iTagID) and
      GetField(cTname, iTagName) do
    Begin
      Log(Format('TagsList   ->  TagID=%d  TagName=%s',
        [iTagID, QuotedStr(iTagName)]));

      ATagList.AddObject(iTagName, TObject(iTagID));
      FQuery.Next;
    End; // while
    ATagList.Assign(iList);

  finally
    FreeAndNil(iList);
  end; // try

End;

function TFileListDB.FileExists(const AFullFileName: TFileName;
  out AFileID: TID): Boolean;
var
  iDir, iOnlyFileName: string;
  iDirID: TID;
begin
  Log(Concat('FileExists           AFullFileName=', QuotedStr(AFullFileName)));
  AFileID := 0;
  SplitDirAndName(AFullFileName, iDir, iOnlyFileName);

  Result := DirExists(iDir, iDirID);
  if not Result then
    Exit;

  Result := FileExists(iDirID, iOnlyFileName, AFileID);
end;

function TFileListDB.FileExists(const aDirID: TID; AOnlyFileName: TFileName;
  out AFileID: TID): Boolean;
var
  iSQLQuery: string;
begin
  Log(Format('FileExists           ADirID=%d, AOnlyFileName=%s',
    [aDirID, QuotedStr(AOnlyFileName)]));

  Result := (aDirID > 0) and (AOnlyFileName <> '');
  if Result then
  Begin
    iSQLQuery := Format(cFileID, [aDirID, QuotedStr(AOnlyFileName)]);
    Result := OpenSQLAndGetFirstID(iSQLQuery, cFid, AFileID);
  End; // if
end;

Function TFileListDB.FileExists(const AFileID: TID): Boolean;
var
  iSQLQuery: string;
Begin
  Log(Concat('FileExists           AFileID=', IntToStr(AFileID)));

  iSQLQuery := Concat(cFileName, ' where ', cFid, ' = ', IntToStr(AFileID));
  Result := OpenSQL(iSQLQuery);
End;

function TFileListDB.isDatabaseIntegrityOK: Boolean;
var
  Value: string;
begin
  Log('isDatabaseIntegrityOK');
  Result := OpenSQL('PRAGMA integrity_check');
  if Result then
    Result := GetField('integrity_check', Value) and (RecordCount = 1);

  if Result then
    Result := LowerCase(Value) = 'ok';
end;

function TFileListDB.Connected: Boolean;
begin
  Result := Assigned(FConn) and FConn.Connected;
end;

Function TFileListDB.FieldFind(const ADataSet: TFDDataSet; const AField: string;
  out ARefField: TField): Boolean;
Begin
  ARefField := nil;
  Result := AField <> '';
  if not Result then
    Exit;

  ARefField := ADataSet.FieldByName(AField);
  Result := Assigned(ARefField);
  // and not ARefField.IsNull;
End;

function TFileListDB.GetField(const AField: string; out AValue: TID): Boolean;
var
  Ref: TField;
begin
  AValue := 0;
  try
    Result := FieldFind(FQuery, AField, Ref);
    if Result then
      AValue := Ref.AsLargeInt;
  except
    Result := False;
  end; // try
end;

function TFileListDB.GetField(const AField: string; out AValue: string)
  : Boolean;
var
  Ref: TField;
begin
  AValue := '';
  try
    Result := FieldFind(FQuery, AField, Ref);
    if Result then
      AValue := Ref.AsString;
  except
    Result := False;
  end; // try
end;

function TFileListDB.GetMemField(const AField: string; out AValue: TID)
  : Boolean;
var
  Ref: TField;
begin
  AValue := 0;
  try
    Result := FieldFind(FMemTable, AField, Ref);
    if Result then
      AValue := Ref.AsLargeInt;
  except
    Result := False;
  end; // try
end;

function TFileListDB.GetMemField(const AField: string;
  out AValue: string): Boolean;
var
  Ref: TField;
begin
  AValue := '';
  try
    Result := FieldFind(FMemTable, AField, Ref);
    if Result then
      AValue := Ref.AsString;
  except
    Result := False;
  end; // try
end;

function TFileListDB.ExecSQL(const ASQL: string): Boolean;
begin
  Log(Concat('ExecSQL              ASQL=', QuotedStr(ASQL)));

  Result := Connected and (ASQL <> '');
  if Result then
    try
      CS.Enter;
      try
        FQuery.ExecSQL(ASQL);
      except
        Result := False;
      end; // try
    finally
      CS.Leave;
    end; // try
end;

function TFileListDB.OpenSQL(const ASQL: string;
  const AUseMemTable: Boolean): Boolean;
begin
  Log(Concat('OpenSQL              ASQL=', QuotedStr(ASQL)));

  Result := Connected and (ASQL <> '');
  if Result then
    try
      CS.Enter;
      try
        FQuery.Open(ASQL);
        FRecordCount := FQuery.RecordCount;
        Result := not FQuery.IsEmpty;

        if AUseMemTable then
        Begin
          if FMemTable.RecordCount > 0 then
            // FMemTable.ClearFields;
            FMemTable.EmptyDataSet;

          FMemTable.CopyDataSet(FQuery, [coStructure, coRestart, coAppend]);
          First;
        end;
      except
        Result := False;
      end; // try

    finally
      CS.Leave;
    end; // try
end;

Function TFileListDB.OpenSQLAndGetFirstID(const ASQL: string;
  const AField: string; out AValue: TID): Boolean;
Begin
  AValue := 0;
  Result := OpenSQL(ASQL);
  if Result then
    Result := GetField(AField, AValue);
End;

procedure TFileListDB.OverloadFunc(AOwner: TComponent);
begin
  // Ïåðåîïðåäåëèë âñòðîåííûå ôóíêöèè, òåïåðü îíè ðàáîòàþò ñ êèðèëèöåé
  FUpper := SQLiteFunction(AOwner, FDriverLink, 'Upper', 1, UpperFunc);
  FLower := SQLiteFunction(AOwner, FDriverLink, 'Lower', 1, LowerFunc);
  FInStr := SQLiteFunction(AOwner, FDriverLink, 'InStr', 2, InstrFunc);

  // StrLike(FieldName, 'test%text').
  // Ñèìâîëû ïîäñòàíîâêè '*' è '?'. Ðåãèñòðîíåçàâèñèìàÿ.
  FStrLike := SQLiteFunction(AOwner, FDriverLink, 'StrLike', 2, StrLikeFunc);
end;

function TFileListDB.DirAdd(ADirectory: string; out aDirID: TID): Boolean;
begin
  aDirID := 0;
  ADirectory := Trim(ADirectory);
  Result := System.SysUtils.DirectoryExists(ADirectory);
  if Result then
    Result := DirInsert(ADirectory, aDirID);
end;

function TFileListDB.DirDelete(const ADirectory: string): Boolean;
var
  iDirID: TID;
begin
  Result := DirExists(ADirectory, iDirID);
  if Result then
    Result := DirDelete(iDirID);
end;

function TFileListDB.DirDelete(const aDirID: TID): Boolean;
begin
  Result := SQLDelete(cDirDelete, aDirID);
end;

function TFileListDB.DirExists(const ADirectory: string;
  out aDirID: TID): Boolean;
var
  iSQLQuery: string;
begin
  iSQLQuery := Format(cDirID, [QuotedStr(ADirectory)]);
  Result := OpenSQLAndGetFirstID(iSQLQuery, cCid, aDirID);
end;

procedure TFileListDB.SetAutoTransaction(const Value: Boolean);
begin
  if FAutoTransaction = Value then
    Exit;

  FAutoTransaction := Value;
  FTrans.Options.AutoCommit := Value;
  FTrans.Options.AutoStart := Value;
  FTrans.Options.AutoStop := Value;
end;

procedure TFileListDB.SetOnLog(const Value: TGetStrProc);
begin
  FOnLog := Value;
end;

function TFileListDB.GetOnLog: TGetStrProc;
begin
  Result := FOnLog;
end;

procedure TFileListDB.Log(const MSG: string);
Begin
  if Assigned(FOnLog) then
    FOnLog(Concat(ClassName, ' ', MSG));
End;

function TFileListDB.CurrentFile(var AFileID: TID;
  var ADir, AFileName: string): Boolean;
Begin
  Result := GetMemField(cFid, AFileID) and GetMemField(cCname, ADir) and
    GetMemField(cFname, AFileName);

  FCurrentOnlyFileName := AFileName;
End;

function TFileListDB.CurrentFile(var AFileID: TID;
  var AFullFileName: string): Boolean;
var
  iDir, iFileName: string;
Begin
  AFullFileName := '';
  Result := CurrentFile(AFileID, iDir, iFileName);
  if Result then
    AFullFileName := Concat(iDir, '\', iFileName);
End;

// function TFileListDB.FileNameSearch(const aStrs: array of string;
// const AUseMasks: Boolean): Boolean;
// var
// i: Integer;
// iSQLQuery, iFilter, tmpStr: string;
// begin
// Result := Connected;
// if not Result then
// Exit;
//
// tmpStr := '';
// iFilter := '';
// for i := Low(aStrs) to High(aStrs) do
// if Trim(aStrs[i]) <> '' then
// Begin
// tmpStr := IfThen(AUseMasks, ' like ', '=') +
// IfThen(AUseMasks, QuotedStr('%' + aStrs[i] + '%'), QuotedStr(aStrs[i]));
//
// iFilter := Concat(iFilter, IfThen(Length(iFilter) > 1, ' or ', ' Where '),
// cFname, tmpStr);
// End; // if, for
//
// iSQLQuery := Concat(cFileName, iFilter);
// Result := OpenSQL(iSQLQuery, True);
// end;

function TFileListDB.FileNameSearch(const aStrs: TStringDynArray;
  const AUseMasks: Boolean): Boolean;
var
  i: Integer;
  iSQLQuery, iFilter, tmpStr: string;
begin
  Result := Connected;
  if not Result then
    Exit;

  tmpStr := '';
  iFilter := '';
  for i := Low(aStrs) to High(aStrs) do
    if Trim(aStrs[i]) <> '' then
    Begin
      if AUseMasks then
        tmpStr := Concat('StrLike(', QuotedStr('*' + aStrs[i] + '*'), ', ',
          cFname, ')')
      else
        tmpStr := Concat(cFname, '=', QuotedStr(aStrs[i]));

      iFilter := Concat(iFilter, IfThen(Length(iFilter) > 1, ' or ',
        ' Where '), tmpStr);
    End; // if, for

  iSQLQuery := Concat(cFileName, iFilter);
  Result := OpenSQL(iSQLQuery, True);
end;

//function LikeField(const AField, AValue: string;
//  const AUseStrLike: Boolean): string;
//Begin
//  Result := '';
//  if (Trim(AField) = '') or (Trim(AValue) = '') then
//    Exit;
//
//  if AUseStrLike then
//    Result := Concat('StrLike(', QuotedStr('*' + AValue + '*'), ', ',
//      AField, ')')
//  else
//    Result := Concat('%' + AField + '%', ' like ', AValue);
//End;

procedure TFileListDB.First;
Begin
  Log('First');
  if FMemTable.RecordCount = 0 then
    Exit;

  FMemTable.First;
  UpdateRecNo;
End;

procedure TFileListDB.Next;
Begin
  Log('Next');
  if FMemTable.RecordCount = 0 then
    Exit;

  FMemTable.Next;
  UpdateRecNo;
End;

procedure TFileListDB.Prior;
Begin
  Log('Prior');
  if FMemTable.RecordCount = 0 then
    Exit;

  FMemTable.Prior;
  UpdateRecNo;
End;

procedure TFileListDB.Last;
Begin
  Log('Last');
  if FMemTable.RecordCount = 0 then
    Exit;

  FMemTable.Last;
  UpdateRecNo;
End;

function TFileListDB.Eof: Boolean;
begin
  Result := FMemTable.Eof;
  Log(Concat('Eof                  Result=', BoolToStr(Result, True)));
end;

function TFileListDB.LinkFileTags(const AFileID, ATagID: TID): Boolean;
var
  iLinkID: TID;
  iSQLQuery: string;
begin
  Log(Format('LinkFileTags         AFileID=%d, ATagID=%d', [AFileID, ATagID]));
  Result := FileExists(AFileID) and TagExists(ATagID);
  if not Result then
    Exit;

  iSQLQuery := Format(cFileTagsSelect, [AFileID, ATagID]);
  Result := not OpenSQLAndGetFirstID(iSQLQuery, cID, iLinkID);

  if Result then
    Result := SQLInsert(cFileTagsInsert, cFilesTags, iLinkID,
      [AFileID, ATagID]);
end;

function TFileListDB.LinkFileTags(const AFileID: TID; ATagName: string)
  : Boolean;
var
  iTagID: TID;
begin
  Log(Format('LinkFileTags         AFileID=%d, ATagName=%s',
    [AFileID, QuotedStr(ATagName)]));
  Result := TagAdd(ATagName, iTagID);

  if not Result then
    Exit;

  Result := LinkFileTags(AFileID, iTagID);
end;

function TFileListDB.GetSequence(const AName: string; out AID: TID): Boolean;
var
  iSQLQuery: string;
begin
  Log(Concat('GetSequence          AName=', QuotedStr(AName)));
  iSQLQuery := Format(cSequence, [QuotedStr(AName)]);
  Result := OpenSQLAndGetFirstID(iSQLQuery, cSeqField, AID);
  Log(Concat('GetSequence          AID=', IntToStr(AID)));
end;

function TFileListDB.UnLinkFileTags(const AFileID, ATagID: TID): Boolean;
var
  iSQLQuery: string;
  iLinkID: TID;
begin
  Log(Format('UnLinkFileTags AFileID=%d, ATagID=%d', [AFileID, ATagID]));
  iSQLQuery := Format(cFileTagsSelect, [AFileID, ATagID]);
  Result := OpenSQLAndGetFirstID(iSQLQuery, cID, iLinkID);
  if Result then
    Result := SQLDelete(cFileTagsDelete, iLinkID);
end;

procedure TFileListDB.UpdateRecNo;
begin
  FRecNo := FMemTable.RecNo;
end;

function TFileListDB.SQLInsert(const AQuery, ATable: string; out AID: TID;
  const AValues: array of const): Boolean;
var
  iSQLQuery: string;
begin
  AID := 0;
  iSQLQuery := Format(AQuery, AValues);
  Log(Concat('SQLInsert            iSQLQuery=', QuotedStr(iSQLQuery)));

  Result := ExecSQL(iSQLQuery);
  if Result then
    Result := GetSequence(ATable, AID);

  Log(Concat('SQLInsert Result=' + BoolToStr(Result, True)));
End;

function TFileListDB.SQLDelete(const AQuery: string; const AID: TID): Boolean;
var
  iSQLQuery: string;
begin
  Log(Format('SQLDelete            AQuery=%s', [QuotedStr(iSQLQuery)]));
  iSQLQuery := Format(AQuery, [AID]);
  Result := ExecSQL(iSQLQuery);
  Log(Concat('SQLDelete Result=' + BoolToStr(Result, True)));
end;

function TFileListDB.FileInsert(const aDirID: TID; const AOnlyFileName: string;
  out AFileID: TID): Boolean;
begin
  Log(Format('FileInsert           ADirID=%d, AOnlyFileName=%s',
    [aDirID, QuotedStr(AOnlyFileName)]));
  Result := SQLInsert(cFileInsert, cFILES, AFileID,
    [aDirID, QuotedStr(AOnlyFileName)]);
end;

function TFileListDB.DirInsert(const ADirectory: string;
  out aDirID: TID): Boolean;
begin
  Log(Concat('DirInsert            ADirectory=' + QuotedStr(ADirectory)));
  Result := SQLInsert(cDirInsert, cCATALOGS, aDirID, [QuotedStr(ADirectory)]);
end;

procedure TFileListDB.UpperFunc(AFunc: TSQLiteFunctionInstance;
  AInputs: TSQLiteInputs; AOutput: TSQLiteOutput; var AUserData: TObject);
begin
  AOutput.ExtDataType := etUString;
  if AInputs.Count <> 1 then
    SetError(1, 'Incorrect parameter count', AOutput)
  else
    AOutput.AsString := AnsiUpperCase(AInputs[0].AsString);
end;

procedure TFileListDB.LowerFunc(AFunc: TSQLiteFunctionInstance;
  AInputs: TSQLiteInputs; AOutput: TSQLiteOutput; var AUserData: TObject);
Begin
  AOutput.ExtDataType := etUString;
  if AInputs.Count <> 1 then
    SetError(1, 'Incorrect parameter count', AOutput)
  else
    AOutput.AsString := AnsiLowerCase(AInputs[0].AsString);
End;

procedure TFileListDB.InstrFunc(AFunc: TSQLiteFunctionInstance;
  AInputs: TSQLiteInputs; AOutput: TSQLiteOutput; var AUserData: TObject);
Begin
  AOutput.ExtDataType := etInteger;
  if AInputs.Count <> 2 then
    SetError(1, 'Incorrect parameter count', AOutput)
  else
    AOutput.AsInteger := AnsiPos(AInputs[1].AsString, AInputs[0].AsString);
End;

procedure TFileListDB.StrLikeFunc(AFunc: TSQLiteFunctionInstance;
  AInputs: TSQLiteInputs; AOutput: TSQLiteOutput; var AUserData: TObject);
var
  Pattern, Input: string;
Begin
  AOutput.ExtDataType := etBoolean;
  if AInputs.Count <> 2 then
    SetError(1, 'Incorrect parameter count', AOutput)
  else
  Begin
    Pattern := AnsiUpperCase(AInputs[0].AsString);
    Input := AnsiUpperCase(AInputs[1].AsString);

    AOutput.AsBoolean := IsMatchMask(Input, Pattern);
  End; // if
End;

function TFileListDB.TagAdd(const ATagName: string; out ATagID: TID): Boolean;
begin
  Log(Concat('TagAdd               ATagName=', QuotedStr(ATagName)));
  ATagID := 0;
  Result := not TagExists(ATagName, ATagID);
  if Result then
    Result := TagInsert(ATagName, ATagID);
end;

function TFileListDB.TagExists(const ATagName: string; out ATagID: TID)
  : Boolean;
var
  iSQLQuery: string;
begin
  Log(Concat('TagExists            ATagName=', QuotedStr(ATagName)));
  Result := ATagName <> '';
  if Result then
  Begin
    iSQLQuery := Format(cTagID, [QuotedStr(ATagName)]);
    Result := OpenSQLAndGetFirstID(iSQLQuery, cTid, ATagID);
  End;
end;

function TFileListDB.TagExists(const ATagID: TID): Boolean;
var
  iSQLQuery, iTagName: string;
begin
  Log(Concat('TagExists            ATagID=', IntToStr(ATagID)));

  iSQLQuery := Format(cTagName, [ATagID]);
  Result := OpenSQL(iSQLQuery);
  if Result then
    Result := GetField(cTname, iTagName) and (iTagName <> '');
end;

function TFileListDB.TagInsert(ATagName: string; out ATagID: TID): Boolean;
begin
  Log(Format('TagInsert            ATagName=%s', [QuotedStr(ATagName)]));

  ATagName := Trim(ATagName);
  Result := SQLInsert(cTagInsert, cTAGS, ATagID, [QuotedStr(ATagName)]);
end;

function TFileListDB.TagDelete(const ATagName: string): Boolean;
var
  iTagID: TID;
begin
  Log(Concat('TagDelete            ATagName=', QuotedStr(ATagName)));
  Result := TagExists(ATagName, iTagID);
  if Result then
    Result := TagDelete(iTagID);
end;

function TFileListDB.TagDelete(const ATagID: TID): Boolean;
begin
  Log(Concat('TagDelete            ATagID=', IntToStr(ATagID)));
  Result := SQLDelete(cTagDelete, ATagID);
end;

end.
