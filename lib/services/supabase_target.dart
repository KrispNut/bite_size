import 'package:flutter_dotenv/flutter_dotenv.dart';
import '/core/theme/activity_packs.dart';

/// Which Supabase project a pack talks to.
///
/// Packs can live in separate projects — `ground_booking` has its own, named
/// by `GROUND_SUPABASE_URL` / `GROUND_SUPABASE_ANON_KEY` in `.env` — and fall
/// back to the main project when those keys are absent. Resolving the target
/// in one place matters because it is needed twice: at cold start in
/// `main()`, and again when someone switches pack in the picker, where the
/// client has to be torn down and rebuilt against the other project. Two
/// copies of this logic would drift.
///
/// Inside a single project, sessions are still kept apart by the pack prefix
/// on `sessions.id` (migration 007). Separate projects keep everything apart;
/// the prefix keeps the data apart even if two packs are ever pointed at one.
class SupabaseTarget {
  final String name;
  final String url;
  final String anonKey;

  const SupabaseTarget({
    required this.name,
    required this.url,
    required this.anonKey,
  });

  static SupabaseTarget forPack(ActivityPack pack) {
    final main = SupabaseTarget(
      name: 'bite-size',
      url: (dotenv.env['SUPABASE_URL'] ?? '').trim(),
      anonKey: (dotenv.env['SUPABASE_ANON_KEY'] ?? '').trim(),
    );
    if (pack.id != 'ground_booking') return main;

    final url = (dotenv.env['GROUND_SUPABASE_URL'] ?? '').trim();
    final key = (dotenv.env['GROUND_SUPABASE_ANON_KEY'] ?? '').trim();
    if (url.isEmpty) return main;
    return SupabaseTarget(
      name: 'ground-booking',
      url: url,
      anonKey: key.isNotEmpty ? key : main.anonKey,
    );
  }

  /// Same project, regardless of how the key was resolved.
  bool sameProjectAs(SupabaseTarget other) => url == other.url;
}
