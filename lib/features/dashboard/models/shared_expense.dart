import '/core/theme/activity_packs.dart';

/// How a cost is divided among the people sharing it.
enum SplitMode {
  /// Everyone sharing pays the same.
  equal,

  /// Weighted — someone who took two portions carries two shares.
  shares;

  static SplitMode fromString(String? value) {
    return SplitMode.values.firstWhere(
      (m) => m.name == value,
      orElse: () => SplitMode.equal,
    );
  }
}

/// Where one person stands on a cost they were named on.
///
/// Being named is an invitation, not a charge — nobody carries money until
/// they say yes, which is why [pending] exists at all.
enum InviteStatus {
  pending,
  accepted,
  declined;

  static InviteStatus fromString(String? value) {
    return InviteStatus.values.firstWhere(
      (s) => s.name == value,
      // Rows written before invites existed were unconditional charges.
      orElse: () => InviteStatus.accepted,
    );
  }
}

/// Where the cost as a whole stands.
enum ExpenseStatus {
  /// Somebody named on it still owes an answer. Blocks the errand.
  pending,

  /// Everyone has answered and at least one person is in.
  confirmed,

  /// Everyone declined — it exists only as a record that it was asked.
  cancelled;

  static ExpenseStatus fromString(String? value) {
    return ExpenseStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => ExpenseStatus.confirmed,
    );
  }
}

/// One person on a [SharedExpense]: their answer and, once they've accepted,
/// their share.
///
/// [amountMinor] is split in Postgres across the accepted people only, so the
/// shares always add back up to the cost exactly. Pending or declined people
/// sit at zero.
class ExpenseShare {
  final String userId;
  final String userName;
  final int weight;
  final int amountMinor;
  final InviteStatus status;
  final DateTime? respondedAt;

  const ExpenseShare({
    required this.userId,
    required this.userName,
    this.weight = 1,
    required this.amountMinor,
    this.status = InviteStatus.accepted,
    this.respondedAt,
  });

  double get amount => PackService.currency.toMajor(amountMinor);

  bool get isPending => status == InviteStatus.pending;

  bool get isAccepted => status == InviteStatus.accepted;

  bool get isDeclined => status == InviteStatus.declined;

  factory ExpenseShare.fromJson(Map<String, dynamic> json) {
    return ExpenseShare(
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      weight: (json['weight'] ?? 1).toInt(),
      amountMinor: (json['amount_minor'] ?? 0).toInt(),
      status: InviteStatus.fromString(json['status']),
      respondedAt: json['responded_at'] != null
          ? DateTime.tryParse(json['responded_at'].toString())
          : null,
    );
  }
}

/// A cost split between some of the group, e.g. two people sharing a karahi.
///
/// The people named on it have to agree first: it stays
/// [ExpenseStatus.pending] until all of them have answered, and the runner
/// can't leave while it is.
class SharedExpense {
  final String id;
  final String sessionId;
  final String description;
  final int costMinor;
  final String paidById;
  final String paidByName;
  final SplitMode splitMode;
  final ExpenseStatus status;
  final String? createdBy;
  final List<ExpenseShare> shares;
  final DateTime? createdAt;
  final DateTime? confirmedAt;

  const SharedExpense({
    required this.id,
    required this.sessionId,
    required this.description,
    required this.costMinor,
    required this.paidById,
    required this.paidByName,
    this.splitMode = SplitMode.equal,
    this.status = ExpenseStatus.confirmed,
    this.createdBy,
    this.shares = const [],
    this.createdAt,
    this.confirmedAt,
  });

  double get cost => PackService.currency.toMajor(costMinor);

  // --- MEMBERSHIP ---

  List<ExpenseShare> get acceptedShares =>
      shares.where((share) => share.isAccepted).toList();

  List<ExpenseShare> get pendingShares =>
      shares.where((share) => share.isPending).toList();

  /// How many people are actually carrying this — not how many were asked.
  int get participantCount => acceptedShares.length;

  /// How many were asked, however they answered.
  int get invitedCount => shares.length;

  int get pendingCount => pendingShares.length;

  /// Roughly what each person pays if everyone still undecided says yes.
  int get estimatedShareMinor {
    final people = pendingCount + participantCount;
    return people > 0 ? costMinor ~/ people : 0;
  }

  // --- STATE ---

  bool get isPending => status == ExpenseStatus.pending;

  bool get isConfirmed => status == ExpenseStatus.confirmed;

  /// Everyone said no. It stays visible so the ask is on the record.
  bool get isCancelled => status == ExpenseStatus.cancelled;

  /// This person is being asked and hasn't answered.
  bool awaitsResponseFrom(String userId) =>
      shareFor(userId)?.isPending ?? false;

  ExpenseShare? shareFor(String userId) {
    for (final share in shares) {
      if (share.userId == userId) return share;
    }
    return null;
  }

  factory SharedExpense.fromJson(
    Map<String, dynamic> json, {
    List<ExpenseShare> shares = const [],
  }) {
    final minor = json['cost_minor'];
    return SharedExpense(
      id: json['id'] ?? '',
      sessionId: json['session_id'] ?? '',
      description: json['description'] ?? '',
      costMinor: minor != null
          ? (minor as num).toInt()
          : PackService.currency.toMinor((json['cost'] ?? 0) as num),
      paidById: json['paid_by_id'] ?? '',
      paidByName: json['paid_by_name'] ?? '',
      splitMode: SplitMode.fromString(json['split_mode']),
      status: ExpenseStatus.fromString(json['status']),
      createdBy: json['created_by'],
      shares: shares,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.tryParse(json['confirmed_at'].toString())
          : null,
    );
  }
}
