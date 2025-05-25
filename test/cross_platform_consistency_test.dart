import 'package:test/test.dart';
import 'package:tsid_dart/src/tsid_default.dart' as tsid_native;
import 'package:tsid_dart/src/tsid_web.dart' as tsid_web;
import 'dart:math'; // For random number generation

// Helper function to assert equality between a native Tsid and a web Tsid
void expectTsidsToBeEquivalent(tsid_native.Tsid nativeTsid, tsid_web.Tsid webTsid) {
  expect(webTsid.toLong(), equals(BigInt.from(nativeTsid.toLong())), reason: "Numeric values should be equivalent (native to web)");
  expect(webTsid.toString(), equals(nativeTsid.toString()), reason: "String representations should be identical (native to web)");
}

// Helper function to assert equality between a web Tsid and a native Tsid
void expectTsidsToBeEquivalentWebToNative(tsid_web.Tsid webTsid, tsid_native.Tsid nativeTsid) {
  expect(BigInt.from(nativeTsid.toLong()), equals(webTsid.toLong()), reason: "Numeric values should be equivalent (web to native)");
  expect(nativeTsid.toString(), equals(webTsid.toString()), reason: "String representations should be identical (web to native)");
}

void main() {
  group('Cross-platform toString()/fromString() Consistency', () {
    test('Native to Web (from Tsid.fast())', () {
      final nativeTsid = tsid_native.Tsid.fast();
      final strRepresentation = nativeTsid.toString();
      final webTsid = tsid_web.Tsid.fromString(strRepresentation);
      expectTsidsToBeEquivalent(nativeTsid, webTsid);
    });

    test('Web to Native (from Tsid.fast())', () {
      final webTsid = tsid_web.Tsid.fast();
      final strRepresentation = webTsid.toString();
      final nativeTsid = tsid_native.Tsid.fromString(strRepresentation);
      expectTsidsToBeEquivalentWebToNative(webTsid, nativeTsid);
    });

    test('Native to Web (from specific random number via toString/fromString)', () {
      final random = Random();
      // Generate a positive 62-bit number to ensure it fits in a signed 64-bit int
      final number = (BigInt.from(random.nextInt(1 << 30)) << 32 | BigInt.from(random.nextInt(1 << 32))).toInt();
      
      final nativeTsid = tsid_native.Tsid(number);
      final strRepresentation = nativeTsid.toString();
      final webTsid = tsid_web.Tsid.fromString(strRepresentation);
      expectTsidsToBeEquivalent(nativeTsid, webTsid);
    });

    test('Web to Native (from specific random BigInt via toString/fromString)', () {
      final random = Random();
      final bigIntNumber = BigInt.from(random.nextInt(1 << 30)) << 32 | BigInt.from(random.nextInt(1 << 32));

      final webTsid = tsid_web.Tsid(bigIntNumber);
      final strRepresentation = webTsid.toString();
      final nativeTsid = tsid_native.Tsid.fromString(strRepresentation);
      expectTsidsToBeEquivalentWebToNative(webTsid, nativeTsid);
    });

     test('fromString with max 64-bit unsigned value', () {
      final maxUint64String = "7ZZZZZZZZZZZZ"; // Max 64-bit unsigned in Crockford Base32 (13 chars)
                                            // 2^64 - 1 = (2^5)^12 * (2^4-1) + ... (incorrect derivation)
                                            // Max value is (2^64)-1. Each char is 5 bits. 13 chars = 65 bits.
                                            // First char has a restriction to not cause overflow (value < 16).
                                            // So, first char max value is 'F' (15). 15 << 60.
                                            // Remaining 12 chars can be 'Z' (31).
                                            // String should be FZZZZZZZZZZZZ
      final maxTsidString = "FZZZZZZZZZZZZ"; 
      
      final nativeTsidMax = tsid_native.Tsid.fromString(maxTsidString);
      final webTsidMax = tsid_web.Tsid.fromString(maxTsidString);
      expectTsidsToBeEquivalent(nativeTsidMax, webTsidMax);

      // Verify against expected BigInt value for FZZZZZZZZZZZZ
      // F = 15 (01111)
      // Z = 31 (11111)
      // Expected BigInt: (15 * 32^12) + (31 * 32^11) + ... + 31
      // (0b01111 << 60) | (0b11111 << 55) | ... | 0b11111
      BigInt expectedValue = BigInt.zero;
      expectedValue = (expectedValue << 5) | BigInt.from(15); // F
      for(int i=0; i<12; i++){
        expectedValue = (expectedValue << 5) | BigInt.from(31); // Z
      }
      expect(webTsidMax.toLong(), equals(expectedValue));
      expect(BigInt.from(nativeTsidMax.toLong()), equals(expectedValue));

    });

    test('fromString with zero value', () {
      final zeroTsidString = "0000000000000"; // 0
      final nativeTsidZero = tsid_native.Tsid.fromString(zeroTsidString);
      final webTsidZero = tsid_web.Tsid.fromString(zeroTsidString);
      expectTsidsToBeEquivalent(nativeTsidZero, webTsidZero);
      expect(webTsidZero.toLong(), BigInt.zero);
    });

  });

  group('Cross-platform Construction Consistency (fromNumber)', () {
    test('fromNumber: native(int) and web(BigInt) from random positive number should be equivalent', () {
      final random = Random();
      // Generate a positive 62-bit number to ensure it fits in a signed 64-bit int
      final number = (BigInt.from(random.nextInt(1 << 30)) << 32 | BigInt.from(random.nextInt(1 << 32)));
      
      final nativeTsid = tsid_native.Tsid(number.toInt()); // Native constructor takes int
      final webTsid = tsid_web.Tsid(number);             // Web constructor takes BigInt

      expectTsidsToBeEquivalent(nativeTsid, webTsid);
    });

    test('fromNumber: native(int) and web(BigInt) from max 64-bit unsigned number should be equivalent', () {
      // This value represents 2^64 - 1, which will be -1 in a signed 64-bit int.
      // Native Tsid constructor takes int, which is signed 64-bit.
      // Web Tsid constructor takes BigInt.
      // The internal _number field should store the bits consistently.
      final maxUint64 = BigInt.parse("FFFFFFFFFFFFFFFF", radix: 16); // 2^64 - 1
      
      final nativeTsid = tsid_native.Tsid(maxUint64.toInt()); // This will be -1
      final webTsid = tsid_web.Tsid(maxUint64); 

      // String representation should be the same as they both should interpret the bits as unsigned for encoding
      expect(nativeTsid.toString(), equals("FZZZZZZZZZZZZ"));
      expect(webTsid.toString(), equals("FZZZZZZZZZZZZ"));
      
      // Numeric value check needs care due to signed vs unsigned interpretation if not using toLong() consistently
      // nativeTsid.toLong() returns int (-1 for maxUint64)
      // webTsid.toLong() returns BigInt (unsigned 2^64-1)
      // BigInt.from(-1) is not what we want for comparison with webTsid.toLong() for maxUint64.
      // Instead, rely on the string representations and the helper's toLong comparison logic.
      expectTsidsToBeEquivalent(nativeTsid, webTsid);
    });

    test('fromNumber: native(int) and web(BigInt) from zero should be equivalent', () {
      final zero = BigInt.zero;
      
      final nativeTsid = tsid_native.Tsid(zero.toInt());
      final webTsid = tsid_web.Tsid(zero);

      expectTsidsToBeEquivalent(nativeTsid, webTsid);
      expect(webTsid.toString(), equals("0000000000000"));
    });

  });

  group('Cross-platform BaseN.encode()/Tsid.decode() Consistency', () {
    final random = Random();
    final testNumbers = [
      BigInt.zero,
      // Medium positive number (e.g., up to 60 bits to avoid toInt() sign issues for native if not handled by toSigned(64))
      (BigInt.from(random.nextInt(1 << 30)) << 30 | BigInt.from(random.nextInt(1 << 30))), 
      BigInt.parse('FFFFFFFFFFFFFFFF', radix: 16), // Max 64-bit unsigned value
      BigInt.parse('0123456789ABCDEF', radix: 16), // A specific known value
      BigInt.from(123456789), // A smaller decimal value
    ];

    final basesToTest = [2, 10, 16, 36, 62];

    for (var number in testNumbers) {
      // Create native and web TSIDs from the same conceptual number.
      // native ._number is int (signed 64-bit), web ._number is BigInt.
      // The native BaseN.encode correctly converts its internal int to an unsigned BigInt.
      final initialNativeTsid = tsid_native.Tsid(number.toSigned(64).toInt());
      final initialWebTsid = tsid_web.Tsid(number);

      // First, ensure the initial TSIDs are considered equivalent by our helpers for sanity.
      // This mainly checks if their toString() and toLong() interpretations align as expected.
      // This is especially important for the max value (FFFFFFFFFFFFFFFF) where native toLong() is -1.
      expectTsidsToBeEquivalent(initialNativeTsid, initialWebTsid, 
        reasonSuffix: " - initial TSID objects for value $number");

      for (var base in basesToTest) {
        test('Native to Web: value $number, base $base', () {
          final encodedString = tsid_native.Tsid.encode(initialNativeTsid, base);
          final decodedWebTsid = tsid_web.Tsid.decode(encodedString, base);
          
          // The decodedWebTsid should be equivalent to the original initialNativeTsid
          expectTsidsToBeEquivalent(initialNativeTsid, decodedWebTsid, 
            reasonSuffix: " - native encoded '$encodedString'");
        });

        test('Web to Native: value $number, base $base', () {
          final encodedString = tsid_web.Tsid.encode(initialWebTsid, base);
          final decodedNativeTsid = tsid_native.Tsid.decode(encodedString, base);

          // The decodedNativeTsid should be equivalent to the original initialWebTsid
          expectTsidsToBeEquivalentWebToNative(initialWebTsid, decodedNativeTsid,
            reasonSuffix: " - web encoded '$encodedString'");
        });

        // Also test that encoding from native and web for the same number produces the same string
        test('Encode consistency: value $number, base $base', () {
          final nativeEncodedString = tsid_native.Tsid.encode(initialNativeTsid, base);
          final webEncodedString = tsid_web.Tsid.encode(initialWebTsid, base);
          expect(nativeEncodedString, equals(webEncodedString), 
            reason: "Encoding of value $number in base $base should be identical for native and web.");
        });
      }
    }
  });
}
