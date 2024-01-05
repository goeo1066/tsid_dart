import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:tsid_dart/src/tsid.dart';
import 'package:tsid_dart/tsid_dart.dart';
import 'package:test/test.dart';

final int TIME_BITS = 42;
final int RANDOM_BITS = 22;
final int LOOP_MAX = 1000;
final int MAX_LONG = 4294967296;
final Runes ALPHABET_CROCKFORD = "0123456789ABCDEFGHJKMNPQRSTVWXYZ".runes;
final Runes ALPHABET_JAVA =
    "0123456789abcdefghijklmnopqrstuv".runes; // Long.parseUnsignedLong()

void main() {
  group('TSID Test', () {
    test('testFromBytes', () {
      for (int i = 0; i < LOOP_MAX; i++) {
        final int number0 = Random().nextInt(MAX_LONG);
        final ByteData buffer = ByteData(8);
        buffer.setInt64(0, number0);
        Uint8List bytes = buffer.buffer.asUint8List();

        final int number1 = Tsid.fromBytes(bytes).toLong();
        assert(number0 == number1);
      }
    });

    test('testToBytes', () {
      for (int i = 0; i < LOOP_MAX; i++) {
        final int number = Random().nextInt(MAX_LONG);
        final ByteData buffer = ByteData(8);
        buffer.setInt64(0, number);
        Uint8List bytes0 = buffer.buffer.asUint8List();

        final String string0 = toString(number);
        Uint8List bytes1 = Tsid.fromString(string0).toBytes();

        assert(ListEquality().equals(bytes0, bytes1));
      }
    });

    test('testFromString', () {
      for (int i = 0; i < LOOP_MAX; i++) {
        final int number0 = Random().nextInt(MAX_LONG);
        final String string0 = toString(number0);
        final int number1 = Tsid.fromString(string0).toLong();
        assert(number0 == number1);
      }
    });

    test('testToString', () {
      for (int i = 0; i < LOOP_MAX; i++) {
        final int number = Random().nextInt(MAX_LONG);
        final String string0 = toString(number);
        final String string1 = Tsid.fromNumber(number).toString();
        assert(string0 == string1);
      }
    });
  });
}

int fromString(String tsid) {
  var number = tsid.substring(0, 10);
  number = transliterate(number, ALPHABET_CROCKFORD, ALPHABET_JAVA);
  return int.parse(number, radix: 32);
}

String toString(int stid) {
  final zero = "0000000000000";
  String number = stid.toUnsigned(64).toRadixString(32);
  number = zero.substring(0, zero.length - number.length) + number;

  return transliterate(number, ALPHABET_JAVA, ALPHABET_CROCKFORD);
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
