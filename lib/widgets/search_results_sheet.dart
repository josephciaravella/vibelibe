import 'dart:ui';
import 'package:flutter/material.dart';
import 'track_tile.dart';

class SearchResultsSheet extends StatelessWidget {
  final List<dynamic> tracks;
  final Function(Map<dynamic, dynamic>) onTrackTap;

  const SearchResultsSheet({
    super.key,
    required this.tracks,
    required this.onTrackTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(28),
        topRight: Radius.circular(28),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.35),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag Handle
                  const SizedBox(height: 12),
                  Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Sheet Header Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.library_music_rounded,
                          color: colorScheme.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Select a Song",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "${tracks.length} results",
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Track List
                  Flexible(
                    child: tracks.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40.0),
                            child: Text(
                              "No songs found.",
                              style: TextStyle(
                                color: colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            itemCount: tracks.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                              color: colorScheme.outline.withValues(alpha: 0.1),
                            ),
                            itemBuilder: (context, index) {
                              final trackItem = tracks[index] as Map<dynamic, dynamic>;
                              return TrackTile(
                                track: trackItem,
                                onTap: () => onTrackTap(trackItem),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
