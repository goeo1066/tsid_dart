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

  factory Tsid.fromNumber(BigInt number) {
    return Tsid._(tsid.Tsid.fromNumber(number));
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

  factory Tsid.fromBytes(Uint8List bytes) {
    return Tsid._(tsid.Tsid.fromBytes(bytes));
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

  Tsid create() {
    return Tsid._(_factory.create());
  }
}
