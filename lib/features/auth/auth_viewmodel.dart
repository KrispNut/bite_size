import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

      debugPrint('🔐 [AUTH] Initializing GoogleSignIn (webClientId: $webClientId)');
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

      debugPrint('🔑 [AUTH] Google account selected: ${googleUser.email} (ID: ${googleUser.id})');
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        debugPrint('❌ [AUTH ERROR] No ID Token returned from Google Sign-In');
        throw 'No ID Token returned. Ensure Web Client ID (serverClientId) is configured.';
      }

      debugPrint('🎫 [AUTH] Acquired ID Token (length: ${idToken.length}). Authenticating with Supabase...');
      final response = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      debugPrint('✅ [AUTH SUCCESS] Supabase authenticated user: ${response.user?.email} (UID: ${response.user?.id})');
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e, st) {
      debugPrint('❌ [AUTH ERROR] Google Sign-In failed: $e\n$st');
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    debugPrint('🖱️ [ON_TAP] "Sign Out" button clicked');
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        debugPrint('🔐 [AUTH] Signing out from GoogleSignIn instance...');
        await googleSignIn.signOut();
      }
    } catch (e) {
      debugPrint('⚠️ [AUTH] Error during Google instance sign out: $e');
    }
    await Supabase.instance.client.auth.signOut();
    debugPrint('✅ [AUTH SUCCESS] Signed out from Supabase');
  }
}
