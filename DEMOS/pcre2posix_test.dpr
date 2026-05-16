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
*************************************************}

(* This program tests the POSIX wrapper to the PCRE2 regular expression library.
   This is a Delphi/Free Pascal port of pcre2posix_test.c *)

program pcre2posix_test;

{$APPTYPE CONSOLE}

uses
  SysUtils, uPCRE2POSIX;

const
  CAPCOUNT = 5;               { Number of captures supported }

var
  v: Boolean;

{ This vector contains compiler flags for each pattern that is tested. }
var
  cflags: array[0..4] of Integer = (
    0,           { Test 0 }
    REG_ICASE,   { Test 1 }
    0,           { Test 2 }
    REG_NEWLINE, { Test 3 }
    0            { Test 4 }
  );

{ This vector contains match flags for each pattern that is tested. }
var
  mflags: array[0..4] of Integer = (
    0,           { Test 0 }
    0,           { Test 1 }
    0,           { Test 2 }
    REG_NOTBOL,  { Test 3 }
    0            { Test 4 }
  );

{ Test data: pattern and subjects for each test case }
type
  TStringArray = array of PAnsiChar;

var
  data0_1: TStringArray;
  data2_3: TStringArray;
  data4: TStringArray;
  data: array[0..4] of TStringArray;

{ Expected results }
var
  results0: array[0..4] of Integer = (
    0,             { Compiler rc }
    0, 6, 11,      { 1st match }
    Ord(REG_NOMATCH)    { 2nd match }
  );

  results1: array[0..6] of Integer = (
    0,             { Compiler rc }
    0, 6, 11,      { 1st match }
    0, 6, 11       { 2nd match }
  );

  results2: array[0..11] of Integer = (
    0,             { Compiler rc }
    0, 0, 3, 0, 3, { 1st match }
    0, 0, 3, 0, 3, { 2nd match }
    Ord(REG_NOMATCH)    { 3rd match }
  );

  results3: array[0..7] of Integer = (
    0,                 { Compiler rc }
    0, 13, 16, 13, 16, { 1st match }
    Ord(REG_NOMATCH),       { 2nd match }
    Ord(REG_NOMATCH)        { 3rd match }
  );

  results4: array[0..0] of Integer = (
    Ord(REG_BADRPT)         { Compiler rc }
  );

  results: array[0..4] of PInteger;

var
  i, j, k: Integer;
  re: regex_t;
  match: array[0..CAPCOUNT-1] of regmatch_t;
  rc: Integer;
  pattern: PAnsiChar;
  subjects: TStringArray;
  rd: PInteger;
  buffer: array[0..255] of AnsiChar;
  subjectIdx: Integer;
  expectedRc: Integer;

begin
  { Initialize data arrays }
  SetLength(data0_1, 3);
  data0_1[0] := 'posix';
  data0_1[1] := 'lower posix';
  data0_1[2] := 'upper POSIX';

  SetLength(data2_3, 5);
  data2_3[0] := '(*LF)^(cat|dog)';
  data2_3[1] := 'catastrophic'#10'cataclysm';
  data2_3[2] := 'dogfight';
  data2_3[3] := 'no animals';
  data2_3[4] := nil;

  SetLength(data4, 2);
  data4[0] := '*badpattern';
  data4[1] := nil;

  data[0] := data0_1;
  data[1] := data0_1;
  data[2] := data2_3;
  data[3] := data2_3;
  data[4] := data4;

  { Initialize results pointers }
  results[0] := @results0;
  results[1] := @results1;
  results[2] := @results2;
  results[3] := @results3;
  results[4] := @results4;

  { Check for verbose mode }
  v := True;//(ParamCount >= 1) and (ParamStr(1) = '-v');

  if v then
    WriteLn('Test of pcre2posix.h without pcre2.h');

  for i := 0 to High(cflags) do
  begin
    pattern := data[i][0];
    rd := results[i];
    rc := regcomp(@re, pattern, cflags[i]);

    if v then
      WriteLn('Pattern: ', pattern, ' flags=0x', IntToHex(cflags[i], 2));

    if rc <> rd^ then
    begin
      WriteLn('Unexpected compile error ', rc, ' (expected ', rd^, ')');
      WriteLn('Pattern is: ', pattern);
    end;

    if rc <> 0 then
    begin
      regerror(rc, @re, buffer, SizeOf(buffer));
      if v then
        WriteLn('Compile error ', rc, ': ', buffer, ' (expected)');
      Continue;
    end;

    { Test each subject }
    for j := 1 to High(data[i]) do
    begin
      if data[i][j] = nil then
        Break;

      subjects := data[i];
      subjectIdx := j;
      expectedRc := rd^;

      rc := regexec(@re, subjects[subjectIdx], CAPCOUNT, @match, mflags[i]);

      if v then
      begin
        Write('Subject: ', subjects[subjectIdx]);
        WriteLn;
        Write('Return:  ', rc);
      end;

      Inc(rd);

      if rc <> rd^ then
      begin
        if v then
          WriteLn;
        WriteLn('Unexpected match error ', rc, ' (expected ', rd^, ')');
        WriteLn('Pattern is: ', pattern);
        WriteLn('Subject is: ', subjects[subjectIdx]);
      end;

      if rc = 0 then
      begin
        for k := 0 to CAPCOUNT - 1 do
        begin
          if match[k].rm_so < 0 then
            Continue;
          Inc(rd);
          if match[k].rm_so <> rd^ then
          begin
            if v then
              WriteLn;
            WriteLn('Mismatched results for successful match');
            WriteLn('Pattern is: ', pattern);
            WriteLn('Subject is: ', subjects[subjectIdx]);
            WriteLn('Result ', k, ': expected ', rd^, ' received ', match[k].rm_so);
          end;
          Inc(rd);
          if match[k].rm_eo <> rd^ then
          begin
            if v then
              WriteLn;
            WriteLn('Mismatched results for successful match');
            WriteLn('Pattern is: ', pattern);
            WriteLn('Subject is: ', subjects[subjectIdx]);
            WriteLn('Result ', k, ': expected ', rd^, ' received ', match[k].rm_eo);
          end;
          if v then
            Write(' (', k, ' ', match[k].rm_so, ' ', match[k].rm_eo, ')');
        end;
      end
      else
      begin
        regerror(rc, @re, buffer, SizeOf(buffer));
        if v then
          Write(': ', buffer, ' (expected)');
      end;

      if v then
        WriteLn;
    end;

    regfree(@re);
  end;

  if v then
    WriteLn('End of test');

  WriteLn('All tests passed!');
  readln
end.
