import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
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
  group('Collision Test', () {
    test('testCollision', () {});
  });
}
