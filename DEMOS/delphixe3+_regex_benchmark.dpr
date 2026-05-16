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

program delphi_regex_benchmark;

{$APPTYPE CONSOLE}

uses
  SysUtils, Windows, System.StrUtils, System.RegularExpressions;

const
  ITERATIONS = 100000; // 可调整
  TEST_SUBJECT = 'The quick brown fox jumps over the lazy dog 12345.';

type
  TTestItem = record
    Pattern: string;
    Options: TRegExOptions;
    Desc: string;
  end;

var
  TestCases: array[0..3] of TTestItem = (
    (Pattern: '\d+'; Options: []; Desc: 'Simple digit match'),
    (Pattern: '(\w+)\s+(\w+)'; Options: []; Desc: 'Two word groups'),
    (Pattern: '^(?:[a-z0-9!#$%&''*+/=?^_`{|}~-]+\.)*[a-z0-9!#$%&''*+/=?^_`{|}~-]+@[a-z0-9-]+(?:\.[a-z0-9-]+)*$';
     Options: [roIgnoreCase]; Desc: 'Email regex (complex)'),
    (Pattern: 'fox|dog|cat|bird'; Options: [roIgnoreCase]; Desc: 'Alternation with caseless')
  );

function GetHighResTimeMs: Double;
var
  freq, cnt: Int64;
begin
  QueryPerformanceFrequency(freq);
  QueryPerformanceCounter(cnt);
  Result := cnt * 1000.0 / freq;
end;

procedure BenchmarkDelphiRegex(const APattern, ASubject: string; AOptions: TRegExOptions);
var
  regex: TRegEx;
  i: Integer;
  start, stop: Double;
  total_ms, avg_us, throughput: Double;
  match: TMatch;
begin
  // 预编译正则（模拟 PCRE2 的 compile 阶段）
  regex := TRegEx.Create(APattern, AOptions);

  // 开始计时
  start := GetHighResTimeMs;

  // 执行多次匹配
  for i := 1 to ITERATIONS do
  begin
    match := regex.Match(ASubject);
    // 不使用 match 结果，仅触发匹配逻辑
    // 注意：Delphi 的 Match 默认从头开始，等价于 pcre2_match(..., startoffset=0)
  end;

  stop := GetHighResTimeMs;
  total_ms := stop - start;
  avg_us := (total_ms * 1000) / ITERATIONS;
  throughput := ITERATIONS / (total_ms / 1000);

  WriteLn(Format('|  Delphi TRegEx | Time: %.2f ms | Avg: %.2f μs | Throughput: %.0f matches/sec  |',
    [total_ms, avg_us, throughput]));
end;

procedure RunBenchmark;
var
  i: Integer;
begin
  WriteLn('========================================');
  WriteLn('Delphi Built-in Regex (TRegEx) Benchmark');
  WriteLn('Using System.RegularExpressions (PCRE-based)');
  WriteLn('Iterations: ', ITERATIONS);
  WriteLn('Subject: "', TEST_SUBJECT, '"');
  WriteLn('========================================');

  for i := Low(TestCases) to High(TestCases) do
  begin
    WriteLn;
    WriteLn('Test: ', TestCases[i].Desc);
    WriteLn('Pattern: ', TestCases[i].Pattern);
    WriteLn('Options: ', IfThen(TestCases[i].Options = [], 'None', 'roIgnoreCase'));

    WriteLn('-------------------------------------------------------------------------------');
    BenchmarkDelphiRegex(TestCases[i].Pattern, TEST_SUBJECT, TestCases[i].Options);
    WriteLn('-------------------------------------------------------------------------------');
  end;
end;

begin
  try
    WriteLn('Delphi Default Regex Engine Benchmark');
    WriteLn('Compiler: ', {$IFDEF DEBUG} 'Debug' {$ELSE} 'Release' {$ENDIF});
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