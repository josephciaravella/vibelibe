import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibelibe/services/vibe_analyzer.dart';
import 'package:vibelibe/widgets/theme_toggle.dart';

class VibeOnboarding extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;
  final VoidCallback onComplete;
  final bool isManualSync;

  const VibeOnboarding({
    super.key,
    required this.onThemeChanged,
    required this.onComplete,
    this.isManualSync = false,
  });

  @override
  State<VibeOnboarding> createState() => _VibeOnboardingState();
}

class _VibeOnboardingState extends State<VibeOnboarding> with SingleTickerProviderStateMixin {
  late AnimationController _waveformController;
  String _statusMessage = "Connecting to Spotify...";
  Timer? _statusTimer;
  bool _hasError = false;
  String _errorMessage = "";
  int _statusIndex = 0;

  final List<String> _statuses = [
    "Connecting to Spotify...",
    "Scanning your playlists...",
    "Caching track vibe signatures...",
    "Determining playlist centroids...",
    "Calibrating your baseline dashboard...",
    "Wrapping up details..."
  ];

  @override
  void initState() {
    super.initState();
    _waveformController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _startStatusCycle();
    _runVibeCheck();
  }

  void _startStatusCycle() {
    _statusTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_statusIndex < _statuses.length - 1) {
        setState(() {
          _statusIndex++;
          _statusMessage = _statuses[_statusIndex];
        });
      }
    });
  }

  Future<void> _runVibeCheck() async {
    setState(() {
      _hasError = false;
      _errorMessage = "";
      _statusMessage = widget.isManualSync 
        ? "Connecting to Spotify & checking for new playlists..."
        : "Contacting Spotify & loading playlist sync state...";
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception("User not authenticated");
      }
      final userId = user.id;

      bool inSync = false;
      int processedCount = 0;
      int totalPlaylists = 0;
      bool isFirstBatch = true;

      while (!inSync) {
        print("Invoking get-uncached-tracks Edge Function...");
        final response = await Supabase.instance.client.functions.invoke('get-uncached-tracks');
        print("Edge Function response status: ${response.status}");
        
        if (response.status != 200) {
          throw Exception("Server returned status ${response.status}");
        }

        final data = response.data;
        if (data == null) {
          throw Exception("No data received from Edge Function");
        }

        final String status = data['status'] ?? 'in_sync';
        
        if (status == 'in_sync') {
          inSync = true;
          break;
        }
        
        _statusTimer?.cancel(); // Stop cycling generic messages

        final List<dynamic> playlists = data['playlists'] ?? [];
        final List<dynamic> uncachedTracks = data['uncached_tracks'] ?? [];
        
        if (isFirstBatch) {
          final int totalRemaining = data['total_remaining'] ?? playlists.length;
          totalPlaylists = processedCount + totalRemaining;
          isFirstBatch = false;
        }
        
        final int totalTracks = uncachedTracks.length;
        print("Need to analyze $totalTracks uncached tracks for this batch...");
        
        final Map<String, dynamic> uncachedTrackMap = {
          for (var t in uncachedTracks) t['id']: t
        };
        final Set<String> analyzedInBatch = {};

        // 1. Process uncached tracks playlist-by-playlist for accurate UI
        for (int pIdx = 0; pIdx < playlists.length; pIdx++) {
          final p = playlists[pIdx];
          final String playlistName = p['name'] ?? 'Playlist';
          final List<dynamic> trackIds = p['track_ids'] ?? [];
          final int playlistTotalTracks = trackIds.length;
          
          for (int tIdx = 0; tIdx < playlistTotalTracks; tIdx++) {
            final String tid = trackIds[tIdx].toString();
            
            if (uncachedTrackMap.containsKey(tid) && !analyzedInBatch.contains(tid)) {
              final track = uncachedTrackMap[tid];
              final String title = track['title'] ?? 'Unknown';
              final String artistName = track['artist'] ?? 'Unknown';
              final String? previewUrl = track['preview_url'];

              setState(() {
                _statusMessage = "Syncing '$playlistName' (${processedCount + pIdx + 1} of $totalPlaylists)...\nAnalyzing missing track ${tIdx + 1} of $playlistTotalTracks:\n$title\nby $artistName";
              });

              List<double>? vibeVector;
              if (previewUrl != null && previewUrl.isNotEmpty) {
                try {
                  vibeVector = await VibeAnalyzer.analyzePreview(previewUrl);
                } catch (e) {
                  print("Failed to analyze track $tid: $e");
                }
              }

              await Supabase.instance.client
                  .from('track_cache')
                  .upsert({
                    'id': tid,
                    'title': title,
                    'artist_name': artistName,
                    'vibe_vector': vibeVector,
                  });
              
              analyzedInBatch.add(tid);
            }
          }
        }

        // Collect all unique track IDs from this batch's playlists
        final Set<String> allTrackIds = {};
        for (final p in playlists) {
          final List<dynamic> trackIds = p['track_ids'] ?? [];
          for (final tid in trackIds) {
            if (tid is String) allTrackIds.add(tid);
          }
        }

        final List<String> allTrackIdList = allTrackIds.toList();
        final Map<String, List<double>?> vectorMap = {};

        const int batchSize = 500;
        for (int i = 0; i < allTrackIdList.length; i += batchSize) {
          final chunk = allTrackIdList.sublist(i, math.min(i + batchSize, allTrackIdList.length));
          final cacheResponse = await Supabase.instance.client
              .from('track_cache')
              .select('id, vibe_vector')
              .inFilter('id', chunk);

          for (final row in cacheResponse) {
            final String tid = row['id'] ?? '';
            final rawVector = row['vibe_vector'];
            if (tid.isNotEmpty) {
              vectorMap[tid] = _parseVector(rawVector);
            }
          }
        }

        // 3. Calculate centroid and upsert for each playlist
        for (int pIdx = 0; pIdx < playlists.length; pIdx++) {
          final p = playlists[pIdx];
          final String playlistId = p['id'] ?? '';
          final String playlistName = p['name'] ?? 'Playlist';
          final String snapshotId = p['snapshot_id'] ?? '';
          final List<dynamic> trackIds = p['track_ids'] ?? [];

          setState(() {
            _statusMessage = "Syncing '$playlistName' (${processedCount + pIdx + 1} of $totalPlaylists)...\nCalibrating playlist vibe...";
          });

          double sumValence = 0.0;
          double sumDanceability = 0.0;
          double sumEnergy = 0.0;
          double sumBpm = 0.0;
          int validCount = 0;

          for (final tid in trackIds) {
            if (tid is String) {
              final vec = vectorMap[tid];
              if (vec != null && vec.length == 4) {
                sumValence += vec[0];
                sumDanceability += vec[1];
                sumEnergy += vec[2];
                sumBpm += vec[3];
                validCount++;
              }
            }
          }

          List<double> playlistCentroid = [0.5, 0.5, 0.5, 120.0];
          if (validCount > 0) {
            playlistCentroid = [
              sumValence / validCount,
              sumDanceability / validCount,
              sumEnergy / validCount,
              sumBpm / validCount,
            ];
          }

          await Supabase.instance.client
              .from('playlist_vibes')
              .upsert({
                'id': playlistId,
                'snapshot_id': snapshotId,
                'vibe_vector': playlistCentroid,
                'user_id': userId,
                'track_count': trackIds.length,
              });
        }
        
        processedCount += playlists.length;
      }

      _statusTimer?.cancel();
      setState(() {
        _statusMessage = widget.isManualSync 
          ? "Sync completed successfully!"
          : "Onboarding completed successfully!";
      });

      if (mounted) {
        // Small delay so user can see "completed" message
        await Future.delayed(const Duration(seconds: 1));
        widget.onComplete();
      }
    } catch (e) {
      print("Vibe sync failed: $e");
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString().replaceAll("Exception: ", "");
        });
      }
    }
  }

  List<double>? _parseVector(dynamic rawVector) {
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

  @override
  void dispose() {
    _waveformController.dispose();
    _statusTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: colorScheme.onSurface.withValues(alpha: 0.7)),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
          ),
          ThemeToggle(onThemeChanged: widget.onThemeChanged),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainer,
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.graphic_eq_rounded,
                  size: 64,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  "vibelibe",
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 48),
                
                if (!_hasError) ...[
                  // Pulse Waveform
                  _buildPulsingWaveform(colorScheme),
                  const SizedBox(height: 40),
                  Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!widget.isManualSync)
                    Text(
                      "This only takes a moment on your first visit.",
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                ] else ...[
                  // Error card
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.error.withValues(alpha: 0.2),
                      ),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: colorScheme.error,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.isManualSync ? "Sync Failed" : "Onboarding Failed",
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage.isNotEmpty 
                              ? _errorMessage 
                              : "An error occurred while communicating with Spotify.",
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _runVibeCheck,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "Retry Analysis",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPulsingWaveform(ColorScheme colorScheme) {
    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(7, (index) {
          return AnimatedBuilder(
            animation: _waveformController,
            builder: (context, child) {
              final t = _waveformController.value;
              final phase = index * 0.5;
              final wave = math.sin(t * 2 * math.pi + phase);
              final normalizedWave = (wave + 1) / 2;
              final height = 15.0 + 35.0 * normalizedWave;
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 6,
                height: height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colorScheme.secondary,
                      colorScheme.primary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3 * normalizedWave),
                      blurRadius: 8,
                    ),
                  ],
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
