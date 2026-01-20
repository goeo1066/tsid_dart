import 'dart:typed_data';

interface class Tsid {
  Tsid(final BigInt number) {
    throw Exception("Stub implementation");
  }

  Tsid.fromNumber(final BigInt number);

  Tsid.fromBytes(Uint8List bytes);

  Tsid.fromString(String string);

  BigInt toLong() {
    throw Exception("Stub implementation");
  }

  int toInt() {
    throw Exception("Stub implementation");
  }

  Uint8List toBytes() {
    throw Exception("Stub implementation");
  }

  static Tsid fast() {
    throw Exception("Stub implementation");
  }

  @override
  String toString() {
    throw Exception("Stub implementation");
  }

  String toLowerCase() {
    throw Exception("Stub implementation");
  }

  BigInt getUnixMilliseconds(final BigInt customEpoch) {
    throw Exception("Stub implementation");
  }

  BigInt getTime() {
    throw Exception("Stub implementation");
  }

  BigInt getRandom() {
    throw Exception("Stub implementation");
  }

  static bool isValid(final String string) {
    throw Exception("Stub implementation");
  }

  @override
  int get hashCode => throw Exception("Stub implementation");

  int compareTo(Tsid that) {
    throw Exception("Stub implementation");
  }

  String encode(final int base) {
    throw Exception("Stub implementation");
  }

  static Tsid decode(final String string, final int base) {
    throw Exception("Stub implementation");
  }

  String format(final String format) {
    throw Exception("Stub implementation");
  }

  static Tsid unformat(final String formatted, final String format) {
    throw Exception("Stub implementation");
  }

  static Runes toCharArray(final String string) {
    throw Exception("Stub implementation");
  }

  static bool isValidCharArray(final Runes runes) {
    throw Exception("Stub implementation");
  }

  factory Tsid.getTsid() {
    throw Exception("Stub implementation");
  }

  factory Tsid.getTsid256() {
    throw Exception("Stub implementation");
  }

  factory Tsid.getTsid1024() {
    throw Exception("Stub implementation");
  }

  factory Tsid.getTsid4096() {
    throw Exception("Stub implementation");
  }

  @override
  bool operator ==(Object other) {
    // TODO: implement ==
    if (other is! Tsid) {
      return false;
    }
    return super.hashCode == other.hashCode;
  }
}

interface class TsidFactory {
  factory TsidFactory() {
    throw Exception("Stub implementation");
  }

  factory TsidFactory.fromNode(BigInt node) {
    throw Exception("Stub implementation");
  }

  Tsid create() {
    throw Exception("Stub implementation");
  }
}
