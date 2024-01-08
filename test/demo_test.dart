import 'package:tsid_dart/tsid_dart.dart';

void main() {
  final String HORIZONTAL_LINE = "----------------------------------------";

  print(HORIZONTAL_LINE);
  print("### TSID number");
  print(HORIZONTAL_LINE);

  for (var i = 0; i < 100; i++) {
    print(Tsid.getTsid1024().toLong());
  }

  print(HORIZONTAL_LINE);
  print("### TSID string");
  print(HORIZONTAL_LINE);

  for (var i = 0; i < 100; i++) {
    print(Tsid.getTsid1024().toString());
  }
}
