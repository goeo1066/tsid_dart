import 'dart:math';
import 'dart:typed_data';

import 'package:tsid_dart/src/tsid_error.dart';

import 'tsid.dart' as tsid;

class Tsid implements tsid.Tsid {
  static const int _randomBits = 22;
  static final BigInt _randomMask = BigInt.from(0x003fffff);

  static final List<int> _alphabetUppercase =
      '0123456789ABCDEFGHJKMNPQRSTVWXYZ'.codeUnits;
  static final List<int> _alphabetLowercase =
      '0123456789abcdefghjkmnpqrstvwxyz'.codeUnits;
  static final List<int> _alphabetValues = _initializeAlphabetValues();

  static const _tsidBytes = 8;
  static const _tsidChars = 13;
  static final BigInt _tsidEpoch =
      BigInt.from(DateTime.utc(2020).millisecondsSinceEpoch);

  static final BigInt _uint64Mask = (BigInt.one << 64) - BigInt.one;
  static final BigInt _byteMask = BigInt.from(0xff);
  static final BigInt _charMask = BigInt.from(0x1f);

  static List<int> _initializeAlphabetValues() {
    final values = List<int>.filled(256, -1);

    for (var i = 0; i < _alphabetUppercase.length; i++) {
      values[_alphabetUppercase[i]] = i;
      values[_alphabetLowercase[i]] = i;
    }

    values['O'.codeUnitAt(0)] = 0x00;
    values['I'.codeUnitAt(0)] = 0x01;
    values['L'.codeUnitAt(0)] = 0x01;

    values['o'.codeUnitAt(0)] = 0x00;
    values['i'.codeUnitAt(0)] = 0x01;
    values['l'.codeUnitAt(0)] = 0x01;

    return values;
  }

  late final BigInt _number;

  static BigInt getNumberFromBytes(Uint8List bytes) {
    if (bytes.length != _tsidBytes) {
      throw TsidError('Invalid length of TSID bytes');
    }

    var number = BigInt.zero;
    for (var i = 0; i < _tsidBytes; i++) {
      number |= BigInt.from(bytes[i] & 0xff) << (56 - (i * 8));
    }

    return number;
  }

  static BigInt getNumberFromString(String string) {
    final chars = toCharArray(string).toList(growable: false);

    var number = BigInt.zero;
    for (var i = 0; i < _tsidChars; i++) {
      final value = _alphabetValues[chars[i]];
      number |= BigInt.from(value) << (60 - (i * 5));
    }

    return number;
  }

  Tsid(BigInt number) {
    _number = number.toUnsigned(64) & _uint64Mask;
  }

  Tsid.fromNumber(BigInt number) : this(number);

  Tsid.fromBytes(Uint8List bytes) : this(getNumberFromBytes(bytes));

  Tsid.fromString(String string) : this(getNumberFromString(string));

  @override
  int toInt() {
    throw UnsupportedError(
      'toInt() is not supported on web because values can exceed '
      'JavaScript safe integer range. Use toLong() instead.',
    );
  }

  @override
  BigInt toLong() {
    return _number;
  }

  @override
  Uint8List toBytes() {
    final bytes = Uint8List(_tsidBytes);

    for (var i = 0; i < _tsidBytes; i++) {
      bytes[i] = ((_number >> (56 - (i * 8))) & _byteMask).toInt();
    }

    return bytes;
  }

  static Tsid fast() {
    final time =
        (BigInt.from(DateTime.now().millisecondsSinceEpoch) - _tsidEpoch) <<
            _randomBits;
    final tail = _LazyHolder.incrementAndGet() & _randomMask;

    return Tsid(time | tail);
  }

  @override
  String toString() {
    return _toString(_alphabetUppercase);
  }

  @override
  String toLowerCase() {
    return _toString(_alphabetLowercase);
  }

  @override
  BigInt getUnixMilliseconds(BigInt customEpoch) {
    return getTime() + customEpoch;
  }

  @override
  BigInt getTime() {
    return _number >> _randomBits;
  }

  @override
  BigInt getRandom() {
    return _number & _randomMask;
  }

  static bool isValid(String string) {
    return isValidCharArray(string.runes);
  }

  @override
  int get hashCode {
    final lower = (_number & BigInt.from(0xffffffff)).toInt();
    final upper = ((_number >> 32) & BigInt.from(0xffffffff)).toInt();
    return upper ^ lower;
  }

  @override
  int compareTo(covariant Tsid that) {
    return _number.compareTo(that._number);
  }

  @override
  String encode(int base) {
    return BaseN.encode(this, base);
  }

  static Tsid decode(String string, int base) {
    return BaseN.decode(string, base);
  }

  @override
  String format(String format) {
    final i = format.indexOf('%');
    if (i < 0 || i == format.length - 1) {
      throw TsidError('Invalid format string: "$format"');
    }

    final placeholder = format.substring(i + 1, i + 2);
    final String replacement;

    switch (placeholder) {
      case 'S':
        replacement = toString();
        break;
      case 's':
        replacement = toLowerCase();
        break;
      case 'X':
        replacement = BaseN.encode(this, 16);
        break;
      case 'x':
        replacement = BaseN.encode(this, 16).toLowerCase();
        break;
      case 'd':
        replacement = BaseN.encode(this, 10);
        break;
      case 'z':
        replacement = BaseN.encode(this, 62);
        break;
      default:
        throw TsidError('Invalid placeholder: "%$placeholder"');
    }

    return format.replaceRange(i, i + 2, replacement);
  }

  static Tsid unformat(String formatted, String format) {
    final i = format.indexOf('%');
    if (i < 0 || i == format.length - 1) {
      throw TsidError('Invalid format string: "$format"');
    }

    final head = format.substring(0, i);
    final tail = format.substring(i + 2);

    if (!formatted.startsWith(head) || !formatted.endsWith(tail)) {
      throw TsidError('Invalid formatted string: "$formatted"');
    }

    final start = head.length;
    final end = formatted.length - tail.length;
    if (end < start) {
      throw TsidError('Invalid formatted string: "$formatted"');
    }

    final substring = formatted.substring(start, end);
    final placeholder = format.substring(i + 1, i + 2);

    switch (placeholder) {
      case 'S':
      case 's':
        return Tsid.fromString(substring);
      case 'X':
      case 'x':
        return BaseN.decode(substring.toUpperCase(), 16);
      case 'd':
        return BaseN.decode(substring, 10);
      case 'z':
        return BaseN.decode(substring, 62);
      default:
        throw TsidError('Invalid placeholder: "%$placeholder"');
    }
  }

  String _toString(List<int> alphabet) {
    final chars = Uint8List(_tsidChars);

    for (var i = 0; i < _tsidChars; i++) {
      final shift = 60 - (i * 5);
      chars[i] = alphabet[((_number >> shift) & _charMask).toInt()];
    }

    return String.fromCharCodes(chars);
  }

  static Runes toCharArray(String string) {
    final runes = string.runes;

    if (!isValidCharArray(runes)) {
      throw TsidError('Invalid TSID string: "$string"');
    }

    return runes;
  }

  static bool isValidCharArray(Runes runes) {
    final chars = runes.toList(growable: false);

    if (chars.length != _tsidChars) {
      return false;
    }

    for (final rune in chars) {
      if (rune < 0 || rune >= _alphabetValues.length) {
        return false;
      }

      if (_alphabetValues[rune] < 0) {
        return false;
      }
    }

    if ((_alphabetValues[chars.first] & 0x10) != 0) {
      return false;
    }

    return true;
  }

  static final TsidFactory _factoryInstance = TsidFactory();
  static final TsidFactory _factory256Instance = TsidFactory.newInstance256();
  static final TsidFactory _factory1024Instance = TsidFactory.newInstance1024();
  static final TsidFactory _factory4096Instance = TsidFactory.newInstance4096();

  factory Tsid.getTsid() {
    return _factoryInstance.create();
  }

  factory Tsid.getTsid256() {
    return _factory256Instance.create();
  }

  factory Tsid.getTsid1024() {
    return _factory1024Instance.create();
  }

  factory Tsid.getTsid4096() {
    return _factory4096Instance.create();
  }

  @override
  bool operator ==(Object other) {
    return other is Tsid && _number == other._number;
  }
}

class BaseN {
  static final BigInt max = (BigInt.one << 64) - BigInt.one;
  static const String alphabet =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';

  static String encode(Tsid tsid, int base) {
    if (base < 2 || base > 62) {
      throw TsidError('Invalid base: $base');
    }

    final baseBigInt = BigInt.from(base);
    final width = _length(base);
    final buffer = Uint8List(width);
    var x = tsid._number;

    for (var i = width - 1; i >= 0; i--) {
      final rem = x.remainder(baseBigInt).toInt();
      buffer[i] = alphabet.codeUnitAt(rem);
      x ~/= baseBigInt;
    }

    return String.fromCharCodes(buffer);
  }

  static Tsid decode(String string, int base) {
    if (base < 2 || base > 62) {
      throw TsidError('Invalid base: $base');
    }

    final length = _length(base);
    if (string.length != length) {
      throw TsidError('Invalid base-$base length: ${string.length}');
    }

    final baseBigInt = BigInt.from(base);
    var value = BigInt.zero;

    for (var i = 0; i < string.length; i++) {
      final char = string.substring(i, i + 1);
      final digit = alphabet.indexOf(char);
      if (digit < 0 || digit >= base) {
        throw TsidError('Invalid base-$base character: $char');
      }

      value = (value * baseBigInt) + BigInt.from(digit);
      if (value > max) {
        throw TsidError('Invalid base-$base value (overflow): $string');
      }
    }

    return Tsid(value);
  }

  static int _length(int base) {
    return (64 * log(2) / log(base)).ceil();
  }
}

class _LazyHolder {
  static final Random _random = Random.secure();
  static BigInt _counter = BigInt.from(_random.nextInt(0x400000));

  static BigInt incrementAndGet() {
    _counter += BigInt.one;
    return _counter;
  }
}

class TsidFactory implements tsid.TsidFactory {
  late BigInt _counter;
  late BigInt _lastTime;
  late final BigInt _node;
  late final BigInt _nodeBits;
  late final BigInt _nodeMask;
  late final BigInt _counterBits;
  late final BigInt _counterMask;
  late final BigInt _customEpoch;
  late final BigInt Function() _timeFunction;
  late final IRandom _random;
  late final int _randomBytes;

  static final BigInt _nodeBits256 = BigInt.from(8);
  static final BigInt _nodeBits1024 = BigInt.from(10);
  static final BigInt _nodeBits4096 = BigInt.from(12);

  TsidFactory() : this.fromBuilder(builder());

  TsidFactory.fromNode(BigInt node)
      : this.fromBuilder(builder().withNode(node));

  TsidFactory.fromBuilder(TsidFactoryBuilder builder) {
    _customEpoch = builder.customEpoch;
    _nodeBits = builder.nodeBits;
    _random = builder.random;
    _timeFunction = builder.timeFunction;

    _counterBits = BigInt.from(Tsid._randomBits) - _nodeBits;
    _counterMask = Tsid._randomMask >> _nodeBits.toInt();
    _nodeMask = Tsid._randomMask >> _counterBits.toInt();

    _randomBytes = ((_counterBits.toInt() - 1) ~/ 8) + 1;

    _node = builder.node & _nodeMask;
    _lastTime = BigInt.zero;
    _counter = _getRandomCounter();
  }

  factory TsidFactory.newInstance256({BigInt? node}) {
    var factory = TsidFactory.builder().withNodeBits(_nodeBits256);
    if (node != null) {
      factory = factory.withNode(node);
    }
    return factory.build();
  }

  factory TsidFactory.newInstance1024({BigInt? node}) {
    var factory = TsidFactory.builder().withNodeBits(_nodeBits1024);
    if (node != null) {
      factory = factory.withNode(node);
    }
    return factory.build();
  }

  factory TsidFactory.newInstance4096({BigInt? node}) {
    var factory = TsidFactory.builder().withNodeBits(_nodeBits4096);
    if (node != null) {
      factory = factory.withNode(node);
    }
    return factory.build();
  }

  @override
  Tsid create() {
    final time = getTime() << Tsid._randomBits;
    final node = _node << _counterBits.toInt();
    final counter = _counter & _counterMask;

    return Tsid(time | node | counter);
  }

  BigInt getTime() {
    var time = _timeFunction();

    if (time <= _lastTime) {
      _counter += BigInt.one;
      final carry = _counter >> _counterBits.toInt();
      _counter &= _counterMask;
      time = _lastTime + carry;
    } else {
      _counter = _getRandomCounter();
    }

    _lastTime = time;
    return time - _customEpoch;
  }

  BigInt _getRandomCounter() {
    if (_random is ByteRandom) {
      final bytes = _random.nextBytes(_randomBytes);
      var counter = BigInt.zero;
      for (final b in bytes) {
        counter = (counter << 8) | BigInt.from(b & 0xff);
      }
      return counter & _counterMask;
    }

    return _random.nextInt() & _counterMask;
  }

  static TsidFactoryBuilder builder() {
    return TsidFactoryBuilder();
  }
}

class TsidFactoryBuilder {
  static final BigInt _tsidEpoch =
      BigInt.from(DateTime.utc(2020).millisecondsSinceEpoch);

  BigInt? _node;
  BigInt _nodeBits = TsidFactory._nodeBits1024;
  bool _nodeBitsExplicit = false;
  BigInt _customEpoch = _tsidEpoch;
  IRandom _random = ByteRandom.fromRandom(Random.secure());
  BigInt Function() _timeFunction =
      () => BigInt.from(DateTime.now().millisecondsSinceEpoch);

  TsidFactoryBuilder withNode(BigInt node) {
    _node = node;
    return this;
  }

  TsidFactoryBuilder withNodeBits(BigInt nodeBits) {
    _nodeBits = nodeBits;
    _nodeBitsExplicit = true;
    return this;
  }

  TsidFactoryBuilder withCustomEpoch(BigInt epoch) {
    _customEpoch = epoch;
    return this;
  }

  TsidFactoryBuilder withRandom(Random random, bool isSecure) {
    if (isSecure) {
      _random = ByteRandom.fromRandom(random);
    } else {
      _random = IntRandom.fromRandom(random);
    }

    return this;
  }

  TsidFactoryBuilder withIntRandomFunction(BigInt Function() randomFunction) {
    _random = IntRandom.fromRandomFunction(randomFunction);
    return this;
  }

  TsidFactoryBuilder withByteRandom(Uint8List Function(int) randomFunction) {
    _random = ByteRandom.fromRandomFunction(randomFunction);
    return this;
  }

  TsidFactoryBuilder withDateTime(DateTime dateTime) {
    _timeFunction = () => BigInt.from(dateTime.millisecondsSinceEpoch);
    return this;
  }

  TsidFactoryBuilder withTimeFunction(BigInt Function() timeFunction) {
    _timeFunction = timeFunction;
    return this;
  }

  BigInt get node {
    final max = (BigInt.one << nodeBits.toInt()) - BigInt.one;

    if (_node == null) {
      final configured = Settings.getNode();
      if (configured != null) {
        _node = configured;
      } else {
        _node = _random.nextInt() & max;
      }
    }

    return _node!;
  }

  BigInt get nodeBits {
    if (!_nodeBitsExplicit) {
      final configuredCount = Settings.getNodeCount();
      if (configuredCount != null) {
        if (configuredCount <= BigInt.zero) {
          throw TsidError('Node count must be positive: $configuredCount');
        }
        _nodeBits =
            BigInt.from((log(configuredCount.toDouble()) / log(2)).floor());
      }
    }

    if (_nodeBits < BigInt.zero || _nodeBits > BigInt.from(20)) {
      throw TsidError('Node bits out of range [0, 20]: $_nodeBits');
    }

    return _nodeBits;
  }

  BigInt get customEpoch {
    return _customEpoch;
  }

  IRandom get random {
    return _random;
  }

  BigInt Function() get timeFunction {
    return _timeFunction;
  }

  TsidFactory build() {
    return TsidFactory.fromBuilder(this);
  }
}

abstract interface class IRandom {
  BigInt nextInt();

  Uint8List nextBytes(int length);
}

class IntRandom implements IRandom {
  late final BigInt Function() _randomFunction;

  IntRandom() : this.fromRandom(Random.secure());

  IntRandom.fromRandom(Random random)
      : this.fromRandomFunction(newRandomFunction(random));

  IntRandom.fromRandomFunction(BigInt Function() randomFunction) {
    _randomFunction = randomFunction;
  }

  static BigInt Function() newRandomFunction(Random random) {
    return () => BigInt.from(random.nextInt(0x100000000));
  }

  @override
  Uint8List nextBytes(int length) {
    var shift = 0;
    var random = BigInt.zero;
    final bytes = Uint8List(length);

    for (var i = 0; i < length; i++) {
      if (shift < 8) {
        shift = 32;
        random = _randomFunction();
      }

      shift -= 8;
      bytes[i] = ((random >> shift) & BigInt.from(0xff)).toInt();
    }

    return bytes;
  }

  @override
  BigInt nextInt() {
    return _randomFunction();
  }
}

class ByteRandom implements IRandom {
  late final Uint8List Function(int) _randomFunction;

  ByteRandom() : this.fromRandom(Random.secure());

  ByteRandom.fromRandom(Random random)
      : this.fromRandomFunction(newRandomFunction(random));

  ByteRandom.fromRandomFunction(Uint8List Function(int) randomFunction) {
    _randomFunction = randomFunction;
  }

  static Uint8List Function(int) newRandomFunction(Random random) {
    return (int length) {
      final bytes = Uint8List(length);
      for (var i = 0; i < length; i++) {
        bytes[i] = random.nextInt(256);
      }
      return bytes;
    };
  }

  @override
  Uint8List nextBytes(int length) {
    return _randomFunction(length);
  }

  @override
  BigInt nextInt() {
    var number = BigInt.zero;
    final bytes = _randomFunction(4);

    for (var i = 0; i < 4; i++) {
      number = (number << 8) | BigInt.from(bytes[i] & 0xff);
    }

    return number;
  }
}

class Settings {
  static const String node = 'tsidcreator.node';
  static const String nodeCount = 'tsidcreator.node.count';
  static final Map<String, String> mockSettings = <String, String>{};

  static BigInt? getNode() {
    return getPropertyAsInt(node);
  }

  static BigInt? getNodeCount() {
    return getPropertyAsInt(nodeCount);
  }

  static BigInt? getPropertyAsInt(String property) {
    final value = getProperty(property);
    if (value == null) {
      return null;
    }

    return BigInt.tryParse(value);
  }

  static String? getProperty(String name) {
    final property = mockSettings[name] ?? '';
    if (property.isNotEmpty) {
      return property;
    }

    return null;
  }
}
