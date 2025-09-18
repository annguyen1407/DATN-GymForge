/// Centralized date utility helpers for formatting and parsing
/// across the workout feature. Avoids duplicating display logic
/// and relying on human-readable strings for programmatic parsing.
class AppDateUtils {
  /// Format a date to dd/MM/yyyy (no time component)
  static String formatDdMMyyyy(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  /// Try to parse either an ISO-8601 string or a dd/MM/yyyy display string.
  /// Returns null if parsing fails.
  static DateTime? parseIsoOrDisplay(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final s = raw.trim();
    // ISO first (contains 'T' or '-')
    try {
      if (s.contains('T') || _isoLike(s)) {
        final iso = DateTime.tryParse(s);
        if (iso != null) return iso;
      }
    } catch (_) {}
    // dd/MM/yyyy fallback
    if (s.contains('/')) {
      final parts = s.split('/');
      if (parts.length == 3) {
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2]);
        if (d != null && m != null && y != null) {
          return DateTime(y, m, d);
        }
      }
    }
    // yyyy-MM-dd without time (still ISO-like but without T)
    if (_isoLike(s)) {
      try {
        return DateTime.parse(s);
      } catch (_) {}
    }
    return null;
  }

  /// Normalize a DateTime to local date only (strip time component)
  static DateTime normalizeToLocalDate(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  static bool _isoLike(String s) {
    // quick heuristic: 4-digit year-2-digit month-2-digit day
    // length 10 pattern yyyy-MM-dd
    if (s.length >= 10 && s[4] == '-' && s[7] == '-') return true;
    return false;
  }
}
