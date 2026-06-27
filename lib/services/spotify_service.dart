import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SpotifyService {
  // Use the singleton instance of the Supabase client
  final _supabase = Supabase.instance.client;

  Future<void> signInWithSpotify() async {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.spotify,
      redirectTo: kIsWeb ? null : 'my.vibelibe.app://callback', 
      scopes: 'playlist-read-private playlist-read-collaborative',
      queryParams: {'show_dialog': 'true'},
      authScreenLaunchMode: kIsWeb 
          ? LaunchMode.platformDefault 
          : LaunchMode.externalApplication,
    );
  }
}