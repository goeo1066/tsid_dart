import 'dart:math';
import 'dart:typed_data';

class BaseN {
  static final int longSizeInBit = 64;
  static final BigInt max = BigInt.from(2).pow(64) - BigInt.one;

  //@formatter:off
  static final List<int> alphabet = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz".codeUnits;
  //@formatter:on
  static final Map<int, int> charToNumMap = initCharToNumMap(alphabet);

  static Map<int, int> initCharToNumMap(List<int> value) {
    Map<int, int> charToNumMap = {};
    for (int num = 0; num < value.length; num++) {
      int char = value[num];
      charToNumMap.putIfAbsent(char, () => num);
    }
    return charToNumMap;
  }

  static String encode(BigInt value, int base) {
    if (base < 2 || base > 62) {
      return "";
    }

    BigInt number = value + BigInt.zero;
    int length = BaseN.length(base);
    Uint8List buffer = Uint8List(length);

    while (number > BigInt.zero) {
      int reminder = (number % BigInt.from(base)).toInt();
      buffer[--length] = alphabet[reminder];
      number = BigInt.from(number / BigInt.from(base));
    }

    int zero = '0'.codeUnitAt(0);
    while (length > 0) {
      buffer[--length] = zero;
    }

    return String.fromCharCodes(buffer);
  }

  static BigInt decode(String value, int base) {
    if (base < 2 || base > 62) {
      return BigInt.from(-1);
    }

    int length = BaseN.length(base);
    if (value.length != length) {
      return BigInt.from(-1);
    }

    BigInt number = BigInt.zero;
    BigInt last = BigInt.zero;
    BigInt baseBigInt = BigInt.from(base);
    int? plus;
    for (int i = 0; i < length; i++) {
      plus = charToNumMap[value.codeUnitAt(i)];
      if (plus == null) {
        // invalid char
        return BigInt.from(-1);
      }

      last = number;
      number = (number * baseBigInt) + BigInt.from(plus);
    }

    if ((last * baseBigInt + BigInt.from(plus!)) > BaseN.max) {
      // overflow
      return BigInt.from(-1);
    }
    return number;
  }

  static int length(int base) {
    return (longSizeInBit / (log(base) / log(2))).toInt();
  }
}
