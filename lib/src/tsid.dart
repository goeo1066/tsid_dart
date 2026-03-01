import 'dart:typed_data' show Uint8List;

import 'imp/tsid.dart'
    if (dart.library.io) 'imp/tsid_native.dart'
    if (dart.library.js_interop) 'imp/tsid_web.dart' as tsid;

/// A Time-Sorted Unique Identifier (TSID).
///
/// A TSID is a 64-bit value composed of:
/// - a time component for natural sorting by creation time, and
/// - a random component for uniqueness.
///
/// Use [toString] for the canonical Crockford base32 representation (13 chars).
class Tsid {
  final tsid.Tsid _tsid;

  /// Creates a TSID from a 64-bit unsigned numeric value.
  Tsid(BigInt number) : _tsid = tsid.Tsid.fromNumber(number);

  Tsid._(this._tsid);

  /// Generates a TSID using the default node settings.
  factory Tsid.getTsid() {
    return Tsid._(tsid.Tsid.getTsid());
  }

  /// Generates a TSID configured for up to 256 nodes.
  factory Tsid.getTsid256() {
    return Tsid._(tsid.Tsid.getTsid256());
  }

  /// Creates a TSID from a 64-bit unsigned numeric value.
  factory Tsid.fromNumber(BigInt number) {
    return Tsid._(tsid.Tsid.fromNumber(number));
  }

  /// Convenience factory for creating a TSID from an [int].
  /// This preserves backward compatibility with versions prior to 0.1.0.
  factory Tsid.fromInt(int number) {
    return Tsid._(tsid.Tsid.fromNumber(BigInt.from(number)));
  }

  /// Parses a TSID from its canonical 13-char string representation.
  factory Tsid.fromString(String string) {
    return Tsid._(tsid.Tsid.fromString(string));
  }

  /// Creates a fast factory-backed TSID instance.
  factory Tsid.fast() {
    return Tsid._(tsid.Tsid.fast());
  }

  /// Generates a TSID configured for up to 1024 nodes.
  factory Tsid.getTsid1024() {
    return Tsid._(tsid.Tsid.getTsid1024());
  }

  /// Generates a TSID configured for up to 4096 nodes.
  factory Tsid.getTsid4096() {
    return Tsid._(tsid.Tsid.getTsid4096());
  }

  /// Creates a TSID from 8 bytes in big-endian order.
  factory Tsid.fromBytes(Uint8List bytes) {
    return Tsid._(tsid.Tsid.fromBytes(bytes));
  }

  /// Returns `true` if [string] is a valid canonical TSID string.
  static bool isValid(String string) {
    return tsid.Tsid.isValid(string);
  }

  /// Decodes a TSID from a string encoded with the provided [base].
  static Tsid decode(String string, int base) {
    return Tsid._(tsid.Tsid.decode(string, base));
  }

  /// Parses a TSID from [formatted] using the given [format] pattern.
  static Tsid unformat(String formatted, String format) {
    return Tsid._(tsid.Tsid.unformat(formatted, format));
  }

  /// Compares this TSID with [that].
  ///
  /// Returns a negative number, `0`, or a positive number if this TSID
  /// is less than, equal to, or greater than [that], respectively.
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

  /// Returns the TSID as an unsigned 64-bit [BigInt].
  BigInt toLong() {
    return _tsid.toLong();
  }

  /// Returns the TSID as an [int].
  ///
  /// On web, this may throw because a TSID can exceed JavaScript's
  /// safe integer range.
  int toInt() {
    return _tsid.toInt();
  }

  /// Returns the TSID as 8 bytes in big-endian order.
  Uint8List toBytes() {
    return _tsid.toBytes();
  }

  /// Returns the canonical 13-char Crockford base32 string.
  @override
  String toString() {
    return _tsid.toString();
  }

  /// Returns the canonical string in lowercase.
  String toLowerCase() {
    return _tsid.toString().toLowerCase();
  }

  /// Encodes this TSID using the provided [base].
  String encode(int base) {
    return _tsid.encode(base);
  }

  /// Formats this TSID using a custom [format] pattern.
  String format(String format) {
    return _tsid.format(format);
  }

  /// Returns the TSID time component (milliseconds since custom epoch).
  BigInt getTime() {
    return _tsid.getTime();
  }

  /// Returns the TSID random component.
  BigInt getRandom() {
    return _tsid.getRandom();
  }

  /// Returns the Unix timestamp in milliseconds based on [customEpoch].
  BigInt getUnixMilliseconds(BigInt customEpoch) {
    return _tsid.getUnixMilliseconds(customEpoch);
  }

  @override
  int get hashCode => _tsid.hashCode;
}

/// Factory used to create TSIDs with a custom node configuration.
class TsidFactory {
  final tsid.TsidFactory _factory;

  TsidFactory._(this._factory);

  /// Creates a TSID factory with default configuration.
  factory TsidFactory() {
    return TsidFactory._(tsid.TsidFactory());
  }

  /// Creates a TSID factory for a specific [node] identifier.
  factory TsidFactory.fromNode(BigInt node) {
    return TsidFactory._(tsid.TsidFactory.fromNode(node));
  }

  /// Convenience factory for creating a TsidFactory from an [int] node.
  /// This preserves backward compatibility with versions prior to 0.1.0.
  factory TsidFactory.fromNodeInt(int node) {
    return TsidFactory._(tsid.TsidFactory.fromNode(BigInt.from(node)));
  }

  /// Creates a new TSID from this factory.
  Tsid create() {
    return Tsid._(_factory.create());
  }
}
