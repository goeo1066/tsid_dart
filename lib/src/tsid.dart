import 'dart:typed_data' show Uint8List;

import 'imp/tsid.dart'
    if (dart.library.io) 'imp/tsid_native.dart'
    if (dart.library.js_interop) 'imp/tsid_web.dart' as tsid;

class Tsid {
  final tsid.Tsid _tsid;

  Tsid(BigInt number) : _tsid = tsid.Tsid.fromNumber(number);

  Tsid._(this._tsid);

  factory Tsid.getTsid() {
    return Tsid._(tsid.Tsid.getTsid());
  }

  factory Tsid.getTsid256() {
    return Tsid._(tsid.Tsid.getTsid256());
  }

  factory Tsid.fromNumber(BigInt number) {
    return Tsid._(tsid.Tsid.fromNumber(number));
  }

  /// Convenience factory for creating a TSID from an [int].
  /// This preserves backward compatibility with versions prior to 0.1.0.
  factory Tsid.fromInt(int number) {
    return Tsid._(tsid.Tsid.fromNumber(BigInt.from(number)));
  }

  factory Tsid.fromString(String string) {
    return Tsid._(tsid.Tsid.fromString(string));
  }

  factory Tsid.fast() {
    return Tsid._(tsid.Tsid.fast());
  }

  factory Tsid.getTsid1024() {
    return Tsid._(tsid.Tsid.getTsid1024());
  }

  factory Tsid.getTsid4096() {
    return Tsid._(tsid.Tsid.getTsid4096());
  }

  factory Tsid.fromBytes(Uint8List bytes) {
    return Tsid._(tsid.Tsid.fromBytes(bytes));
  }

  static bool isValid(String string) {
    return tsid.Tsid.isValid(string);
  }

  static Tsid decode(String string, int base) {
    return Tsid._(tsid.Tsid.decode(string, base));
  }

  static Tsid unformat(String formatted, String format) {
    return Tsid._(tsid.Tsid.unformat(formatted, format));
  }

  int compareTo(Tsid that) {
    return _tsid.compareTo(that._tsid);
  }

  @override
  operator ==(Object other) {
    if (other is! Tsid) {
      return false;
    }

    return _tsid == other._tsid;
  }

  BigInt toLong() {
    return _tsid.toLong();
  }

  int toInt() {
    return _tsid.toInt();
  }

  Uint8List toBytes() {
    return _tsid.toBytes();
  }

  @override
  String toString() {
    return _tsid.toString();
  }

  String toLowerCase() {
    return _tsid.toString().toLowerCase();
  }

  String encode(int base) {
    return _tsid.encode(base);
  }

  String format(String format) {
    return _tsid.format(format);
  }

  BigInt getTime() {
    return _tsid.getTime();
  }

  BigInt getRandom() {
    return _tsid.getRandom();
  }

  BigInt getUnixMilliseconds(BigInt customEpoch) {
    return _tsid.getUnixMilliseconds(customEpoch);
  }

  @override
  int get hashCode => _tsid.hashCode;
}

class TsidFactory {
  final tsid.TsidFactory _factory;

  TsidFactory._(this._factory);

  factory TsidFactory() {
    return TsidFactory._(tsid.TsidFactory());
  }

  factory TsidFactory.fromNode(BigInt node) {
    return TsidFactory._(tsid.TsidFactory.fromNode(node));
  }

  /// Convenience factory for creating a TsidFactory from an [int] node.
  /// This preserves backward compatibility with versions prior to 0.1.0.
  factory TsidFactory.fromNodeInt(int node) {
    return TsidFactory._(tsid.TsidFactory.fromNode(BigInt.from(node)));
  }

  Tsid create() {
    return Tsid._(_factory.create());
  }
}
