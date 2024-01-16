unit uRecordHash;

interface

uses System.Types, System.Classes, Data.DB;


function RecordHashMD5(const AFields: TStringDynArray; const ADS: TDataSet): string; overload;

function RecordHashMD5(const ADS: TDataSet): string; overload;

implementation

uses Hash;

function HashMD5(const ASource: TMemoryStream): string;
var
  hash: THashMD5;
begin
  hash := THashMD5.Create;
  hash.Update(ASource.Memory, ASource.Size);
  result := hash.HashAsString;
end;


function RecordHashMD5(const AFields: TStringDynArray; const ADS: TDataSet): string; overload;
var mem: TMemoryStream;
    DataBytes: TArray<Byte>;
    i, L: Integer;
    ref: TField;
    IsNull: Boolean;
Begin
  Result:= '';
  if not Assigned(ADS) or
     not ADS.Active or
     (ADS.Fields.Count = 0) or
     (ADS.RecordCount = 0) or
     (Length(AFields) = 0) then Exit;

  mem:= TMemoryStream.Create;
  try
   for I := Low(AFields) to High(AFields) do
    Begin

     IsNull:= ADS.FieldByName( AFields[i] ).IsNull;
     if IsNull then
      mem.WriteData( Byte(1), 1)
     else
      mem.WriteData( Byte(0), 1);

     DataBytes:= ADS.FieldByName( AFields[i] ).AsBytes;
     L:= Length(DataBytes);
     if L > 0 then
      mem.WriteData( DataBytes[0], L)
     else
      mem.WriteData( Byte(0), 1);

    End;// for

   if mem.Size > 0 then
    Result:= HashMD5(mem);

  finally
   mem.Free;
  end;

End;



function RecordHashMD5(const ADS: TDataSet): string;
var SortedFieldList: TStringList;
    mem: TMemoryStream;
    DataBytes: TArray<Byte>;
    i, L: Integer;
    ref: TField;
    IsNull: Boolean;
Begin
  Result:= '';
  if not Assigned(ADS) or
     not ADS.Active or
     (ADS.Fields.Count = 0) or
     (ADS.RecordCount = 0) then Exit;

  SortedFieldList:= TStringList.Create;
  mem:= TMemoryStream.Create;
  Try
    for i := 0 to ADS.Fields.Count -1 do
     Begin
      ref:= ADS.Fields[i];
      SortedFieldList.AddObject(ref.FieldName, TObject(ref.DataType) );
     End;

    // Сортировать поля необходимо на случай если в одной базе было расширение схемы (поля добавлялись в конец),
    // а другая создавалась "с нуля" с другой последовательностью полей
    SortedFieldList.Sorted:= True;
    try
     for i := 0 to SortedFieldList.Count-1 do
      Begin

       IsNull:= ADS.FieldByName( SortedFieldList[i] ).IsNull;
       if IsNull then
        mem.WriteData( Byte(1), 1)
       else
        mem.WriteData( Byte(0), 1);

       DataBytes:= ADS.FieldByName( SortedFieldList[i] ).AsBytes;
       L:= Length(DataBytes);
       if L > 0 then
        mem.WriteData( DataBytes[0], L)
       else
        mem.WriteData( Byte(0), 1);

      End;// for

     if mem.Size > 0 then
      Result:= HashMD5(mem);

    finally
     mem.Free;
    end;

  Finally
   mem.Free;
   SortedFieldList.Free;
  End;

End;

end.
