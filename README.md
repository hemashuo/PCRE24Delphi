# PCRE24Delphi

Pascal (Delphi / Free Pascal) bindings for **PCRE2** — the Perl-Compatible Regular Expressions library (version 10.47).

## Overview

This project provides native Pascal translations of the PCRE2 C header files, enabling Delphi and Free Pascal applications to call the PCRE2 shared library directly without a C intermediate layer.

| Unit | Source Header | Description |
|------|---------------|-------------|
| `uPCRE2.pas` | `pcre2.h` | Full PCRE2 API — compile, match (interpretive & DFA), JIT, substitute, pattern info, config, serialize, and all associated contexts and error codes |
| `uPCRE2POSIX.pas` | `pcre2posix.h` | POSIX regex wrapper — `regcomp`, `regexec`, `regerror`, `regfree` (plus `pcre2_`- prefixed and `PCRE2`- prefixed aliases) |

## PCRE2 Version

- **Library version:** 10.47 (released 2025-10-21)
- All constants, error codes, and option flags are translated from the original `pcre2.h` / `pcre2posix.h` headers of this version.

## Supported Platforms

The bindings resolve the correct shared library name per platform:

| Platform | Library naming |
|----------|---------------|
| Windows | `libpcre2-8-0.dll`, `libpcre2-16-0.dll`, `libpcre2-32-0.dll`, `libpcre2-posix-3.dll` |
| macOS | `libpcre2-8-0.dylib`, … |
| Linux / other Unix | `libpcre2-8-0.so`, … |

## Compiler Compatibility

| Compiler | Notes |
|----------|-------|
| Delphi 2010+ (CompilerVersion ≥ 21.0) | Uses **delayed loading** (`delayed` directive) — the DLL is loaded on first call, not at program startup |
| Delphi 2009 and earlier | Links at startup (no delayed loading) |
| Free Pascal (FPC) | `$mode objfpc{$H+}`; no delayed loading |

The default code-unit width is **8-bit** (`PCRE2_LOCAL_WIDTH8`). 16-bit and 32-bit widths can be enabled by uncommenting `PCRE2_LOCAL_WIDTH16` / `PCRE2_LOCAL_WIDTH32` in `uPCRE2.pas`.

## API Coverage

### uPCRE2 — Native PCRE2 API

All major PCRE2 function families are bound:

- **Compile:** `pcre2_compile_8`, `pcre2_pattern_info_8`
- **Match:** `pcre2_match_8`, `pcre2_dfa_match_8`
- **JIT:** `pcre2_jit_compile_8`, `pcre2_jit_match_8`, `pcre2_jit_stack_create_8` / `assign` / `free_8`
- **Substitute:** `pcre2_substitute_8`
- **Contexts:** general / compile / match / convert contexts (create, copy, free, and all setter/getter functions)
- **Match data:** create, create_from_pattern, free, get_ovector, get_matched_slice, substring extraction by index / name / list
- **Config:** `pcre2_config_8` (version, Unicode version, JIT availability, newline, BSR, limits, …)
- **Convert:** `pcre2_pattern_convert_8`, `pcre2_convert_context_8`
- **Serialize:** save / load compiled patterns
- **Error messages:** `pcre2_get_error_message_8`
- **Substring utilities:** copy, get, free by index / name / list

All compile options, match options, extra options, JIT options, substitute options, newline/BSR settings, error codes (compile & match), and `pcre2_pattern_info` / `pcre2_config` request types are translated as Pascal constants.

### uPCRE2POSIX — POSIX Regex Interface

Standard POSIX `regex_t` / `regmatch_t` structures and functions:

- `regcomp` → `pcre2_regcomp`
- `regexec` → `pcre2_regexec`
- `regerror` → `pcre2_regerror`
- `regfree` → `pcre2_regfree`

Plus Debian-compatible `PCRE2regcomp` / `PCRE2regexec` / `PCRE2regerror` / `PCRE2regfree` aliases.

POSIX option flags: `REG_ICASE`, `REG_NEWLINE`, `REG_NOTBOL`, `REG_NOTEOL`, `REG_DOTALL`, `REG_NOSUB`, `REG_UTF`, `REG_STARTEND`, `REG_NOTEMPTY`, `REG_UNGREEDY`, `REG_UCP`, `REG_PEND`, `REG_NOSPEC`, `REG_EXTENDED`.

## Demo Programs

| File | Description |
|------|-------------|
| `DEMOS/pcre2test.dpr` | Comprehensive functional test — config query, basic match, named/numbered captures, JIT match with custom stack, substitute, error message extraction, and proper resource cleanup |
| `DEMOS/pcre2_benchmark.dpr` | Performance benchmark — compares interpretive `pcre2_match_8` vs JIT `pcre2_jit_match_8` across 4 patterns (100 000 iterations each) with high-precision timing |
| `DEMOS/pcre2posix_test.dpr` | POSIX wrapper correctness test — 5 test groups verifying `regcomp` / `regexec` / `regfree` / `regerror` with various flags, ported from the official `pcre2posix_test.c` |
| `DEMOS/delphixe3+_regex_benchmark.dpr` | Reference benchmark using Delphi's built-in `TRegEx` (XE3+) — same patterns & iterations as `pcre2_benchmark.dpr` for cross-engine comparison |

# PCRE2 Performance Benchmark Report

## System Information

- **Operating System**: Windows 10 (Version 22H2, OS Build 19045.2251, 64-bit Edition)  
- **Architecture**: x86  
- **CPU Model**: 11th Gen Intel(R) Core(TM) i7-1165G7 @ 2.80GHz  
- **Logical Cores**: 8  

---

## Test Configuration

- **Test Subject String**: `"The quick brown fox jumps over the lazy dog 12345."`  
- **Iterations**: 100,000  

---

## JIT Support Comparison

| JIT Support | Behavior |
|-------------|----------|
| ❌ No       | All tests fell back to normal matching mode; JIT compilation failed |
| ✅ Yes      | JIT mode successfully enabled, delivering significant performance gains |

---

## Performance Comparison (Normal vs. JIT)

### 1. Simple Digit Match  
**Pattern**: `\d+`

| Mode   | Time    | Avg Time/Match | Throughput (matches/sec) |
|--------|---------|----------------|---------------------------|
| Normal | 13.00 ms | 0.13 μs        | 7,692,308                 |
| JIT    | 7.00 ms  | 0.07 μs        | 14,285,714                |

> **Performance Gain**: ~85.7%

---

### 2. Two-Word Group Capture  
**Pattern**: `(\w+)\s+(\w+)`

| Mode   | Time    | Avg Time/Match | Throughput (matches/sec) |
|--------|---------|----------------|---------------------------|
| Normal | 15.00 ms | 0.15 μs        | 6,666,667                 |
| JIT    | 5.00 ms  | 0.05 μs        | 20,000,000                |

> **Performance Gain**: 200%

---

### 3. Complex Email Validation  
**Pattern**:  
`^(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+\.)*[a-z0-9!#$%&'*+/=?^_`{|}~-]+@[a-z0-9-]+(?:\.[a-z0-9-]+)*$`

| Mode   | Time    | Avg Time/Match | Throughput (matches/sec) |
|--------|---------|----------------|---------------------------|
| Normal | 6.00 ms  | 0.06 μs        | 16,666,667                |
| JIT    | 4.00 ms  | 0.04 μs        | 25,000,000                |

> **Performance Gain**: ~50%

---

### 4. Case-Insensitive Alternation  
**Pattern**: `(?i)fox|dog|cat|bird`

| Mode   | Time    | Avg Time/Match | Throughput (matches/sec) |
|--------|---------|----------------|---------------------------|
| Normal | 27.00 ms | 0.27 μs        | 3,703,704                 |
| JIT    | 6.00 ms  | 0.06 μs        | 16,666,667                |

> **Performance Gain**: ~350%

---

## Conclusion

- Enabling **PCRE2 JIT** significantly improves regex matching performance, especially for complex patterns or high-frequency matching scenarios.
- Across all test cases, JIT consistently outperformed the normal mode, with speedups ranging from **50% to 350%**.
- The most substantial gains were observed in alternation and capturing-group patterns.
- If the system supports JIT (as determined by CPU capabilities and build configuration), it is strongly recommended to enable JIT for optimal performance.

## Prerequisites

- A PCRE2 shared library (`.dll` / `.dylib` / `.so`) built for your target platform must be available on the system library path.
- For JIT features, the library must be compiled with JIT support enabled.

## Usage Example (8-bit API)

```pascal
uses
  uPCRE2;

var
  re: Pointer;
  match_data: Pointer;
  ovector: PPCRE2_SIZE;
  rc: Integer;
  pattern: AnsiString;
  subject: AnsiString;

begin
  pattern := '^Hello (\w+)!';
  subject := 'Hello World!';

  re := pcre2_compile_8(PCRE2_SPTR8(@pattern[1]),
    Length(pattern), PCRE2_CASELESS, @rc, @error_offset, nil);

  if re = nil then
  begin
    // handle compile error using pcre2_get_error_message_8
    Exit;
  end;

  match_data := pcre2_match_data_create_from_pattern_8(re, nil);
  rc := pcre2_match_8(re, PCRE2_SPTR8(@subject[1]),
    Length(subject), 0, 0, match_data, nil);

  if rc > 0 then
  begin
    ovector := pcre2_get_ovector_pointer_8(match_data);
    // ovector[0]..ovector[1] = full match offsets
    // ovector[2]..ovector[3] = capture group 1 offsets
  end;

  pcre2_match_data_free_8(match_data);
  pcre2_code_free_8(re);
end;
```

## Usage Example (POSIX API)

```pascal
uses
  uPCRE2POSIX;

var
  regex: regex_t;
  matches: array[0..1] of regmatch_t;
  rc: Integer;

begin
  rc := regcomp(@regex, '^Hello (\w+)!', REG_ICASE);
  if rc <> 0 then Exit;

  rc := regexec(@regex, 'Hello World!', 2, @matches[0], 0);
  if rc = 0 then
  begin
    // matches[0].rm_so..rm_eo = full match
    // matches[1].rm_so..rm_eo = capture group 1
  end;

  regfree(@regex);
end;
```

## License

- **Binding code** (`uPCRE2.pas`, `uPCRE2POSIX.pas`, demo programs): **MIT License** — Copyright © 2026 hemashuo (和码说)
- **PCRE2 library itself**: BSD-style license — Copyright © University of Cambridge (original API 1997–2012, new API 2016–2023), written by Philip Hazel

See the [LICENSE](LICENSE) file for the full MIT text. The PCRE2 license notice is included as comments in the source headers.