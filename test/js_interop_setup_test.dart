@TestOn('browser')
library js_interop_setup_test;

import 'dart:js_interop';
import 'package:test/test.dart';

void main() {
  // Define the suite of JavaScript helper functions in the global scope.
  // This is done once before any tests run.
  setUpAll(() {
    const jsDefinitions = '''
      globalThis.jsEchoTsidString = function(str) {
        // console.log(`JS: jsEchoTsidString received: \${str}`);
        return str;
      };

      globalThis.jsValidateTsidString = function(str) {
        // console.log(`JS: jsValidateTsidString received: \${str}`);
        if (typeof str !== 'string' || str.length !== 13) {
          return false;
        }
        // Regex from subtask description. Note: Allows 'Z'.
        // TSID's Crockford usually excludes U, L, I, O. And 'Z' is typically part of it.
        // For TSID, the valid chars are 0123456789ABCDEFGHJKMNPQRSTVWXYZ.
        const crockfordRegex = /^[0-9A-HJKMNP-TV-Z]{13}$/; 
        if (!crockfordRegex.test(str)) { 
          return false;
        }
        return true;
      };

      globalThis.jsProvideTsidString = function() {
        const tsid = "0123456789ABC"; // Valid according to the regex above
        // console.log(`JS: jsProvideTsidString returning: \${tsid}`);
        return tsid;
      };

      globalThis.jsReceiveNumber = function(num) {
        // console.log(`JS: jsReceiveNumber received: \${num} (type: \${typeof num})`);
        return num;
      };

      globalThis.jsReceiveAsBigInt = function(jsBi) {
        // console.log(`JS: jsReceiveAsBigInt received: \${jsBi} (type: \${typeof jsBi})`);
        if (typeof jsBi !== 'bigint') {
          return "Error: Expected a BigInt, got " + (typeof jsBi);
        }
        return jsBi.toString(); // Return as string for Dart to handle
      };

      globalThis.jsProvideMalformedTsidString = function() {
        // 'L' is not in the typical TSID Crockford alphabet and also not in the regex provided.
        // The regex /^[0-9A-HJKMNP-TV-Z]{13}$/ does NOT match L.
        return "0123456789ABL"; 
      };

      globalThis.jsProvideShortTsidString = function() {
        const shortTsid = "0123456789AB";
        // console.log(`JS: jsProvideShortTsidString returning: \${shortTsid}`);
        return shortTsid;
      };
    ''';

    try {
      (globalContext['eval'.toJS] as JSFunction).callAsConstructor<JSObject>(jsDefinitions.toJS);
    } catch (e) {
      print('Failed to define JS helper functions using eval: $e');
      // This would likely cause subsequent tests to fail when functions aren't found.
      // For a setup verification, this failure is critical.
      throw StateError('Could not define essential JavaScript helper functions: $e');
    }
  });

  group('JavaScript Helper Function Verification', () {
    test('jsEchoTsidString is defined and callable', () {
      final func = globalContext['jsEchoTsidString'.toJS] as JSFunction?;
      expect(func, isNotNull, reason: 'jsEchoTsidString should be defined');
      final testStr = 'TestString123'.toJS;
      final result = func!.call(null, testStr) as JSString?;
      expect(result?.toDart, equals('TestString123'));
    });

    test('jsValidateTsidString is defined and callable', () {
      final func = globalContext['jsValidateTsidString'.toJS] as JSFunction?;
      expect(func, isNotNull, reason: 'jsValidateTsidString should be defined');
      expect((func!.call(null, '0123456789ABC'.toJS) as JSBoolean?)?.toDart, isTrue);
      expect((func.call(null, '0123456789ABL'.toJS) as JSBoolean?)?.toDart, isFalse); // L is invalid by regex
      expect((func.call(null, 'short'.toJS) as JSBoolean?)?.toDart, isFalse);
    });

    test('jsProvideTsidString is defined and callable', () {
      final func = globalContext['jsProvideTsidString'.toJS] as JSFunction?;
      expect(func, isNotNull, reason: 'jsProvideTsidString should be defined');
      final result = func!.call(null) as JSString?;
      expect(result?.toDart, equals('0123456789ABC'));
    });

    test('jsReceiveNumber is defined and callable', () {
      final func = globalContext['jsReceiveNumber'.toJS] as JSFunction?;
      expect(func, isNotNull, reason: 'jsReceiveNumber should be defined');
      final testNum = 123.45.toJS;
      final result = func!.call(null, testNum) as JSNumber?;
      // JS numbers are doubles
      expect(result?.toDart, equals(123.45));
    });

    test('jsReceiveAsBigInt is defined and callable', () {
      final func = globalContext['jsReceiveAsBigInt'.toJS] as JSFunction?;
      expect(func, isNotNull, reason: 'jsReceiveAsBigInt should be defined');
      
      // Create a JS BigInt using JS eval for the test input
      final jsBigIntVal = (globalContext['eval'.toJS] as JSFunction).call(null, '12345678901234567890n'.toJS);
      final result = func!.call(null, jsBigIntVal) as JSString?;
      expect(result?.toDart, equals('12345678901234567890'));

      final notABigInt = 'not a bigint'.toJS;
      final errorResult = func.call(null, notABigInt) as JSString?;
      expect(errorResult?.toDart, contains('Error: Expected a BigInt'));
    });

    test('jsProvideMalformedTsidString is defined and callable', () {
      final func = globalContext['jsProvideMalformedTsidString'.toJS] as JSFunction?;
      expect(func, isNotNull, reason: 'jsProvideMalformedTsidString should be defined');
      final result = func!.call(null) as JSString?;
      expect(result?.toDart, equals('0123456789ABL'));
    });

    test('jsProvideShortTsidString is defined and callable', () {
      final func = globalContext['jsProvideShortTsidString'.toJS] as JSFunction?;
      expect(func, isNotNull, reason: 'jsProvideShortTsidString should be defined');
      final result = func!.call(null) as JSString?;
      expect(result?.toDart, equals('0123456789AB'));
    });
  });
}
