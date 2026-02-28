import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:tsid_dart/tsid_dart.dart';

BigInt _big(String value) => BigInt.parse(value);

Uint8List _toBytes(BigInt value) {
  final bytes = Uint8List(8);
  for (var i = 0; i < 8; i++) {
    bytes[i] = ((value >> (56 - (i * 8))) & BigInt.from(0xff)).toInt();
  }
  return bytes;
}

void main() {
  group('Tsid', () {
    test('round-trips unsigned 64-bit values via bytes', () {
      final values = <BigInt>[
        BigInt.zero,
        BigInt.one,
        _big('4294967295'),
        _big('9223372036854775807'),
        _big('9223372036854775808'),
        _big('18446744073709551615'),
      ];

      for (final value in values) {
        final bytes = _toBytes(value);
        final tsid = Tsid.fromBytes(bytes);

        expect(tsid.toLong(), equals(value));
        expect(tsid.toBytes(), equals(bytes));
      }
    });

    test('round-trips canonical strings including max unsigned value', () {
      const min = '0000000000000';
      const maxSigned = '7ZZZZZZZZZZZZ';
      const maxUnsigned = 'FZZZZZZZZZZZZ';

      expect(Tsid.fromString(min).toString(), equals(min));
      expect(Tsid.fromString(maxSigned).toString(), equals(maxSigned));
      expect(Tsid.fromString(maxUnsigned).toString(), equals(maxUnsigned));
      expect(
        Tsid.fromString(maxUnsigned).toLong(),
        equals(_big('18446744073709551615')),
      );
    });

    test('rejects invalid TSID strings', () {
      expect(Tsid.isValid('!!!!!!!!!!!!!'), isFalse);
      expect(Tsid.isValid('short'), isFalse);
      expect(() => Tsid.fromString('!!!!!!!!!!!!!'), throwsA(isA<TsidError>()));
      expect(() => Tsid.fromString('short'), throwsA(isA<TsidError>()));
    });

    test('getRandom returns full 22-bit random component', () {
      final tsid = Tsid.fromNumber(BigInt.from(31));
      expect(tsid.getRandom(), equals(BigInt.from(31)));
    });

    test('format placeholders are replaced correctly', () {
      final tsid = Tsid.fromString('0AXS751X00W7R');
      expect(tsid.format('ID-%S'), equals('ID-${tsid.toString()}'));
      expect(tsid.format('ID-%s'), equals('ID-${tsid.toLowerCase()}'));
      expect(tsid.format('ID-%X'), equals('ID-${tsid.encode(16)}'));
      expect(
          tsid.format('ID-%x'), equals('ID-${tsid.encode(16).toLowerCase()}'));
      expect(tsid.format('ID-%d'), equals('ID-${tsid.encode(10)}'));
      expect(tsid.format('ID-%z'), equals('ID-${tsid.encode(62)}'));
    });

    test('base encoding lengths and decode validation are correct', () {
      final tsid = Tsid.fromNumber(BigInt.one);

      expect(tsid.encode(10).length, equals(20));
      expect(tsid.encode(62).length, equals(11));
      expect(Tsid.decode(tsid.encode(10), 10).toLong(), equals(BigInt.one));
      expect(Tsid.decode(tsid.encode(62), 62).toLong(), equals(BigInt.one));

      expect(
        () => Tsid.decode('0000000000000000000A', 10),
        throwsA(isA<TsidError>()),
      );
    });

    test('operator == and hashCode are value-based', () {
      final a = Tsid.fromString('0AXS751X00W7R');
      final b = Tsid.fromString('0AXS751X00W7R');
      final c = Tsid.fromString('0AXS751X00W7S');

      expect(a == b, isTrue);
      expect(a == c, isFalse);
      expect(a.hashCode, equals(b.hashCode));
      expect(a.hashCode, isNot(equals(0)));
    });

    test('factory variants are available', () {
      expect(Tsid.getTsid().toString().length, equals(13));
      expect(Tsid.getTsid256().toString().length, equals(13));
      expect(Tsid.getTsid1024().toString().length, equals(13));
      expect(Tsid.getTsid4096().toString().length, equals(13));
    });

    test('unformat reverses format', () {
      final tsid = Tsid.getTsid1024();
      final formatted = tsid.format('A-%S-Z');
      final parsed = Tsid.unformat(formatted, 'A-%S-Z');
      expect(parsed, equals(tsid));
    });
  });
}
