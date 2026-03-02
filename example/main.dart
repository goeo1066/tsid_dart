import 'package:tsid_dart/tsid_dart.dart';

void main() {
  final tsid = Tsid.getTsid();
  final parsed = Tsid.fromString(tsid.toString());
  final fromFactory = TsidFactory().create();

  print('Generated : ${tsid.toString()}');
  print('As number : ${tsid.toLong()}');
  print('Parsed ok : ${parsed == tsid}');
  print('Factory   : ${fromFactory.toString()}');
}
