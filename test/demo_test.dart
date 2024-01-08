import 'package:tsid_dart/tsid_dart.dart';

void main() {
  final String horizontalLine = "----------------------------------------";

  print(horizontalLine);
  print("### TSID number");
  print(horizontalLine);

  for (var i = 0; i < 100; i++) {
    print(Tsid.getTsid1024().toLong());
  }

  print(horizontalLine);
  print("### TSID string");
  print(horizontalLine);

  for (var i = 0; i < 100; i++) {
    print(Tsid.getTsid1024().toString());
  }
}
