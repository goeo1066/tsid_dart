/// Support for doing something awesome.
///
/// More dartdocs go here.
library;

export 'src/tsid_stub.dart'
    if (dart.library.io) 'src/tsid_default.dart'
    if (dart.library.html) 'src/tsid_web.dart';
export 'src/tsid_error.dart';
