import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '/core/alerts/toast.dart';
import '/core/network/network_monitor.dart';
import '/core/theme/activity_packs.dart';
import '/features/auth/models/app_user.dart';
import '/services/identity_service.dart';
import '/services/notification_service.dart';
import '/services/push_service.dart';
import '/services/supabase_service.dart';
import 'models/activity_session.dart';
import 'models/ping.dart';
import 'models/roster_entry.dart';
import 'models/shared_expense.dart';

class DashboardViewModel extends ChangeNotifier {
  static const _notSignedIn = 'Not signed in yet — try again.';

  final SupabaseService _service = SupabaseService.instance;
  final String sessionId = SupabaseService.todaySessionId();

  ActivitySession? session;
  List<RosterEntry> entries = [];
  List<SharedExpense> sharedExpenses = [];

  List<AppUser> allUsers = [];
  bool isLoading = true;
  String? error;

  StreamSubscription<ActivitySession?>? _sessionSub;
  StreamSubscription<List<RosterEntry>>? _entriesSub;
  StreamSubscription<List<SharedExpense>>? _sharedExpensesSub;
  StreamSubscription<List<Ping>>? _pingsSub;
  StreamSubscription<ForegroundPing>? _pushSub;
  StreamSubscription<bool>? _networkSub;

  DashboardViewModel() {
    _networkSub = NetworkMonitor().onReconnectedStream.listen((_) {
      if (error != null) refresh();
    });
    // We exist before anyone signs in, and the ping stream needs our id.
    _identity.addListener(_ensurePingSub);
    // Pings that arrive over push while the app is open.
    _pushSub = PushService.instance.foregroundPings.listen(
      (ping) => _presentPing(
        id: ping.id,
        fromName: ping.fromName,
        message: ping.message,
      ),
    );
    _init();
  }

  Completer<void>? _reloaded;

  /// Re-subscribes to everything. The future completes once fresh data has
  /// arrived (or after a few seconds), so pull-to-refresh can wait for the
  /// real thing. [showSkeleton] is for a cold retry; a pull keeps what's on
  /// screen while it reloads.
  Future<void> refresh({bool showSkeleton = true}) {
    error = null;
    if (showSkeleton) isLoading = true;
    _isFirstSessionEvent = true;
    _sessionSub?.cancel();
    _entriesSub?.cancel();
    _sharedExpensesSub?.cancel();
    _pingsSub?.cancel();
    _pingsSub = null;
    notifyListeners();

    final reloaded = _reloaded = Completer<void>();
    _init();
    return reloaded.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () {},
    );
  }

  void _finishReload() {
    final reloaded = _reloaded;
    _reloaded = null;
    if (reloaded != null && !reloaded.isCompleted) reloaded.complete();
  }

  IdentityService get _identity => IdentityService.instance;
  String get currentUid => _identity.appUserId;
  String get currentUserName => _identity.displayName;
  bool get isAdmin => _identity.isAdmin;
  String get currentUserPhotoUrl => _identity.photoUrl;

  Future<String?> updateProfile({
    required String name,
    String? photoUrl,
  }) async {
    if (currentUid.isEmpty) return _notSignedIn;
    try {
      await _service.updateUserProfile(
        userId: currentUid,
        name: name,
        photoUrl: photoUrl,
      );
      final current = _identity.profile;
      if (current != null) {
        _identity.apply(current.copyWith(name: name, photoUrl: photoUrl));
      }
      notifyListeners();
      return null;
    } catch (e, st) {
      debugPrint('❌ [DASHBOARD VM ERROR] Failed updateProfile: $e\n$st');
      return 'Could not update profile: $e';
    }
  }

  Future<String?> setProfilePhoto(XFile photo) async {
    if (currentUid.isEmpty) return _notSignedIn;
    try {
      final bytes = await photo.readAsBytes();
      final pickedExtension = photo.name.split('.').last.toLowerCase();
      final fileExtension =
          (pickedExtension == 'png' || pickedExtension == 'webp')
          ? pickedExtension
          : 'jpg';

      final publicUrl = await _service.uploadAvatar(
        userId: currentUid,
        imageBytes: bytes,
        fileExtension: fileExtension,
      );

      final name = currentUserName.isNotEmpty
          ? currentUserName
          : PackService.labels.activityName;
      await _service.updateUserProfile(
        userId: currentUid,
        name: name,
        photoUrl: publicUrl,
      );
      final current = _identity.profile;
      if (current != null) {
        _identity.apply(current.copyWith(name: name, photoUrl: publicUrl));
      }

      notifyListeners();
      return null;
    } catch (e, st) {
      debugPrint('❌ [DASHBOARD VM ERROR] Failed setProfilePhoto: $e\n$st');
      return 'Could not upload avatar: $e';
    }
  }

  /// How many people this session's costs are divided between: whoever is on
  /// the roster, or the whole group for packs without one.
  int get participantCount {
    if (PackService.modules.roster) {
      return session?.headcount ?? entries.length;
    }
    return allUsers.where((user) => user.isActive).length;
  }

  RosterEntry? get myEntry {
    for (final entry in entries) {
      if (entry.userId == currentUid) return entry;
    }
    return null;
  }

  bool get isRunner => session != null && session!.runnerId == currentUid;

  /// Only the runner or an admin can say the runner has left.
  bool get canMarkDeparted => isRunner || isAdmin;

  // The realtime stream echoes our own writes back to us, so these stop us
  // notifying the person who just tapped the button.
  bool _isFirstSessionEvent = true;
  bool _markedArrivedHere = false;
  bool _markedDepartedHere = false;

  void _init() {
    debugPrint('🎬 [DASHBOARD VM] Loading session $sessionId');
    try {
      _sessionSub = _service
          .watchSession(sessionId)
          .listen(_onSession, onError: _onStreamError);
      _entriesSub = _service.watchEntries(sessionId).listen((value) {
        entries = value;
        notifyListeners();
      }, onError: _onStreamError);
      _sharedExpensesSub = _service.watchSharedExpenses(sessionId).listen((
        value,
      ) {
        _notifyExpenseChanges(value);
        sharedExpenses = value;
        notifyListeners();
      }, onError: _onStreamError);
      _loadUsers();
      _ensurePingSub();
    } catch (e) {
      _onStreamError(e);
    }
  }

  void _onSession(ActivitySession? value) {
    if (value != null) {
      if (!_isFirstSessionEvent) _notifyErrandChanges(value);
      _isFirstSessionEvent = false;
    }

    if (isAdmin) _updateRunnerReminders(value);

    session = value;
    isLoading = false;
    error = null;
    notifyListeners();
    _finishReload();
  }

  bool? _remindersOn;

  /// The admin gets an hourly nag while nobody has the errand. Rescheduling
  /// the alarm is a platform call, so only do it when the answer changes.
  void _updateRunnerReminders(ActivitySession? latest) {
    final wanted = latest != null && !latest.hasRunner;
    if (wanted == _remindersOn) return;
    _remindersOn = wanted;
    if (wanted) {
      NotificationService.instance.startRunnerReminders();
    } else {
      NotificationService.instance.stopRunnerReminders();
    }
  }

  /// Tells everyone else when the food lands or the runner leaves.
  void _notifyErrandChanges(ActivitySession updated) {
    final previous = session;
    final notifications = NotificationService.instance;

    final justArrived = updated.hasArrived && !(previous?.hasArrived ?? false);
    if (justArrived && !_markedArrivedHere) {
      notifications.showArrivalNotification(
        announcedBy:
            updated.arrivedByName ??
            updated.runnerName ??
            PackService.labels.outsider,
        arrivalTime: DateFormat.jm().format(updated.arrivedAt!.toLocal()),
      );
    }

    final justDeparted =
        updated.hasDeparted && !(previous?.hasDeparted ?? false);
    if (justDeparted && !_markedDepartedHere) {
      notifications.showRunnerDepartedNotification(
        runnerName: updated.runnerName ?? 'The ${PackService.labels.runner}',
        departureTime: DateFormat.jm().format(
          updated.runnerDepartedAt!.toLocal(),
        ),
        expenseCount: activeExpenseCount,
      );
    }
  }

  Future<void> _loadUsers() async {
    try {
      final rows = await _service.fetchActiveUsers();
      allUsers = rows.map(AppUser.fromJson).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ [DASHBOARD VM] Could not load users: $e');
    }
  }

  // --- Shared expenses ---

  List<SharedExpense> get myPendingInvites => sharedExpenses
      .where((expense) => expense.awaitsResponseFrom(currentUid))
      .toList();

  List<SharedExpense> get unresolvedExpenses =>
      sharedExpenses.where((expense) => expense.isPending).toList();

  /// Expenses somebody is actually in on — everything but the ones everyone
  /// declined.
  int get activeExpenseCount =>
      sharedExpenses.where((expense) => !expense.isCancelled).length;

  /// Why the runner can't leave yet, naming who everyone is waiting on. Null
  /// when nothing is holding them up.
  String? get departureBlockReason {
    if (session == null || !session!.hasRunner) {
      return 'Assign the ${PackService.labels.errand} first.';
    }
    if (session!.hasDeparted) return null;
    if (PackService.modules.units && session!.totalUnits == 0) {
      return 'Nobody has asked for any ${PackService.labels.unitPlural} yet.';
    }
    final waiting = unresolvedExpenses;
    if (waiting.isEmpty) return null;

    final people = <String>{
      for (final expense in waiting)
        for (final share in expense.pendingShares)
          share.userName.split(' ').first,
    };
    final names = people.take(3).join(', ');
    final more = people.length > 3 ? ' +${people.length - 3} more' : '';
    return waiting.length == 1
        ? 'Waiting on $names$more to answer "${waiting.first.description}".'
        : '${waiting.length} ${PackService.labels.expensePlural} are still '
              'unanswered — waiting on $names$more.';
  }

  final Set<String> _notifiedInvites = {};
  final Map<String, SharedExpense> _previousExpenses = {};

  /// Local notifications for what changed since the last snapshot: a new
  /// invite for me, or someone answering an expense I paid for.
  void _notifyExpenseChanges(List<SharedExpense> incoming) {
    final me = currentUid;
    if (me.isEmpty) return;
    final notifications = NotificationService.instance;

    for (final expense in incoming) {
      final previous = _previousExpenses[expense.id];

      if (expense.awaitsResponseFrom(me) && _notifiedInvites.add(expense.id)) {
        notifications.showExpenseInviteNotification(
          expenseId: expense.id,
          fromName: expense.paidByName.isEmpty ? 'Someone' : expense.paidByName,
          description: expense.description,
          estimatedMinor: expense.estimatedShareMinor,
        );
        continue;
      }

      if (expense.paidById != me || previous == null) continue;

      for (final share in expense.shares) {
        final before = previous.shareFor(share.userId);
        if (before == null ||
            before.status == share.status ||
            share.isPending ||
            share.userId == me) {
          continue;
        }
        notifications.showExpenseResponseNotification(
          expenseId: expense.id,
          whoName: share.userName.isEmpty ? 'Someone' : share.userName,
          description: expense.description,
          accepted: share.isAccepted,
          myNewMinor: expense.shareFor(me)?.amountMinor ?? 0,
        );
      }

      if (expense.isConfirmed && previous.isPending) {
        notifications.showExpenseConfirmedNotification(
          expenseId: expense.id,
          description: expense.description,
          headcount: expense.participantCount,
        );
      }
    }

    _previousExpenses
      ..clear()
      ..addEntries(incoming.map((expense) => MapEntry(expense.id, expense)));
  }

  Future<String?> addSharedExpense({
    required String description,
    required double cost,
    required List<String> participantIds,
    String? paidById,
  }) async {
    if (currentUid.isEmpty) return _notSignedIn;
    if (participantIds.isEmpty) return 'Pick at least one person sharing this.';
    if (cost <= 0) return 'Enter a cost above zero.';
    try {
      await _service.createSharedExpense(
        sessionId: sessionId,
        description: description,
        costMinor: PackService.currency.toMinor(cost),
        paidById: paidById ?? currentUid,
        participantIds: participantIds,
      );
      return null;
    } catch (e, st) {
      debugPrint('❌ [DASHBOARD VM ERROR] Failed addSharedExpense: $e\n$st');
      return _readableError(e);
    }
  }

  Future<String?> respondToExpense(
    String expenseId, {
    required bool accept,
  }) async {
    if (currentUid.isEmpty) return _notSignedIn;
    try {
      await _service.respondToSharedExpense(
        expenseId: expenseId,
        accept: accept,
      );
      return null;
    } catch (e, st) {
      debugPrint('❌ [DASHBOARD VM ERROR] Failed respondToExpense: $e\n$st');
      return _readableError(e);
    }
  }

  Future<String?> removeSharedExpense(String expenseId) async {
    try {
      await _service.deleteSharedExpense(expenseId);
      return null;
    } catch (e) {
      debugPrint('❌ [DASHBOARD VM ERROR] Failed removeSharedExpense: $e');
      return _readableError(e);
    }
  }

  // --- The errand ---

  Future<String?> assignRunner(String runnerName) async {
    if (currentUid.isEmpty) return _notSignedIn;
    try {
      await _service.assignRunner(sessionId: sessionId, userName: runnerName);
      return null;
    } on StateError catch (e) {
      return e.message;
    } catch (e, st) {
      debugPrint('❌ [DASHBOARD VM ERROR] Failed assignRunner: $e\n$st');
      return 'Could not assign: $e';
    }
  }

  /// The runner has left. This locks the roster and the shared expenses.
  Future<String?> markDeparted() async {
    if (currentUid.isEmpty) return _notSignedIn;
    if (session == null) return 'No session open yet today.';
    try {
      _markedDepartedHere = true;
      await _service.markDeparted(sessionId);
      return null;
    } catch (e, st) {
      _markedDepartedHere = false;
      debugPrint('❌ [DASHBOARD VM ERROR] Failed markDeparted: $e\n$st');
      return _readableError(e);
    }
  }

  Future<String?> markArrived() async {
    try {
      final name = currentUserName.isNotEmpty
          ? currentUserName
          : (session?.runnerName ?? PackService.labels.outsider);
      _markedArrivedHere = true;
      await _service.markArrived(sessionId: sessionId, announcedByName: name);
      return null;
    } catch (e, st) {
      _markedArrivedHere = false;
      debugPrint('❌ [DASHBOARD VM ERROR] Failed markArrived: $e\n$st');
      return 'Could not mark it arrived: $e';
    }
  }

  /// The bare codes our RPCs raise, as sentences. A getter rather than a
  /// const map so the messages can use this pack's words.
  Map<String, String> get _errorMessages {
    final labels = PackService.labels;
    return {
      'runner_already_left':
          'The ${labels.runner} has already left — the list is locked.',
      'session_already_settled': 'The bill is already settled.',
      'payer_cannot_decline':
          'You paid for this one — you can remove it, but not decline it.',
      'not_invited': "You aren't on this ${labels.expense}.",
      'not_the_runner': 'Only the ${labels.runner} or an admin can do that.',
      'no_runner_assigned': 'Nobody has been given the ${labels.errand} yet.',
      'no_units_to_buy': 'Nobody has asked for any ${labels.unitPlural} yet.',
      'order_not_found': 'That ${labels.expense} is gone — someone removed it.',
      'ping_target_unknown': 'Nobody is set to receive pings.',
      'cannot_ping_self': "You can't ping yourself.",
    };
  }

  String _readableError(Object e, {String? fallback}) {
    final message = e.toString();
    if (message.contains('orders_not_finalized')) {
      return departureBlockReason ??
          'Some ${PackService.labels.expensePlural} are still waiting on an '
              'answer.';
    }
    for (final entry in _errorMessages.entries) {
      if (message.contains(entry.key)) return entry.value;
    }
    return fallback ?? 'Something went wrong: $e';
  }

  void _onStreamError(Object e) {
    debugPrint('❌ [DASHBOARD VM ERROR] Stream error: $e');
    final message = e.toString();
    error = message.contains('initialize') || message.contains('SupabaseClient')
        ? 'Supabase isn\'t configured yet.\n'
              'Ensure Supabase.initialize is called in main.dart.'
        : message;
    isLoading = false;
    notifyListeners();
    _finishReload();
  }

  // --- Roster and bill ---

  Future<String?> submitEntry({
    required String userName,
    required String contribution,
    required int covers,
    required int unitsTaken,
  }) async {
    if (currentUid.isEmpty) return _notSignedIn;
    try {
      await _service.upsertEntry(
        sessionId: sessionId,
        entry: RosterEntry(
          userId: currentUid,
          userName: userName,
          userPhotoUrl: currentUserPhotoUrl.isNotEmpty
              ? currentUserPhotoUrl
              : null,
          contribution: contribution,
          covers: covers,
          unitsTaken: unitsTaken,
        ),
      );
      return null;
    } on StateError catch (e) {
      return e.message;
    } catch (e, st) {
      debugPrint('❌ [DASHBOARD VM ERROR] Failed submitEntry: $e\n$st');
      // Postgres locks the roster the moment the runner leaves (migration 011).
      return _readableError(e, fallback: 'Could not save entry: $e');
    }
  }

  Future<String?> resetTodayData() => _service.resetSessionData(sessionId);

  // --- Ping ---

  /// The one person flagged `is_ping_target` in `public.users`, if any.
  AppUser? get pingTarget {
    for (final user in allUsers) {
      if (user.isPingTarget && user.isActive) return user;
    }
    return null;
  }

  bool get _amPingTarget => pingTarget?.uid == _identity.appUserId;

  /// Everyone except the target sees the button, in packs that have one.
  bool get showPing =>
      PackService.modules.ping && pingTarget != null && !_amPingTarget;

  String get pingTargetName {
    final name = pingTarget?.name.trim() ?? '';
    return name.isEmpty ? 'them' : name.split(' ').first;
  }

  /// There's no cooldown on purpose: the button exists to be annoying.
  Future<String?> ping() async {
    if (!showPing) return "This button isn't for you.";
    try {
      // No recipient is sent: send_ping() looks up the target itself.
      await _service.sendPing(
        message:
            '$currentUserName needs you — open '
            '${PackService.labels.activityName}.',
        sessionId: sessionId,
      );
      return null;
    } catch (e, st) {
      debugPrint('❌ [DASHBOARD VM ERROR] Failed ping: $e\n$st');
      return _readableError(e, fallback: 'Could not ping: $e');
    }
  }

  /// Pings created before we subscribed (less some clock skew) arrived while
  /// the app was closed. They're marked seen without ringing.
  DateTime? _pingSubscribedAt;
  static const _pingClockSkew = Duration(seconds: 90);
  final Set<String> _seenPings = {};

  /// Safe to call repeatedly; subscribes once we know who we are.
  void _ensurePingSub() {
    if (_pingsSub != null || currentUid.isEmpty) return;
    _pingSubscribedAt = DateTime.now();
    _pingsSub = _service
        .watchPingsFor(currentUid)
        .listen(
          _onPings,
          onError: (e) => debugPrint('⚠️ [DASHBOARD VM] pings stream: $e'),
        );
  }

  void _onPings(List<Ping> pings) {
    final since = _pingSubscribedAt?.subtract(_pingClockSkew);
    for (final ping in pings) {
      if (ping.toId != currentUid || _seenPings.contains(ping.id)) continue;
      final createdAt = ping.createdAt;
      if (since == null || createdAt == null || !createdAt.isAfter(since)) {
        _seenPings.add(ping.id);
        continue;
      }
      _presentPing(id: ping.id, fromName: ping.fromName, message: ping.message);
    }
  }

  /// A ping can arrive over realtime and over push; whichever lands first
  /// wins. On screen it buzzes and toasts; in the background push owns the
  /// notification shade, with a local notification only as a fallback.
  void _presentPing({
    required String id,
    required String fromName,
    required String message,
  }) {
    if (id.isEmpty || !_seenPings.add(id)) return;
    final state = WidgetsBinding.instance.lifecycleState;
    final onScreen = state == null || state == AppLifecycleState.resumed;

    if (onScreen) {
      HapticFeedback.heavyImpact();
      ShowToastDialog.showToast(
        '🔔 $fromName pinged you',
        duration: const Duration(seconds: 6),
      );
      return;
    }

    if (PushService.instance.isEnabled) return;
    NotificationService.instance.showPingNotification(
      pingId: id,
      fromName: fromName,
      message: message,
    );
  }

  @override
  void dispose() {
    _identity.removeListener(_ensurePingSub);
    _sessionSub?.cancel();
    _entriesSub?.cancel();
    _sharedExpensesSub?.cancel();
    _pingsSub?.cancel();
    _pushSub?.cancel();
    _networkSub?.cancel();
    super.dispose();
  }
}
