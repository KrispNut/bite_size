import '/core/theme/activity_packs.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/network/network_monitor.dart';
import '../../services/identity_service.dart';
import '../../services/supabase_service.dart';
import '../auth/models/app_user.dart';

class DayPricing {
  final int totalUnits;
  final double cost;

  const DayPricing({required this.totalUnits, required this.cost});

  double? get unitPrice => totalUnits > 0 ? cost / totalUnits : null;
}

class LedgerViewModel extends ChangeNotifier {
  DateTime currentMonth = DateTime.now();
  late DateTime selectedDate = DateTime.now();
  List<AppUser> users = [];
  Map<String, Map<String, int>> ledgerData = {};

  Map<String, DayPricing> pricing = {};

  /// `sessions.status` for each day of the month that has a session row.
  final Map<String, String> _sessionStatus = {};

  bool isLoading = false;
  String? error;

  StreamSubscription<bool>? _networkSub;

  bool get isAdmin => IdentityService.instance.isAdmin;
  String get currentUid => IdentityService.instance.appUserId;

  void selectDate(DateTime date) {
    selectedDate = date;
    notifyListeners();
  }

  void setMonth(DateTime month) {
    currentMonth = month;
    final now = DateTime.now();
    if (month.year == now.year && month.month == now.month) {
      selectedDate = now;
    } else {
      selectedDate = DateTime(month.year, month.month, 1);
    }
    loadMonth();
  }

  List<DateTime> get monthDays {
    final lastDay = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
    final days = <DateTime>[];
    for (int i = 1; i <= lastDay; i++) {
      days.add(DateTime(currentMonth.year, currentMonth.month, i));
    }
    return days;
  }

  List<DateTime> get workingDays {
    final now = DateTime.now();
    final isCurrentMonth =
        currentMonth.year == now.year && currentMonth.month == now.month;
    final lastDay = isCurrentMonth
        ? now.day
        : DateTime(currentMonth.year, currentMonth.month + 1, 0).day;

    final days = <DateTime>[];
    for (int i = 1; i <= lastDay; i++) {
      final day = DateTime(currentMonth.year, currentMonth.month, i);
      if (day.weekday != DateTime.saturday && day.weekday != DateTime.sunday) {
        days.add(day);
      }
    }
    return days;
  }

  String get monthLabel => DateFormat('MMMM yyyy').format(currentMonth);

  int userTotalUnits(String userId) {
    int sum = 0;
    for (var date in workingDays) {
      final dateStr = PackService.sessionIdFor(date);
      sum += ledgerData[dateStr]?[userId] ?? 0;
    }
    return sum;
  }

  int dayTotalUnits(String dateStr) {
    int sum = 0;
    if (ledgerData.containsKey(dateStr)) {
      for (var count in ledgerData[dateStr]!.values) {
        sum += count;
      }
    }
    return sum;
  }

  double? unitPriceFor(String dateStr) => pricing[dateStr]?.unitPrice;
  double userCostOn(String dateStr, String userId) {
    final price = unitPriceFor(dateStr);
    if (price == null) return 0;
    return (ledgerData[dateStr]?[userId] ?? 0) * price;
  }

  double userTotalCost(String userId) {
    double sum = 0;
    for (final date in workingDays) {
      sum += userCostOn(_key(date), userId);
    }
    return sum;
  }

  double dayTotalCost(String dateStr) => pricing[dateStr]?.cost ?? 0;

  double get grandTotalCost {
    double sum = 0;
    for (final date in workingDays) {
      sum += dayTotalCost(_key(date));
    }
    return sum;
  }

  int get unsettledDayCount {
    var count = 0;
    for (final date in workingDays) {
      final key = _key(date);
      if (dayTotalUnits(key) > 0 && unitPriceFor(key) == null) count++;
    }
    return count;
  }

  String _key(DateTime d) => PackService.sessionIdFor(d);

  int get grandTotalUnits {
    int sum = 0;
    for (var date in workingDays) {
      final dateStr = PackService.sessionIdFor(date);
      sum += dayTotalUnits(dateStr);
    }
    return sum;
  }

  Future<void> loadMonth() async {
    _networkSub ??= NetworkMonitor().onReconnectedStream.listen((_) {
      if (error != null) {
        loadMonth();
      }
    });

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      debugPrint('📊 [LEDGER VM] Loading month: $monthLabel');

      // Fetch users
      final usersData = await Supabase.instance.client
          .from('users')
          .select()
          .eq('is_active', true)
          .order('name');

      users = (usersData as List).map((u) => AppUser.fromJson(u)).toList();

      // Session ids are pack-prefixed; a constant prefix on both ends keeps
      // the string range sorting exactly as the bare dates did.
      final prefix = PackService.instance.pack.sessionPrefix;
      final startDate =
          '$prefix${currentMonth.year}-${currentMonth.month.toString().padLeft(2, '0')}-01';
      final lastDayOfMonth = DateTime(
        currentMonth.year,
        currentMonth.month + 1,
        0,
      ).day;
      final endDate =
          '$prefix${currentMonth.year}-${currentMonth.month.toString().padLeft(2, '0')}-${lastDayOfMonth.toString().padLeft(2, '0')}';

      final entriesData = await Supabase.instance.client
          .from('entries')
          .select('session_id, user_id, rotis_needed')
          .gte('session_id', startDate)
          .lte('session_id', endDate);

      final sessionsData = await Supabase.instance.client
          .from('sessions')
          .select('id, total_rotis, total_roti_cost, status')
          .gte('id', startDate)
          .lte('id', endDate);

      pricing.clear();
      _sessionStatus.clear();
      for (var row in sessionsData) {
        _sessionStatus[row['id'] as String] =
            row['status'] as String? ?? 'open';
        final cost = (row['total_roti_cost'] as num?)?.toDouble();
        if (cost == null) continue;
        pricing[row['id'] as String] = DayPricing(
          totalUnits: (row['total_rotis'] as num?)?.toInt() ?? 0,
          cost: cost,
        );
      }

      ledgerData.clear();
      for (var entry in entriesData) {
        final sessionId = entry['session_id'] as String;
        final userId = entry['user_id'] as String;
        final units = entry['rotis_needed'] as int? ?? 0;

        if (!ledgerData.containsKey(sessionId)) {
          ledgerData[sessionId] = {};
        }
        ledgerData[sessionId]![userId] = units;
      }

      debugPrint('📊 [LEDGER VM] Successfully loaded ledger data.');
    } catch (e) {
      error = e.toString();
      debugPrint('📊 [LEDGER VM] Error loading month: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Days this month that still need billing. Today is left out while its
  /// roster is still open, so settling mid-lunch can't lock people out.
  List<String> get unsettledSessionIds {
    final today = PackService.todaySessionId();
    return [
      for (final entry in _sessionStatus.entries)
        if (entry.value != 'settled' &&
            !(entry.key == today && entry.value == 'open'))
          entry.key,
    ]..sort();
  }

  int get unsettledUnits => unsettledSessionIds.fold(
    0,
    (sum, sessionId) => sum + dayTotalUnits(sessionId),
  );

  int get myUnsettledUnits => unsettledSessionIds.fold(
    0,
    (sum, sessionId) => sum + (ledgerData[sessionId]?[currentUid] ?? 0),
  );

  /// Bills every unsettled day this month at [unitPrice] per unit, owed to
  /// the admin settling it, then reloads the month.
  Future<String?> settleMonth(double unitPrice) async {
    if (!isAdmin) return 'Only an admin can settle the month.';
    final name = IdentityService.instance.displayName;
    try {
      await SupabaseService.instance.settleSessions(
        sessionIds: unsettledSessionIds,
        unitPrice: unitPrice,
        paidById: currentUid,
        paidByName: name.isEmpty ? 'Admin' : name,
      );
      await loadMonth();
      return null;
    } catch (e) {
      debugPrint('📊 [LEDGER VM] Error settling $monthLabel: $e');
      return 'Could not settle $monthLabel: $e';
    }
  }

  void goToPreviousMonth() {
    currentMonth = DateTime(currentMonth.year, currentMonth.month - 1);
    loadMonth();
  }

  void goToNextMonth() {
    final now = DateTime.now();
    if (currentMonth.year == now.year && currentMonth.month == now.month) {
      return; // Can't go beyond current month
    }
    currentMonth = DateTime(currentMonth.year, currentMonth.month + 1);
    loadMonth();
  }

  Future<void> updateUnits(
    String sessionId,
    String userId,
    String userName,
    int newCount,
  ) async {
    if (!isAdmin) {
      debugPrint('📊 [LEDGER VM] Update rejected: not admin.');
      return;
    }

    try {
      debugPrint(
        '📊 [LEDGER VM] Upserting units ($newCount) for $userName on $sessionId',
      );
      await SupabaseService.instance.adminUpsertEntry(
        sessionId: sessionId,
        userId: userId,
        userName: userName,
        unitsTaken: newCount,
      );
      if (!ledgerData.containsKey(sessionId)) {
        ledgerData[sessionId] = {};
      }
      ledgerData[sessionId]![userId] = newCount;
      notifyListeners();

      debugPrint('📊 [LEDGER VM] Successfully updated local ledger.');
    } catch (e) {
      error = e.toString();
      notifyListeners();
      debugPrint('📊 [LEDGER VM] Error updating units: $e');
    }
  }

  @override
  void dispose() {
    _networkSub?.cancel();
    super.dispose();
  }
}
