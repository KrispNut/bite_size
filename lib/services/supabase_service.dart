import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/features/dashboard/models/extra_order.dart';
import '/features/dashboard/models/lunch_entry.dart';
import '/features/dashboard/models/lunch_session.dart';
import '/features/ledger/models/ledger_transaction.dart';

/// Service layer interacting with Supabase database and authentication.
class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();
  factory SupabaseService() => instance;
  SupabaseService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  /// Session doc ID for today, e.g. "2026-07-17".
  static String todaySessionId() =>
      DateFormat('yyyy-MM-dd').format(DateTime.now());

  // --- STREAMS ---

  /// Emits today's session updates.
  Stream<LunchSession?> watchSession(String sessionId) {
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
          return LunchSession.fromJson(list.first);
        });
  }

  /// Emits entry list updates for the session.
  Stream<List<LunchEntry>> watchEntries(String sessionId) {
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
              .map((json) => LunchEntry.fromJson(json))
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
      await _client.from('users').upsert({
        'id': userId,
        'name': name,
        'email': _client.auth.currentUser?.email ?? '',
        'photo_url': ?photoUrl,
      });

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
        UserAttributes(data: {'name': name, 'avatar_url': ?photoUrl}),
      );
      debugPrint(
        '✅ [SUPABASE DB SUCCESS] User profile, entries & sessions updated!',
      );
    } catch (e, st) {
      debugPrint('❌ [SUPABASE DB ERROR] Failed updateUserProfile: $e\n$st');
      rethrow;
    }
  }

  // --- WRITES ---

  /// Create or update the user's entry for the day.
  Future<void> upsertEntry({
    required String sessionId,
    required LunchEntry entry,
  }) async {
    debugPrint(
      '🚀 [SUPABASE DB] Attempting upsertEntry | User: "${entry.userName}" (${entry.userId}) | Dish: "${entry.dishName}" | Portions: ${entry.portions} | Rotis: ${entry.rotisNeeded}',
    );
    try {
      // 1. Ensure user profile exists in public.users table
      debugPrint(
        '👤 [SUPABASE DB] Ensuring user profile exists in public.users table for ${entry.userId}',
      );
      await _client.from('users').upsert({
        'id': entry.userId,
        'name': entry.userName,
        'email': _client.auth.currentUser?.email ?? '',
        if (entry.userPhotoUrl != null) 'photo_url': entry.userPhotoUrl,
      });

      // 2. Ensure the session exists
      final sessionResponse = await _client
          .from('sessions')
          .select()
          .eq('id', sessionId)
          .maybeSingle();

      if (sessionResponse == null) {
        final now = DateTime.now();
        debugPrint(
          '➕ [SUPABASE DB] Creating new daily session doc for $sessionId',
        );
        await _client.from('sessions').insert({
          'id': sessionId,
          'date': DateTime(
            now.year,
            now.month,
            now.day,
          ).toIso8601String().substring(0, 10),
          'cutoff_at': DateTime(
            now.year,
            now.month,
            now.day,
            12,
            30,
          ).toIso8601String(),
          'status': 'open',
        });
      } else {
        final session = LunchSession.fromJson(sessionResponse);
        if (session.status != SessionStatus.open) {
          debugPrint(
            '⚠️ [SUPABASE DB] Roster is locked for session $sessionId',
          );
          throw StateError('Roster is locked for today.');
        }
      }

      // 2. Upsert entry
      await _client.from('entries').upsert(entry.toJson(sessionId));
      debugPrint(
        '✅ [SUPABASE DB SUCCESS] Successfully upserted entry for ${entry.userName}!',
      );
    } catch (e, st) {
      debugPrint('❌ [SUPABASE DB ERROR] Failed upsertEntry: $e\n$st');
      rethrow;
    }
  }

  /// Claim the Tandoor Runner role.
  Future<void> claimTandoorRunner({
    required String sessionId,
    String? userId,
    required String userName,
  }) async {
    debugPrint(
      '🚀 [SUPABASE DB] Attempting claimTandoorRunner | User: "$userName" ($userId) | Session: $sessionId',
    );
    try {
      final sessionResponse = await _client
          .from('sessions')
          .select()
          .eq('id', sessionId)
          .maybeSingle();

      if (sessionResponse == null) {
        debugPrint(
          '⚠️ [SUPABASE DB] Session does not exist yet for $sessionId',
        );
        throw StateError('Add your entry first to start today\'s session.');
      }

      final session = LunchSession.fromJson(sessionResponse);
      if (session.hasRunner) {
        debugPrint(
          '⚠️ [SUPABASE DB] Runner already claimed by ${session.tandoorRunnerName}',
        );
        throw StateError('${session.tandoorRunnerName} already claimed it.');
      }

      await _client
          .from('sessions')
          .update({
            'tandoor_runner_id': userId,
            'tandoor_runner_name': userName,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId);
      debugPrint(
        '✅ [SUPABASE DB SUCCESS] Successfully claimed Tandoor Runner for $userName!',
      );
    } catch (e, st) {
      debugPrint('❌ [SUPABASE DB ERROR] Failed claimTandoorRunner: $e\n$st');
      rethrow;
    }
  }

  /// Emits transactions created for a session.
  Stream<List<LedgerTransaction>> watchTransactions(String sessionId) {
    debugPrint(
      '📡 [SUPABASE DB] Listening to transactions stream for session ID: $sessionId',
    );
    return _client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('session_id', sessionId)
        .map((list) {
          debugPrint(
            '💾 [SUPABASE DB] Received transactions snapshot count: ${list.length}',
          );
          return list.map((json) => LedgerTransaction.fromJson(json)).toList();
        });
  }

  /// Mark today's food as arrived at the office table.
  Future<void> markFoodArrived({
    required String sessionId,
    required String announcedByName,
  }) async {
    debugPrint(
      '🚀 [SUPABASE DB] Marking food arrived for session $sessionId by $announcedByName',
    );
    try {
      final now = DateTime.now();
      await _client
          .from('sessions')
          .update({
            'arrived_at': now.toIso8601String(),
            'arrived_by_name': announcedByName,
            'updated_at': now.toIso8601String(),
          })
          .eq('id', sessionId);
      debugPrint('✅ [SUPABASE DB SUCCESS] Food marked as arrived!');
    } catch (e, st) {
      debugPrint('❌ [SUPABASE DB ERROR] Failed markFoodArrived: $e\n$st');
      rethrow;
    }
  }

  /// Settle session billings and insert transactions into the ledger.
  Future<void> settleSessionBilling({
    required String sessionId,
    required double totalRotiCost,
    required List<ExtraOrder> extraOrders,
    required List<LunchEntry> entries,
    required String paidById,
    required String paidByName,
  }) async {
    debugPrint(
      '🚀 [SUPABASE DB] Settling billing for session $sessionId | Total Rotis Cost: $totalRotiCost | Extra Orders: ${extraOrders.length}',
    );
    try {
      final now = DateTime.now();

      // 1. Update session status & roti cost
      await _client
          .from('sessions')
          .update({
            'total_roti_cost': totalRotiCost,
            'status': 'settled',
            'updated_at': now.toIso8601String(),
          })
          .eq('id', sessionId);

      // 2. Insert Extra Orders if any
      for (final extra in extraOrders) {
        await _client.from('extra_orders').insert(extra.toJson());
      }

      // 3. Calculate and insert transactions
      final transactions = <Map<String, dynamic>>[];

      // Roti cost breakdown
      final totalRotis = entries.fold<int>(0, (sum, e) => sum + e.rotisNeeded);
      if (totalRotis > 0 && totalRotiCost > 0) {
        for (final entry in entries) {
          final share = (entry.rotisNeeded / totalRotis) * totalRotiCost;
          if (entry.userId != paidById && share > 0) {
            transactions.add({
              'session_id': sessionId,
              'type': TransactionType.roti.name,
              'from_id': entry.userId,
              'from_name': entry.userName,
              'to_id': paidById,
              'to_name': paidByName,
              'amount': share.roundToDouble(),
              'note': '${entry.rotisNeeded} rotis share',
            });
          }
        }
      }

      // Extra orders breakdown
      for (final extra in extraOrders) {
        if (extra.sharedByIds.isNotEmpty && extra.cost > 0) {
          final perPersonCost = (extra.cost / extra.sharedByIds.length)
              .roundToDouble();
          for (final userId in extra.sharedByIds) {
            if (userId != extra.paidById) {
              final participant = entries.firstWhere(
                (e) => e.userId == userId,
                orElse: () => LunchEntry(
                  userId: userId,
                  userName: 'Coworker',
                  dishName: '',
                  portions: 0,
                  rotisNeeded: 0,
                ),
              );

              transactions.add({
                'session_id': sessionId,
                'type': TransactionType.extraFood.name,
                'from_id': userId,
                'from_name': participant.userName,
                'to_id': extra.paidById,
                'to_name': extra.paidByName,
                'amount': perPersonCost,
                'note': extra.description,
              });
            }
          }
        }
      }

      if (transactions.isNotEmpty) {
        debugPrint(
          '➕ [SUPABASE DB] Inserting ${transactions.length} ledger transactions',
        );
        await _client.from('transactions').insert(transactions);
      }

      debugPrint(
        '✅ [SUPABASE DB SUCCESS] Successfully settled session billing!',
      );
    } catch (e, st) {
      debugPrint('❌ [SUPABASE DB ERROR] Failed settleSessionBilling: $e\n$st');
      rethrow;
    }
  }

  // =========================================================================
  // ROTI LEDGER QUERIES
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

  /// Fetch all entries within a date range for the Roti Ledger.
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
    required int rotisNeeded,
  }) async {
    debugPrint('🚀 [SUPABASE DB] Admin upserting entry | Session: $sessionId | User: $userName | Rotis: $rotisNeeded');
    try {
      // Ensure session exists
      final sessionResponse = await _client
          .from('sessions')
          .select()
          .eq('id', sessionId)
          .maybeSingle();

      if (sessionResponse == null) {
        final date = DateTime.parse(sessionId);
        debugPrint('➕ [SUPABASE DB] Creating session for $sessionId');
        await _client.from('sessions').insert({
          'id': sessionId,
          'date': sessionId,
          'cutoff_at': DateTime(date.year, date.month, date.day, 12, 30).toIso8601String(),
          'status': 'open',
        });
      }

      // Upsert entry
      await _client.from('entries').upsert({
        'session_id': sessionId,
        'user_id': userId,
        'user_name': userName,
        'dish_name': 'Admin entry',
        'portions': 0,
        'rotis_needed': rotisNeeded,
      });
      debugPrint('✅ [SUPABASE DB SUCCESS] Admin upserted entry for $userName on $sessionId');
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
