{
 Использовано https://k210.org/delphi/main/6/

 Запуск одной копии приложения.
}

unit OneApplicationRun;

interface

function GetMutex: THandle;
function GeUniqueMutexName: string;

implementation

uses
  Windows, Sysutils;

var
  UniqueMutexName : string = '';
  hMutex: THandle = 0;


function GetMutex: THandle;
Begin
  Result:= hMutex;
End;

function GeUniqueMutexName: string;
Begin
  Result:= UniqueMutexName;
End;


initialization
  UniqueMutexName := ExtractFileName(ParamStr(0));
  hMutex := OpenMutex(MUTEX_ALL_ACCESS, False, PChar(UniqueMutexName));
  if hMutex <> 0 then
  begin
    CloseHandle(hMutex);
    Halt;
  end;
  hMutex := CreateMutex(nil, False, PChar(UniqueMutexName));

finalization
  ReleaseMutex(hMutex);

end.
