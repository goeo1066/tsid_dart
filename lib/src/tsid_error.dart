class TsidError extends Error {
  late final message;

  TsidError(this.message);

  @override
  String toString() {
    // TODO: implement toString
    return "TSID Error: $message";
  }
}
