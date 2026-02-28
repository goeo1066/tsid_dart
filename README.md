# TSID-Dart

A Dart library for generating Time-Sorted Unique Identifiers (TSID).

This library is a Dart implementation of [tsid-creator](https://github.com/f4b6a3/tsid-creator).

## Install

```yaml
# pubspec.yaml
dependencies:
  tsid_dart: ^0.1.2
```

## Quick Start

```dart
import 'package:tsid_dart/tsid_dart.dart';

void main() {
  // Generate a TSID
  final tsid = Tsid.getTsid();

  // String form (Crockford base32, 13 chars)
  final asString = tsid.toString();

  // Numeric form (unsigned 64-bit as BigInt)
  final asNumber = tsid.toLong();

  print('$asString -> $asNumber');
}
```

## API Highlights

```dart
// Parse
final a = Tsid.fromString('0AXS751X00W7R');
final b = Tsid.fromNumber(BigInt.one);
final c = Tsid.fromBytes(Uint8List(8));

// Validate
final ok = Tsid.isValid('0AXS751X00W7R');

// Different node capacities
final t256 = Tsid.getTsid256();
final t1024 = Tsid.getTsid1024();
final t4096 = Tsid.getTsid4096();

// Base-N conversion
final z = a.encode(62);
final zBack = Tsid.decode(z, 62);

// Formatting
final formatted = a.format('DOC-%S');
final parsed = Tsid.unformat(formatted, 'DOC-%S');
```

## Notes

- Use `toLong()` for numeric representation (`BigInt`).
- On web, `toInt()` is intentionally unsupported because TSID values can exceed JavaScript safe integer range.
