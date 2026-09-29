import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/features/auth/models/app_user.dart';
import 'analytics_service.dart';

/// Why a sign-in was refused. The codes mirror the exceptions raised by
/// `claim_identity()` in migration 001.
enum IdentityError {
  notAuthenticated,
  noEmailOnToken,
  notAllowlisted,
  emailAlreadyClaimed,
  accountDisabled,
  unknown;

  /// The bare codes `claim_identity()` raises, in the order they're matched.
  static const _codes = {
    'not_allowlisted': IdentityError.notAllowlisted,
    'email_already_claimed': IdentityError.emailAlreadyClaimed,
    'account_disabled': IdentityError.accountDisabled,
    'no_email_on_token': IdentityError.noEmailOnToken,
    'not_authenticated': IdentityError.notAuthenticated,
  };

  static IdentityError fromMessage(String message) {
    final m = message.toLowerCase();
    for (final entry in _codes.entries) {
      if (m.contains(entry.key)) return entry.value;
    }
    return IdentityError.unknown;
  }

  String get message {
    switch (this) {
      case IdentityError.notAllowlisted:
        return 'You\'re not on the office list. Ask the admin to add your email.';
      case IdentityError.emailAlreadyClaimed:
        return 'That email is already linked to another account.';
      case IdentityError.accountDisabled:
        return 'Your account has been deactivated.';
      case IdentityError.noEmailOnToken:
        return 'Google didn\'t share an email address with the app.';
      case IdentityError.notAuthenticated:
        return 'Not signed in — try again.';
      case IdentityError.unknown:
        return 'Could not verify your account. Try again.';
    }
  }
}

class IdentityException implements Exception {
  final IdentityError error;
  const IdentityException(this.error);

  String get message => error.message;

  @override
  String toString() => message;
}

/// Holds the signed-in person's *app* profile — the row in `public.users`,
/// not the Supabase Auth user.
///
/// Everything that writes a `user_id` must read [appUserId] from here. The
/// Auth UID is only ever used to look this row up; the two are different
/// identifiers now that people are seeded before they first sign in.
class IdentityService extends ChangeNotifier {
  static final IdentityService instance = IdentityService._internal();
  IdentityService._internal();

  AppUser? _profile;

  AppUser? get profile => _profile;

  /// The id every foreign key uses. Empty when nobody is signed in.
  String get appUserId => _profile?.uid ?? '';

  String get displayName => _profile?.name ?? '';

  String get photoUrl => _profile?.photoUrl ?? '';

  String get email => _profile?.email ?? '';

  bool get isAdmin => _profile?.isAdmin ?? false;

  bool get isReady => _profile != null;

  /// Verifies the signed-in Google account against the allowlist and loads
  /// the matching profile. Throws [IdentityException] if it isn't allowed.
  Future<AppUser> claim() async {
    final client = Supabase.instance.client;
    final authUser = client.auth.currentUser;
    if (authUser == null) {
      throw const IdentityException(IdentityError.notAuthenticated);
    }

    final meta = authUser.userMetadata ?? const {};
    final name = (meta['name'] ?? meta['full_name'] ?? '').toString();
    final photo = (meta['avatar_url'] ?? meta['picture'] ?? '').toString();

    debugPrint('🪪 [IDENTITY] Claiming allowlist row for ${authUser.email}');
    try {
      final data = await client.rpc(
        'claim_identity',
        params: {'p_name': name, 'p_photo_url': photo},
      );

      // The RPC returns a single `public.users` row; PostgREST may hand it
      // back either bare or wrapped in a list depending on the driver.
      final row = data is List ? data.first : data;
      _profile = AppUser.fromJson(Map<String, dynamic>.from(row as Map));
      debugPrint(
        '✅ [IDENTITY] Claimed as ${_profile!.name} (${_profile!.role.name}) → ${_profile!.uid}',
      );
      // Session replay is worth little without knowing whose session it is,
      // and this is the only moment the app learns that.
      Analytics.identify(_profile!.uid);
      notifyListeners();
      return _profile!;
    } on PostgrestException catch (e) {
      debugPrint('❌ [IDENTITY] claim_identity rejected: ${e.message}');
      throw IdentityException(IdentityError.fromMessage(e.message));
    } catch (e) {
      debugPrint('❌ [IDENTITY] claim_identity failed: $e');
      throw IdentityException(IdentityError.fromMessage(e.toString()));
    }
  }

  /// Re-establishes the profile on app launch when a Supabase session is
  /// already restored from disk. Returns null if there's nobody to restore or
  /// the account is no longer allowed.
  Future<AppUser?> restore() async {
    if (Supabase.instance.client.auth.currentSession == null) return null;
    try {
      return await claim();
    } on IdentityException catch (e) {
      debugPrint('⚠️ [IDENTITY] Could not restore session: ${e.message}');
      return null;
    }
  }

  /// Applies a locally-updated profile (name/photo edit) without a round trip.
  void apply(AppUser updated) {
    _profile = updated;
    notifyListeners();
  }

  void clear() {
    debugPrint('🧹 [IDENTITY] Cleared profile');
    _profile = null;
    notifyListeners();
  }
}
