/// One person's roster entry for a day.
class LunchEntry {
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String dishName;
  final int portions;
  final int rotisNeeded;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const LunchEntry({
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.dishName,
    required this.portions,
    required this.rotisNeeded,
    this.createdAt,
    this.updatedAt,
  });

  factory LunchEntry.fromJson(Map<String, dynamic> json) {
    return LunchEntry(
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      userPhotoUrl: json['user_photo_url'],
      dishName: json['dish_name'] ?? '',
      portions: (json['portions'] ?? 0).toInt(),
      rotisNeeded: (json['rotis_needed'] ?? 0).toInt(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson(String sessionId) {
    return {
      'session_id': sessionId,
      'user_id': userId,
      'user_name': userName,
      if (userPhotoUrl != null) 'user_photo_url': userPhotoUrl,
      'dish_name': dishName,
      'portions': portions,
      'rotis_needed': rotisNeeded,
    };
  }

  LunchEntry copyWith({String? userName, String? userPhotoUrl}) {
    return LunchEntry(
      userId: userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      dishName: dishName,
      portions: portions,
      rotisNeeded: rotisNeeded,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
