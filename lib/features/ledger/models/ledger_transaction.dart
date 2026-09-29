/// What a ledger row is for.
///
/// The [wire] values are still the original strings, because the CHECK
/// constraint on `transactions.type` has not moved yet — the schema migration
/// renames the column values and these together. Nothing outside this enum
/// should ever see them.
enum TransactionType {
  /// A slice of the bulk item, billed by how many units the person took.
  units('roti'),

  /// A slice of a cost somebody else fronted.
  sharedExpense('extraFood'),

  /// A straight payment between two people.
  settlement('settlement');

  const TransactionType(this.wire);

  /// What goes in, and comes out of, `transactions.type`.
  final String wire;

  static TransactionType fromString(String? value) {
    return TransactionType.values.firstWhere(
      (t) => t.wire == value,
      orElse: () => TransactionType.units,
    );
  }
}

class LedgerTransaction {
  final String id;
  final String sessionId;
  final TransactionType type;
  final String fromId;
  final String fromName;
  final String toId;
  final String toName;
  final double amount;
  final String note;
  final DateTime? createdAt;

  const LedgerTransaction({
    required this.id,
    required this.sessionId,
    required this.type,
    required this.fromId,
    required this.fromName,
    required this.toId,
    required this.toName,
    required this.amount,
    this.note = '',
    this.createdAt,
  });

  factory LedgerTransaction.fromJson(Map<String, dynamic> json) {
    return LedgerTransaction(
      id: json['id'] ?? '',
      sessionId: json['session_id'] ?? '',
      type: TransactionType.fromString(json['type']),
      fromId: json['from_id'] ?? '',
      fromName: json['from_name'] ?? '',
      toId: json['to_id'] ?? '',
      toName: json['to_name'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      note: json['note'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId.isEmpty ? null : sessionId,
      'type': type.name,
      'from_id': fromId,
      'from_name': fromName,
      'to_id': toId,
      'to_name': toName,
      'amount': amount,
      'note': note,
    };
  }
}
