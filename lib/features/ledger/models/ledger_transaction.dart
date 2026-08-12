enum TransactionType {
  roti, // share of the tandoor run, owed to the runner
  extraFood, // share of an extra order, owed to whoever paid
  settlement; // cash exchanged to clear balances

  static TransactionType fromString(String? value) {
    return TransactionType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => TransactionType.roti,
    );
  }
}

/// One immutable ledger line.
class LedgerTransaction {
  final String id;
  final String sessionId; // yyyy-MM-dd, empty for settlements
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
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
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
