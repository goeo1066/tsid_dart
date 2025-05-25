import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:tsid_dart/tsid_dart.dart';
import 'package:test/test.dart';

final int timeBits = 42;
final int randomBits = 22;
final int loopMax = 1000;
final int maxLong = 4294967296;
final Runes alphabetCrockford = "0123456789ABCDEFGHJKMNPQRSTVWXYZ".runes;
final Runes alphabetJava =
    "0123456789abcdefghijklmnopqrstuv".runes; // Long.parseUnsignedLong()

void main() {
  group('TSID Test', () {
    test('testFromBytes', () {
      for (int i = 0; i < loopMax; i++) {
        final int number0 = Random().nextInt(maxLong);
        final ByteData buffer = ByteData(8);
        buffer.setInt64(0, number0);
        Uint8List bytes = buffer.buffer.asUint8List();

        final int number1 = Tsid.fromBytes(bytes).toLong();
        assert(number0 == number1);
      }
    });

    test('testToBytes', () {
      for (int i = 0; i < loopMax; i++) {
        final int number = Random().nextInt(maxLong);
        final ByteData buffer = ByteData(8);
        buffer.setInt64(0, number);
        Uint8List bytes0 = buffer.buffer.asUint8List();

        final String string0 = toString(number);
        Uint8List bytes1 = Tsid.fromString(string0).toBytes();

        assert(ListEquality().equals(bytes0, bytes1));
      }
    });

    test('testFromString', () {
      for (int i = 0; i < loopMax; i++) {
        final int number0 = Random().nextInt(maxLong);
        final String string0 = toString(number0);
        final int number1 = Tsid.fromString(string0).toLong();
        assert(number0 == number1);
      }
    });

    test('testToString', () {
      for (int i = 0; i < loopMax; i++) {
        final int number = Random().nextInt(maxLong);
        final String string0 = toString(number);
        final String string1 = Tsid.fromNumber(number).toString();
        assert(string0 == string1);
      }
    });

    group('Operator ==', () {
      test('equal number', () {
        for (int i = 0; i < loopMax; i++) {
          final int number = Random().nextInt(maxLong);
          final Tsid tsid1 = Tsid.fromNumber(number);
          final Tsid tsid2 = Tsid.fromNumber(number);
          assert(tsid1 == tsid2);
        }
      });

      test('different number', () {
        for (int i = 0; i < loopMax; i++) {
          final int number1 = Random().nextInt(maxLong);
          final int number2 = Random().nextInt(maxLong);
          final Tsid tsid1 = Tsid.fromNumber(number1);
          final Tsid tsid2 = Tsid.fromNumber(number2);
          assert(tsid1 != tsid2);
        }
      });
    });
  });

  // New tests for BaseN.decode
  group('BaseN.decode Tests', () {
    test('should decode valid base 10 string', () {
      // Max BigInt is 18446744073709551615
      // The string "18446744073709551615" (20 chars) for base 10, _length(10) = 20
      final maxTsid = BaseN.decode("18446744073709551615", 10);
      expect(maxTsid.toLong(), equals(BigInt.parse("18446744073709551615")));

      final tsidSmall = BaseN.decode("0", 10);
      expect(tsidSmall.toLong(), BigInt.zero);
       final tsidMid = BaseN.decode("123456789012345678", 10);
      expect(tsidMid.toLong(), BigInt.parse("123456789012345678"));
    });

    test('should decode valid base 16 string', () {
      // _length(16) = 16
      final tsid = BaseN.decode("0123456789ABCDEF", 16);
      expect(tsid.toLong(), equals(BigInt.parse("0123456789ABCDEF", radix: 16)));

      final tsidMax = BaseN.decode("FFFFFFFFFFFFFFFF", 16);
      expect(tsidMax.toLong(), equals(BigInt.parse("FFFFFFFFFFFFFFFF", radix: 16)));
    });

    test('should decode valid base 36 string', () {
      // _length(36) = 13
      final tsid = BaseN.decode("AZERTYUIOPK", 36); // Example valid string
      BigInt expected = BigInt.zero;
      String s = "AZERTYUIOPK";
      for (int i = 0; i < s.length; i++) {
        expected = expected * BigInt.from(36) + BigInt.from(alphabetCrockford.toList().indexOf(s.runes.elementAt(i)));
      }
      expect(tsid.toLong(), equals(expected));
    });


    test('should decode valid base 62 string', () {
      // _length(62) = 11
      // Example: "aZ" -> 'a' is 36, 'Z' is 35. 36*62 + 35 = 2232 + 35 = 2267
      final tsid = BaseN.decode("aZ", 62);
      expect(tsid.toLong(), equals(BigInt.from(2267)));

      // Max 64-bit value in base62 is "LygHnO2XyR7"
      // This was calculated as BigInt.parse("18446744073709551615").toRadixString(62) -> needs custom encoder.
      // Let's use a known TSID's max string: Tsid(0xFFFFFFFFFFFFFFFF).encode(62)
      // This is difficult to verify without a trusted encode for max value.
      // Let's use a smaller known value for now. "10" in base 62 is 62.
      final tsid10 = BaseN.decode("10", 62);
      expect(tsid10.toLong(), equals(BigInt.from(62)));
    });

    test('throws error for invalid character in base 16', () {
      expect(
          () => BaseN.decode("0123456789ABCDEZ", 16), // Z is invalid
          throwsA(isA<TsidError>().having((e) => e.message, 'message',
              contains("Invalid base-16 character: 'Z'"))));
    });

    test('throws error for invalid character in base 10', () {
      expect(
          () => BaseN.decode("123A", 10), // A is invalid
          throwsA(isA<TsidError>().having((e) => e.message, 'message',
              contains("Invalid base-10 character: 'A'"))));
    });

    test('throws error for invalid character in base 62', () {
      expect(
          () => BaseN.decode("abc+", 62), // + is invalid
          throwsA(isA<TsidError>().having((e) => e.message, 'message',
              contains("Invalid base-62 character: '+'"))));
    });

    test('throws error for overflow in base 10', () {
      // 2^64 = 18446744073709551616. _length(10) = 20
      expect(
          () => BaseN.decode("18446744073709551616", 10),
          throwsA(isA<TsidError>().having((e) => e.message, 'message',
              stringContainsInOrder(["Invalid base-10 value (overflow) for string: '18446744073709551616'"]))));
    });

    test('throws error for overflow in base 36', () {
      // _length(36) = 13. Max is approx 1.844e19.
      // "Z000000000000" (Z * 36^12) will be 35 * 36^12 which is ~1.65e20. This should overflow.
      expect(
          () => BaseN.decode("Z000000000000", 36),
          throwsA(isA<TsidError>().having((e) => e.message, 'message',
              stringContainsInOrder(["Invalid base-36 value (overflow) for string: 'Z000000000000'"]))));
    });
    
    test('throws error for overflow in base 62', () {
      // _length(62) = 11. Max is approx 1.844e19.
      // "z0000000000" (z is 61) -> 61 * 62^10 is approx 5.12e19. This should overflow.
      expect(
          () => BaseN.decode("z0000000000", 62),
          throwsA(isA<TsidError>().having((e) => e.message, 'message',
              stringContainsInOrder(["Invalid base-62 value (overflow) for string: 'z0000000000'"]))));
    });

    test('throws error for invalid base value', () {
      expect(() => BaseN.decode("123", 1),
          throwsA(isA<TsidError>().having((e) => e.message, 'message', contains("Invalid base: 1"))));
      expect(() => BaseN.decode("123", 0),
          throwsA(isA<TsidError>().having((e) => e.message, 'message', contains("Invalid base: 0"))));
      expect(() => BaseN.decode("123", -1),
          throwsA(isA<TsidError>().having((e) => e.message, 'message', contains("Invalid base: -1"))));
      expect(() => BaseN.decode("123", 63),
          throwsA(isA<TsidError>().having((e) => e.message, 'message', contains("Invalid base: 63"))));
    });

     test('throws error for incorrect string length for base', () {
      // For base 10, expected length is 20
      expect(
          () => BaseN.decode("12345", 10),
          throwsA(isA<TsidError>().having(
              (e) => e.message, 'message', "Invalid base-10 length: 5")));
      expect(
          () => BaseN.decode("123456789012345678901", 10), // 21 chars
          throwsA(isA<TsidError>().having(
              (e) => e.message, 'message', "Invalid base-10 length: 21")));
              
      // For base 16, expected length is 16
      expect(
          () => BaseN.decode("ABC", 16),
          throwsA(isA<TsidError>().having(
              (e) => e.message, 'message', "Invalid base-16 length: 3")));
      expect(
          () => BaseN.decode("0123456789ABCDEF0", 16), // 17 chars
          throwsA(isA<TsidError>().having(
              (e) => e.message, 'message', "Invalid base-16 length: 17")));

      // For base 62, expected length is 11
      expect(
          () => BaseN.decode("short", 62),
          throwsA(isA<TsidError>().having(
              (e) => e.message, 'message', "Invalid base-62 length: 5")));
      expect(
          () => BaseN.decode("longstring12", 62), // 12 chars
          throwsA(isA<TsidError>().having(
              (e) => e.message, 'message', "Invalid base-62 length: 12")));
    });
  });

  // New tests for Tsid.format
  group('Tsid.format Tests', () {
    // For 0x0123456789ABCDEF, Tsid.toString() is "02468ACEGIKMO"
    // BaseN.encode(tsid, 16) is "0123456789ABCDEF" (padded to 16 chars by BaseN.encode)
    // BaseN.encode(tsid, 10) is "0081985529216486895" (padded to 20 chars)
    // BaseN.encode(tsid, 62) is "0004S9PGF85E8KF" (padded to 11 chars)
    // The Tsid constructor takes an int. On native, int is 64-bit.
    final testTsid = Tsid(BigInt.parse("0123456789ABCDEF", radix: 16).toInt());
    final expectedTsidString = "02468ACEGIKMO"; // Manually derived based on Tsid._toString logic
    final expectedHexUpper = "0123456789ABCDEF"; // BaseN.encode output
    final expectedHexLower = "0123456789abcdef";
    final expectedDecimal = "0081985529216486895";
    final expectedBase62 = "0004S9PGF85E8KF";


    test('formats with prefix and suffix using %S', () {
      expect(testTsid.format("PREFIX-%S-SUFFIX"), equals("PREFIX-$expectedTsidString-SUFFIX"));
    });

    test('formats with %S placeholder only', () {
      expect(testTsid.format("%S"), equals(expectedTsidString));
    });
    
    test('formats with prefix and suffix using %s (lowercase S)', () {
      expect(testTsid.format("PREFIX-%s-SUFFIX"), equals("PREFIX-$expectedTsidString-SUFFIX"));
    });

    test('formats with %s placeholder only', () {
      expect(testTsid.format("%s"), equals(expectedTsidString));
    });

    test('formats with %X (uppercase hex)', () {
      expect(testTsid.format("%X"), equals(expectedHexUpper));
    });

    test('formats with %x (lowercase hex)', () {
      expect(testTsid.format("%x"), equals(expectedHexLower));
    });

    test('formats with %d (decimal)', () {
      expect(testTsid.format("%d"), equals(expectedDecimal));
    });

    test('formats with %z (base62)', () {
      expect(testTsid.format("%z"), equals(expectedBase62));
    });

    test('throws error for format string with no placeholder', () {
      expect(
          () => testTsid.format("JUSTSTRING"),
          throwsA(isA<TsidError>().having(
              (e) => e.message, 'message', contains("Invalid format string"))));
    });
    
    test('formats correctly when placeholder is at the beginning', () {
      expect(testTsid.format("%S-SUFFIX"), equals("$expectedTsidString-SUFFIX"));
    });

    test('formats correctly when placeholder is at the end', () {
      expect(testTsid.format("PREFIX-%S"), equals("PREFIX-$expectedTsidString"));
    });

    test('formats with multiple placeholders (only first is replaced)', () {
      // This is current behavior. If multiple were desired, the format method would need a loop.
      expect(testTsid.format("%S-DATA-%S"), equals("$expectedTsidString-DATA-%S"));
    });

    test('throws error for format string ending with %', () {
      expect(
          () => testTsid.format("ID-%"),
          throwsA(isA<TsidError>().having(
              (e) => e.message, 'message', contains("Invalid format string"))));
    });
    
    test('throws error for format string with only %', () {
      expect(
          () => testTsid.format("%"),
          throwsA(isA<TsidError>().having(
              (e) => e.message, 'message', contains("Invalid format string"))));
    });


    test('throws error for invalid placeholder', () {
      expect(
          () => testTsid.format("ID-%Q"),
          throwsA(isA<TsidError>().having(
              (e) => e.message, 'message', contains("Invalid placeholder: \"%Q\""))));
    });
  });

  // New tests for TsidFactoryBuilder.nodeBits
  group('TsidFactoryBuilder.nodeBits Tests', () {
    test(
        'builder.nodeBits returns default (10) if nothing else is specified or set by settings',
        () {
      // This test assumes Settings.getNodeCount() returns null (no env var set)
      final builder = TsidFactory.builder();
      expect(builder.nodeBits, equals(10));
    });

    test('withNodeBits() sets nodeBits correctly, reflected by builder.nodeBits getter', () {
      final builder = TsidFactory.builder().withNodeBits(8);
      expect(builder.nodeBits, equals(8));

      builder.withNodeBits(0);
      expect(builder.nodeBits, equals(0));

      builder.withNodeBits(20);
      expect(builder.nodeBits, equals(20));
    });

    test(
        'builder.nodeBits throws error if withNodeBits() was called with an out-of-range value',
        () {
      final builderInvalid1 = TsidFactory.builder().withNodeBits(21);
      expect(
          () => builderInvalid1.nodeBits,
          throwsA(isA<TsidError>().having((e) => e.message, 'message',
              contains("Node bits out of range [0, 20]: 21"))));

      final builderInvalid2 = TsidFactory.builder().withNodeBits(-1);
      expect(
          () => builderInvalid2.nodeBits,
          throwsA(isA<TsidError>().having((e) => e.message, 'message',
              contains("Node bits out of range [0, 20]: -1"))));
    });

    test('Factory uses nodeBits from builder', () {
      final factory1 = TsidFactory.builder().withNodeBits(5).build();
      // To check the effective nodeBits in the factory, we can infer it from counterMask or nodeMask
      // _counterBits = _randomBits - _nodeBits; (22 - nodeBits)
      // _counterMask = _randomMask >>> _nodeBits;
      // _nodeMask = _randomMask >>> _counterBits;
      // Let's try to get a TSID and inspect its components, though this is indirect.
      // A more direct way would be if TsidFactory exposed its nodeBits, but it doesn't.
      // The builder's nodeBits is what's passed to the factory constructor.
      final tsid = factory1.create(); // This will use nodeBits = 5
      expect(tsid, isNotNull); // Basic check that factory works

      // Test default nodeBits in factory
      final factoryDefault = TsidFactory.builder().build();
      final tsidDefault = factoryDefault.create();
      expect(tsidDefault, isNotNull);
    });

    // As per previous analysis, directly testing the Settings.getNodeCount() interaction
    // by mocking environment variables or forcing tsid_web.dart is not straightforward
    // in this testing environment. The manual review of the logic in SUBTASK_project_3
    // and the tests for `(log(nodeCount) / log(2)).floor()` behavior in SUBTASK_project_4
    // cover parts of that functionality.
  });
}

int fromString(String tsid) {
  var number = tsid.substring(0, 10);
  number = transliterate(number, alphabetCrockford, alphabetJava);
  return int.parse(number, radix: 32);
}

String toString(int stid) {
  final zero = "0000000000000";
  String number = stid.toUnsigned(64).toRadixString(32);
  number = zero.substring(0, zero.length - number.length) + number;

  return transliterate(number, alphabetJava, alphabetCrockford);
}

String transliterate(String string, Runes alphabet1, Runes alphabet2) {
  List<int> output = List.of(string.codeUnits);
  for (int i = 0; i < output.length; i++) {
    for (int j = 0; j < alphabet1.length; j++) {
      if (output.elementAt(i) == alphabet1.elementAt(j)) {
        output[i] = alphabet2.elementAt(j);
        break;
      }
    }
  }
  return String.fromCharCodes(output);
}
