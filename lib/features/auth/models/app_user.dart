/// What a person is allowed to do.
///
/// Roles are enforced in Postgres (RLS + `is_admin()`), not here — this enum
/// only decides what the UI bothers to show.
enum UserRole {
  admin,
  member;

  static UserRole fromString(String? value) {
    return UserRole.values.firstWhere(
      (r) => r.name == value,
      orElse: () => UserRole.member,
    );
  }
}

/// A coworker on the allowlist.
///
/// `uid` is the app-side id (`users.id`) and is what every other table's
/// foreign key points at. It is deliberately NOT the Supabase Auth UID —
/// people are seeded before they have ever signed in. `authUid` holds the
/// Google-backed Auth UID once they claim the row.
///
/// `balance` is the running net in rupees:
/// positive → the group owes this person, negative → they owe the group.
class AppUser {
  final String uid;
  final String? authUid;
  final String name;
  final String email;
  final UserRole role;
  final String? photoUrl;
  final String? fcmToken;
  final double balance;
  final bool isActive;

  /// True for the one person the dashboard Ping button reaches.
  ///
  /// A flag on the row, not an email compiled into the build: moving the ping
  /// used to mean rebuilding and reinstalling on every phone, and until the
  /// last phone was updated the roster disagreed about who to ping. At most
  /// one row may carry it — migration 009 enforces that with a partial unique
  /// index.
  final bool isPingTarget;

  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    this.authUid,
    required this.name,
    required this.email,
    this.role = UserRole.member,
    this.photoUrl,
    this.fcmToken,
    this.balance = 0,
    this.isActive = true,
    this.isPingTarget = false,
    this.createdAt,
  });

  bool get isAdmin => role == UserRole.admin;

  /// True once this person has signed in and bound their Google account.
  bool get hasClaimed => authUid != null && authUid!.isNotEmpty;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['id'] ?? '',
      authUid: json['auth_uid'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: UserRole.fromString(json['role']),
      photoUrl: json['photo_url'],
      fcmToken: json['fcm_token'],
      balance: (json['balance'] ?? 0).toDouble(),
      isActive: json['is_active'] ?? true,
      isPingTarget: json['is_ping_target'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': uid,
      'auth_uid': authUid,
      'name': name,
      'email': email,
      'role': role.name,
      'photo_url': photoUrl,
      'fcm_token': fcmToken,
      'balance': balance,
      'is_active': isActive,
      'is_ping_target': isPingTarget,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  AppUser copyWith({
    String? authUid,
    String? name,
    String? email,
    UserRole? role,
    String? photoUrl,
    String? fcmToken,
    double? balance,
    bool? isActive,
    bool? isPingTarget,
  }) {
    return AppUser(
      uid: uid,
      authUid: authUid ?? this.authUid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      balance: balance ?? this.balance,
      isActive: isActive ?? this.isActive,
      isPingTarget: isPingTarget ?? this.isPingTarget,
      createdAt: createdAt,
    );
  }
}
