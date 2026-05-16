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

program pcre2_benchmark;

{$APPTYPE CONSOLE}

uses
  SysUtils, Windows, uPCRE2;

const
  ITERATIONS = 100000; // 可调整：10万次匹配
  TEST_SUBJECT = 'The quick brown fox jumps over the lazy dog 12345.';

type
  TTestItem = record
    Pattern: string;
    Options: Cardinal;
    Desc: string;
  end;

var
  TestCases: array[0..3] of TTestItem = (
    (Pattern: '\d+'; Options: 0; Desc: 'Simple digit match'),
    (Pattern: '(\w+)\s+(\w+)'; Options: 0; Desc: 'Two word groups'),
    (Pattern: '^(?:[a-z0-9!#$%&''*+/=?^_`{|}~-]+\.)*[a-z0-9!#$%&''*+/=?^_`{|}~-]+@[a-z0-9-]+(?:\.[a-z0-9-]+)*$';
     Options: PCRE2_CASELESS; Desc: 'Email regex (complex)'),
    (Pattern: '(?i)fox|dog|cat|bird'; Options: 0; Desc: 'Alternation with caseless')
  );

function GetTickCount64HighRes: Int64;
var
  freq, cnt: Int64;
begin
  // 使用 QueryPerformanceCounter 获取高精度时间
  QueryPerformanceFrequency(freq);
  QueryPerformanceCounter(cnt);
  Result := Trunc(cnt * 1000 / freq); // 转为毫秒
end;

function IfThen(ACondition: Boolean; const ATrue: string; const AFalse: string): string;
begin
  if ACondition then
    Result := ATrue
  else
    Result := AFalse;
end;

procedure BenchmarkMatch(const APattern, ASubject: PAnsiChar; AOptions: Cardinal; UseJIT: Boolean);
var
  code: pcre2_code_8;
  match_data: pcre2_match_data_8;
  mcontext: pcre2_match_context_8;
  jit_stack: pcre2_jit_stack_8;
  errorcode, erroroffset: Integer;
  rc: Integer;
  i: Integer;
  start, stop: Int64;
  total_ms: Double;
  avg_us, throughput: Double;
begin
  // 编译正则
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
    WriteLn('Compile failed!');
    Exit;
  end;

  // JIT 编译（如果启用）
  if UseJIT then
  begin
    rc := pcre2_jit_compile_8(code, PCRE2_JIT_COMPLETE);
    if rc < 0 then
    begin
      WriteLn('JIT compile failed, fallback to normal match');
      UseJIT := False;
    end;
  end;

  // 创建 match_data
  match_data := pcre2_match_data_create_from_pattern_8(code, nil);
  if match_data = nil then
  begin
    pcre2_code_free_8(code);
    Exit;
  end;

  // JIT 上下文（仅 JIT 模式需要）
  if UseJIT then
  begin
    mcontext := pcre2_match_context_create_8(nil);
    jit_stack := pcre2_jit_stack_create_8(32*1024, 512*1024, nil);
    pcre2_jit_stack_assign_8(mcontext, nil, jit_stack);
  end
  else
  begin
    mcontext := nil;
    jit_stack := nil;
  end;

  // 开始计时
  start := GetTickCount64HighRes;

  // 执行多次匹配
  for i := 1 to ITERATIONS do
  begin
    if UseJIT then
      rc := pcre2_jit_match_8(
        code,
        PCRE2_SPTR8(ASubject),
        PCRE2_SIZE(StrLen(ASubject)),
        0,
        0,
        match_data,
        mcontext
      )
    else
      rc := pcre2_match_8(
        code,
        PCRE2_SPTR8(ASubject),
        PCRE2_SIZE(StrLen(ASubject)),
        0,
        0,
        match_data,
        nil
      );
    // 不处理结果，只测速度
  end;

  stop := GetTickCount64HighRes;
  total_ms := (stop - start);

  // 输出结果
  avg_us := (total_ms * 1000) / ITERATIONS;
  throughput := ITERATIONS / (total_ms / 1000);

  WriteLn(Format('|  %s | Time: %.2f ms | Avg: %.2f μs | Throughput: %.0f matches/sec  |',
    [IfThen(UseJIT, 'JIT ', 'Normal'), total_ms, avg_us, throughput]));

  // 清理
  if jit_stack <> nil then pcre2_jit_stack_free_8(jit_stack);
  if mcontext <> nil then pcre2_match_context_free_8(mcontext);
  pcre2_match_data_free_8(match_data);
  pcre2_code_free_8(code);
end;

procedure RunBenchmark;
var
  i: Integer;
begin
  WriteLn('========================================');
  WriteLn('PCRE2 Performance Benchmark');
  WriteLn('Iterations: ', ITERATIONS);
  WriteLn('Subject: "', TEST_SUBJECT, '"');
  WriteLn('========================================');

  for i := Low(TestCases) to High(TestCases) do
  begin
    WriteLn;
    WriteLn('Test: ', TestCases[i].Desc);
    WriteLn('Pattern: ', TestCases[i].Pattern);

    WriteLn('-------------------------------------------------------------------------------');
    BenchmarkMatch(PAnsiChar(TestCases[i].Pattern), PAnsiChar(TEST_SUBJECT), TestCases[i].Options, False);
    BenchmarkMatch(PAnsiChar(TestCases[i].Pattern), PAnsiChar(TEST_SUBJECT), TestCases[i].Options, True);
    WriteLn('-------------------------------------------------------------------------------');
  end;
end;

var
  jitSupported: Integer;
begin
  try
    // 检查 JIT 是否支持
    pcre2_config_8(PCRE2_CONFIG_JIT, @jitSupported);
    WriteLn('PCRE2 JIT Support: ', IfThen(jitSupported <> 0, 'Yes', 'No'));
    WriteLn;

    RunBenchmark;

    WriteLn;
    WriteLn('Benchmark completed.');
    ReadLn;
  except
    on E: Exception do
      WriteLn('Error: ', E.Message);
  end;
end.