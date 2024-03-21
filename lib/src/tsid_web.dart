import 'dart:math';
import 'dart:typed_data';

import 'package:tsid_dart/src/tsid_error.dart';
import 'package:convert/convert.dart';

class Tsid {
  static final BigInt _randomBits = BigInt.from(22);
  static final BigInt _randomMask = BigInt.from(0x003fffff);

  static final _alphabetValues = initializeAlphabetValues();
  static final alphabetUppercase =
      Runes("0123456789ABCDEFGHJKMNPQRSTVWXYZ").toList();
  static final _alphabetLowercase =
      Runes("0123456789abcdefghjkmnpqrstvwxyz").toList();

  static const _tsidBytes = 8;
  static const _tsidChars = 13;
  static final _tsidEpoch =
      BigInt.from(DateTime.utc(2020).millisecondsSinceEpoch);

  static Uint8List initializeAlphabetValues() {
    var values = Uint8List.fromList(List<int>.filled(256, -1));
    for (var i = 0; i < alphabetUppercase.length; i++) {
      values[alphabetUppercase[i]] = i;
    }
    for (var i = 0; i < alphabetUppercase.length; i++) {
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
      throw TsidError("Invalid Length of TSID Bytes");
    }
    var number = 0;

    number |= (bytes[0x0] & 0xff) << 56;
    number |= (bytes[0x1] & 0xff) << 48;
    number |= (bytes[0x2] & 0xff) << 40;
    number |= (bytes[0x3] & 0xff) << 32;
    number |= (bytes[0x4] & 0xff) << 24;
    number |= (bytes[0x5] & 0xff) << 16;
    number |= (bytes[0x6] & 0xff) << 8;
    number |= (bytes[0x7] & 0xff);

    return BigInt.from(number);
  }

  static BigInt getNumberFromString(String string) {
    Uint8List chars = Uint8List.fromList(
        string.split('').map((e) => e.codeUnitAt(0)).toList(growable: false));

    var number = 0;

    number |= _alphabetValues[chars[0x00]] << 60;
    number |= _alphabetValues[chars[0x01]] << 55;
    number |= _alphabetValues[chars[0x02]] << 50;
    number |= _alphabetValues[chars[0x03]] << 45;
    number |= _alphabetValues[chars[0x04]] << 40;
    number |= _alphabetValues[chars[0x05]] << 35;
    number |= _alphabetValues[chars[0x06]] << 30;
    number |= _alphabetValues[chars[0x07]] << 25;
    number |= _alphabetValues[chars[0x08]] << 20;
    number |= _alphabetValues[chars[0x09]] << 15;
    number |= _alphabetValues[chars[0x0a]] << 10;
    number |= _alphabetValues[chars[0x0b]] << 5;
    number |= _alphabetValues[chars[0x0c]];

    return BigInt.from(number);
  }

  Tsid(final BigInt number) {
    _number = number;
  }

  Tsid.fromNumber(final BigInt number) : this(number);

  Tsid.fromBytes(Uint8List bytes) : this(getNumberFromBytes(bytes));

  Tsid.fromString(String string) : this(getNumberFromString(string));

  // todo remove
  // int toInt() {
  //   return _number;
  // }

  BigInt toLong() {
    return _number;
  }

  Uint8List toBytes() {
    final bytes = Uint8List(_tsidBytes);

    bytes[0x0] =
        (_number & BigInt.parse('0xFF00000000000000', radix: 16) >> 8 * 7)
            .toInt();
    bytes[0x1] =
        (_number & BigInt.parse('0x00FF000000000000', radix: 16) >> 8 * 6)
            .toInt();
    bytes[0x2] =
        (_number & BigInt.parse('0x0000FF0000000000', radix: 16) >> 8 * 5)
            .toInt();
    bytes[0x3] =
        (_number & BigInt.parse('0x000000FF00000000', radix: 16) >> 8 * 4)
            .toInt();
    bytes[0x4] =
        (_number & BigInt.parse('0x00000000FF000000', radix: 16) >> 8 * 3)
            .toInt();
    bytes[0x5] =
        (_number & BigInt.parse('0x0000000000FF0000', radix: 16) >> 8 * 2)
            .toInt();
    bytes[0x6] =
        (_number & BigInt.parse('0x000000000000FF00', radix: 16) >> 8 * 1)
            .toInt();
    bytes[0x7] =
        (_number & BigInt.parse('0x00000000000000FF', radix: 16) >> 8 * 0)
            .toInt();

    return bytes;
  }

  static Tsid fast() {
    final time =
        BigInt.from(DateTime.now().millisecondsSinceEpoch) - _tsidEpoch <<
            _randomBits.toInt();
    final tail = _LazyHolder.incrementAndGet() & _randomMask;
    return Tsid(time | tail);
  }

  @override
  String toString() {
    return _toString(alphabetUppercase);
  }

  String toLowerCase() {
    return _toString(_alphabetLowercase);
  }

  BigInt getUnixMilliseconds(final BigInt customEpoch) {
    return getTime() + customEpoch;
  }

  BigInt getTime() {
    return _number >> _randomBits.toInt();
  }

  BigInt getRandom() {
    return _number & _randomBits;
  }

  static bool isValid(final String string) {
    return isValidCharArray(Runes(string));
  }

  @override
  int get hashCode => ((_number ^ _number) >> 32).toInt();

  int compareTo(Tsid that) {
    final BigInt min = BigInt.from(0x8000000000000000);
    final BigInt a = _number + min;
    final BigInt b = _number + min;

    if (a > b) {
      return 1;
    } else if (a < b) {
      return -1;
    }

    return 0;
  }

  String encode(final int base) {
    return BaseN.encode(this, base);
  }

  static Tsid decode(final String string, final int base) {
    return BaseN.decode(string, base);
  }

  String format(final String format) {
    final int i = format.indexOf('%');
    if (i < 0 || i == format.length - 1) {
      throw TsidError("Invalid format string: \"format\"");
    }

    final String replacement;
    final int longest = 20;
    final String placeholder = format.substring(i + 1, i + 2);

    switch (placeholder) {
      case 'S':
        replacement = toString();
        break;
      case 's':
        replacement = toString();
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
        throw TsidError("Invalid placeholder: \"%$placeholder\"");
    }

    return '${format.length + longest}$format'
        .replaceRange(i, i + 2, replacement);
  }

  static Tsid unformat(final String formatted, final String format) {
    final int i = format.indexOf('%');
    if (i < 0 || i == format.length - 1) {
      throw TsidError("Invalid format string: \"format\"");
    }

    final String head = format.substring(0, i);
    final String tail = format.substring(i + 2);

    final String placeholder = format.substring(i + 1, i + 2);
    final int length = formatted.length - head.length - tail.length;

    if (formatted.startsWith(head) && formatted.endsWith(tail)) {
      final String substring = formatted.substring(i, i + length);
      switch (placeholder) {
        case 'S':
          return Tsid.fromString(substring);
        case 's':
          return Tsid.fromString(substring);
        case 'X':
          return BaseN.decode(substring.toUpperCase(), 16);
        case 'x':
          return BaseN.decode(substring.toUpperCase(), 16);
        case 'd':
          return BaseN.decode(substring, 10);
        case 'z':
          return BaseN.decode(substring, 62);
        default:
          throw TsidError("Invalid placeholder: \"%$placeholder\"");
      }
    }
    throw TsidError("Invalid formatted string: \"$formatted\"");
  }

  String _toString(final List<int> alphabet) {
    final Uint8List chars = Uint8List(_tsidChars);
    BigInt ander = BigInt.from(0x1F);
    chars[0x00] = alphabet[((_number >> 60) & ander).toInt()];
    chars[0x01] = alphabet[((_number >> 55) & ander).toInt()];
    chars[0x02] = alphabet[((_number >> 50) & ander).toInt()];
    chars[0x03] = alphabet[((_number >> 45) & ander).toInt()];
    chars[0x04] = alphabet[((_number >> 40) & ander).toInt()];
    chars[0x05] = alphabet[((_number >> 35) & ander).toInt()];
    chars[0x06] = alphabet[((_number >> 30) & ander).toInt()];
    chars[0x07] = alphabet[((_number >> 25) & ander).toInt()];
    chars[0x08] = alphabet[((_number >> 20) & ander).toInt()];
    chars[0x09] = alphabet[((_number >> 15) & ander).toInt()];
    chars[0x0a] = alphabet[((_number >> 10) & ander).toInt()];
    chars[0x0b] = alphabet[((_number >> 5) & ander).toInt()];
    chars[0x0c] = alphabet[(_number & ander).toInt()];

    return String.fromCharCodes(chars);
  }

  static Runes toCharArray(final String string) {
    Runes runes = string.runes;
    if (!isValidCharArray(runes)) {
      throw TsidError("Invalid TSID string: \"$string\"");
    }
    return runes;
  }

  static bool isValidCharArray(final Runes runes) {
    if (runes.length != _tsidChars) {
      return false;
    }

    for (int i = 0; i < runes.length; i++) {
      try {
        if (_alphabetValues[runes.elementAt(i)] == -1) {
          return false;
        }
      } on IndexError {
        return false;
      }
    }

    if ((_alphabetValues[runes.elementAt(0)] & 0x10) != 0) {
      return false; // overflow!
    }

    return true; // It seems to be OK.
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
  bool operator ==(covariant Tsid other) => compareTo(other) == 0;
}

class BaseN {
  static final BigInt max = BigInt.two.pow(64) - BigInt.one;
  static final String alphabet =
      "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"; // base-62

  static String encode(final Tsid tsid, final int base) {
    if (base < 2 || base > 62) {
      throw TsidError("Invalid base: $base");
    }

    BigInt baseBigInt = BigInt.from(base);
    BigInt x = tsid._number;
    int b = _length(base);
    Uint8List buffer = Uint8List(b);

    while (x > BigInt.zero) {
      final BigInt div = x ~/ baseBigInt;
      final BigInt rem = x.remainder(baseBigInt);
      buffer[--b] = alphabet.runes.elementAt(rem.toInt());
      x = div;
    }

    while (b > 0) {
      buffer[--b] = '0'.runes.first;
    }
    return String.fromCharCodes(buffer);
  }

  static Tsid decode(final String string, final int base) {
    if (base < 2 || base > 62) {
      throw TsidError("Invalid base: $base");
    }

    int x = 0;
    int last = 0;
    int plus = 0;

    final int length = _length(base);
    if (string.length != length) {
      throw TsidError("Invalid base-$base length: ${string.length}");
    }

    for (int i = 0; i < length; i++) {
      plus = alphabet.indexOf(string.substring(i, i + 1)); // ???
      if (plus == -1) {
        throw TsidError(
            "Invalid base-$base character: $string.substring(i, i + 1)");
      }

      last = x;
      x = (x * base) + plus;
    }

    ByteData buff = ByteData(8);
    buff.setInt64(0, last);
    Uint8List bytes = buff.buffer.asUint8List();
    String bytesString = hex.encode(bytes);
    BigInt lazt = BigInt.parse(bytesString, radix: 16);
    BigInt baze = BigInt.from(base);
    BigInt pluz = BigInt.from(plus);
    if ((lazt * baze) + pluz > max) {
      throw TsidError("Invalid base-$base value (overflow): $lazt");
    }

    return Tsid(BigInt.from(x));
  }

  static int _length(int base) {
    return (64 / log(base) / log(2)).ceil();
  }
}

class _LazyHolder {
  static final BigInt maxInt = BigInt.parse("0x7FFFFFFFFFFFFFFF", radix: 16);
  static const int maxIntUpper = 0x7FFF;
  static const int maxIntLower = 0xFFFFFFFFFFFF;
  static const int maxIntLowerSizeInBits = 6 * 8;

  // static const int maxInt = 0x7FFFFFFFFFFFFFFF;

  static BigInt _counter = BigInt.zero;

  static BigInt get counter {
    final random = Random();
    final bigInt =
        BigInt.from(random.nextInt(maxIntUpper)) << maxIntLowerSizeInBits;
    _counter = bigInt + BigInt.from(random.nextInt(maxIntLower));
    return _counter;
  }

  static BigInt incrementAndGet() {
    final result = _counter;
    _counter = _counter + BigInt.one;
    return result;
  }

  static BigInt randomNextInt(BigInt bound) {
    final random = Random();
    final bigInt =
        BigInt.from(random.nextInt(maxIntUpper)) << maxIntLowerSizeInBits;
    return bigInt + BigInt.from(random.nextInt(maxIntLower));
  }
}

class TsidFactory {
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
  late final BigInt _randomBytes;

  static final BigInt _randomBits = Tsid._randomBits;
  static final BigInt _randomMask = Tsid._randomMask;

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

    _counterBits = _randomBits - _nodeBits;
    _counterMask = _randomMask >> _nodeBits.toInt();
    _nodeMask = _randomMask >> _counterBits.toInt();

    _randomBytes = ((_counterBits - BigInt.one) ~/ BigInt.from(8)) + BigInt.one;

    _node = builder.node & _nodeMask;
    _lastTime = BigInt.zero; // 1970-01-01
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

  Tsid create() {
// lock.lock()
    try {
      final BigInt time = getTime() << _randomBits.toInt();
      final BigInt node = _node << _counterBits.toInt();
      final BigInt counter = _counter & _counterMask;

      return Tsid(time | node | counter);
    } finally {
// lock.unlock();
    }
  }

  BigInt getTime() {
    BigInt time = _timeFunction();
    if (time <= _lastTime) {
      _counter = _counter + BigInt.one;
      BigInt carry = _counter >> _counterBits.toInt();
      _counter = _counter & _counterMask;
      time = _lastTime + carry;
    } else {
      _counter = _getRandomCounter();
    }
    _lastTime = time;
    return time - _customEpoch;
  }

  BigInt _getRandomCounter() {
    if (_random is ByteRandom) {
      final Uint8List bytes = _random.nextBytes(_randomBytes.toInt());
      switch (bytes.length) {
        case 1:
          return BigInt.from(bytes[0] & 0xFF) & _counterMask;
        case 2:
          return BigInt.from(((bytes[0] & 0xFF) << 8) | (bytes[1] & 0xFF)) &
              _counterMask;
        default:
          return BigInt.from(((bytes[0] & 0xff) << 16) |
                  ((bytes[1] & 0xff) << 8) |
                  (bytes[2] & 0xff)) &
              _counterMask;
      }
    } else {
      return _random.nextInt() & _counterMask;
    }
  }

  static TsidFactoryBuilder builder() {
    return TsidFactoryBuilder();
  }
}

class TsidFactoryBuilder {
  static final _tsidEpoch = Tsid._tsidEpoch;

  // error if removed
  late BigInt? _node = null;
  late BigInt _nodeBits = TsidFactory._nodeBits1024;
  late BigInt _customEpoch = _tsidEpoch;
  late IRandom _random = ByteRandom.fromRandom(Random.secure());
  late BigInt Function() _timeFunction =
      () => BigInt.from(DateTime.now().millisecondsSinceEpoch);

  TsidFactoryBuilder withNode(BigInt node) {
    _node = node;
    return this;
  }

  TsidFactoryBuilder withNodeBits(BigInt nodeBits) {
    _nodeBits = nodeBits;
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
    _timeFunction = () => BigInt.from(dateTime.millisecond);
    return this;
  }

  TsidFactoryBuilder withTimeFunction(BigInt Function() timeFunction) {
    _timeFunction = timeFunction;
    return this;
  }

  BigInt get node {
    final BigInt max = BigInt.from((1 << _nodeBits.toInt()) - 1);
    if (_node == null) {
      if (Settings.getNode() != null) {
        _node = Settings.getNode()!;
      } else {
        _node = _random.nextInt() & max;
      }
    }
    return _node!;
  }

  BigInt get nodeBits {
    if (Settings.getNodeCount() != null) {
      _nodeBits =
          BigInt.from(log(Settings.getNodeCount()!.toDouble()) ~/ log(2));
    } else {
      _nodeBits = TsidFactory._nodeBits1024;
    }

    if (_nodeBits.toInt() < 0 || _nodeBits.toInt() > 20) {
      throw TsidError("Node bits out of range [0, 20]: $_nodeBits");
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
    return () {
      return _LazyHolder.randomNextInt(_LazyHolder.maxInt);
    };
  }

  @override
  Uint8List nextBytes(int length) {
    BigInt shift = BigInt.zero;
    BigInt random = BigInt.zero;
    Uint8List bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      if (shift < BigInt.from(8) /* Byte.SIZE */) {
        shift = BigInt.from(32); /* Integer.SIZE*/
        random = _randomFunction();
      }
      shift -= BigInt.from(8); /* Byte.SIZE */
      bytes[i] = (random >> shift.toInt()).toInt();
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
    return (final int length) {
      final Uint8List bytes = Uint8List(length);
      for (int i = 0; i < length; i++) {
        bytes[i] = random.nextInt(255); // random.nextByte();
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
    BigInt number = BigInt.zero;
    Uint8List bytes = _randomFunction(4);
/* Integer.BYTES */
    for (int i = 0; i < 4 /* Integer.BYTES */; i++) {
      number = (number << 8) | BigInt.from(bytes[i] & 0xff);
    }
    return number;
  }
}

class Settings {
  static final String node = "tsidcreator.node";
  static final String nodeCount = "tsidcreator.node.count";
  static final Map<String, String> mockSettings = <String, String>{};
  static BigInt? getNode() {
    return getPropertyAsInt(node);
  }

  static BigInt? getNodeCount() {
    return getPropertyAsInt(nodeCount);
  }

  static BigInt? getPropertyAsInt(String property) {
    try {
      var value = getProperty(property);
      if (value == null) {
        throw FormatException("Invalid Number format.");
      }
      return BigInt.parse(value);
    } on FormatException {
      return null;
    }
  }

  static String? getProperty(String name) {
    String property = mockSettings[name] ?? '';
    if (property.isNotEmpty) {
      return property;
    }
    return null;
  }
}
