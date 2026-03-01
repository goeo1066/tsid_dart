/// Error thrown when TSID parsing or formatting fails.
class TsidError extends Error {
  /// Human-readable error message.
  late final String message;

  TsidError(this.message);

  @override
  String toString() {
    return "TSID Error: $message";
  }
}
