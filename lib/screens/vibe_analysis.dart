import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vibelibe/widgets/theme_toggle.dart';
import 'package:vibelibe/widgets/track_tile.dart';

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

  @override
  void initState() {
    super.initState();
    _waveformController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _waveformController.dispose();
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
                
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Loading Audio Waveform Visualizer (Exact 7-bar wave from song_search.dart)
                      _buildPulsingWaveform(colorScheme),
                      
                      const SizedBox(height: 48),
                      
                      // Loading Status Text
                      Text(
                        "Analyzing Playlist Vibes...",
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Deconstructing acoustic features & sonic landscape",
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
              // Phase shift per bar
              final phase = index * 0.5;
              // Smooth continuous wave
              final wave = math.sin(t * 2 * math.pi + phase);
              // Normalized from 0.0 to 1.0
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
