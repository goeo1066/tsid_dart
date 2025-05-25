@TestOn('browser')
library tsid_js_interop_test;

import 'package:test/test.dart';
import 'package:tsid_dart/tsid_dart.dart'; // Uses tsid_web.dart in browser
import 'dart:js_interop';

// JSFunction references - initialized in setUpAll
late final JSFunction jsEchoTsidString;
late final JSFunction jsValidateTsidString;
late final JSFunction jsProvideTsidString;
late final JSFunction jsReceiveNumber;
late final JSFunction jsReceiveAsBigInt;
late final JSFunction jsProvideMalformedTsidString;
late final JSFunction jsProvideShortTsidString;

void main() {
  setUpAll(() {
    // Initialize JSFunction references from the global context
    // Assumes these functions were defined globally by js_interop_setup_test.dart's setUpAll
    // or a similar mechanism if that file isn't run first by the test runner.
    // For robust testing, it's better if the setup file (js_interop_setup_test.dart)
    // is guaranteed to run its setUpAll before this file's tests.
    // If not, these definitions might need to be duplicated or ensured here.
    // For now, we assume they are available from the previous task's execution.

    var func = globalContext['jsEchoTsidString'.toJS];
    if (func == null || func == undefined) throw StateError('jsEchoTsidString not found');
    jsEchoTsidString = func as JSFunction;

    func = globalContext['jsValidateTsidString'.toJS];
    if (func == null || func == undefined) throw StateError('jsValidateTsidString not found');
    jsValidateTsidString = func as JSFunction;

    func = globalContext['jsProvideTsidString'.toJS];
    if (func == null || func == undefined) throw StateError('jsProvideTsidString not found');
    jsProvideTsidString = func as JSFunction;

    func = globalContext['jsReceiveNumber'.toJS];
    if (func == null || func == undefined) throw StateError('jsReceiveNumber not found');
    jsReceiveNumber = func as JSFunction;

    func = globalContext['jsReceiveAsBigInt'.toJS];
    if (func == null || func == undefined) throw StateError('jsReceiveAsBigInt not found');
    jsReceiveAsBigInt = func as JSFunction;

    func = globalContext['jsProvideMalformedTsidString'.toJS];
    if (func == null || func == undefined) throw StateError('jsProvideMalformedTsidString not found');
    jsProvideMalformedTsidString = func as JSFunction;

    func = globalContext['jsProvideShortTsidString'.toJS];
    if (func == null || func == undefined) throw StateError('jsProvideShortTsidString not found');
    jsProvideShortTsidString = func as JSFunction;
  });

  group('Dart to JS String Passing', () {
    test('Echo TSID String', () {
      final tsid = Tsid.fast();
      final tsidStr = tsid.toString();
      final echoedStr = jsEchoTsidString.call(null, tsidStr.toJS) as JSString?;
      expect(echoedStr?.toDart, equals(tsidStr));
    });

    test('Validate TSID String (Valid Case)', () {
      final tsid = Tsid.fast();
      final tsidStr = tsid.toString();
      final isValid = jsValidateTsidString.call(null, tsidStr.toJS) as JSBoolean?;
      expect(isValid?.toDart, isTrue);
    });

    test('Validate TSID String (Invalid Case - by JS standards)', () {
      // "0123456789ABL" - 'L' is rejected by the regex in jsValidateTsidString
      final invalidForJsValidation = "0123456789ABL".toJS;
      final isValid = jsValidateTsidString.call(null, invalidForJsValidation) as JSBoolean?;
      expect(isValid?.toDart, isFalse);
    });
  });

  group('JS to Dart String Passing', () {
    test('Parse Valid TSID String from JS', () {
      final tsidStrFromJs = jsProvideTsidString.call(null) as JSString?;
      expect(tsidStrFromJs, isNotNull, reason: "jsProvideTsidString should return a non-null string");
      final tsid = Tsid.fromString(tsidStrFromJs!.toDart);
      expect(tsid.toString(), equals("0123456789ABC")); // Matches what jsProvideTsidString returns
    });
  });

  group('Numeric Interoperability & Precision', () {
    test('Demonstrate Precision Loss with JS Number', () {
      final bigIntValue = BigInt.parse('12345678901234567890'); // Exceeds JS Number.MAX_SAFE_INTEGER
      final tsid = Tsid(bigIntValue); // TSID stores it as BigInt (for web)

      // Convert Dart BigInt to JS Number (via double). This is where precision is lost.
      final jsNumRepresentation = tsid.toLong().toDouble().toJS;
      
      final returnedNum = jsReceiveNumber.call(null, jsNumRepresentation) as JSNumber?;
      expect(returnedNum, isNotNull);

      // Convert the JS Number back to a Dart double, then to BigInt for comparison
      // Note: returnedNum.toDart is double. BigInt.from(double) can be lossy itself.
      // For a clearer demonstration, we can parse its string representation.
      final returnedDouble = returnedNum!.toDart;
      final returnedBigInt = BigInt.tryParse(returnedDouble.toStringAsFixed(0)); // toStringAsFixed(0) to avoid sci notation
      
      print('Original BigInt: $bigIntValue, JS Number via double: $returnedDouble, Parsed back to BigInt: $returnedBigInt');
      expect(returnedBigInt, isNot(equals(bigIntValue)), 
        reason: "Precision loss expected when TSID's BigInt is forced through JS Number via double.");
    });

    test('Pass BigInt to JS (JS BigInt aware function)', () {
      final bigIntValue = BigInt.parse('12345678901234567890');
      final tsid = Tsid(bigIntValue);

      // tsid.toLong() returns BigInt. .toJS should expose it as JSCompatibleBigInt / JSBigInt
      final jsBigIntRepresentation = tsid.toLong().toJS; 
      
      final returnedString = jsReceiveAsBigInt.call(null, jsBigIntRepresentation) as JSString?;
      expect(returnedString, isNotNull);
      expect(returnedString!.toDart, equals(bigIntValue.toString()),
        reason: "JS function jsReceiveAsBigInt should receive and return the BigInt value as a string correctly.");
    });
  });

  group('Error Handling for Strings from JS', () {
    test('Parse Malformed TSID String from JS (Invalid Character)', () {
      final malformedStr = jsProvideMalformedTsidString.call(null) as JSString?;
      expect(malformedStr, isNotNull);
      // 'L' is not in TSID's Crockford alphabet
      expect(() => Tsid.fromString(malformedStr!.toDart), throwsA(isA<TsidError>()),
        reason: "Parsing a string with invalid characters ('L') should throw TsidError.");
    });

    test('Parse Malformed TSID String from JS (Too Short)', () {
      final shortStr = jsProvideShortTsidString.call(null) as JSString?;
      expect(shortStr, isNotNull);
      expect(() => Tsid.fromString(shortStr!.toDart), throwsA(isA<TsidError>()),
        reason: "Parsing a string that is too short should throw TsidError.");
    });
  });
}
