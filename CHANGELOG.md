## 0.1.2

- Fix major TSID correctness issues across native and web implementations:
  - Correct 64-bit unsigned handling and byte/string conversions.
  - Fix random-part masking (`22-bit` mask) and hash code behavior.
  - Fix formatting/unformatting and base-N encode/decode validation.
  - Fix factory configuration bugs (`withNodeBits`, `withDateTime`) and random byte generation.
- Expand public API wrappers:
  - Added `getTsid256()`, `getTsid4096()`, `isValid()`, `decode()`, and `unformat()`.
- Improve test coverage:
  - Add boundary tests for unsigned 64-bit values and string validation.
  - Add factory regression tests and collision/ordering checks.

## 0.0.4

- Resolved Error in case of web.
  - Problem was about range of number
  - Resolved by replacing int to BigInt for web [lib/src/tsid_web.dart](tsid_web.dart)
  - Some types are mismatched in tsid_default.dart and tsid_web.dart
    - Probably 'BigInt' will be used instead of 'int' for public methods

## 0.0.5
- Added == Operator for the Tsid Comparison Test
  - [PR#2](https://github.com/goeo1066/tsid_dart/pull/2)
