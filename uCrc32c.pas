unit uCrc32c;

// Функции Crc32cFast и Crc32cSSE42 взяты из файла SynCrypto.pas проекта mORMot.

interface

// При инициализации проверяет поддержку инструкций SSE4.2 и использует Crc32cSSE42 или Crc32cFast
function Crc32c(crc: cardinal; buf: PAnsiChar; len: cardinal): cardinal;

// Опимизирована на асемблере
function Crc32cFast(crc: cardinal; buf: PAnsiChar; len: cardinal): cardinal;

// Опимизирована на асемблере с использованием инструкций SSE42
function Crc32cSSE42(crc: cardinal; buf: PAnsiChar; len: cardinal): cardinal;

// Проверяем есть ли поддержка инструкций SSE42
function SupportSSE42: Boolean;

implementation

const
  kernel32 = 'kernel32.dll';
  PF_SSE42_INSTRUCTIONS_AVAILABLE = $100000;

function IsProcessorFeaturePresent(ProcessorFeature: cardinal): LongBool;
  stdcall; external kernel32 name 'IsProcessorFeaturePresent';

type
  TCrc32tab = array [0 .. 7, Byte] of cardinal;
  TCrc32c = function(crc: cardinal; buf: PAnsiChar; len: cardinal): cardinal;

var
  crc32ctab: TCrc32tab;
  gCrc32c: TCrc32c = Crc32cFast;

function Crc32c(crc: cardinal; buf: PAnsiChar; len: cardinal): cardinal;
Begin
  Result := gCrc32c(crc, buf, len);
End;

function SupportSSE42: Boolean;
begin
  Result := IsProcessorFeaturePresent(PF_SSE42_INSTRUCTIONS_AVAILABLE);
end;

// function Crc32c(crc: cardinal; buf: PAnsiChar; len: cardinal): cardinal;
// var
// tab: ^TCrc32tab;
// begin
// tab := @crc32ctab;
// Result := not crc;
// if (buf <> nil) and (len > 0) then
// begin
// repeat
// if NativeUInt(buf) and 3 = 0 then // align to 4 bytes boundary
// break;
// Result := tab[0, Byte(Result xor ord(buf^))] xor (Result shr 8);
// dec(len);
// inc(buf);
// until len = 0;
// if len >= 4 then
// repeat
// Result := Result xor PCardinal(buf)^;
// inc(buf, 4);
// dec(len, 4);
// Result := tab[3, Byte(Result)] xor tab[2, Byte(Result shr 8)
// ] xor tab[1, Byte(Result shr 16)] xor tab[0, Result shr 24];
// until len < 4;
// while len > 0 do
// begin
// Result := tab[0, Byte(Result xor ord(buf^))] xor (Result shr 8);
// dec(len);
// inc(buf);
// end;
// end;
// Result := not Result;
// end;

function Crc32cFast(crc: cardinal; buf: PAnsiChar; len: cardinal): cardinal;
asm     // adapted from fast Aleksandr Sharahov version
  test    edx, edx
  jz      @ret
  neg     ecx
  jz      @ret
  not     eax
  push    ebx
@head:  test    dl, 3
  jz      @aligned
  movzx   ebx, byte[edx]
  inc     edx
  xor     bl, al
  shr     eax, 8
  xor     eax, dword ptr[ebx * 4 + crc32ctab]
  inc     ecx
  jnz     @head
  pop     ebx
  not     eax
  ret
@ret:   rep     ret
@aligned:
  sub     edx, ecx
  add     ecx, 8
  jg      @bodydone
  push    esi
  push    edi
  mov     edi, edx
  mov     edx, eax
@bodyloop:
  mov     ebx, [edi + ecx - 4]
  xor     edx, [edi + ecx - 8]
  movzx   esi, bl
  mov     eax, dword ptr[esi * 4 + crc32ctab + 1024 * 3]
  movzx   esi, bh
  xor     eax, dword ptr[esi * 4 + crc32ctab + 1024 * 2]
  shr     ebx, 16
  movzx   esi, bl
  xor     eax, dword ptr[esi * 4 + crc32ctab + 1024 * 1]
  movzx   esi, bh
  xor     eax, dword ptr[esi * 4 + crc32ctab + 1024 * 0]
  movzx   esi, dl
  xor     eax, dword ptr[esi * 4 + crc32ctab + 1024 * 7]
  movzx   esi, dh
  xor     eax, dword ptr[esi * 4 + crc32ctab + 1024 * 6]
  shr     edx, 16
  movzx   esi, dl
  xor     eax, dword ptr[esi * 4 + crc32ctab + 1024 * 5]
  movzx   esi, dh
  xor     eax, dword ptr[esi * 4 + crc32ctab + 1024 * 4]
  add     ecx, 8
  jg      @done
  mov     ebx, [edi + ecx - 4]
  xor     eax, [edi + ecx - 8]
  movzx   esi, bl
  mov     edx, dword ptr[esi * 4 + crc32ctab + 1024 * 3]
  movzx   esi, bh
  xor     edx, dword ptr[esi * 4 + crc32ctab + 1024 * 2]
  shr     ebx, 16
  movzx   esi, bl
  xor     edx, dword ptr[esi * 4 + crc32ctab + 1024 * 1]
  movzx   esi, bh
  xor     edx, dword ptr[esi * 4 + crc32ctab + 1024 * 0]
  movzx   esi, al
  xor     edx, dword ptr[esi * 4 + crc32ctab + 1024 * 7]
  movzx   esi, ah
  xor     edx, dword ptr[esi * 4 + crc32ctab + 1024 * 6]
  shr     eax, 16
  movzx   esi, al
  xor     edx, dword ptr[esi * 4 + crc32ctab + 1024 * 5]
  movzx   esi, ah
  xor     edx, dword ptr[esi * 4 + crc32ctab + 1024 * 4]
  add     ecx, 8
  jle     @bodyloop
  mov     eax, edx
@done:  mov     edx, edi
  pop     edi
  pop     esi
@bodydone:
  sub     ecx, 8
  jl      @tail
  pop     ebx
  not     eax
  ret
@tail:  movzx   ebx, byte[edx + ecx]
  xor     bl, al
  shr     eax, 8
  xor     eax, dword ptr[ebx * 4 + crc32ctab]
  inc     ecx
  jnz     @tail
  pop     ebx
  not     eax
end;

function Crc32cSSE42(crc: cardinal; buf: PAnsiChar; len: cardinal): cardinal;
asm // eax=crc, edx=buf, ecx=len
  not     eax
  test    ecx, ecx
  jz      @0
  test    edx, edx
  jz      @0
@3:     test    edx, 3
  jz      @8 // align to 4 bytes boundary
  {$IFDEF FPC_OR_UNICODE}
  crc32   eax, byte ptr[edx]
  {$ELSE}
  db      $F2, $0F, $38, $F0, $02
  {$ENDIF}
  inc     edx
  dec     ecx
  jz      @0
  test    edx, 3
  jnz     @3
@8:     push    ecx
  shr     ecx, 3
  jz      @2
@1:     {$IFDEF FPC_OR_UNICODE}
  crc32   eax, dword ptr[edx]
  crc32   eax, dword ptr[edx + 4]
  {$ELSE}
  db      $F2, $0F, $38, $F1, $02
  db      $F2, $0F, $38, $F1, $42, $04
  {$ENDIF}
  add     edx, 8
  dec     ecx
  jnz     @1
@2:     pop     ecx
  and     ecx, 7
  jz      @0
  cmp     ecx, 4
  jb      @4
  {$IFDEF FPC_OR_UNICODE}
  crc32   eax, dword ptr[edx]
  {$ELSE}
  db      $F2, $0F, $38, $F1, $02
  {$ENDIF}
  add     edx, 4
  sub     ecx, 4
  jz      @0
@4:     {$IFDEF FPC_OR_UNICODE}
  crc32   eax, byte ptr[edx]
  dec     ecx
  jz      @0
  crc32   eax, byte ptr[edx + 1]
  dec     ecx
  jz      @0
  crc32   eax, byte ptr[edx + 2]
  {$ELSE}
  db      $F2, $0F, $38, $F0, $02
  dec     ecx
  jz      @0
  db      $F2, $0F, $38, $F0, $42, $01
  dec     ecx
  jz      @0
  db      $F2, $0F, $38, $F0, $42, $02
  {$ENDIF}
@0:     not     eax
end;

procedure InitCRC32cTable;
var
  i, n: integer;
  crc: cardinal;
begin
  // initialize tables for crc32cfast() and SymmetricEncrypt/FillRandom
  for i := 0 to 255 do
  begin
    crc := i;
    for n := 1 to 8 do
      if (crc and 1) <> 0 then // polynom is not the same as with zlib's crc32()
        crc := (crc shr 1) xor $82F63B78
      else
        crc := crc shr 1;
    crc32ctab[0, i] := crc;
  end;

  for i := 0 to 255 do
  begin
    crc := crc32ctab[0, i];
    for n := 1 to high(crc32ctab) do
    begin
      crc := (crc shr 8) xor crc32ctab[0, Byte(crc)];
      crc32ctab[n, i] := crc;
    end;
  end;
end;

Procedure InitCrc32c;
Begin
  if SupportSSE42 then
    gCrc32c := Crc32cSSE42
  else
    gCrc32c := Crc32cFast;
end;

initialization

InitCRC32cTable;
InitCrc32c;

finalization

end.
