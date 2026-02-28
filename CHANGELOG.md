# Changelog

All notable changes to this project are documented in this file.

## 0.1.2

- Fix major TSID correctness issues across native and web implementations:
  - Correct unsigned 64-bit handling and byte/string conversions.
  - Fix random-part masking (22-bit mask) and hash code behavior.
  - Fix formatting/unformatting and base-N encode/decode validation.
  - Fix factory configuration bugs (`withNodeBits`, `withDateTime`) and random byte generation.
- Expand public API wrappers:
  - Added `getTsid256()`, `getTsid4096()`, `isValid()`, `decode()`, and `unformat()`.
- Improve test coverage:
  - Add boundary tests for unsigned 64-bit values and string validation.
  - Add factory regression tests and collision/ordering checks.

## 0.1.1

- Restore missing public API methods in the main facade (issue #8).
- Keep implementation and exposed API behavior aligned across platforms.

## 0.1.0

- Move core factory internals to `BigInt` for safer cross-platform behavior.
- Refactor and cleanup implementation bridge/stub structure.
- Update package dependencies and lint configuration.

## 0.0.5

- Add and validate `==` operator behavior.
- Fix `compareTo` to compare against the argument value.
- Improve related tests.

## 0.0.4

- Split implementation by platform (native vs web).
- Fix web numeric range issues by moving web implementation to `BigInt`.
- Align type mismatches between implementations.

## 0.0.3

- Bump package version and SDK/package metadata.

## 0.0.2

- Early public package setup updates (README dependency and platform metadata).

## 1.0.0 (legacy internal version)

- Initial scaffold and early TSID generation implementation before public versioning normalized.
