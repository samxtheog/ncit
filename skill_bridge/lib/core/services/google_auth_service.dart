import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static const _clientId =
      '622381804025-367c0u8v2bq3cn4r2cp1fetdkm35ed7j.apps.googleusercontent.com';

  static final _instance = kIsWeb
      ? GoogleSignIn(
          clientId: _clientId,
          scopes: ['email', 'profile', 'openid'],
        )
      : GoogleSignIn(
          serverClientId: _clientId,
          scopes: ['email', 'profile'],
        );

  /// Returns a map with either `{idToken}` (Android/when available) or
  /// `{accessToken, email, name}` (web fallback).
  static Future<Map<String, String>?> signIn() async {
    try {
      await _instance.signOut();
      final account = await _instance.signIn();
      if (account == null) return null; // cancelled

      final auth = await account.authentication;

      // idToken available (Android, or web when GIS returns one)
      if (auth.idToken != null && auth.idToken!.isNotEmpty) {
        return {'idToken': auth.idToken!};
      }

      // Web fallback — accessToken + profile from the signed-in account
      if (auth.accessToken != null && auth.accessToken!.isNotEmpty) {
        return {
          'accessToken': auth.accessToken!,
          'email': account.email,
          'name': account.displayName ?? account.email.split('@').first,
        };
      }

      throw Exception(
          'Google Sign-In completed but returned no token. '
          'Check your OAuth client configuration in Google Cloud Console.');
    } catch (e) {
      rethrow;
    }
  }
}
