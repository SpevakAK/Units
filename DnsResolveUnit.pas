// Создано по мотивам
// https://github.com/magicmonty/delphi-code-coverage/blob/master/3rdParty/JWAPI/jwapi2.2a/Win32API/JwaWinDNS.pas
// и
// https://stackoverflow.com/questions/6444102/look-up-if-mail-server-exists-for-list-of-emails
//


// Разыменование доменного имени (только A и AAAA записи)
unit DnsResolveUnit;

interface

uses Windows, Classes;


Function ResolveInitialized: Boolean;

// Возврощает первый IP из нескольких
Function ResolveDomainNameToIPv4(const ADomainName: string): string;
Function ResolveDomainNameToIPv6(const ADomainName: string): string;

// Возврощает список IP адресов
// !!! По непонятной (пока) причине в список попадают ip-адреса NS-серверов !!!

Function ResolveDomainNameListIPv4(const ADomainName: string; const AList: TStrings): Boolean;
Function ResolveDomainNameListIPv6(const ADomainName: string; const AList: TStrings): Boolean;


implementation

uses System.SysUtils, System.StrUtils;

type
  DNS_STATUS = Integer;
  IP4_ADDRESS = DWORD;
  IP6_ADDRESS = array [0..2] of UInt64;

  DNS_FREE_TYPE = (  DnsFreeFlat = 0, DnsFreeRecordList, DnsFreeParsedMessageFields);

  _DNS_RECORD_FLAGS = packed record
     case Boolean of
     True: (DW: DWORD);
     False: (DNS_RECORD_FLAGS: DWORD);
   end;

   // https://learn.microsoft.com/ru-ru/windows/win32/api/windns/ns-windns-dns_a_data
   DNS_A_DATA = packed record
     case Boolean of
       True: (IpAddress: IP4_ADDRESS);
       False: (Bytes:array[0..3] of Byte);
   end;

   // https://learn.microsoft.com/ru-ru/windows/win32/api/windns/ns-windns-dns_aaaa_data
   DNS_AAAA_DATA = packed record
     case Boolean of
       True: (Ip6Address: IP6_ADDRESS);
       False: (Bytes:array[0..16] of Byte);
   end;

   _DNS_RECORD_DATA_UNION = packed record
     case Integer of
       0:  (A   : DNS_A_DATA    );
       42: (AAAA: DNS_AAAA_DATA );
   end;

   // https://learn.microsoft.com/ru-ru/windows/win32/api/windns/ns-windns-dns_recordw
   PDNS_RECORD = ^TDNS_RECORD;
   TDNS_RECORD = packed record
     NextRecord: PDNS_RECORD;
     pName: PWChar;
     wType: Word;
     wDataLength: Word;
     Flags: _DNS_RECORD_FLAGS;
     dwTtl: DWORD;
     dwReserved: DWORD;
     Data: _DNS_RECORD_DATA_UNION;

//     function ToString: string;
   end;

   TDnsQuery = function (lpstrName: PWChar; wType: Word; Options: DWORD; pExtra: Pointer; out ppQueryResultsSet: PDNS_RECORD; pReserved: Pointer): DNS_STATUS; stdcall;
   TDnsRecordListFree = procedure (pRecordList: PDNS_RECORD; FreeType: DNS_FREE_TYPE); stdcall;



// https://learn.microsoft.com/en-us/windows/win32/dns/dns-constants
const
  DnsApiDLL = 'dnsapi.dll';

// DNS record types
  DNS_TYPE_A      = $0001;
  DNS_TYPE_AAAA 	= $001c;


// DNS query options
  DNS_QUERY_STANDARD    =	$00000000;

//  DNS_QUERY_BYPASS_CACHE  =	$00000008; // 	Bypasses the resolver cache on the lookup.
//
//  DNS_QUERY_NO_WIRE_QUERY = $00000010; // 	Directs DNS to perform a query on the local cache only.
//                                       //  Windows 2000 Server and Windows 2000 Professional: This value is not supported.
//                                       //  For similar functionality, use DNS_QUERY_CACHE_ONLY.
//
//  DNS_QUERY_NO_HOSTS_FILE =	$00000040; //	Prevents the DNS query from consulting the HOSTS file.
//                                       // Windows 2000 Server and Windows 2000 Professional: This value is not supported.

var
  GHandle: HMODULE = 0;
  GResolveInitialized: Boolean = False;

  DnsQuery_W: TDnsQuery = nil;
  DnsRecordListFree: TDnsRecordListFree = nil;



procedure DNSResolveInitialization;
begin
  GResolveInitialized:= False;
  GHandle := LoadLibrary(DnsApiDLL);
  if GHandle <> 0 then
  begin
    @DnsQuery_W        := GetProcAddress(GHandle, 'DnsQuery_W');
    @DnsRecordListFree := GetProcAddress(GHandle, 'DnsRecordListFree');

    GResolveInitialized:= (@DnsQuery_W <> nil) and (@DnsRecordListFree <> nil);
    if not GResolveInitialized then
     Begin
      FreeLibrary(GHandle);
      GHandle:= 0;
     End;
  end;

End;

procedure DNSResolveFinalization;
Begin
  if GHandle <> 0 then
   FreeLibrary(GHandle);

  GResolveInitialized:= False;
End;

Function ResolveInitialized: Boolean;
Begin
  Result:= GResolveInitialized;
End;

// Для IPv4
function BytesToStr( const ASource: array of Byte; ADataLength: Word): string;
var i: Integer;
    tmpList:TStringList;
Begin
  Result:= '';
  if not(Length(ASource) = 4) or not(ADataLength = 4) then Exit;

  tmpList:= TStringList.Create;
  try
    tmpList.Delimiter:= '.';

    i:= 0;
    while i < ADataLength do
    Begin
     tmpList.Add( IntToStr(ASource[i]) );
     Inc(i);
    End;

    Result:= tmpList.DelimitedText;
  finally
   tmpList.Free;
  end;

End;

// Для IPv6
function BytesToHexStr( const ASource: array of Byte; ADataLength: Word): string;
var i: Integer;
    tmpList:TStringList;
Begin
  Result:='';
  if not(Length(ASource) = 17) or not (ADataLength = 16) then Exit;

  tmpList:= TStringList.Create;
  try
    tmpList.Delimiter:= ':';

    i:= 0;
    while i < ADataLength do
    Begin
     tmpList.Add( IntToHex(ASource[i], 2) + IntToHex(ASource[i+1], 2) );
     Inc(i, 2);
    End;

    Result:= tmpList.DelimitedText;
  finally
   tmpList.Free;
  end;

End;


Function ResolveDomainNameToIPv4(const ADomainName: string): string;
var DNS_REC: PDNS_RECORD;
begin
  Result:= '';
  if not GResolveInitialized or (Trim(ADomainName) = EmptyStr) then Exit;

  if DnsQuery_W(PWChar(ADomainName), DNS_TYPE_A, DNS_QUERY_STANDARD, nil, DNS_REC, nil) = 0 then
  try
   if Assigned(DNS_REC) then
    Result:= BytesToStr(DNS_REC.Data.A.Bytes, DNS_REC.wDataLength);

  finally
    DnsRecordListFree(DNS_REC, DnsFreeRecordList);
  end;

End;

Function ResolveDomainNameToIPv6(const ADomainName: string): string;
var DNS_REC: PDNS_RECORD;
begin
  Result:= '';
  if not GResolveInitialized or (Trim(ADomainName) = EmptyStr) then Exit;

  if DnsQuery_W(PWChar(ADomainName), DNS_TYPE_AAAA, DNS_QUERY_STANDARD, nil, DNS_REC, nil) = 0 then
  try
   if Assigned(DNS_REC) then
    Result:= BytesToHexStr(DNS_REC.Data.AAAA.Bytes, DNS_REC.wDataLength) ;

  finally
   DnsRecordListFree(DNS_REC, DnsFreeRecordList);
  end;

End;

Function ResolveDomainNameListIPv4(const ADomainName: string; const AList: TStrings): Boolean;
var DNS_REC: PDNS_RECORD;
    Iterate_REC: PDNS_RECORD;
    IPStr: string;
begin
  Result:= False;
  if not GResolveInitialized or not Assigned(AList) or (Trim(ADomainName) = EmptyStr) then Exit;

  if DnsQuery_W(PWChar(ADomainName), DNS_TYPE_A, DNS_QUERY_STANDARD, nil, DNS_REC, nil) = 0 then
  try

    Iterate_REC:= DNS_REC;
    while Assigned(Iterate_REC) do
    begin
      if (Iterate_REC.wType = DNS_TYPE_A) and
         (Iterate_REC.Flags.DW <> 8203)  then  // <- Значение 8203 определено опытным путём,
                                               //  пока не пойму почему попадают IP адреса NS-серверов
      Begin
        IPStr:= BytesToStr(Iterate_REC.Data.A.Bytes, Iterate_REC.wDataLength);
        if IPStr <> EmptyStr then
         AList.Add( IPStr );
//         AList.Add( Iterate_REC.ToString );
      End;

      Iterate_REC := Iterate_REC.NextRecord;
    end;

    Result:= True;
  finally
    DnsRecordListFree(DNS_REC, DnsFreeRecordList);
  end;// while

end;

Function ResolveDomainNameListIPv6(const ADomainName: string; const AList: TStrings): Boolean;
var DNS_REC: PDNS_RECORD;
    Iterate_REC: PDNS_RECORD;
    IPStr: string;
begin
  Result:= False;
  if not GResolveInitialized or not Assigned(AList) or (Trim(ADomainName) = EmptyStr) then Exit;

  if DnsQuery_W(PWChar(ADomainName), DNS_TYPE_AAAA, DNS_QUERY_STANDARD, nil, DNS_REC, nil) = 0 then
  try

    Iterate_REC:= DNS_REC;
    while Assigned(Iterate_REC) do
    begin
      if (Iterate_REC.wType = DNS_TYPE_AAAA) and
         (Iterate_REC.Flags.DW <> 8203)  then  // <- Значение 8203 определено опытным путём,
                                               // пока не пойму почему попадают IP адреса NS-серверов
      Begin
       IPStr:= BytesToHexStr(Iterate_REC.Data.AAAA.Bytes, Iterate_REC.wDataLength);
       if IPStr <> EmptyStr then
        AList.Add( IPStr );
//        AList.Add( Iterate_REC.ToString );
      End;

      Iterate_REC := Iterate_REC.NextRecord;
    end;// while

    Result:= True;
  finally
    DnsRecordListFree(DNS_REC, DnsFreeRecordList);
  end;

End;

//{ DNS_RECORD }
//
//function TDNS_RECORD.ToString: string;
//begin
//  Result:= 'Name: ' + String(pName) + '     Type: ' +  wType.ToString + ' DataLength: ' + wDataLength.ToString+
//           '  Flags.DW: ' + Flags.DW.ToString + '   Flags.DNS_RECORD_FLAGS: '+ Flags.DNS_RECORD_FLAGS.ToString +
//           '  TTL: ' + dwTtl.ToString;
//
//  case wType of
//   DNS_TYPE_A    : Result:= Result + '  IPv4: ' + BytesToStr(Data.A.Bytes, wDataLength);
//   DNS_TYPE_AAAA : Result:= Result + '  IPv6: ' + BytesToHexStr(Data.AAAA.Bytes, wDataLength);
//  end;
//
//
//end;

initialization
  DNSResolveInitialization;

finalization
  DNSResolveFinalization;




end.
