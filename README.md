# TSID-Dart

A Dart library for generating Time-Sorted Unique Identifiers (TSID).

This library is a Dart implementation of [tsid-creator](https://github.com/f4b6a3/tsid-creator)

Create a TSID:
```dart
  var tsid = Tsid.getTsid();
```

Create a TSID as long:
```dart
var number = Tsid.getTsid().toLong();
```

create a TSID as string:
```dart
var string = Tsid.getTsid().toString();
```

### Dependency

```yaml
# pubspec.yaml
...
dependencies:
  tsid_dart: ^0.0.2
...
```