import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SpotifyService {
  // Use the singleton instance of the Supabase client
  final _supabase = Supabase.instance.client;

  Future<void> signInWithSpotify() async {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.spotify,
      redirectTo: kIsWeb ? null : 'my.vibelibe.app://callback', 
      scopes: 'playlist-read-private playlist-read-collaborative playlist-modify-public playlist-modify-private',
      queryParams: {'show_dialog': 'true'},
      authScreenLaunchMode: kIsWeb 
          ? LaunchMode.platformDefault 
          : LaunchMode.externalApplication,
    );
  }

  Future<void> addTrackToPlaylist({
    required String playlistId,
    required String trackId,
    required String trackTitle,
    required String artistName,
  }) async {
    final response = await _supabase.functions.invoke(
      'add-track-to-playlist',
      body: {
        'playlistId': playlistId,
        'trackId': trackId,
        'trackTitle': trackTitle,
        'artistName': artistName,
      },
    );

    if (response.status != 200) {
      final data = response.data;
      final String errorMsg = (data is Map) 
          ? (data['error'] ?? data['details'] ?? 'Server returned status ${response.status}')
          : 'Server returned status ${response.status}';
      throw Exception(errorMsg);
    }
  }
}