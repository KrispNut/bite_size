import '/core/theme/activity_packs.dart';

/// Fixed geometry for the ledger table.
///
/// The name column, the scrolling day grid and the pinned month column are
/// three separate widgets that have to line up to the pixel. They agree by
/// reading these, not by each hard-coding the same number.
class LedgerMetrics {
  LedgerMetrics._();

  static const double rowHeight = 58;
  static const double headHeight = 44;
  static const double nameColWidth = 140;
  static const double totalColWidth = 86;
  static const double dayColWidth = 58;

  /// The session id a day's data is stored under for the *running pack* —
  /// `2026-09-14` for lunch, `ground_booking:2026-09-14` for cricket. The
  /// ledger reads whichever pack you're in; it never mixes the two.
  static String dateKeyOf(DateTime d) => PackService.sessionIdFor(d);
}
