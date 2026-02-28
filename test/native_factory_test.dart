import 'dart:math';

import 'package:test/test.dart';
import 'package:tsid_dart/src/imp/tsid_native.dart' as native;

BigInt _randomPart(native.Tsid tsid) {
  return tsid.toLong() & BigInt.from(0x003fffff);
}

void main() {
  group('Native TsidFactory', () {
    test('withNodeBits affects node placement', () {
      final fixedTime = DateTime.utc(2026, 1, 1).millisecondsSinceEpoch;

      final f256 = native.TsidFactory.builder()
          .withNodeBits(8)
          .withNode(1)
          .withIntRandomFunction(() => 0)
          .withTimeFunction(() => fixedTime)
          .build();

      final f1024 = native.TsidFactory.builder()
          .withNodeBits(10)
          .withNode(1)
          .withIntRandomFunction(() => 0)
          .withTimeFunction(() => fixedTime)
          .build();

      final f4096 = native.TsidFactory.builder()
          .withNodeBits(12)
          .withNode(1)
          .withIntRandomFunction(() => 0)
          .withTimeFunction(() => fixedTime)
          .build();

      expect(_randomPart(f256.create()), equals(BigInt.from(1 << 14)));
      expect(_randomPart(f1024.create()), equals(BigInt.from(1 << 12)));
      expect(_randomPart(f4096.create()), equals(BigInt.from(1 << 10)));
    });

    test('withDateTime uses millisecondsSinceEpoch', () {
      final dateTime = DateTime.utc(2024, 1, 1, 12, 34, 56, 789);
      final epoch = BigInt.from(DateTime.utc(2020).millisecondsSinceEpoch);

      final factory = native.TsidFactory.builder()
          .withDateTime(dateTime)
          .withIntRandomFunction(() => 0)
          .build();

      final tsid = factory.create();
      expect(
        tsid.getUnixMilliseconds(epoch),
        equals(BigInt.from(dateTime.millisecondsSinceEpoch)),
      );
    });

    test('non-secure random path does not throw range errors', () {
      final factory =
          native.TsidFactory.builder().withRandom(Random(1), false).build();

      expect(() => factory.create(), returnsNormally);
    });
  });
}
