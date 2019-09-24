{

  http://www.kansoftware.ru/?tid=5071

}

unit awMachMask; // © Alexandr Petrovich Sysoev

interface

uses Classes;

Function IsMatchMask(aText, aMask: pChar): Boolean; overload;
Function IsMatchMask(aText, aMask: String): Boolean; overload;


implementation

uses
  SysUtils;

Function IsMatchMask(aText, aMask: pChar): Boolean; overload;
begin
  Result := False;
  While True Do
  begin
    Case aMask^ of
      '*': // соответствует любому числу любых символов кроме конца строки
        begin
          // переместиться на очередной символ шаблона, при этом, подряд
          // идущие '*' эквивалентны одному, поэтому пропуск всех '*'
          repeat
            Inc(aMask);
          Until (aMask^ <> '*');
          // если за '*' следует любой символ кроме '?' то он должен совпасть
          // с символом в тексте. т.е. нужно пропустить все не совпадающие,
          // но не далее конца строки
          If aMask^ <> '?' then
            While (aText^ <> #0) And (aText^ <> aMask^) Do
              Inc(aText);

          If aText^ <> #0 Then
          begin // не конец строки, значит совпал символ
            // '*' 'жадный' шаблон поэтому попробуем отдать совпавший символ
            // ему. т.е. проверить совпадение продолжения строки с шаблоном,
            // начиная с того-же '*'. если продолжение совпадает, то
            If IsMatchMask(aText + 1, aMask - 1) Then
              Break; // это СОВПАДЕНИЕ
            // продолжение не совпало, значит считаем что здесь закончилось
            // соответствие '*'. Продолжим сопоставление со следующего
            // символа шаблона
            Inc(aMask);
            Inc(aText); // иначе переходим к следующему символу
          End
          Else If (aMask^ = #0) Then // конец строки и конец шаблона
            Break // это СОВПАДЕНИЕ
          Else // конец строки но не конец шаблона
            Exit // это НЕ СОВПАДЕНИЕ
        End;

      '?': // соответствует любому кроме конца строки
        If (aText^ = #0) Then // конец строки
          Exit // это НЕ СОВПАДЕНИЕ
        Else
        begin // иначе
          Inc(aMask);
          Inc(aText); // иначе переходим к следующему символу
        End;

    Else // символ в шаблоне должен совпасть с символом в строке
      If aMask^ <> aText^ Then // символы не совпали -
        Exit // это НЕ СОВПАДЕНИЕ
      Else
      begin // совпал очередной символ
        If (aMask^ = #0) Then // совпавший символ последний -
          Break; // это СОВПАДЕНИЕ
        Inc(aMask);
        Inc(aText); // иначе переходим к следующему символу
      End;
    End;
  End;
  Result := True;
End;

Function IsMatchMask(aText, aMask: String): Boolean; overload;
begin
  Result := IsMatchMask(pChar(aText), pChar(aMask));
End;

end.
