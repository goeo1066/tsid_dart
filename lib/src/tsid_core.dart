import 'dart:math';

import 'package:tsid_dart/src/tsid_default.dart';

import 'base_n.dart';

class TsidCore {
  static final int _tsidChars = 13;

  static final int tsidEpoch = DateTime(2020).millisecondsSinceEpoch;
  static final int randomBits = 22;
  static final int randomMask = 0x003FFFFF;

  static final List<int> alphabetValues = initAlphabetValues();

  //@formatter:off
  static final List<int> alphabetUppercase = "0123456789ABCDEFGHJKMNPQRSTVWXYZ".codeUnits;
  static final List<int> alphabetLowercase = "0123456789abcdefghjkmnpqrstvwxyz".codeUnits;
  //@formatter:on

  BigInt _number = BigInt.zero;

  TsidCore(BigInt number) {
    _number = number;
  }

  BigInt getTime() {
    return TsidCore.shiftRight(_number, randomBits);
  }

  BigInt getRandom() {
    return _number & BigInt.from(randomMask);
  }

  String encode(int base) {
    return BaseN.encode(_number, base);
  }

  static TsidCore decode(String value, int base) {
    BigInt number = BaseN.decode(value, base);
    return TsidCore(number);
  }

  @override
  bool operator ==(Object other) {
    return equals(other);
  }

  bool operator >(TsidCore other) {
    return compareTo(other) > 0;
  }

  bool operator <(TsidCore other) {
    return compareTo(other) < 0;
  }

  bool equals(Object other) {
    if (other is TsidCore) {
      return _number == other._number;
    } else {
      return false;
    }
  }

  int compareTo(TsidCore other) {
    BigInt min = BigInt.one << 64;

    BigInt a = _number + min;
    BigInt b = other._number + min;

    if (a > b) {
      return 1;
    } else if (a < b) {
      return -1;
    }
    return 0;
  }

  String toStringByCodeChars(List<int> codeChars) {
    List<int> chars = List<int>.filled(_tsidChars, 0);

    BigInt mask = BigInt.from(0x1F);
    int bits = 65;
    //@formatter:off
    chars[0x01] = codeChars[(TsidCore.shiftRight(_number, bits-=5) & mask).toInt()];
    chars[0x02] = codeChars[(TsidCore.shiftRight(_number, bits-=5) & mask).toInt()];
    chars[0x03] = codeChars[(TsidCore.shiftRight(_number, bits-=5) & mask).toInt()];
    chars[0x04] = codeChars[(TsidCore.shiftRight(_number, bits-=5) & mask).toInt()];
    chars[0x05] = codeChars[(TsidCore.shiftRight(_number, bits-=5) & mask).toInt()];
    chars[0x06] = codeChars[(TsidCore.shiftRight(_number, bits-=5) & mask).toInt()];
    chars[0x07] = codeChars[(TsidCore.shiftRight(_number, bits-=5) & mask).toInt()];
    chars[0x08] = codeChars[(TsidCore.shiftRight(_number, bits-=5) & mask).toInt()];
    chars[0x09] = codeChars[(TsidCore.shiftRight(_number, bits-=5) & mask).toInt()];
    chars[0x0A] = codeChars[(TsidCore.shiftRight(_number, bits-=5) & mask).toInt()];
    chars[0x0B] = codeChars[(TsidCore.shiftRight(_number, bits-=5) & mask).toInt()];
    chars[0x0C] = codeChars[(_number & mask).toInt()];
    //@formatter:on

    return String.fromCharCodes(chars);
  }

  static BigInt shiftRight(BigInt value, int bits) {
    return value ~/ (BigInt.one << bits);
  }

  static List<int> toCharArray(String string) {
    List<int> chars = string.codeUnits;
    if (TsidCore.isValidCharArray(chars)) {
      return List<int>.empty();
    }
    return chars;
  }

  static List<int> initAlphabetValues() {
    List<int> alphabetValues = List<int>.filled(_tsidChars, -1);

    for (int i = 0; i < alphabetUppercase.length; i++) {
      alphabetValues[alphabetUppercase[i]] = i;
    }

    for (int i = 0; i < alphabetLowercase.length; i++) {
      alphabetValues[alphabetLowercase[i]] = i;
    }

    alphabetValues['O'.codeUnitAt(0)] = 0x00;
    alphabetValues['I'.codeUnitAt(0)] = 0x01;
    alphabetValues['L'.codeUnitAt(0)] = 0x01;

    alphabetValues['o'.codeUnitAt(0)] = 0x00;
    alphabetValues['i'.codeUnitAt(0)] = 0x01;
    alphabetValues['l'.codeUnitAt(0)] = 0x01;

    return alphabetValues;
  }

  static bool isValidCharArray(List<int> chars) {
    if (chars.length != TsidCore._tsidChars) {
      return false;
    }

    for (int i = 0; i < chars.length; i++) {
      try {
        if (alphabetValues[chars[i]] == -1) {
          return false;
        }
      } catch (e) {
        return false;
      }
    }

    if ((alphabetValues[chars[0]] & 16) != 0) {
      return false;
    }

    return true;
  }

  @override
  int get hashCode {
    BigInt value = TsidCore.shiftRight(_number, 32);
    return (_number ^ value).toInt();
  }
}

class TsidCoreSpecBuilder {
  int? _node;
  int? _nodeBits;
  BigInt? _customEpoch;
  IRandom? _random;
  BigInt Function()? _timeFunction;

  TsidCoreSpecBuilder node(int value) {
    _node = value;
    return this;
  }

  TsidCoreSpecBuilder nodeBits(int value) {
    _nodeBits = value;
    return this;
  }

  TsidCoreSpecBuilder customEpoch(DateTime value) {
    _customEpoch = BigInt.from(value.millisecondsSinceEpoch);
    return this;
  }

  TsidCoreSpecBuilder intRandomSupplier(BigInt Function(BigInt) func) {
    _random = IntRandom.forAppWithRandomSupplier(func);
    return this;
  }

  TsidCoreSpecBuilder byteRandomSupplier(List<int> Function(int) func) {
    _random = ByteRandom.forAppWithRandomSupplier(func);
    return this;
  }

  TsidCoreSpecBuilder timeFunction(BigInt Function() func){
    _timeFunction = func;
    return this;
  }
}

abstract interface class IRandom {
  // static final int _maxIntForWeb = 0x1FFFFFFFFFFFFF;
  static final BigInt _maxIntForApp = BigInt.from(0xFFFFFFFFFFFFFFFF);

  // static final int _maxBitsForWeb = 53;
  static const int _maxBitsForApp = 64;

  static const int _byteSizeInBits = 8;
  static const int _integerSizeInBits = 32;

  BigInt nextInt();

  List<int> nextBytes(int length);

  static BigInt maxIntFromBits(int bits) {
    return BigInt.two.pow(bits) - BigInt.one;
  }
}

class IntRandom implements IRandom {
  final int _maxBits;
  final int _maxBytes;
  final BigInt _maxInt;
  final BigInt Function(BigInt) _randomFunction;

  IntRandom(int maxBits, {required BigInt Function(BigInt) random})
      : _maxBits = maxBits,
        _maxBytes = (maxBits / 8).ceil(),
        _maxInt = IRandom.maxIntFromBits(maxBits),
        _randomFunction = random;

  IntRandom.forAppWithRandomSupplier(BigInt Function(BigInt) random) : this (IRandom._maxBitsForApp, random: random);

  IntRandom.forAppWithRandom(Random? random) : this.forAppWithRandomSupplier(IntRandom.newRandomFunction(random));

  @override
  List<int> nextBytes(int length) {
    int shift = 0;
    BigInt random = BigInt.zero;
    List<int> bytes = List<int>.filled(length, 0);

    for (int i = 0; i < length; i++) {
      if (shift < IRandom._byteSizeInBits) {
        shift = IRandom._integerSizeInBits;
        random = _randomFunction(_maxInt);
      }
      shift -= IRandom._byteSizeInBits;
      bytes[i] = (TsidCore.shiftRight(random, shift)).toInt();
    }

    return bytes;
  }

  @override
  BigInt nextInt() {
    return _randomFunction(IRandom._maxIntForApp);
  }

  static BigInt Function(BigInt) newRandomFunction(Random? random) {
    Random entropy;
    if (random == null) {
      entropy = Random.secure();
    } else {
      entropy = random;
    }

    return (BigInt maxInt) {
      return BigInt.from(entropy.nextDouble() * maxInt.toDouble());
    };
  }
}

class ByteRandom implements IRandom {
  final int _maxBits;
  final int _maxBytes;
  final BigInt _maxInt;
  final List<int> Function(int) _randomFunction;

  ByteRandom(int maxBits, {required List<int> Function(int) random})
      : _maxBits = maxBits,
        _maxBytes = (maxBits / 8).ceil(),
        _maxInt = IRandom.maxIntFromBits(maxBits),
        _randomFunction = random;

  ByteRandom.forAppWithRandomSupplier(List<int> Function(int) random) : this (IRandom._maxBitsForApp, random: random);

  ByteRandom.forAppWithRandom(Random? random) : this.forAppWithRandomSupplier(ByteRandom.newRandomFunction(random));


  // ByteRandom.forWeb({Random? random}) : this(IRandom._maxBitsForWeb, random: random);

  @override
  List<int> nextBytes(int length) {
    return _randomFunction(length);
  }

  @override
  BigInt nextInt() {
    BigInt number = BigInt.zero;
    List<int> bytes = _randomFunction(_maxBytes);
    for (int i = 0; i < _maxBytes; i++) {
      number = (number << 8) | BigInt.from(bytes[i] & 0xFF);
    }

    BigInt mask = (BigInt.one << _maxBits) - BigInt.one;
    number = number & mask;
    return number;
  }

  static List<int> Function(int) newRandomFunction(Random? random) {
    Random entropy;
    if (random == null) {
      entropy = Random.secure();
    } else {
      entropy = random;
    }

    return (int length) {
      List<int> bytes = List<int>.filled(length, -1);
      for (int i = 0; i < length; i++) {
        bytes[i] = entropy.nextInt(0xFF);
      }
      return bytes;
    };
  }
}