/// Model for extra food/salan/drink items ordered during lunch.
class ExtraOrder {
  final String id;
  final String sessionId;
  final String description;
  final double cost;
  final String paidById;
  final String paidByName;
  final List<String> sharedByIds;
  final DateTime? createdAt;

  const ExtraOrder({
    required this.id,
    required this.sessionId,
    required this.description,
    required this.cost,
    required this.paidById,
    required this.paidByName,
    required this.sharedByIds,
    this.createdAt,
  });

  factory ExtraOrder.fromJson(Map<String, dynamic> json) {
    return ExtraOrder(
      id: json['id'] ?? '',
      sessionId: json['session_id'] ?? '',
      description: json['description'] ?? '',
      cost: (json['cost'] ?? 0).toDouble(),
      paidById: json['paid_by_id'] ?? '',
      paidByName: json['paid_by_name'] ?? '',
      sharedByIds: (json['shared_by_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'description': description,
      'cost': cost,
      'paid_by_id': paidById,
      'paid_by_name': paidByName,
      'shared_by_ids': sharedByIds,
    };
  }
}
