import 'package:test/test.dart';
import 'package:tsid_dart/tsid_dart.dart';

void main() {
  group('Collision Test', () {
    test('generated TSIDs are unique and non-decreasing', () {
      const iterations = 10000;
      final seen = <String>{};
      BigInt? previous;

      for (var i = 0; i < iterations; i++) {
        final tsid = Tsid.getTsid1024();
        final number = tsid.toLong();

        expect(seen.add(tsid.toString()), isTrue);
        if (previous != null) {
          expect(number >= previous, isTrue);
        }

        previous = number;
      }
    });
  });
}
