import 'dart:typed_data';

abstract interface class Tsid<T> {
  static Uint8List initializeAlphabetValues() => throw UnimplementedError();

  static int getNumberFromBytes(Uint8List bytes) => throw UnimplementedError();

  static int getNumberFromString(String string) => throw UnimplementedError();

  Tsid(final int number);

  Tsid.fromNumber(final int number);

  Tsid.fromBytes(Uint8List bytes);

  Tsid.fromString(String string);

  T toLong();

  Uint8List toBytes();

  factory Tsid.fast() => throw UnimplementedError();

  @override
  String toString();

  String toLowerCase();

  T getUnixMilliseconds(final T customEpoch);

  T getTime();

  T getRandom();

  static bool isValid(final String string) => throw UnimplementedError();

  int compareTo(Tsid that);

  String encode(final int base);

  static Tsid decode(final String string, final int base) =>
      throw UnimplementedError();

  String format(final String format);

  static Tsid unformat(final String formatted, final String format) =>
      throw UnimplementedError();

  static Runes toCharArray(final String string) => throw UnimplementedError();

  static bool isValidCharArray(final Runes runes) => throw UnimplementedError();

  factory Tsid.getTsid() => throw UnimplementedError();

  factory Tsid.getTsid256() => throw UnimplementedError();

  factory Tsid.getTsid1024() => throw UnimplementedError();

  factory Tsid.getTsid4096() => throw UnimplementedError();
}
