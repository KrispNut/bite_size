import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/services/identity_service.dart';

class AuthViewModel extends ChangeNotifier {
  bool isLoading = false;
  String? error;

  Future<bool> signInWithGoogle() async {
    debugPrint('🖱️ [ON_TAP] "Sign In with Google" button clicked');
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '';
      final iosClientId = dotenv.env['GOOGLE_IOS_CLIENT_ID'] ?? '';

      debugPrint(
        '🔐 [AUTH] Initializing GoogleSignIn (webClientId: $webClientId)',
      );
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: iosClientId.isNotEmpty ? iosClientId : null,
        serverClientId: webClientId.isNotEmpty ? webClientId : null,
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('ℹ️ [AUTH] User cancelled Google Sign-In dialog');
        isLoading = false;
        notifyListeners();
        return false;
      }

      debugPrint(
        '🔑 [AUTH] Google account selected: ${googleUser.email} (ID: ${googleUser.id})',
      );
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        debugPrint('❌ [AUTH ERROR] No ID Token returned from Google Sign-In');
        throw 'No ID Token returned. Ensure Web Client ID (serverClientId) is configured.';
      }

      debugPrint(
        '🎫 [AUTH] Acquired ID Token (length: ${idToken.length}). Authenticating with Supabase...',
      );

      AuthResponse? response;
      int attempts = 0;
      const maxAttempts = 3;

      while (attempts < maxAttempts) {
        attempts++;
        try {
          response = await Supabase.instance.client.auth.signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: idToken,
            accessToken: accessToken,
          );
          break;
        } on AuthRetryableFetchException catch (e) {
          debugPrint(
            '⚠️ [AUTH RETRY] Transient gateway/network error (attempt $attempts/$maxAttempts): ${e.message}',
          );
          if (attempts >= maxAttempts) rethrow;
          await Future.delayed(Duration(seconds: attempts));
        }
      }

      if (response == null) {
        throw 'Failed to authenticate with Supabase.';
      }

      debugPrint(
        '✅ [AUTH SUCCESS] Supabase authenticated user: ${response.user?.email} (UID: ${response.user?.id})',
      );

      // Authenticated is not the same as allowed. Google proved who they are;
      // the allowlist decides whether that person is on the office roster.
      try {
        await IdentityService.instance.claim();
      } on IdentityException catch (e) {
        debugPrint(
          '🚫 [AUTH] Allowlist rejected ${response.user?.email}: ${e.message}',
        );
        await _hardSignOut();
        error = e.message;
        isLoading = false;
        notifyListeners();
        return false;
      }

      isLoading = false;
      notifyListeners();
      return true;
    } catch (e, st) {
      debugPrint('❌ [AUTH ERROR] Google Sign-In failed: $e\n$st');
      if (e is AuthRetryableFetchException ||
          e.toString().contains('502') ||
          e.toString().contains('Bad Gateway')) {
        error =
            'Authentication service is temporarily unavailable. Please try signing in again.';
      } else if (e is AuthException) {
        error = e.message;
      } else {
        error = e.toString().replaceAll(RegExp(r'^Exception:\s*'), '');
      }
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    debugPrint('🖱️ [ON_TAP] "Sign Out" button clicked');
    await _hardSignOut();
    debugPrint('✅ [AUTH SUCCESS] Signed out from Supabase');
  }

  /// Drops Google, Supabase and the cached profile together. Used both for a
  /// deliberate sign-out and for backing out of a rejected sign-in — leaving
  /// any one of the three behind strands the app in a half-authenticated state.
  Future<void> _hardSignOut() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        debugPrint('🔐 [AUTH] Signing out from GoogleSignIn instance...');
        await googleSignIn.signOut();
      }
    } catch (e) {
      debugPrint('⚠️ [AUTH] Error during Google instance sign out: $e');
    }
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      debugPrint('⚠️ [AUTH] Error during Supabase sign out: $e');
    }
    IdentityService.instance.clear();
  }
}
