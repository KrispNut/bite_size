import 'package:flutter/foundation.dart';
import '/core/theme/activity_packs.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/features/dashboard/models/shared_expense.dart';
import '/features/dashboard/models/ping.dart';
import '/features/dashboard/models/roster_entry.dart';
import '/features/dashboard/models/activity_session.dart';
import '/features/ledger/models/ledger_transaction.dart';

/// Service layer interacting with Supabase database and authentication.
class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();
  factory SupabaseService() => instance;
  SupabaseService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  /// Session doc ID for today, e.g. "2026-07-17".
  /// Pack-aware: the lunch pack keeps bare dates, every other pack prefixes
  /// its id, so two packs never share a day's row.
  static String todaySessionId() => PackService.todaySessionId();

  // --- STREAMS ---

  /// Emits today's session updates.
  Stream<ActivitySession?> watchSession(String sessionId) {
    debugPrint(
      '📡 [SUPABASE DB] Listening to session stream for ID: $sessionId',
    );
    return _client
        .from('sessions')
        .stream(primaryKey: ['id'])
        .eq('id', sessionId)
        .map((list) {
          debugPrint(
            '💾 [SUPABASE DB] Received session snapshot for $sessionId: ${list.isNotEmpty ? list.first : "No session yet"}',
          );
          if (list.isEmpty) return null;
          return ActivitySession.fromJson(list.first);
        });
  }

  /// Emits entry list updates for the session.
  Stream<List<RosterEntry>> watchEntries(String sessionId) {
    debugPrint(
      '📡 [SUPABASE DB] Listening to entries stream for session ID: $sessionId',
    );
    return _client
        .from('entries')
        .stream(primaryKey: ['session_id', 'user_id'])
        .eq('session_id', sessionId)
        .asyncMap((list) async {
          debugPrint(
            '💾 [SUPABASE DB] Received entries snapshot count: ${list.length}',
          );
          final entries = list
              .map((json) => RosterEntry.fromJson(json))
              .toList();

          // Fetch user profile details (latest name & photo) from public.users
          final userIds = entries.map((e) => e.userId).toSet();
          if (userIds.isNotEmpty) {
            try {
              final usersData = await _client
                  .from('users')
                  .select('id, name, photo_url')
                  .inFilter('id', userIds.toList());
              final userMap = <String, Map<String, String>>{};
              for (final row in usersData) {
                final uid = row['id']?.toString();
                if (uid != null) {
                  userMap[uid] = {
                    'name': row['name']?.toString() ?? '',
                    'photo_url': row['photo_url']?.toString() ?? '',
                  };
                }
              }
              for (var i = 0; i < entries.length; i++) {
                final e = entries[i];
                if (userMap.containsKey(e.userId)) {
                  final u = userMap[e.userId]!;
                  final newName = u['name']!;
                  final newPhoto = u['photo_url']!;
                  entries[i] = e.copyWith(
                    userName: newName.isNotEmpty ? newName : e.userName,
                    userPhotoUrl: newPhoto.isNotEmpty
                        ? newPhoto
                        : e.userPhotoUrl,
                  );
                }
              }
            } catch (e) {
              debugPrint('⚠️ Error fetching user profile details: $e');
            }
          }

          entries.sort((a, b) {
            if (a.createdAt == null) return 1;
            if (b.createdAt == null) return -1;
            return a.createdAt!.compareTo(b.createdAt!);
          });
          return entries;
        });
  }

  /// Upload a user profile avatar image to Supabase Storage bucket `avatars`.
  /// Returns the public URL of the uploaded image.
  Future<String> uploadAvatar({
    required String userId,
    required List<int> imageBytes,
    required String fileExtension,
  }) async {
    final fileName =
        '$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
    debugPrint(
      '🚀 [SUPABASE STORAGE] Uploading avatar $fileName | Size: ${imageBytes.length} bytes',
    );
    try {
      await _client.storage
          .from('avatars')
          .uploadBinary(
            fileName,
            Uint8List.fromList(imageBytes),
            fileOptions: FileOptions(
              contentType: 'image/$fileExtension',
              upsert: true,
            ),
          );
      final publicUrl = _client.storage.from('avatars').getPublicUrl(fileName);
      debugPrint(
        '✅ [SUPABASE STORAGE SUCCESS] Uploaded avatar public URL: $publicUrl',
      );
      return publicUrl;
    } catch (e, st) {
      debugPrint('❌ [SUPABASE STORAGE ERROR] Failed uploadAvatar: $e\n$st');
      rethrow;
    }
  }

  /// Update user profile (name & photo URL) in public.users and auth.user metadata.
  Future<void> updateUserProfile({
    required String userId,
    required String name,
    String? photoUrl,
  }) async {
    debugPrint(
      '🚀 [SUPABASE DB] Updating profile for user $userId | Name: $name | Photo: $photoUrl',
    );
    try {
      await _client
          .from('users')
          .update({
            'name': name,
            if (photoUrl != null && photoUrl.isNotEmpty) 'photo_url': photoUrl,
          })
          .eq('id', userId);

      await _client
          .from('entries')
          .update({
            'user_name': name,
            if (photoUrl != null && photoUrl.isNotEmpty)
              'user_photo_url': photoUrl,
          })
          .eq('user_id', userId);

      await _client
          .from('sessions')
          .update({'tandoor_runner_name': name})
          .eq('tandoor_runner_id', userId);

      await _client.auth.updateUser(
        UserAttributes(
          data: {
            'name': name,
            if (photoUrl != null && photoUrl.isNotEmpty) 'avatar_url': photoUrl,
            if (photoUrl != null && photoUrl.isNotEmpty) 'picture': photoUrl,
          },
        ),
      );
      debugPrint(
        '✅ [SUPABASE DB SUCCESS] User profile, entries & sessions updated!',
      );
    } catch (e, st) {
      debugPrint('❌ [SUPABASE DB ERROR] Failed updateUserProfile: $e\n$st');
      rethrow;
    }
  }

  /// The device token push goes to. Written by PushService on sign-in and
  /// whenever Firebase rotates it; read by the ping-push Edge Function.
  Future<void> saveFcmToken({
    required String userId,
    required String token,
  }) async {
    debugPrint('🚀 [SUPABASE DB] Saving FCM token for $userId');
    await _client.from('users').update({'fcm_token': token}).eq('id', userId);
  }

  // --- WRITES ---

  /// Today's (or any day's) session row, created by `ensure_session()` if
  /// nobody has touched that day yet.
  Future<ActivitySession> _ensureSession(String sessionId) async {
    await _client.rpc('ensure_session', params: {'p_session_id': sessionId});
    final row = await _client
        .from('sessions')
        .select()
        .eq('id', sessionId)
        .single();
    return ActivitySession.fromJson(row);
  }

  /// Create or update the user's entry for the day.
  Future<void> upsertEntry({
    required String sessionId,
    required RosterEntry entry,
  }) async {
    debugPrint(
      '🚀 [SUPABASE DB] Attempting upsertEntry | User: "${entry.userName}" (${entry.userId}) | contribution: "${entry.contribution}" | covers: ${entry.covers} | units: ${entry.unitsTaken}',
    );
    try {
      // The user row is created by seeding and bound by claim_identity() —
      // never minted here. Auto-creating it would let anyone who authenticates
      // add themselves to the roster, which is exactly what the allowlist
      // exists to prevent.

      final session = await _ensureSession(sessionId);
      if (session.status != SessionStatus.open) {
        throw StateError('Roster is locked for today.');
      }

      await _client.from('entries').upsert(entry.toJson(sessionId));
      debugPrint(
        '✅ [SUPABASE DB SUCCESS] Successfully upserted entry for ${entry.userName}!',
      );
    } catch (e, st) {
      debugPrint('❌ [SUPABASE DB ERROR] Failed upsertEntry: $e\n$st');
      rethrow;
    }
  }

  /// Give today's errand to someone. [userId] is null for an outsider with no
  /// account, such as the office boy.
  Future<void> assignRunner({
    required String sessionId,
    String? userId,
    required String userName,
  }) async {
    try {
      // The admin can pick a runner before anyone has added an entry.
      final session = await _ensureSession(sessionId);
      if (session.hasRunner) {
        throw StateError('${session.runnerName} already has it.');
      }

      await _client
          .from('sessions')
          .update({
            'tandoor_runner_id': userId,
            'tandoor_runner_name': userName,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', sessionId);
    } catch (e, st) {
      debugPrint('❌ [SUPABASE DB ERROR] Failed assignRunner: $e\n$st');
      rethrow;
    }
  }

  /// Adds a shared expense and invites the people on it.
  ///
  /// `create_extra_order()` in Postgres does the split, so the per-person
  /// amounts always add back up to the cost exactly.
  Future<void> createSharedExpense({
    required String sessionId,
    required String description,
    required int costMinor,
    required String paidById,
    required List<String> participantIds,
  }) async {
    try {
      await _client.rpc(
        'create_extra_order',
        params: {
          'p_session_id': sessionId,
          'p_description': description,
          'p_cost_minor': costMinor,
          'p_paid_by': paidById,
          'p_participants': participantIds,
        },
      );
    } catch (e, st) {
      debugPrint('❌ [SUPABASE DB ERROR] Failed createSharedExpense: $e\n$st');
      rethrow;
    }
  }

  Future<void> deleteSharedExpense(String expenseId) async {
    await _client.from('extra_orders').delete().eq('id', expenseId);
  }

  /// Accept or decline an invite. Postgres re-splits the cost across whoever
  /// is still in, so a decline never leaves a hole in the bill.
  Future<void> respondToSharedExpense({
    required String expenseId,
    required bool accept,
  }) async {
    try {
      await _client.rpc(
        'respond_to_extra_order',
        params: {'p_order_id': expenseId, 'p_accept': accept},
      );
    } catch (e, st) {
      debugPrint(
        '❌ [SUPABASE DB ERROR] Failed respondToSharedExpense: $e\n$st',
      );
      rethrow;
    }
  }

  /// The runner has left: locks the roster and the shared expenses.
  ///
  /// Postgres refuses while any shared expense is unanswered, since the
  /// runner wouldn't know what to buy.
  Future<void> markDeparted(String sessionId) async {
    try {
      await _client.rpc(
        'depart_for_tandoor',
        params: {'p_session_id': sessionId},
      );
    } catch (e, st) {
      debugPrint('❌ [SUPABASE DB ERROR] Failed markDeparted: $e\n$st');
      rethrow;
    }
  }

  /// Emits the day's shared expenses with each person's share attached.
  Stream<List<SharedExpense>> watchSharedExpenses(String sessionId) {
    return _client
        .from('extra_orders')
        .stream(primaryKey: ['id'])
        .eq('session_id', sessionId)
        .asyncMap((rows) async {
          final expenses = await _withShares(rows);
          expenses.sort((a, b) {
            if (a.createdAt == null) return 1;
            if (b.createdAt == null) return -1;
            return a.createdAt!.compareTo(b.createdAt!);
          });
          return expenses;
        });
  }

  /// Turns `extra_orders` rows into [SharedExpense]s, fetching everyone's
  /// share for them in one query.
  Future<List<SharedExpense>> _withShares(
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) return [];
    final ids = rows.map((row) => row['id'].toString()).toList();
    final shareRows = await _client
        .from('extra_order_shares')
        .select()
        .inFilter('order_id', ids);

    final sharesByExpense = <String, List<ExpenseShare>>{};
    for (final row in shareRows) {
      (sharesByExpense[row['order_id'].toString()] ??= []).add(
        ExpenseShare.fromJson(row),
      );
    }
    return [
      for (final row in rows)
        SharedExpense.fromJson(
          row,
          shares: sharesByExpense[row['id'].toString()] ?? const [],
        ),
    ];
  }

  // ===========================================================================
  // PINGS
  // ===========================================================================

  /// Pings whoever is flagged `is_ping_target` in `public.users`. Raises bare
  /// codes: ping_target_unknown, cannot_ping_self. There is no rate limit
  /// (migration 010): repeat taps are the point.
  ///
  /// The recipient is deliberately not a parameter. `send_ping()` resolves it
  /// server-side (migration 009), so a phone running an older build cannot
  /// ping the person who used to be the target.
  Future<void> sendPing({required String message, String? sessionId}) async {
    debugPrint('🚀 [SUPABASE DB] Pinging the flagged target');
    await _client.rpc(
      'send_ping',
      params: {'p_message': message, 'p_session_id': sessionId},
    );
  }

  /// Pings addressed to [userId]. RLS already restricts reads to your own
  /// rows; the filter keeps the stream small and is belt-and-braces.
  Stream<List<Ping>> watchPingsFor(String userId) {
    debugPrint('📡 [SUPABASE DB] Listening to pings for $userId');
    return _client
        .from('pings')
        .stream(primaryKey: ['id'])
        .eq('to_id', userId)
        .order('created_at', ascending: false)
        .limit(20)
        .map((rows) {
          debugPrint('📬 [SUPABASE DB] Pings stream: ${rows.length} row(s)');
          return rows.map(Ping.fromJson).toList();
        });
  }

  /// Mark what was fetched as having turned up.
  Future<void> markArrived({
    required String sessionId,
    required String announcedByName,
  }) async {
    debugPrint(
      '🚀 [SUPABASE DB] Marking arrival for session $sessionId by $announcedByName',
    );
    try {
      final now = DateTime.now();
      await _client
          .from('sessions')
          .update({
            'arrived_at': now.toUtc().toIso8601String(),
            'arrived_by_name': announcedByName,
            'updated_at': now.toUtc().toIso8601String(),
          })
          .eq('id', sessionId);
      debugPrint('✅ [SUPABASE DB SUCCESS] Marked as arrived!');
    } catch (e, st) {
      debugPrint('❌ [SUPABASE DB ERROR] Failed markArrived: $e\n$st');
      rethrow;
    }
  }

  /// Settles a stretch of days at one [unitPrice]: everyone's units at that
  /// price, owed to [paidById], plus every shared expense at the split its
  /// people already agreed to. Each day is then marked settled with its bulk
  /// cost stored, which is what the ledger reads.
  Future<void> settleSessions({
    required List<String> sessionIds,
    required double unitPrice,
    required String paidById,
    required String paidByName,
  }) async {
    if (sessionIds.isEmpty) return;
    try {
      final entryRows = await _client
          .from('entries')
          .select()
          .inFilter('session_id', sessionIds);
      final entriesBySession = <String, List<RosterEntry>>{};
      for (final row in entryRows) {
        (entriesBySession[row['session_id'] as String] ??= []).add(
          RosterEntry.fromJson(row),
        );
      }

      // One day at a time, so a dropped connection leaves at most one day
      // half-written rather than the whole month.
      for (final sessionId in sessionIds) {
        await _settleSession(
          sessionId: sessionId,
          entries: entriesBySession[sessionId] ?? const [],
          unitPrice: unitPrice,
          paidById: paidById,
          paidByName: paidByName,
        );
      }
    } catch (e, st) {
      debugPrint('❌ [SUPABASE DB ERROR] Failed settleSessions: $e\n$st');
      rethrow;
    }
  }

  /// Shared expenses are read back from the database rather than passed in:
  /// `create_extra_order` already split them exactly, and re-deriving the
  /// shares here would bring the rounding drift back.
  Future<void> _settleSession({
    required String sessionId,
    required List<RosterEntry> entries,
    required double unitPrice,
    required String paidById,
    required String paidByName,
  }) async {
    final totalUnits = entries.fold<int>(
      0,
      (sum, entry) => sum + entry.unitsTaken,
    );
    await _client
        .from('sessions')
        .update({
          'total_roti_cost': totalUnits * unitPrice,
          'status': 'settled',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', sessionId);

    final transactions = <Map<String, dynamic>>[
      for (final entry in entries)
        if (entry.userId != paidById && entry.unitsTaken > 0 && unitPrice > 0)
          {
            'session_id': sessionId,
            'type': TransactionType.units.wire,
            'from_id': entry.userId,
            'from_name': entry.userName,
            'to_id': paidById,
            'to_name': paidByName,
            'amount': (entry.unitsTaken * unitPrice).roundToDouble(),
            'note': '${PackService.labels.unitCount(entry.unitsTaken)} share',
          },
    ];

    final expenseRows = await _client
        .from('extra_orders')
        .select()
        .eq('session_id', sessionId);
    for (final expense in await _withShares(expenseRows)) {
      // Everyone declined, so there is no bill to write.
      if (expense.isCancelled) continue;
      // Only accepted shares: someone who said no never owed anything, and a
      // pending share carries zero anyway.
      for (final share in expense.acceptedShares) {
        if (share.userId == expense.paidById || share.amountMinor <= 0) {
          continue;
        }
        transactions.add({
          'session_id': sessionId,
          'type': TransactionType.sharedExpense.wire,
          'from_id': share.userId,
          'from_name': share.userName,
          'to_id': expense.paidById,
          'to_name': expense.paidByName,
          'amount': share.amount,
          'note': expense.description,
        });
      }
    }

    if (transactions.isNotEmpty) {
      await _client.from('transactions').insert(transactions);
    }
  }

  // =========================================================================
  // LEDGER QUERIES
  // =========================================================================

  /// Fetch all active users, ordered by name.
  Future<List<Map<String, dynamic>>> fetchActiveUsers() async {
    debugPrint('📡 [SUPABASE DB] Fetching all active users');
    try {
      final data = await _client
          .from('users')
          .select()
          .eq('is_active', true)
          .order('name');
      debugPrint('✅ [SUPABASE DB] Fetched ${data.length} active users');
      return List<Map<String, dynamic>>.from(data);
    } catch (e, st) {
      debugPrint('❌ [SUPABASE DB ERROR] Failed fetchActiveUsers: $e\n$st');
      rethrow;
    }
  }

  /// Fetch all entries within a date range for the ledger.
  Future<List<Map<String, dynamic>>> fetchEntriesForRange({
    required String startDate,
    required String endDate,
  }) async {
    debugPrint('📡 [SUPABASE DB] Fetching entries from $startDate to $endDate');
    try {
      final data = await _client
          .from('entries')
          .select('session_id, user_id, user_name, rotis_needed')
          .gte('session_id', startDate)
          .lte('session_id', endDate);
      debugPrint('✅ [SUPABASE DB] Fetched ${data.length} entries for ledger');
      return List<Map<String, dynamic>>.from(data);
    } catch (e, st) {
      debugPrint('❌ [SUPABASE DB ERROR] Failed fetchEntriesForRange: $e\n$st');
      rethrow;
    }
  }

  /// Admin: Upsert an entry for a specific date and user (creates session if needed).
  Future<void> adminUpsertEntry({
    required String sessionId,
    required String userId,
    required String userName,
    required int unitsTaken,
  }) async {
    debugPrint(
      '🚀 [SUPABASE DB] Admin upserting entry | Session: $sessionId | User: $userName | units: $unitsTaken',
    );
    try {
      await _ensureSession(sessionId);

      // Patch ONLY the unit count. Upserting the whole row here used to
      // overwrite the person's real dish name and portion count with
      // 'Admin entry'/0, which also made the session aggregate trigger
      // subtract their portions.
      final existing = await _client
          .from('entries')
          .select('session_id')
          .eq('session_id', sessionId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing == null) {
        await _client.from('entries').insert({
          'session_id': sessionId,
          'user_id': userId,
          'user_name': userName,
          'dish_name': 'Nothing',
          'portions': 0,
          'rotis_needed': unitsTaken,
        });
      } else {
        await _client
            .from('entries')
            .update({'rotis_needed': unitsTaken})
            .eq('session_id', sessionId)
            .eq('user_id', userId);
      }
      debugPrint(
        '✅ [SUPABASE DB SUCCESS] Admin upserted entry for $userName on $sessionId',
      );
    } catch (e, st) {
      debugPrint('❌ [SUPABASE DB ERROR] Failed adminUpsertEntry: $e\n$st');
      rethrow;
    }
  }

  Future<String?> resetSessionData(String sessionId) async {
    try {
      debugPrint('🚨 [SUPABASE DB] Resetting all data for session: $sessionId');
      await _client.from('transactions').delete().eq('session_id', sessionId);
      await _client.from('entries').delete().eq('session_id', sessionId);
      await _client.from('sessions').delete().eq('id', sessionId);
      return null;
    } catch (e) {
      debugPrint('❌ [SUPABASE DB ERROR] Failed resetSessionData: $e');
      return e.toString();
    }
  }
}
