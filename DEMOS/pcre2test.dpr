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
*             PCRE2 testing program              *
*************************************************}

(* This program tests the PCRE2 Delphi binding.
   Demonstrates: compile, match, JIT, substitution, etc. *)

program pcre2test;

{$APPTYPE CONSOLE}

uses
  SysUtils, uPCRE2;

var
  i: Integer;
  rc: Integer;
  errorcode: Integer;
  erroroffset: PCRE2_SIZE;
  code: pcre2_code_8;
  match_data: pcre2_match_data_8;
  ovector, c_ovector, n_ovector: PPCRE2_SIZE;
  ovecount: Cardinal;
  subject: PAnsiChar;
  pattern: PAnsiChar;
  output: array[0..511] of AnsiChar;
  output_len: PCRE2_SIZE;

{ Test helper }
procedure TestMatch(const APattern, ASubject: PAnsiChar; AOptions: Cardinal = 0);
begin
    
  WriteLn('========================================');
  WriteLn('Pattern: ', APattern);
  WriteLn('Subject: ', ASubject);
  WriteLn('Options: 0x', IntToHex(AOptions, 8));
  WriteLn('----------------------------------------');

  { Compile the pattern }
  code := pcre2_compile_8(
    PCRE2_SPTR8(APattern),
    PCRE2_SIZE(StrLen(APattern)),
    AOptions,
    @errorcode,
    @erroroffset,
    nil
  );

  if code = nil then
  begin
    pcre2_get_error_message_8(errorcode, PPCRE2_UCHAR8(@output), Length(output));
    WriteLn('Compile error ', errorcode, ' at offset ', erroroffset, ': ', output);
    Exit;
  end;
  WriteLn('Compiled successfully!');

  { Create match data }
  match_data := pcre2_match_data_create_from_pattern_8(code, nil);
  if match_data = nil then
  begin
    WriteLn('Failed to create match data');
    pcre2_code_free_8(code);
    Exit;
  end;

  { Execute match }
  rc := pcre2_match_8(
    code,
    PCRE2_SPTR8(ASubject),
    PCRE2_SIZE(StrLen(ASubject)),
    0,
    AOptions,
    match_data,
    nil
  );

  if rc < 0 then
  begin
    if rc = PCRE2_ERROR_NOMATCH then
      WriteLn('No match')
    else
    begin
      pcre2_get_error_message_8(rc, PPCRE2_UCHAR8(@output), Length(output));
      WriteLn('Match error ', rc, ': ', output);
    end;
  end
  else
  begin
    ovecount := pcre2_get_ovector_count_8(match_data);
    ovector := pcre2_get_ovector_pointer_8(match_data);
    WriteLn('Match found! (', ovecount, ' capturing groups)');

    c_ovector := ovector;
    n_ovector := ovector;
    for i := 0 to Pred(ovecount) do
    begin
      Inc(c_ovector, 2*i);
      Inc(n_ovector, (2*i + 1));
      WriteLn('  Group ', i, ': [', c_ovector^, '..', n_ovector^, ') = ''',
        Copy(ASubject, c_ovector^ + 1, n_ovector^ - c_ovector^), '''');
    end;
  end;

  { Clean up }
  pcre2_match_data_free_8(match_data);
  pcre2_code_free_8(code);
  WriteLn;
end;

{ Test JIT compilation }
procedure TestJIT(const APattern, ASubject: PAnsiChar);
var
  jit_stack: pcre2_jit_stack_8;
  mcontext: pcre2_match_context_8;
  c_ovector, n_ovector: PPCRE2_SIZE;
begin
  WriteLn('========================================');
  WriteLn('JIT Test');
  WriteLn('========================================');

  { Compile with JIT }
  code := pcre2_compile_8(
    PCRE2_SPTR8(APattern),
    PCRE2_SIZE(StrLen(APattern)),
    0,
    @errorcode,
    @erroroffset,
    nil
  );

  if code = nil then
  begin
    pcre2_get_error_message_8(errorcode, PPCRE2_UCHAR8(@output), Length(output));
    WriteLn('Compile error: ', output);
    Exit;
  end;

  { JIT compile }
  rc := pcre2_jit_compile_8(code, 0);
  if rc < 0 then
  begin
    WriteLn('JIT compile error: ', rc);
    pcre2_code_free_8(code);
    Exit;
  end;
  WriteLn('JIT compiled successfully!');

  { Create match data and context }
  match_data := pcre2_match_data_create_from_pattern_8(code, nil);
  mcontext := pcre2_match_context_create_8(nil);

  { Create JIT stack }
  jit_stack := pcre2_jit_stack_create_8(4096, 65536, nil);
  pcre2_jit_stack_assign_8(mcontext, nil, nil);

  { Match with JIT }
  rc := pcre2_jit_match_8(
    code,
    PCRE2_SPTR8(ASubject),
    PCRE2_SIZE(StrLen(ASubject)),
    0,
    0,
    match_data,
    mcontext
  );

  if rc >= 0 then
  begin
    ovecount := pcre2_get_ovector_count_8(match_data);
    ovector := pcre2_get_ovector_pointer_8(match_data);

    c_ovector := ovector;
    n_ovector := ovector;
    Inc(n_ovector);
    
    WriteLn('JIT Match found! Group 0: [', c_ovector^, '..', n_ovector^, ')');
  end
  else if rc = PCRE2_ERROR_NOMATCH then
    WriteLn('JIT: No match')
  else
    WriteLn('JIT match error: ', rc);

  { Clean up }
  pcre2_jit_stack_free_8(jit_stack);
  pcre2_match_context_free_8(mcontext);
  pcre2_match_data_free_8(match_data);
  pcre2_code_free_8(code);
  WriteLn;
end;

{ Test substitution }
procedure TestSubstitute(const APattern, ASubject, AReplacement: PAnsiChar);
begin
  WriteLn('========================================');
  WriteLn('Substitution Test');
  WriteLn('========================================');
  WriteLn('Pattern: ', APattern);
  WriteLn('Subject: ', ASubject);
  WriteLn('Replace: ', AReplacement);
  WriteLn('----------------------------------------');

  { Compile }
  code := pcre2_compile_8(
    PCRE2_SPTR8(APattern),
    PCRE2_SIZE(StrLen(APattern)),
    0,
    @errorcode,
    @erroroffset,
    nil
  );

  if code = nil then
  begin
    pcre2_get_error_message_8(errorcode, PPCRE2_UCHAR8(@output), Length(output));
    WriteLn('Compile error: ', output);
    Exit;
  end;

  { Create match data }
  match_data := pcre2_match_data_create_from_pattern_8(code, nil);

  { Substitute }
  output_len := PCRE2_SIZE(Length(output));
  rc := pcre2_substitute_8(
    code,
    PCRE2_SPTR8(ASubject),
    PCRE2_SIZE(StrLen(ASubject)),
    0,
    0,
    match_data,
    nil,
    PCRE2_SPTR8(AReplacement),
    PCRE2_SIZE(StrLen(AReplacement)),
    PPCRE2_UCHAR8(@output),
    @output_len
  );

  if rc >= 0 then
  begin
    output[output_len] := #0;
    WriteLn('Result: ', output);
  end
  else
  begin
    pcre2_get_error_message_8(rc, PPCRE2_UCHAR8(@output), Length(output));
    WriteLn('Substitute error: ', output);
  end;

  pcre2_match_data_free_8(match_data);
  pcre2_code_free_8(code);
  WriteLn;
end;

{ Test error handling }
procedure TestError;
begin
  WriteLn('========================================');
  WriteLn('Error Handling Test');
  WriteLn('========================================');

  { Try to compile invalid pattern }
  code := pcre2_compile_8(
    PCRE2_SPTR8(PAnsiChar('(*BAD')),
    5,
    0,
    @errorcode,
    @erroroffset,
    nil
  );

  if code = nil then
  begin
    pcre2_get_error_message_8(errorcode, PPCRE2_UCHAR8(@output), Length(output));
    WriteLn('Expected error: ', output);
    WriteLn('Error code: ', errorcode);
    WriteLn('Error offset: ', erroroffset);
  end
  else
  begin
    WriteLn('ERROR: Should have failed!');
    pcre2_code_free_8(code);
  end;
  WriteLn;
end;

{ Test configuration }
procedure TestConfig;
var
  val: Integer;
  buf: array[0..63] of AnsiChar;
begin
  WriteLn('========================================');
  WriteLn('Configuration Test');
  WriteLn('========================================');

  pcre2_config_8(PCRE2_CONFIG_VERSION, @buf);
  WriteLn('Version: ', buf);

  pcre2_config_8(PCRE2_CONFIG_UNICODE_VERSION, @buf);
  WriteLn('Unicode Version: ', buf);

  pcre2_config_8(PCRE2_CONFIG_JIT, @val);
  WriteLn('JIT Support: ', val);

  pcre2_config_8(PCRE2_CONFIG_NEWLINE, @val);
  WriteLn('Newline: ', val, ' (LF=10, CR=13, CRLF=13, ANY=10)');

//  pcre2_config_8(PCRE2_CONFIG_UTF8, @val);
//  WriteLn('UTF-8 Support: ', val);

//  pcre2_config_8(PCRE2_CONFIG_UNICODE_PROPERTIES, @val);
//  WriteLn('Unicode Properties: ', val);

  WriteLn;
end;

begin
  WriteLn('PCRE2 Delphi Binding Test');
  WriteLn('PCRE2 Major: ', PCRE2_MAJOR, ' Minor: ', PCRE2_MINOR);
  WriteLn;

  { Test configuration }
  TestConfig;

  { Basic matching tests }
  TestMatch('abc', 'abcdef');
  TestMatch('abc', 'ABCDEF', PCRE2_CASELESS);
  TestMatch('(\d+)-(\d+)', '123-456');
  TestMatch('^(a|b)+$', 'ababab');
  TestMatch('(?P<name>\w+):(?P<value>\d+)', 'age:25');

  { Error handling }
  TestError;

  { JIT test }
  TestJIT('test\d+', 'test123');

  { Substitution test }
  TestSubstitute('(\d+)', 'abc123def456', '[$1]');

  WriteLn('========================================');
  WriteLn('All tests completed!');
  WriteLn('========================================');
end.
