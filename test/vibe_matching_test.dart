import 'package:flutter_test/flutter_test.dart';
import 'package:vibelibe/services/vibe_service.dart';

void main() {
  group('Vibe Distance Calculations', () {
    test('BPM Normalization handles standard range', () {
      expect(VibeService.calculateBpmNormalized(60.0), closeTo(0.0, 0.001));
      expect(VibeService.calculateBpmNormalized(200.0), closeTo(1.0, 0.001));
      expect(VibeService.calculateBpmNormalized(130.0), closeTo(0.5, 0.001));
    });

    test('BPM Normalization clamps outliers', () {
      expect(VibeService.calculateBpmNormalized(40.0), closeTo(0.0, 0.001));
      expect(VibeService.calculateBpmNormalized(250.0), closeTo(1.0, 0.001));
    });

    test('Distance of identical vectors is 0', () {
      final songVec = [0.8, 0.7, 0.6, 130.0];
      final plVec = [0.8, 0.7, 0.6, 130.0];
      
      final distance = VibeService.calculateDistance(songVec, plVec);
      expect(distance, closeTo(0.0, 0.001));
    });

    test('Distance of completely opposite vectors is 2.0', () {
      final songVec = [0.0, 0.0, 0.0, 60.0];
      final plVec = [1.0, 1.0, 1.0, 200.0];
      
      final distance = VibeService.calculateDistance(songVec, plVec);
      expect(distance, closeTo(2.0, 0.001));
    });

    test('Distance is calculated and sorted correctly', () {
      final songVec = [0.8, 0.7, 0.6, 130.0]; // normalized bpm = 0.5
      
      final pl1 = {'name': 'Pl 1 (Very Close)', 'vector': [0.8, 0.7, 0.6, 130.0]}; // dist = 0.0
      final pl2 = {'name': 'Pl 2 (Medium)', 'vector': [0.6, 0.5, 0.4, 110.0]}; // bpmNorm = (110-60)/140 = 0.357
      // dv=0.2, dd=0.2, de=0.2, db=0.143 -> dist = sqrt(0.04*3 + 0.02) = sqrt(0.14) = ~0.374
      final pl3 = {'name': 'Pl 3 (Far)', 'vector': [0.1, 0.1, 0.1, 60.0]}; // bpmNorm = 0.0
      // dv=0.7, dd=0.6, de=0.5, db=0.5 -> dist = sqrt(0.49+0.36+0.25+0.25) = sqrt(1.35) = ~1.162

      final playlists = [pl3, pl1, pl2];
      
      final List<Map<String, dynamic>> results = playlists.map((pl) {
        final dist = VibeService.calculateDistance(songVec, pl['vector'] as List<double>);
        return {
          'name': pl['name'],
          'distance': dist,
        };
      }).toList();

      results.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

      expect(results[0]['name'], 'Pl 1 (Very Close)');
      expect(results[1]['name'], 'Pl 2 (Medium)');
      expect(results[2]['name'], 'Pl 3 (Far)');
    });
  });
}
