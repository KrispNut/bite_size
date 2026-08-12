enum SessionStatus {
  open, // accepting entries
  locked, // past cutoff — roster frozen, tandoor run happens
  settled; // costs entered, ledger written

  static SessionStatus fromString(String? value) {
    return SessionStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => SessionStatus.open,
    );
  }
}

/// One day's lunch.
/// The `id` is the date (yyyy-MM-dd), which is what gives us the daily reset.
class LunchSession {
  final String id; // yyyy-MM-dd
  final DateTime date;
  final DateTime cutoffAt;
  final SessionStatus status;
  final String? tandoorRunnerId;
  final String? tandoorRunnerName;
  final DateTime? arrivedAt;
  final String? arrivedByName;
  final int headcount;
  final int totalPortions;
  final int totalRotis;
  final double? totalRotiCost;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const LunchSession({
    required this.id,
    required this.date,
    required this.cutoffAt,
    this.status = SessionStatus.open,
    this.tandoorRunnerId,
    this.tandoorRunnerName,
    this.arrivedAt,
    this.arrivedByName,
    this.headcount = 0,
    this.totalPortions = 0,
    this.totalRotis = 0,
    this.totalRotiCost,
    this.createdAt,
    this.updatedAt,
  });

  int get portionDeficit => headcount - totalPortions;

  bool get hasDeficit => portionDeficit > 0;

  bool get isPastCutoff => DateTime.now().isAfter(cutoffAt);

  bool get hasRunner =>
      tandoorRunnerName != null && tandoorRunnerName!.isNotEmpty;

  bool get hasArrived => arrivedAt != null;

  double rotiCostFor(int rotisNeeded) {
    if (totalRotiCost == null || totalRotis == 0) return 0;
    return rotisNeeded / totalRotis * totalRotiCost!;
  }

  factory LunchSession.fromJson(Map<String, dynamic> json) {
    return LunchSession(
      id: json['id'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date'].toString()) : DateTime.now(),
      cutoffAt: json['cutoff_at'] != null ? DateTime.parse(json['cutoff_at'].toString()) : DateTime.now(),
      status: SessionStatus.fromString(json['status']),
      tandoorRunnerId: json['tandoor_runner_id'],
      tandoorRunnerName: json['tandoor_runner_name'],
      arrivedAt: json['arrived_at'] != null ? DateTime.tryParse(json['arrived_at'].toString()) : null,
      arrivedByName: json['arrived_by_name'],
      headcount: (json['headcount'] ?? 0).toInt(),
      totalPortions: (json['total_portions'] ?? 0).toInt(),
      totalRotis: (json['total_rotis'] ?? 0).toInt(),
      totalRotiCost: (json['total_roti_cost'] as num?)?.toDouble(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String().substring(0, 10),
      'cutoff_at': cutoffAt.toIso8601String(),
      'status': status.name,
      'tandoor_runner_id': tandoorRunnerId,
      'tandoor_runner_name': tandoorRunnerName,
      'headcount': headcount,
      'total_portions': totalPortions,
      'total_rotis': totalRotis,
      'total_roti_cost': totalRotiCost,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}
