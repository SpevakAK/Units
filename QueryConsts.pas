unit QueryConsts;

interface

const
  cPRAGMA_Settings: array [0 .. 7] of string = ('PRAGMA foreign_keys=ON;',
    'PRAGMA case_sensitive_like=OFF;',
    'PRAGMA page_size=32768;',
    'PRAGMA recursive_triggers=ON;',
    'PRAGMA secure_delete=ON;',
    'PRAGMA locking_mode=EXCLUSIVE;',
    'PRAGMA journal_mode=4;', // in memory
    'PRAGMA temp_store=2;' // in memory
    );
  // 'PRAGMA encoding = UTF-8/UTF-16le/UTF-16be;'); UTF-8/UTF-16le/UTF-16be;

  cCATALOGS = 'CATALOGS';
  cFILES = 'FILES';
  cTAGS = 'TAGS';
  cFilesTags = 'FILESTAGS';
  cHashs = 'HASHS';
  cFilesHashs = 'FILESHASHS';

  cID = 'id';

  cFid = 'fid';
  cFcid = 'fcid';
  cFname = 'fname';

  cCid = 'cid';
  cCname = 'cname';

  cTid = 'tid';
  cTname = 'tagname';

  cHid = 'hid';
  cHash = 'hash';
  cHname = 'hname';

  cSeqField = 'seq';

  // ---------------------------------------------------------------------------
  // Таблица каталогов
  cCreateTableCatalogs = 'CREATE TABLE IF NOT EXISTS ' + cCATALOGS + '(' +
   cCid + ' INTEGER PRIMARY KEY AUTOINCREMENT,' +
   cCname + ' TEXT UNIQUE NOT NULL COLLATE NOCASE);';

  // Таблица файлов
  cCreateTableFiles = 'CREATE TABLE IF NOT EXISTS ' + cFILES + '(' +
   cFid + ' INTEGER PRIMARY KEY AUTOINCREMENT, ' +
   cFcid + ' INTEGER NOT NULL, ' +
   cFname + ' TEXT NOT NULL COLLATE NOCASE, ' +
   'FOREIGN KEY (' + cFcid + ') REFERENCES ' + cCATALOGS + '(' + cCid + ') ' +
   'ON DELETE CASCADE ON UPDATE CASCADE, ' +
   'CONSTRAINT Сonstrn_' + cFILES + ' UNIQUE (' + cFcid + ', ' + cFname + ') );';

  // Таблица тегов
  cCreateTableTags = 'CREATE TABLE IF NOT EXISTS ' + cTAGS + '(' +
   cTid + ' INTEGER PRIMARY KEY AUTOINCREMENT,' +
   cTname + ' TEXT UNIQUE NOT NULL COLLATE NOCASE);';

  // Связь файлов с тегами
  cCreateTableFilesTags = 'CREATE TABLE IF NOT EXISTS ' + cFilesTags + '(' +
    cID + ' INTEGER PRIMARY KEY AUTOINCREMENT,' +
    cFid + ' INTEGER NOT NULL,' +
    cTid + ' INTEGER NOT NULL,' +
    'FOREIGN KEY (' + cFid + ') REFERENCES ' + cFILES + '(' + cFid + ') ' +
    'ON DELETE CASCADE ON UPDATE CASCADE, ' +
    'FOREIGN KEY (' + cTid + ') REFERENCES ' + cTAGS + '(' + cTid + ') ' +
    'ON DELETE CASCADE ON UPDATE CASCADE, ' +
    'CONSTRAINT Сonstrn_' + cFilesTags + ' UNIQUE (' + cFid + ', ' + cTid + ') );';

  // Список хещей
  cCreateTableHashs = 'CREATE TABLE IF NOT EXISTS '+cHashs+'('+
                      cHid + ' INTEGER PRIMARY KEY AUTOINCREMENT,'+
                      cHname + ' TEXT UNIQUE NOT NULL COLLATE NOCASE);';

  // Связь файлов и хешей
  cCreateTableFilesHashs = 'CREATE TABLE IF NOT EXISTS '+cFilesHashs+'('+
   cID +' INTEGER PRIMARY KEY AUTOINCREMENT,'+
   cFid +' INTEGER NOT NULL,'+
   cHid + ' INTEGER NOT NULL,'+
   cHash +' TEXT NOT NULL COLLATE NOCASE,'+
   'FOREIGN KEY ('+cFid+') REFERENCES '+cFILES+'('+cFid+') '+
   'ON DELETE CASCADE ON UPDATE CASCADE,'+
   'FOREIGN KEY ('+cHid+') REFERENCES '+cHashs+'('+cHid+') '+
   'ON DELETE CASCADE ON UPDATE CASCADE,'+
   'CONSTRAINT Сonstrn_'+cFilesHashs+' UNIQUE ('+cFid+', '+cHid+') );';

  // ===========================================================================
  cSequence = 'SELECT ' + cSeqField + ' FROM sqlite_sequence where name = %s';

  // ---------------------------------------------------------------------------
  cDirID = 'select ' + cCid + ' from ' + cCATALOGS + ' where ' + cCname
    + ' = %s';
  cDirDelete = 'delete from ' + cCATALOGS + ' where ' + cCid + ' = %d';
  cDirInsert = 'INSERT INTO ' + cCATALOGS + ' (' + cCname + ') VALUES (%s)';

  // ---------------------------------------------------------------------------
  cFileID = 'select ' + cFid + ' from ' + cFILES + ' where ' + cFcid +
    ' = %d and ' + cFname + ' = %s';
  cFileDelete = 'delete from ' + cFILES + ' where ' + cFid + ' = %d';
  cFileInsert = 'INSERT INTO ' + cFILES + ' (' + cFcid + ', ' + cFname +
    ') VALUES (%d, %s);';

  cFileName = 'select distinct ' + cFid + ', ' + cCname + ', ' + cFname + ' from ' +
    cFILES + ' left join ' + cCATALOGS + ' on ' + cCid + ' = ' + cFcid;

  cFileNameUpdate = 'UPDATE ' + cFILES + ' SET ' + cFname + ' = %s WHERE ' +
    cFid + ' = %d ;';

  // ---------------------------------------------------------------------------
  cTagID = 'select ' + cTid + ' from ' + cTAGS + ' where ' + cTname + '= %s';
  cTagName = 'select ' + cTname + ' from ' + cTAGS + ' where ' + cTid + '= %d';
  cTagInsert = 'INSERT INTO ' + cTAGS + ' (' + cTname + ') VALUES (%s)';
  cTagDelete = 'delete from ' + cTAGS + ' where ' + cTid + ' = %d';
  cTagUpdate = 'UPDATE ' + cTAGS + ' SET ' + cTname + ' = %s WHERE ' + cTid
    + ' = %d';

  // ---------------------------------------------------------------------------
  cFileTagsSelect = 'select ' + cID + ' from ' + cFilesTags + ' where ' + cFid +
    ' = %d and ' + cTid + ' = %d';
  cFileTagsInsert = 'INSERT INTO ' + cFilesTags + ' (' + cFid + ', ' + cTid +
    ') VALUES (%d, %d)';
  cFileTagsDelete = 'delete from ' + cFilesTags + ' where ' + cID + ' = %d';

  cFileTagsLink = 'select t.' + cTid + ', t.' + cTname + ' from ' + cFilesTags +
    ' ft ' + 'inner join ' + cTAGS + ' t on t.' + cTid + ' = ft.' + cTid;

  cFileTagsList = 'select ' + cTid + ', ' + cTname + ' from ' + cTAGS;

  cFileTagsSearch = 'select distinct fl.' + cFid + ', ' + cCname + ', ' + cFname + ' from ' + cTAGS + ' tg ' +
   ' left join ' + cFilesTags + ' ft on ft.' + cTid + ' = tg.' + cTid +
   ' left join ' + cFILES + ' fl on fl.' + cFid + ' = ft.' + cFid +
   ' left join ' + cCATALOGS + ' ct on ct.' + cCid + ' = fl.' + cFcid;
  // + ' where tg.'+cTname+' = %s';

  // ---------------------------------------------------------------------------
  cDelete_CATALOGS = 'delete from ' + cCATALOGS + ' where ' + cCid +
    'in (select ' + cCid + ' from ' + cCATALOGS + ' left join ' + cFILES +
    ' on ' + cFcid + ' = ' + cCid + ' where ' + cFid + ' is null)';

implementation

end.
