import 'dart:typed_data';

class Tsid {
  static Uint8List initializeAlphabetValues() {
    throw Exception("Stub implementation");
  }

  late final int _number;

  static int getNumberFromBytes(Uint8List bytes) {
    throw Exception("Stub implementation");
  }

  static int getNumberFromString(String string) {
    throw Exception("Stub implementation");
  }

  Tsid(final int number) {
    _number = number;
  }

  Tsid.fromNumber(final int number) : this(number);

  Tsid.fromBytes(Uint8List bytes) : this(getNumberFromBytes(bytes));

  Tsid.fromString(String string) : this(getNumberFromString(string));

  int toLong() {
    throw Exception("Stub implementation");  }

  Uint8List toBytes() {
    throw Exception("Stub implementation");
  }

  static Tsid fast() {
    throw Exception("Stub implementation");
  }

  @override
  String toString() {
    throw Exception("Stub implementation");  }

  String toLowerCase() {
    throw Exception("Stub implementation");  }

  int getUnixMilliseconds(final int customEpoch) {
    throw Exception("Stub implementation");  }

  int getTime() {
    throw Exception("Stub implementation");  }

  int getRandom() {
    throw Exception("Stub implementation");  }

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