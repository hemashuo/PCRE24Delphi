{-----------------------------------------------------------------------------
MIT License

Copyright (c) 2026 hemashuo 和码说

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*************************************************
*      Perl-Compatible Regular Expressions       *
*************************************************/

/* PCRE2 is a library of functions to support regular expressions whose syntax
and semantics are as close as possible to those of the Perl 5 language. This is
the public header file to be #included by applications that call PCRE2 via the
POSIX wrapper interface.

                       Written by Philip Hazel
     Original API code Copyright (c) 1997-2012 University of Cambridge
          New API code Copyright (c) 2016-2023 University of Cambridge

-----------------------------------------------------------------------------
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

    * Neither the name of the University of Cambridge nor the names of its
      contributors may be used to endorse or promote products derived from
      this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
-----------------------------------------------------------------------------
* This file has been converted from pcre2posix.h to Pascal
*/}

unit uPCRE2POSIX;

{$IFDEF FPC}
  {$mode objfpc}{$H+}
{$ENDIF}

//Delphi 2010 (Ver 21.0)
{$IFDEF CompilerVersion >= 21.0}
  {$DEFINE DELAYED_LOAD}
{$ENDIF}

interface

uses
  SysUtils;

const
  {$IFDEF MSWINDOWS}
  LIB_PCRE2_POSIX = 'libpcre2-posix-3.dll';
  {$ELSE}
    {$IFDEF DARWIN}
    LIB_PCRE2_POSIX = 'libpcre2-posix-3.dylib';
    {$ELSE}
    LIB_PCRE2_POSIX = 'libpcre2-posix-3.so';
    {$ENDIF}
  {$ENDIF}

  { Options, mostly defined by POSIX, but with some extras. }
  REG_ICASE     = $0001;  { Maps to PCRE2_CASELESS }
  REG_NEWLINE   = $0002;  { Maps to PCRE2_MULTILINE }
  REG_NOTBOL    = $0004;  { Maps to PCRE2_NOTBOL }
  REG_NOTEOL    = $0008;  { Maps to PCRE2_NOTEOL }
  REG_DOTALL    = $0010;  { NOT defined by POSIX; maps to PCRE2_DOTALL }
  REG_NOSUB     = $0020;  { Do not report what was matched }
  REG_UTF       = $0040;  { NOT defined by POSIX; maps to PCRE2_UTF }
  REG_STARTEND  = $0080;  { BSD feature: pass subject string by so,eo }
  REG_NOTEMPTY  = $0100;  { NOT defined by POSIX; maps to PCRE2_NOTEMPTY }
  REG_UNGREEDY  = $0200;  { NOT defined by POSIX; maps to PCRE2_UNGREEDY }
  REG_UCP       = $0400;  { NOT defined by POSIX; maps to PCRE2_UCP }
  REG_PEND      = $0800;  { GNU feature: pass end pattern by re_endp }
  REG_NOSPEC    = $1000;  { Maps to PCRE2_LITERAL }

  { This is not used by PCRE2, but by defining it we make it easier
    to slot PCRE2 into existing programs that make POSIX calls. }
  REG_EXTENDED  = 0;

type

{$IFNDEF NativeUInt}
    NativeUInt = Cardinal;
{$ENDIF}

  { Error values. Not all these are relevant or used by the wrapper. }
  TRegErrCode = (
    REG_ASSERT = 1,   { internal error ? }
    REG_BADBR,        { invalid repeat counts in }
    REG_BADPAT,       { pattern error }
    REG_BADRPT,       { ? * + invalid }
    REG_EBRACE,       { unbalanced }
    REG_EBRACK,       { unbalanced [] }
    REG_ECOLLATE,     { collation error - not relevant }
    REG_ECTYPE,       { bad class }
    REG_EESCAPE,      { bad escape sequence }
    REG_EMPTY,        { empty expression }
    REG_EPAREN,       { unbalanced () }
    REG_ERANGE,       { bad range inside [] }
    REG_ESIZE,        { expression too big }
    REG_ESPACE,       { failed to get memory }
    REG_ESUBREG,      { bad back reference }
    REG_INVARG,       { bad argument }
    REG_NOMATCH       { match failed }
  );

  { The structure representing a compiled regular expression.
    It is also used for passing the pattern end pointer when REG_PEND is set. }
  pregex_t = ^regex_t;	
  regex_t = record
    re_pcre2_code: Pointer;
    re_match_data: Pointer;
    re_endp: PAnsiChar;
    re_nsub: NativeUInt;
    re_erroffset: NativeUInt;
    re_cflags: Integer;
  end;

  { The structure in which a captured offset is returned. }
  regoff_t = Integer;

  pregmatch_t = ^regmatch_t;
  regmatch_t = record
    rm_so: regoff_t;
    rm_eo: regoff_t;
  end;

{ * When an application links to a PCRE2 DLL in Windows, the symbols that are
	imported have to be identified as such. When building PCRE2, the appropriate
	export settings are needed, and are set in pcre2posix.c before including this
	file. So, we don't change existing definitions of PCRE2POSIX_EXP_DECL.

	By default, we use the standard "extern" declarations. * 
	When compiling with the MSVC compiler, it is sometimes necessary to include
	a "calling convention" before exported function names. For example:

	  void __cdecl function(....)

	might be needed. In order to make this easy, all the exported functions have
	PCRE2_CALL_CONVENTION just before their names.

	PCRE2 normally uses the platform's standard calling convention, so this should
	not be set unless you know you need it. *}
	
{* The functions. The actual code is in functions with pcre2_xxx names for
	uniqueness. POSIX names are provided as macros for API compatibility with POSIX
	regex functions. It's done this way to ensure to they are always linked from
	the PCRE2 library and not by accident from elsewhere (regex_t differs in size
	elsewhere). *}
	
function pcre2_regcomp(regex: pregex_t; const pattern: PAnsiChar; flags: Integer): Integer; cdecl; external LIB_PCRE2_POSIX{$IFDEF DELAYED_LOAD} delayed{$ENDIF};
function pcre2_regexec(const regex: pregex_t; const subject: PAnsiChar; nmatches: NativeUInt; pmatches: pregmatch_t; eflags: Integer): Integer; cdecl; external LIB_PCRE2_POSIX{$IFDEF DELAYED_LOAD} delayed{$ENDIF};
function pcre2_regerror(err_code: Integer; const regex: pregex_t; buffer: PAnsiChar; buffer_len: NativeUInt): NativeUInt; cdecl; external LIB_PCRE2_POSIX{$IFDEF DELAYED_LOAD} delayed{$ENDIF};
procedure pcre2_regfree(regex: pregex_t); cdecl; external LIB_PCRE2_POSIX{$IFDEF DELAYED_LOAD} delayed{$ENDIF};

function regcomp(regex: pregex_t; const pattern: PAnsiChar; flags: Integer): Integer; cdecl; external LIB_PCRE2_POSIX name 'pcre2_regcomp'{$IFDEF DELAYED_LOAD} delayed{$ENDIF};
function regexec(const regex: pregex_t; const subject: PAnsiChar; nmatches: NativeUInt; pmatches: pregmatch_t; eflags: Integer): Integer; cdecl; external LIB_PCRE2_POSIX name 'pcre2_regexec'{$IFDEF DELAYED_LOAD} delayed{$ENDIF};
function regerror(err_code: Integer; const regex: pregex_t; buffer: PAnsiChar; buffer_len: NativeUInt): NativeUInt; cdecl; external LIB_PCRE2_POSIX name 'pcre2_regerror'{$IFDEF DELAYED_LOAD} delayed{$ENDIF};
procedure regfree(regex: pregex_t); cdecl; external LIB_PCRE2_POSIX name 'pcre2_regfree';

{ * Debian had a patch that used different names. These are now here to save
	them having to maintain their own patch, but are not documented by PCRE2. * }
	
function PCRE2regcomp(regex: pregex_t; const pattern: PAnsiChar; flags: Integer): Integer; cdecl; external LIB_PCRE2_POSIX name 'pcre2_regcomp'{$IFDEF DELAYED_LOAD} delayed{$ENDIF};
function PCRE2regexec(const regex: pregex_t; const subject: PAnsiChar; nmatches: NativeUInt; pmatches: pregmatch_t; eflags: Integer): Integer; cdecl; external LIB_PCRE2_POSIX name 'pcre2_regexec'{$IFDEF DELAYED_LOAD} delayed{$ENDIF};
function PCRE2regerror(err_code: Integer; const regex: pregex_t; buffer: PAnsiChar; buffer_len: NativeUInt): NativeUInt; cdecl; external LIB_PCRE2_POSIX name 'pcre2_regerror'{$IFDEF DELAYED_LOAD} delayed{$ENDIF};
procedure PCRE2regfree(regex: pregex_t); cdecl; external LIB_PCRE2_POSIX name 'pcre2_regfree'{$IFDEF DELAYED_LOAD} delayed{$ENDIF};

implementation

end.