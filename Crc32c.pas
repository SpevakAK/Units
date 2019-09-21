unit Crc32c;

// CRC-32C (Castagnoli) Polynomial (Normal)  0x1EDC6F41
// https://blog.csdn.net/codegame/article/details/6540965
// https://uzzz.org/2011/06/13/9e5147d36716cbb152c986146eafae2a.html

interface

// uses Classes;

function _Crc32cX86(Data: PByte; aLength: Integer): Cardinal;
function _Crc32cSSE(Data: PByte; aLength: Integer): Cardinal; assembler;

implementation

const
  //CRCPOLY = $EDB88320;
  CRCPOLY = $1EDC6F41;
//  CRCPOLY = $82F63B78;
//  CRCPOLY = $8F6E37A0;

var
  _CRC32CTable: array [Byte] of Cardinal;

procedure BuildCRCTable;
var
  i, j: Word;
  r: LongWord;
begin
  FillChar(_CRC32CTable, SizeOf(_CRC32CTable), 0);
  for i := 0 to 255 do
  begin
    r := i shl 1;
    for j := 8 downto 0 do
      if (r and 1) <> 0 then
        r := (r Shr 1) xor CRCPOLY
      else
        r := r shr 1;
    _CRC32CTable[i] := r;
  end;
end;

function _Crc32cX86(Data: PByte; aLength: Integer): Cardinal;
{const
  _CRC32CTable: array [Byte] of Cardinal = ($00000000, $F26B8303, $E13B70F7,
    $1350F3F4, $C79A971F, $35F1141C, $26A1E7E8, $D4CA64EB, $8AD958CF, $78B2DBCC,
    $6BE22838, $9989AB3B, $4D43CFD0, $BF284CD3, $AC78BF27, $5E133C24, $105EC76F,
    $E235446C, $F165B798, $030E349B, $D7C45070, $25AFD373, $36FF2087, $C494A384,
    $9A879FA0, $68EC1CA3, $7BBCEF57, $89D76C54, $5D1D08BF, $AF768BBC, $BC267848,
    $4E4DFB4B, $20BD8EDE, $D2D60DDD, $C186FE29, $33ED7D2A, $E72719C1, $154C9AC2,
    $061C6936, $F477EA35, $AA64D611, $580F5512, $4B5FA6E6, $B93425E5, $6DFE410E,
    $9F95C20D, $8CC531F9, $7EAEB2FA, $30E349B1, $C288CAB2, $D1D83946, $23B3BA45,
    $F779DEAE, $05125DAD, $1642AE59, $E4292D5A, $BA3A117E, $4851927D, $5B016189,
    $A96AE28A, $7DA08661, $8FCB0562, $9C9BF696, $6EF07595, $417B1DBC, $B3109EBF,
    $A0406D4B, $522BEE48, $86E18AA3, $748A09A0, $67DAFA54, $95B17957, $CBA24573,
    $39C9C670, $2A993584, $D8F2B687, $0C38D26C, $FE53516F, $ED03A29B, $1F682198,
    $5125DAD3, $A34E59D0, $B01EAA24, $42752927, $96BF4DCC, $64D4CECF, $77843D3B,
    $85EFBE38, $DBFC821C, $2997011F, $3AC7F2EB, $C8AC71E8, $1C661503, $EE0D9600,
    $FD5D65F4, $0F36E6F7, $61C69362, $93AD1061, $80FDE395, $72966096, $A65C047D,
    $5437877E, $4767748A, $B50CF789, $EB1FCBAD, $197448AE, $0A24BB5A, $F84F3859,
    $2C855CB2, $DEEEDFB1, $CDBE2C45, $3FD5AF46, $7198540D, $83F3D70E, $90A324FA,
    $62C8A7F9, $B602C312, $44694011, $5739B3E5, $A55230E6, $FB410CC2, $092A8FC1,
    $1A7A7C35, $E811FF36, $3CDB9BDD, $CEB018DE, $DDE0EB2A, $2F8B6829, $82F63B78,
    $709DB87B, $63CD4B8F, $91A6C88C, $456CAC67, $B7072F64, $A457DC90, $563C5F93,
    $082F63B7, $FA44E0B4, $E9141340, $1B7F9043, $CFB5F4A8, $3DDE77AB, $2E8E845F,
    $DCE5075C, $92A8FC17, $60C37F14, $73938CE0, $81F80FE3, $55326B08, $A759E80B,
    $B4091BFF, $466298FC, $1871A4D8, $EA1A27DB, $F94AD42F, $0B21572C, $DFEB33C7,
    $2D80B0C4, $3ED04330, $CCBBC033, $A24BB5A6, $502036A5, $4370C551, $B11B4652,
    $65D122B9, $97BAA1BA, $84EA524E, $7681D14D, $2892ED69, $DAF96E6A, $C9A99D9E,
    $3BC21E9D, $EF087A76, $1D63F975, $0E330A81, $FC588982, $B21572C9, $407EF1CA,
    $532E023E, $A145813D, $758FE5D6, $87E466D5, $94B49521, $66DF1622, $38CC2A06,
    $CAA7A905, $D9F75AF1, $2B9CD9F2, $FF56BD19, $0D3D3E1A, $1E6DCDEE, $EC064EED,
    $C38D26C4, $31E6A5C7, $22B65633, $D0DDD530, $0417B1DB, $F67C32D8, $E52CC12C,
    $1747422F, $49547E0B, $BB3FFD08, $A86F0EFC, $5A048DFF, $8ECEE914, $7CA56A17,
    $6FF599E3, $9D9E1AE0, $D3D3E1AB, $21B862A8, $32E8915C, $C083125F, $144976B4,
    $E622F5B7, $F5720643, $07198540, $590AB964, $AB613A67, $B831C993, $4A5A4A90,
    $9E902E7B, $6CFBAD78, $7FAB5E8C, $8DC0DD8F, $E330A81A, $115B2B19, $020BD8ED,
    $F0605BEE, $24AA3F05, $D6C1BC06, $C5914FF2, $37FACCF1, $69E9F0D5, $9B8273D6,
    $88D28022, $7AB90321, $AE7367CA, $5C18E4C9, $4F48173D, $BD23943E, $F36E6F75,
    $0105EC76, $12551F82, $E03E9C81, $34F4F86A, $C69F7B69, $D5CF889D, $27A40B9E,
    $79B737BA, $8BDCB4B9, $988C474D, $6AE7C44E, $BE2DA0A5, $4C4623A6, $5F16D052,
    $AD7D5351);}

var
  i: Cardinal;
begin
  Result := $FFFFFFFF;
  for i := 0 to aLength - 1 do
  begin
    Result := (Result shr 8) xor _CRC32CTable[(Result and $FF) xor Data^];
    Inc(Data);
  end;
  Result := not Result;
end;

function _Crc32cSSE(Data: PByte; aLength: Integer): Cardinal;
asm
  push esi
  push edx
  push ecx
  mov esi,eax
  mov eax,$FFFFFFFF
  test edx,edx
  jz @Exit
  test esi,esi
  jz @Exit
  mov ecx,edx
  shr ecx, 2
  test ecx,ecx
  jz @Exit
  xor edx,edx
@Alignment:
  crc32 eax,[edx*4+esi]
  inc edx
  cmp edx,ecx
  jb @Alignment
@Exit:
  not eax
  pop ecx
  pop edx
  pop esi
end;


initialization
 BuildCRCTable;

end.
