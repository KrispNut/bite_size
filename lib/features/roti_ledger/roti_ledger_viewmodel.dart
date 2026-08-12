import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/network/network_monitor.dart';
import '../auth/models/app_user.dart';

class RotiLedgerViewModel extends ChangeNotifier {
  DateTime currentMonth = DateTime.now();
  List<AppUser> users = [];
  Map<String, Map<String, int>> ledgerData = {};
  bool isLoading = false;
  String? error;
  
  StreamSubscription<bool>? _networkSub;

  bool get isAdmin => Supabase.instance.client.auth.currentUser?.email == AppConstants.adminEmail;
  String get currentUid => Supabase.instance.client.auth.currentUser?.id ?? '';

  List<DateTime> get workingDays {
    final now = DateTime.now();
    final isCurrentMonth = currentMonth.year == now.year && currentMonth.month == now.month;
    final lastDay = isCurrentMonth ? now.day : DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
    
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

  int userTotalRotis(String userId) {
    int sum = 0;
    for (var date in workingDays) {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      sum += ledgerData[dateStr]?[userId] ?? 0;
    }
    return sum;
  }

  int dayTotalRotis(String dateStr) {
    int sum = 0;
    if (ledgerData.containsKey(dateStr)) {
      for (var count in ledgerData[dateStr]!.values) {
        sum += count;
      }
    }
    return sum;
  }

  int get grandTotalRotis {
    int sum = 0;
    for (var date in workingDays) {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      sum += dayTotalRotis(dateStr);
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
      debugPrint('📊 [ROTI LEDGER VM] Loading month: $monthLabel');
      
      // Fetch users
      final usersData = await Supabase.instance.client
          .from('users')
          .select()
          .eq('is_active', true)
          .order('name');
          
      users = (usersData as List).map((u) => AppUser.fromJson(u)).toList();

      // Fetch entries for the month range
      final startDate = '${currentMonth.year}-${currentMonth.month.toString().padLeft(2, '0')}-01';
      final lastDayOfMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
      final endDate = '${currentMonth.year}-${currentMonth.month.toString().padLeft(2, '0')}-${lastDayOfMonth.toString().padLeft(2, '0')}';
      
      final entriesData = await Supabase.instance.client
          .from('entries')
          .select('session_id, user_id, rotis_needed')
          .gte('session_id', startDate)
          .lte('session_id', endDate);

      ledgerData.clear();
      for (var entry in entriesData) {
        final sessionId = entry['session_id'] as String;
        final userId = entry['user_id'] as String;
        final rotis = entry['rotis_needed'] as int? ?? 0;
        
        if (!ledgerData.containsKey(sessionId)) {
          ledgerData[sessionId] = {};
        }
        ledgerData[sessionId]![userId] = rotis;
      }
      
      debugPrint('📊 [ROTI LEDGER VM] Successfully loaded ledger data.');
    } catch (e) {
      error = e.toString();
      debugPrint('📊 [ROTI LEDGER VM] Error loading month: $e');
    } finally {
      isLoading = false;
      notifyListeners();
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

  Future<void> updateRotis(String sessionId, String userId, String userName, int newCount) async {
    if (!isAdmin) {
      debugPrint('📊 [ROTI LEDGER VM] Update rejected: not admin.');
      return;
    }

    try {
      debugPrint('📊 [ROTI LEDGER VM] Upserting rotis ($newCount) for $userName on $sessionId');
      // First ensure session exists
      final sessionResponse = await Supabase.instance.client
          .from('sessions')
          .select()
          .eq('id', sessionId)
          .maybeSingle();
      
      if (sessionResponse == null) {
        // Create the session
        final date = DateTime.parse(sessionId);
        await Supabase.instance.client.from('sessions').insert({
          'id': sessionId,
          'date': sessionId,
          'cutoff_at': DateTime(date.year, date.month, date.day, 12, 30).toIso8601String(),
          'status': 'open',
        });
        debugPrint('📊 [ROTI LEDGER VM] Created missing session $sessionId');
      }
      
      await Supabase.instance.client.from('entries').upsert({
        'session_id': sessionId,
        'user_id': userId,
        'user_name': userName,
        'dish_name': 'Admin entry',
        'portions': 0,
        'rotis_needed': newCount,
      });

      // Update local data
      if (!ledgerData.containsKey(sessionId)) {
        ledgerData[sessionId] = {};
      }
      ledgerData[sessionId]![userId] = newCount;
      notifyListeners();
      
      debugPrint('📊 [ROTI LEDGER VM] Successfully updated local ledger.');
    } catch (e) {
      error = e.toString();
      notifyListeners();
      debugPrint('📊 [ROTI LEDGER VM] Error updating rotis: $e');
    }
  }

  @override
  void dispose() {
    _networkSub?.cancel();
    super.dispose();
  }
}
