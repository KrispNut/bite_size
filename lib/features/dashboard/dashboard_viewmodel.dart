import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/features/ledger/models/ledger_transaction.dart';
import 'models/extra_order.dart';
import 'models/lunch_entry.dart';
import 'models/lunch_session.dart';
import '/services/notification_service.dart';
import '/services/supabase_service.dart';
import '/core/network/network_monitor.dart';
import '/core/constants/app_constants.dart';

/// ViewModel for the main dashboard, acting as a mediator between views and Supabase.
class DashboardViewModel extends ChangeNotifier {
  final SupabaseService _service = SupabaseService.instance;
  final String sessionId = SupabaseService.todaySessionId();

  LunchSession? session;
  List<LunchEntry> entries = [];
  List<LedgerTransaction> transactions = [];
  bool isLoading = true;
  String? error;

  StreamSubscription<LunchSession?>? _sessionSub;
  StreamSubscription<List<LunchEntry>>? _entriesSub;
  StreamSubscription<List<LedgerTransaction>>? _transactionsSub;
  StreamSubscription<bool>? _networkSub;

  DashboardViewModel() {
    _networkSub = NetworkMonitor().onReconnectedStream.listen((_) {
      if (error != null) refresh();
    });
    _init();
  }

  void refresh() {
    error = null;
    isLoading = true;
    _isFirstSessionEvent = true;
    _sessionSub?.cancel();
    _entriesSub?.cancel();
    _transactionsSub?.cancel();
    notifyListeners();
    _init();
  }

  // --- IDENTITY ---

  String get currentUid {
    try {
      return Supabase.instance.client.auth.currentUser?.id ?? '';
    } catch (_) {
      return '';
    }
  }

  String get currentUserName {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      return user?.userMetadata?['name']?.toString() ?? user?.email ?? '';
    } catch (_) {
      return '';
    }
  }

  bool get isAdmin =>
      Supabase.instance.client.auth.currentUser?.email == AppConstants.adminEmail;

  String get currentUserPhotoUrl {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      return user?.userMetadata?['avatar_url']?.toString() ??
          user?.userMetadata?['picture']?.toString() ??
          '';
    } catch (_) {
      return '';
    }
  }

  Future<String?> updateProfile({
    required String name,
    String? photoUrl,
  }) async {
    if (currentUid.isEmpty) return 'Not signed in yet — try again.';
    try {
      await _service.updateUserProfile(
        userId: currentUid,
        name: name,
        photoUrl: photoUrl,
      );
      notifyListeners();
      return null;
    } catch (e, st) {
      debugPrint('❌ [DASHBOARD VM ERROR] Failed updateProfile: $e\n$st');
      return 'Could not update profile: $e';
    }
  }

  /// Pick an image from Camera or Gallery, upload to Supabase Storage, and save as profile avatar.
  Future<String?> uploadAndSetAvatar(ImageSource source) async {
    if (currentUid.isEmpty) return 'Not signed in yet — try again.';
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (pickedFile == null) return null; // User cancelled

      final bytes = await pickedFile.readAsBytes();
      final ext = pickedFile.name.split('.').last.toLowerCase();
      final validExt = (ext == 'png' || ext == 'webp') ? ext : 'jpg';

      final publicUrl = await _service.uploadAvatar(
        userId: currentUid,
        imageBytes: bytes,
        fileExtension: validExt,
      );

      final name = currentUserName.isNotEmpty
          ? currentUserName
          : 'Bite Size User';
      await _service.updateUserProfile(
        userId: currentUid,
        name: name,
        photoUrl: publicUrl,
      );

      notifyListeners();
      return null;
    } catch (e, st) {
      debugPrint('❌ [DASHBOARD VM ERROR] Failed uploadAndSetAvatar: $e\n$st');
      return 'Could not upload avatar: $e';
    }
  }

  LunchEntry? get myEntry {
    for (final e in entries) {
      if (e.userId == currentUid) return e;
    }
    return null;
  }

  bool get amRunner =>
      session != null && session!.tandoorRunnerId == currentUid;

  bool _isFirstSessionEvent = true;
  bool _didIMarkFoodArrived = false;

  void _init() {
    debugPrint(
      '🎬 [DASHBOARD VM] Initializing DashboardViewModel for session $sessionId',
    );
    try {
      _sessionSub = _service.watchSession(sessionId).listen((value) {
        debugPrint(
          '📊 [DASHBOARD VM] Session updated: Headcount=${value?.headcount}, Portions=${value?.totalPortions}, Rotis=${value?.totalRotis}, Arrived=${value?.hasArrived}',
        );

        // Check for real-time food arrival notification
        if (value != null &&
            value.hasArrived &&
            (session == null || !session!.hasArrived)) {
          if (!_isFirstSessionEvent && !_didIMarkFoodArrived) {
            final arrivedAt = value.arrivedAt!;
            final timeStr = DateFormat.jm().format(arrivedAt.toLocal());
            NotificationService.instance.showFoodArrivedNotification(
              announcedBy:
                  value.arrivedByName ??
                  value.tandoorRunnerName ??
                  'Office Boy',
              arrivalTime: timeStr,
            );
          }
        }

        if (value != null) {
          _isFirstSessionEvent = false;
        }

        if (isAdmin) {
          if (value == null || value.hasRunner) {
            NotificationService.instance.stopRunnerReminders();
          } else {
            NotificationService.instance.startRunnerReminders();
          }
        }

        session = value;
        isLoading = false;
        error = null;
        notifyListeners();
      }, onError: _onStreamError);
      _entriesSub = _service.watchEntries(sessionId).listen((value) {
        debugPrint(
          '👥 [DASHBOARD VM] Entries updated: total ${value.length} entries in roster',
        );
        entries = value;
        notifyListeners();
      }, onError: _onStreamError);
      _transactionsSub = _service.watchTransactions(sessionId).listen((value) {
        debugPrint(
          '💳 [DASHBOARD VM] Transactions updated: total ${value.length} transactions in ledger',
        );
        transactions = value;
        notifyListeners();
      }, onError: _onStreamError);
    } catch (e) {
      _onStreamError(e);
    }
  }

  void _onStreamError(Object e) {
    debugPrint('❌ [DASHBOARD VM ERROR] Stream error: $e');
    error =
        e.toString().contains('initialize') ||
            e.toString().contains('SupabaseClient')
        ? 'Supabase isn\'t configured yet.\n'
              'Ensure Supabase.initialize is called in main.dart.'
        : e.toString();
    isLoading = false;
    notifyListeners();
  }

  /// Mark today's food as arrived at the office table. Returns error message or null.
  Future<String?> markFoodArrived() async {
    debugPrint(
      '🖱️ [DASHBOARD VM] Announcing Food Arrived for session $sessionId',
    );
    try {
      final name = currentUserName.isNotEmpty
          ? currentUserName
          : (session?.tandoorRunnerName ?? 'Office Boy');
      
      _didIMarkFoodArrived = true;
      
      await _service.markFoodArrived(
        sessionId: sessionId,
        announcedByName: name,
      );
      debugPrint('✅ [DASHBOARD VM] markFoodArrived completed successfully');
      return null;
    } catch (e, st) {
      debugPrint('❌ [DASHBOARD VM ERROR] Failed markFoodArrived: $e\n$st');
      return 'Could not mark food arrived: $e';
    }
  }

  /// Add or edit the caller's entry. Returns an error message or null.
  Future<String?> submitEntry({
    required String userName,
    required String dishName,
    required int portions,
    required int rotisNeeded,
  }) async {
    debugPrint(
      '🖱️ [DASHBOARD VM] Submitting entry form | Name: "$userName", Dish: "$dishName", Portions: $portions, Rotis: $rotisNeeded',
    );
    if (currentUid.isEmpty) {
      debugPrint(
        '⚠️ [DASHBOARD VM] submitEntry aborted: User is not authenticated',
      );
      return 'Not signed in yet — try again.';
    }
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'name': userName}),
      );

      await _service.upsertEntry(
        sessionId: sessionId,
        entry: LunchEntry(
          userId: currentUid,
          userName: userName,
          userPhotoUrl: currentUserPhotoUrl.isNotEmpty
              ? currentUserPhotoUrl
              : null,
          dishName: dishName,
          portions: portions,
          rotisNeeded: rotisNeeded,
        ),
      );
      debugPrint('✅ [DASHBOARD VM] submitEntry completed successfully');
      return null;
    } on StateError catch (e) {
      debugPrint('⚠️ [DASHBOARD VM] StateError in submitEntry: ${e.message}');
      return e.message;
    } catch (e, st) {
      debugPrint('❌ [DASHBOARD VM ERROR] Failed submitEntry: $e\n$st');
      return 'Could not save entry: $e';
    }
  }

  /// Claim today's Tandoor Runner role. Returns an error message or null.
  Future<String?> claimRunner(String runnerName) async {
    debugPrint(
      '🖱️ [DASHBOARD VM] Claiming Tandoor Runner role for "$runnerName"',
    );
    if (currentUid.isEmpty) {
      debugPrint(
        '⚠️ [DASHBOARD VM] claimRunner aborted: User is not authenticated',
      );
      return 'Not signed in yet — try again.';
    }
    try {
      await _service.claimTandoorRunner(
        sessionId: sessionId,
        userId: null,
        userName: runnerName,
      );
      debugPrint('✅ [DASHBOARD VM] claimRunner completed successfully');
      return null;
    } on StateError catch (e) {
      debugPrint('⚠️ [DASHBOARD VM] StateError in claimRunner: ${e.message}');
      return e.message;
    } catch (e, st) {
      debugPrint('❌ [DASHBOARD VM ERROR] Failed claimRunner: $e\n$st');
      return 'Could not claim: $e';
    }
  }

  /// Settle today's session bill (rotis + extra salan/orders). Returns error message or null.
  Future<String?> settleBilling({
    required double totalRotiCost,
    required List<ExtraOrder> extraOrders,
  }) async {
    debugPrint(
      '🖱️ [DASHBOARD VM] Settling session bill | Rotis Cost: $totalRotiCost | Extras: ${extraOrders.length}',
    );
    if (currentUid.isEmpty) return 'Not signed in yet — try again.';
    try {
      await _service.settleSessionBilling(
        sessionId: sessionId,
        totalRotiCost: totalRotiCost,
        extraOrders: extraOrders,
        entries: entries,
        paidById: currentUid,
        paidByName: currentUserName.isEmpty ? 'Runner' : currentUserName,
      );
      debugPrint('✅ [DASHBOARD VM] settleBilling completed successfully');
      return null;
    } catch (e, st) {
      debugPrint('❌ [DASHBOARD VM ERROR] Failed settleBilling: $e\n$st');
      return 'Could not settle bill: $e';
    }
  }

  @override
  void dispose() {
    debugPrint('🧹 [DASHBOARD VM] Disposing DashboardViewModel');
    _sessionSub?.cancel();
    _entriesSub?.cancel();
    _transactionsSub?.cancel();
    _networkSub?.cancel();
    super.dispose();
  }


  Future<String?> resetTodayData() async {
    return await _service.resetSessionData(sessionId);
  }

}
