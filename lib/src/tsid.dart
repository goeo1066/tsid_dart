import 'dart:math';
import 'dart:typed_data';

import 'package:tsid_dart/src/tsid_error.dart';
import 'package:convert/convert.dart';

class Tsid {
  static final _TSID_BYTES = 8;
  static final _TSID_CHARS = 13;
  static final _TSID_EPOCH =
      DateTime(2020, 1, 1, 0, 0, 0, 0).millisecondsSinceEpoch;

  late final _number;
  static final _RANDOM_BITS = 32;
  static final _RANDOM_MASK = 0x003fffff;

  static final _ALPHABET_VALUES = initializeAlphabetValues();
  static final _ALPHABET_UPPERCASE =
      Runes("0123456789ABCDEFGHJKMNPQRSTVWXYZ").toList();
  static final _ALPHABET_LOWERCASE =
      Runes("0123456789abcdefghjkmnpqrstvwxyz").toList();

  static Uint8List initializeAlphabetValues() {
    var values = Uint8List.fromList(List<int>.filled(256, -1));
    for (var i = 0; i < _ALPHABET_UPPERCASE.length; i++) {
      values[_ALPHABET_UPPERCASE[i]] = i;
    }
    for (var i = 0; i < _ALPHABET_UPPERCASE.length; i++) {
      values[_ALPHABET_LOWERCASE[i]] = i;
    }

    values['O'.codeUnitAt(0)] = 0x00;
    values['I'.codeUnitAt(0)] = 0x01;
    values['L'.codeUnitAt(0)] = 0x01;

    values['o'.codeUnitAt(0)] = 0x00;
    values['i'.codeUnitAt(0)] = 0x01;
    values['l'.codeUnitAt(0)] = 0x01;

    return values;
  }

  static int getNumberFromBytes(Uint8List bytes) {
    if (bytes.length != _TSID_BYTES) {
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

    return number;
  }

  static int getNumberFromString(String string) {
    Uint8List chars = Uint8List.fromList(
        string.split('').map((e) => e.codeUnitAt(0)).toList(growable: false));

    var number = 0;

    number |= _ALPHABET_VALUES[chars[0x00]] << 60;
    number |= _ALPHABET_VALUES[chars[0x01]] << 55;
    number |= _ALPHABET_VALUES[chars[0x02]] << 50;
    number |= _ALPHABET_VALUES[chars[0x03]] << 45;
    number |= _ALPHABET_VALUES[chars[0x04]] << 40;
    number |= _ALPHABET_VALUES[chars[0x05]] << 35;
    number |= _ALPHABET_VALUES[chars[0x06]] << 30;
    number |= _ALPHABET_VALUES[chars[0x07]] << 25;
    number |= _ALPHABET_VALUES[chars[0x08]] << 20;
    number |= _ALPHABET_VALUES[chars[0x09]] << 15;
    number |= _ALPHABET_VALUES[chars[0x0a]] << 10;
    number |= _ALPHABET_VALUES[chars[0x0b]] << 5;
    number |= _ALPHABET_VALUES[chars[0x0c]];

    return number;
  }

  Tsid(final int number) {
    _number = number;
  }

  Tsid.fromNumber(final int number) : this(number);

  Tsid.fromBytes(Uint8List bytes) : this(getNumberFromBytes(bytes));

  Tsid.fromString(String string) : this(getNumberFromString(string));

  int toInt() {
    return _number;
  }

  int toLong() {
    return _number;
  }

  Uint8List toBytes() {
    final bytes = Uint8List(_TSID_BYTES);

    bytes[0x0] = (_number >>> 56);
    bytes[0x1] = (_number >>> 48);
    bytes[0x2] = (_number >>> 40);
    bytes[0x3] = (_number >>> 32);
    bytes[0x4] = (_number >>> 24);
    bytes[0x5] = (_number >>> 16);
    bytes[0x6] = (_number >>> 8);
    bytes[0x7] = (_number);

    return bytes;
  }

  static Tsid fast() {
    final time =
        (DateTime.now().millisecondsSinceEpoch - _TSID_EPOCH) << _RANDOM_BITS;
    final tail = _LazyHolder.incrementAndGet() & _RANDOM_MASK;
    return Tsid(time | tail);
  }

  @override
  String toString() {
    return _toString(_ALPHABET_UPPERCASE);
  }

  String toLowerCase() {
    return _toString(_ALPHABET_LOWERCASE);
  }

  int getUnixMilliseconds(final int customEpoch) {
    return getTime() + customEpoch;
  }

  int getTime() {
    return _number >>> _RANDOM_BITS;
  }

  int getRandom() {
    return _number & _RANDOM_BITS;
  }

  static bool isValid(final String string) {
    return isValidCharArray(Runes(string));
  }

  @override
  // TODO: implement hashCode
  int get hashCode => _number ^ _number >>> 32;

  int compareTo(Tsid that) {
    final int min = 0x8000000000000000;
    final int a = _number + min;
    final int b = _number + min;

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
    final Uint8List chars = Uint8List(_TSID_CHARS);
    chars[0x00] = alphabet[((_number >>> 60) & 0x1F)];
    chars[0x01] = alphabet[((_number >>> 55) & 0x1F)];
    chars[0x02] = alphabet[((_number >>> 50) & 0x1F)];
    chars[0x03] = alphabet[((_number >>> 45) & 0x1F)];
    chars[0x04] = alphabet[((_number >>> 40) & 0x1F)];
    chars[0x05] = alphabet[((_number >>> 35) & 0x1F)];
    chars[0x06] = alphabet[((_number >>> 30) & 0x1F)];
    chars[0x07] = alphabet[((_number >>> 25) & 0x1F)];
    chars[0x08] = alphabet[((_number >>> 20) & 0x1F)];
    chars[0x09] = alphabet[((_number >>> 15) & 0x1F)];
    chars[0x0a] = alphabet[((_number >>> 10) & 0x1F)];
    chars[0x0b] = alphabet[((_number >>> 5) & 0x1F)];
    chars[0x0c] = alphabet[(_number & 0x1F)];

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
    if (runes.length != _TSID_CHARS) {
      return false;
    }

    for (int i = 0; i < runes.length; i++) {
      try {
        if (_ALPHABET_VALUES[runes.elementAt(i)] == -1) {
          return false;
        }
      } on IndexError {
        return false;
      }
    }

    if ((_ALPHABET_VALUES[runes.elementAt(0)] & 0x10) != 0) {
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
}

class BaseN {
  static final BigInt MAX = BigInt.two.pow(64) - BigInt.one;
  static final String ALPHABET =
      "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"; // base-62

  static String encode(final Tsid tsid, final int base) {
    if (base < 2 || base > 62) {
      throw TsidError("Invalid base: $base");
    }

    BigInt baseBigInt = BigInt.from(base).toUnsigned(64);
    BigInt x = BigInt.from(tsid._number).toUnsigned(64);
    int b = _length(base);
    Uint8List buffer = Uint8List(b);

    while (x > BigInt.zero) {
      final BigInt div = x ~/ baseBigInt;
      final BigInt rem = x.remainder(baseBigInt);
      buffer[--b] = ALPHABET.runes.elementAt(rem.toInt());
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
      plus = ALPHABET.indexOf(string.substring(i, i + 1)); // ???
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
    if ((lazt * baze) + pluz > MAX) {
      throw TsidError("Invalid base-$base value (overflow): $lazt");
    }

    return Tsid(x);
  }

  static int _length(int base) {
    return (64 / log(base) / log(2)).ceil();
  }
}

class _LazyHolder {
  static const int MAX_INT = 0x7FFFFFFFFFFFFFFF;

  static int COUNTER = Random().nextInt(MAX_INT);

  static int incrementAndGet() {
    return ++COUNTER;
  }
}

class TsidFactory {
  late int _counter;
  late int _lastTime;
  late final int _node;
  late final int _nodeBits;
  late final int _nodeMask;
  late final int _counterBits;
  late final int _counterMask;
  late final int _customEpoch;
  late final int Function() _timeFunction;
  late final IRandom _random;
  late final int _randomBytes;

  static final int _NODE_BITS_256 = 8;
  static final int _NODE_BITS_1024 = 10;
  static final int _NODE_BITS_4096 = 12;

  TsidFactory() : this.fromBuilder(builder());

  TsidFactory.fromNode(int node) : this.fromBuilder(builder().withNode(node));

  TsidFactory.fromBuilder(TsidFactoryBuilder builder) {
    _customEpoch = builder.customEpoch;
    _nodeBits = builder.nodeBits;
    _random = builder.random;
    _timeFunction = builder.timeFunction;

    _counterBits = Tsid._RANDOM_BITS - _nodeBits;
    _counterMask = Tsid._RANDOM_MASK >>> _nodeBits;
    _nodeMask = Tsid._RANDOM_MASK >>> _counterBits;

    _randomBytes = ((_counterBits - 1) ~/ 8) + 1;

    _node = builder.node & _nodeMask;
    _lastTime = 0; // 1970-01-01
    _counter = _getRandomCounter();
  }

  factory TsidFactory.newInstance256({int? node}) {
    var factory = TsidFactory.builder().withNodeBits(_NODE_BITS_256);
    if (node != null) {
      factory = factory.withNode(node);
    }
    return factory.build();
  }

  factory TsidFactory.newInstance1024({int? node}) {
    var factory = TsidFactory.builder().withNodeBits(_NODE_BITS_1024);
    if (node != null) {
      factory = factory.withNode(node);
    }
    return factory.build();
  }

  factory TsidFactory.newInstance4096({int? node}) {
    var factory = TsidFactory.builder().withNodeBits(_NODE_BITS_4096);
    if (node != null) {
      factory = factory.withNode(node);
    }
    return factory.build();
  }

  Tsid create() {
    // lock.lock()
    try {
      final int __time = getTime() << Tsid._RANDOM_BITS;
      final int __node = _node << _counterBits;
      final int __counter = _counter & _counterMask;

      return Tsid(__time | __node | __counter);
    } finally {
      // lock.unlock();
    }
  }

  int getTime() {
    int time = _timeFunction();
    if (time <= _lastTime) {
      _counter++;
      int carry = _counter >>> _counterBits;
      _counter = _counter & _counterMask;
      time = _lastTime + carry;
    } else {
      _counter = _getRandomCounter();
    }
    _lastTime = time;
    return time - _customEpoch;
  }

  int _getRandomCounter() {
    if (_random is ByteRandom) {
      final Uint8List bytes = _random.nextBytes(_randomBytes);
      switch (bytes.length) {
        case 1:
          return (bytes[0] & 0xFF) & _counterMask;
        case 2:
          return (((bytes[0] & 0xFF) << 8) | (bytes[1] & 0xFF)) & _counterMask;
        default:
          return (((bytes[0] & 0xff) << 16) |
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
  late int _node;
  late int _nodeBits = TsidFactory._NODE_BITS_1024;
  late int _customEpoch = Tsid._TSID_EPOCH;
  late IRandom _random = ByteRandom.fromRandom(Random.secure());
  late int Function() _timeFunction = () => DateTime.now().millisecond;

  TsidFactoryBuilder withNode(int node) {
    _node = node;
    return this;
  }

  TsidFactoryBuilder withNodeBits(int nodeBits) {
    _nodeBits = nodeBits;
    return this;
  }

  TsidFactoryBuilder withCustomEpoch(int epoch) {
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

  TsidFactoryBuilder withIntRandomFunction(int Function() randomFunction) {
    _random = IntRandom.fromRandomFunction(randomFunction);
    return this;
  }

  TsidFactoryBuilder withByteRandom(Uint8List Function(int) randomFunction) {
    _random = ByteRandom.fromRandomFunction(randomFunction);
    return this;
  }

  TsidFactoryBuilder withDateTime(DateTime dateTime) {
    _timeFunction = () => dateTime.millisecond;
    return this;
  }

  TsidFactoryBuilder withTimeFunction(int Function() timeFunction) {
    _timeFunction = timeFunction;
    return this;
  }

  int get node {
    int node;
    final int max = (1 << _nodeBits) - 1;
    if (Settings.getNode() != null) {
      node = Settings.getNode()!;
    } else {
      node = _random.nextInt() & max;
    }
    return _node = node;
  }

  int get nodeBits {
    if (Settings.getNodeCount() != null) {
      _nodeBits = log(Settings.getNodeCount()!) ~/ log(2);
    } else {
      _nodeBits = TsidFactory._NODE_BITS_1024;
    }

    if (_nodeBits < 0 || _nodeBits > 20) {
      throw TsidError("Node bits out of range [0, 20]: $_nodeBits");
    }

    return _nodeBits;
  }

  int get customEpoch {
    return _customEpoch;
  }

  IRandom get random {
    return _random;
  }

  int Function() get timeFunction {
    return _timeFunction;
  }

  TsidFactory build() {
    return TsidFactory.fromBuilder(this);
  }
}

abstract interface class IRandom {
  int nextInt();

  Uint8List nextBytes(int length);
}

class IntRandom implements IRandom {
  late final int Function() _randomFunction;

  IntRandom() : this.fromRandom(Random.secure());

  IntRandom.fromRandom(Random random)
      : this.fromRandomFunction(newRandomFunction(random));

  IntRandom.fromRandomFunction(int Function() randomFunction) {
    _randomFunction = randomFunction;
  }

  static int Function() newRandomFunction(Random random) {
    return () {
      return random.nextInt(_LazyHolder.MAX_INT);
    };
  }

  @override
  Uint8List nextBytes(int length) {
    int shift = 0;
    int random = 0;
    Uint8List bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      if (shift < 8 /* Byte.SIZE */) {
        shift = 32; /* Integer.SIZE*/
        random = _randomFunction();
      }
      shift -= 8; /* Byte.SIZE */
      bytes[i] = random >>> shift;
    }
    return bytes;
  }

  @override
  int nextInt() {
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
  int nextInt() {
    int number = 0;
    Uint8List bytes = _randomFunction(4);
    /* Integer.BYTES */;
    for (int i = 0; i < 4 /* Integer.BYTES */; i++) {
      number = (number << 8) | (bytes[i] & 0xff);
    }
    return number;
  }
}

class Settings {
  static final String NODE = "tsidcreator.node";
  static final String NODE_COUNT = "tsidcreator.node.count";

  static int? getNode() {
    return getPropertyAsInt(NODE);
  }

  static int? getNodeCount() {
    return getPropertyAsInt(NODE_COUNT);
  }

  static int? getPropertyAsInt(String property) {
    try {
      var value = getProperty(property);
      if (value == null) {
        throw FormatException("Invalid Number format.");
      }
      return int.parse(value);
    } on FormatException {
      return null;
    }
  }

  static String? getProperty(String name) {
    // TODO: find and add a proper dart way of implementing 'System.getProperty' of Java
    String property =
        String.fromEnvironment(name.toUpperCase(), defaultValue: '');
    if (property.isNotEmpty) {
      return property;
    }
    return null;
  }
}
