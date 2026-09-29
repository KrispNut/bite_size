/// One tap of the Ping button, as the recipient's device sees it arrive.
///
/// Read-only on the client: rows are written by `send_ping()` in Postgres,
/// which resolves the recipient from the configured email so the app never
/// holds — or could forge — the target's id.
class Ping {
  final String id;
  final String fromId;
  final String fromName;
  final String toId;
  final String message;
  final DateTime? createdAt;

  const Ping({
    required this.id,
    required this.fromId,
    required this.fromName,
    required this.toId,
    this.message = '',
    this.createdAt,
  });

  factory Ping.fromJson(Map<String, dynamic> json) => Ping(
    id: json['id']?.toString() ?? '',
    fromId: json['from_id']?.toString() ?? '',
    fromName: (json['from_name'] as String?)?.trim().isNotEmpty == true
        ? (json['from_name'] as String).trim()
        : 'Someone',
    toId: json['to_id']?.toString() ?? '',
    message: (json['message'] as String?) ?? '',
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'].toString())
        : null,
  );
}
