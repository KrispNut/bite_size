/// A coworker.
///
/// `balance` is the running net in rupees:
/// positive → the group owes this person, negative → they owe the group.
class AppUser {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String? fcmToken;
  final double balance;
  final bool isActive;
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.fcmToken,
    this.balance = 0,
    this.isActive = true,
    this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      photoUrl: json['photo_url'],
      fcmToken: json['fcm_token'],
      balance: (json['balance'] ?? 0).toDouble(),
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': uid,
      'name': name,
      'email': email,
      'photo_url': photoUrl,
      'fcm_token': fcmToken,
      'balance': balance,
      'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  AppUser copyWith({
    String? name,
    String? email,
    String? photoUrl,
    String? fcmToken,
    double? balance,
    bool? isActive,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      balance: balance ?? this.balance,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}
