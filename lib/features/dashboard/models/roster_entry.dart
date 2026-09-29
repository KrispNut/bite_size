/// One person's line on the roster.
///
/// What they put in ([contribution]), how far it stretches ([covers]) and how
/// many of the bulk item they're taking ([unitsTaken]). A lunch fills all
/// three; a pack without the units module leaves [unitsTaken] at zero; a
/// pack with the roster module off never writes one of these at all.
///
/// The JSON keys are still `dish_name` / `portions` / `rotis_needed`, so this
/// reads the live schema without a migration.
class RosterEntry {
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String contribution;
  final int covers;
  final int unitsTaken;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RosterEntry({
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.contribution,
    required this.covers,
    required this.unitsTaken,
    this.createdAt,
    this.updatedAt,
  });

  factory RosterEntry.fromJson(Map<String, dynamic> json) {
    return RosterEntry(
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      userPhotoUrl: json['user_photo_url'],
      contribution: json['dish_name'] ?? '',
      covers: (json['portions'] ?? 0).toInt(),
      unitsTaken: (json['rotis_needed'] ?? 0).toInt(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson(String sessionId) {
    return {
      'session_id': sessionId,
      'user_id': userId,
      'user_name': userName,
      if (userPhotoUrl != null) 'user_photo_url': userPhotoUrl,
      'dish_name': contribution,
      'portions': covers,
      'rotis_needed': unitsTaken,
    };
  }

  RosterEntry copyWith({String? userName, String? userPhotoUrl}) {
    return RosterEntry(
      userId: userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      contribution: contribution,
      covers: covers,
      unitsTaken: unitsTaken,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
