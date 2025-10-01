/// Text normalization helpers for multi-line exercise fields.
/// - Decodes escaped newlines ("\n") into real line breaks
/// - Normalizes Windows line endings
/// - Trims trailing whitespace per line while preserving intentional blank lines
extension TextNormalizer on String {
  String normalizedMultiline() {
    if (isEmpty) return this;
    // First normalize CRLF to LF
    var out = replaceAll('\r\n', '\n');
    // Decode escaped literal backslash-n sequences (two characters: \ + n)
    out = out.replaceAll('\\n', '\n');
    // Optionally collapse triple blank lines to double to avoid huge gaps
    out = out.replaceAll(RegExp('\n{3,}'), '\n\n');
    // Trim right whitespace on each line (left spaces kept for formatting if any)
    out = out
        .split('\n')
        .map((l) => l.replaceAll(RegExp(r'[ \t]+$'), ''))
        .join('\n');
    return out;
  }

  /// (Optional) highlight steps pattern "Bước X:" by wrapping with markers.
  /// Currently unused; kept for future styling with RichText if needed.
  List<String> splitLines() => normalizedMultiline().split('\n');
}
