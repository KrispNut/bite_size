enum SessionStatus {
  open, // accepting entries
  locked, // runner has departed — roster frozen, the errand happens
  settled; // costs entered, ledger written

  static SessionStatus fromString(String? value) {
    return SessionStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => SessionStatus.open,
    );
  }
}

/// One occurrence of whatever the group does together — a day's lunch, a
/// match, a supply run.
///
/// The `id` is the date (yyyy-MM-dd), which is what gives a daily pack its
/// free reset. An ad-hoc pack still keys by date today; that is the constraint
/// the groups migration lifts.
///
/// The field names are the pack's vocabulary, not any one domain's: `units`
/// are units to a lunch and hours to a ground booking, and `covers` is how far
/// what somebody brought will stretch. The JSON keys are still the original
/// columns, so this reads and writes the live schema unchanged.
class ActivitySession {
  final String id; // yyyy-MM-dd
  final DateTime date;
  final SessionStatus status;
  final String? runnerId;
  final String? runnerName;

  /// When the runner actually left. Being *assigned* doesn't close the list;
  /// leaving does — after this nothing can be added, removed or answered,
  /// because somebody is out there buying it.
  final DateTime? runnerDepartedAt;
  final DateTime? arrivedAt;
  final String? arrivedByName;
  final int headcount;

  /// How many people the contributions on the roster will feed between them.
  final int totalCovers;

  /// How many of the countable bulk item the group needs in total.
  final int totalUnits;

  /// What that bulk item ended up costing, once someone entered the bill.
  final double? totalUnitCost;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ActivitySession({
    required this.id,
    required this.date,
    this.status = SessionStatus.open,
    this.runnerId,
    this.runnerName,
    this.runnerDepartedAt,
    this.arrivedAt,
    this.arrivedByName,
    this.headcount = 0,
    this.totalCovers = 0,
    this.totalUnits = 0,
    this.totalUnitCost,
    this.createdAt,
    this.updatedAt,
  });

  /// How many people the roster is short of feeding. Only meaningful under a
  /// pack with the coverage module on.
  int get coverageDeficit => headcount - totalCovers;

  bool get hasDeficit => coverageDeficit > 0;

  bool get hasRunner => runnerName != null && runnerName!.isNotEmpty;

  bool get hasDeparted => runnerDepartedAt != null;

  bool get hasArrived => arrivedAt != null;

  /// One person's slice of the bulk bill, by how many units they took.
  double unitCostFor(int unitsTaken) {
    if (totalUnitCost == null || totalUnits == 0) return 0;
    return unitsTaken / totalUnits * totalUnitCost!;
  }

  factory ActivitySession.fromJson(Map<String, dynamic> json) {
    return ActivitySession(
      id: json['id'] ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'].toString())
          : DateTime.now(),
      status: SessionStatus.fromString(json['status']),
      runnerId: json['tandoor_runner_id'],
      runnerName: json['tandoor_runner_name'],
      runnerDepartedAt: json['runner_departed_at'] != null
          ? DateTime.tryParse(json['runner_departed_at'].toString())
          : null,
      arrivedAt: json['arrived_at'] != null
          ? DateTime.tryParse(json['arrived_at'].toString())
          : null,
      arrivedByName: json['arrived_by_name'],
      headcount: (json['headcount'] ?? 0).toInt(),
      totalCovers: (json['total_portions'] ?? 0).toInt(),
      totalUnits: (json['total_rotis'] ?? 0).toInt(),
      totalUnitCost: (json['total_roti_cost'] as num?)?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String().substring(0, 10),
      'status': status.name,
      'tandoor_runner_id': runnerId,
      'tandoor_runner_name': runnerName,
      if (runnerDepartedAt != null)
        'runner_departed_at': runnerDepartedAt!.toIso8601String(),
      'headcount': headcount,
      'total_portions': totalCovers,
      'total_rotis': totalUnits,
      'total_roti_cost': totalUnitCost,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}
