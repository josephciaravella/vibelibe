import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SpotifyService {
  // Use the singleton instance of the Supabase client
  final _supabase = Supabase.instance.client;

  Future<void> signInWithSpotify() async {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.spotify,
      // Matches your AndroidManifest.xml: android:scheme="my.vibelibe.app" android:host="auth"
      redirectTo: kIsWeb ? null : 'my.vibelibe.app://callback', 
      authScreenLaunchMode: kIsWeb 
          ? LaunchMode.platformDefault 
          : LaunchMode.externalApplication,
    );
  }
}