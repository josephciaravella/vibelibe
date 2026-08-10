import 'dart:math' as math;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibelibe/services/vibe_analyzer.dart';

class VibeMatchResult {
  final List<double> trackVector;
  final List<Map<String, dynamic>> matchingPlaylists;

  VibeMatchResult({
    required this.trackVector,
    required this.matchingPlaylists,
  });
}

class VibeService {
  static List<double>? parseVector(dynamic rawVector) {
    if (rawVector == null) return null;
    if (rawVector is List) {
      return rawVector.map((e) => double.tryParse(e.toString()) ?? 0.5).toList();
    }
    if (rawVector is String) {
      final clean = rawVector.replaceAll('[', '').replaceAll(']', '').replaceAll('{', '').replaceAll('}', '');
      if (clean.isEmpty) return null;
      return clean.split(',').map((e) => double.tryParse(e.trim()) ?? 0.5).toList();
    }
    return null;
  }

  static double calculateBpmNormalized(double bpm) {
    return ((bpm - 60.0) / 140.0).clamp(0.0, 1.0);
  }

  static double calculateDistance(List<double> songVec, List<double> plVec) {
    if (songVec.length != 4 || plVec.length != 4) return 2.0;

    final double dv = songVec[0] - plVec[0];
    final double dd = songVec[1] - plVec[1];
    final double de = songVec[2] - plVec[2];
    
    final double bpmSongNorm = calculateBpmNormalized(songVec[3]);
    final double bpmPlNorm = calculateBpmNormalized(plVec[3]);
    final double db = bpmSongNorm - bpmPlNorm;

    return math.sqrt(dv * dv + dd * dd + de * de + db * db);
  }

  static Future<VibeMatchResult> matchSongToPlaylists(Map<dynamic, dynamic> track) async {
    final String trackId = track['id'] ?? '';
    if (trackId.isEmpty) {
      throw Exception("Invalid track ID");
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception("User not authenticated");
    }
    final String currentUserId = user.id;

    List<double>? trackVector;

    // 1. Check if track vector is cached in track_cache
    try {
      final cacheRes = await Supabase.instance.client
          .from('track_cache')
          .select('vibe_vector')
          .eq('id', trackId)
          .maybeSingle();

      if (cacheRes != null && cacheRes['vibe_vector'] != null) {
        trackVector = parseVector(cacheRes['vibe_vector']);
      }
    } catch (cacheError) {
      print("Failed to load track cache: $cacheError");
    }

    // 2. If not cached, analyze it
    if (trackVector == null) {
      final String? previewUrl = track['preview_url'];
      if (previewUrl != null && previewUrl.isNotEmpty) {
        final vector = await VibeAnalyzer.analyzePreview(previewUrl);
        if (vector != null && vector.length == 4) {
          trackVector = vector;

          // Cache it in track_cache
          final String artists = (track['artists'] as List?)
              ?.map((a) => a['name'] ?? 'Unknown')
              .join(', ') ?? 'Unknown Artist';

          try {
            await Supabase.instance.client.from('track_cache').upsert({
              'id': trackId,
              'title': track['name'] ?? 'Unknown Track',
              'artist_name': artists,
              'vibe_vector': vector,
            });
          } catch (upsertError) {
            print("Failed to save track to cache: $upsertError");
          }
        }
      }
    }

    if (trackVector == null) {
      throw Exception("Acoustic preview is unavailable for this track.\nWe cannot perform direct vibe analysis.");
    }

    // 3. Fetch playlist centroids and metadata directly from the database!
    // This is instant and completely bypasses the heavy Edge Function.
    final vibesResponse = await Supabase.instance.client
        .from('playlist_vibes')
        .select('id, name, image_url, vibe_vector, track_count')
        .eq('user_id', currentUserId);

    final List<Map<String, dynamic>> matches = [];
    
    for (final row in vibesResponse) {
      final String pid = row['id'] ?? '';
      final String pName = row['name'] ?? 'Playlist';
      final String? imageUrl = row['image_url'];
      final int trackCount = row['track_count'] ?? 0;
      
      final rawVector = row['vibe_vector'];
      final vec = parseVector(rawVector);
      
      if (pid.isNotEmpty && vec != null && vec.length == 4) {
        final distance = calculateDistance(trackVector, vec);
        final similarity = (1.0 - (distance / 2.0)) * 100.0;
        matches.add({
          'id': pid,
          'name': pName,
          'image_url': imageUrl,
          'similarity': similarity.clamp(0.0, 100.0),
          'track_count': trackCount,
        });
      }
    }

    // 4. Sort matches by similarity (highest first)
    matches.sort((a, b) => (b['similarity'] as double).compareTo(a['similarity'] as double));

    return VibeMatchResult(
      trackVector: trackVector,
      matchingPlaylists: matches.take(10).toList(),
    );
  }
}
