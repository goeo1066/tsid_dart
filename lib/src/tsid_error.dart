class TsidError extends Error {
  late final String message;

  TsidError(this.message);

  @override
  String toString() {
    return "TSID Error: $message";
  }
}
