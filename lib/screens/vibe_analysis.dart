import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vibelibe/services/vibe_service.dart';
import 'package:vibelibe/widgets/theme_toggle.dart';
import 'package:vibelibe/widgets/track_tile.dart';
import 'package:vibelibe/widgets/playlist_match_tile.dart';

class VibeAnalysis extends StatefulWidget {
  final Map<dynamic, dynamic> track;
  final Function(ThemeMode) onThemeChanged;

  const VibeAnalysis({
    super.key,
    required this.track,
    required this.onThemeChanged,
  });

  @override
  State<VibeAnalysis> createState() => _VibeAnalysisState();
}

class _VibeAnalysisState extends State<VibeAnalysis> with SingleTickerProviderStateMixin {
  late AnimationController _waveformController;
  
  bool _isLoading = true;
  String _statusMessage = "Locating track vibe signature...";
  String? _errorMessage;
  List<Map<String, dynamic>> _matchingPlaylists = [];

  @override
  void initState() {
    super.initState();
    _waveformController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _performVibeMatching();
  }

  @override
  void dispose() {
    _waveformController.dispose();
    super.dispose();
  }

  Future<void> _performVibeMatching() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statusMessage = "Locating track vibe signature...";
    });

    try {
      // Delegate matching logic to VibeService
      final result = await VibeService.matchSongToPlaylists(widget.track);

      if (mounted) {
        setState(() {
          _matchingPlaylists = result.matchingPlaylists;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Vibe matching failed: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll("Exception: ", "");
        });
      }
    }
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
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
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                
                // Track Card Header
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.15),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.03),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: TrackTile(
                    track: widget.track,
                  ),
                ),
                
                const SizedBox(height: 16),

                Expanded(
                  child: _isLoading 
                      ? _buildLoadingState(colorScheme, textTheme)
                      : _errorMessage != null 
                          ? _buildErrorState(colorScheme, textTheme)
                          : _buildResultsState(colorScheme, textTheme),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPulsingWaveform(colorScheme),
        const SizedBox(height: 48),
        Text(
          _statusMessage,
          textAlign: TextAlign.center,
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Comparing acoustic characteristics & vibe models",
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.error.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.error.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: colorScheme.error,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                "Analysis Unavailable",
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? "An unknown error occurred.",
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.secondaryContainer,
            foregroundColor: colorScheme.onSecondaryContainer,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text("Go Back to Search", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildResultsState(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Row(
          children: [
            Icon(
              Icons.compare_arrows_rounded,
              color: colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              "Top Matching Playlists",
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Match list
        Expanded(
          child: _matchingPlaylists.isEmpty
              ? Center(
                  child: Text(
                    "No playlists matched. Please sync your playlists first.",
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                )
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: _matchingPlaylists.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final pl = _matchingPlaylists[index];
                    return PlaylistMatchTile(playlist: pl);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPulsingWaveform(ColorScheme colorScheme) {
    return SizedBox(
      height: 80,
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
              final height = 20.0 + 40.0 * normalizedWave;
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
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
                      color: colorScheme.primary.withValues(alpha: 0.4 * normalizedWave),
                      blurRadius: 12,
                      spreadRadius: 2,
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
