import 'package:flutter/material.dart';
import 'base_tile.dart';

class PlaylistMatchTile extends StatelessWidget {
  final Map<String, dynamic> playlist;
  final VoidCallback? onTap;

  const PlaylistMatchTile({
    super.key,
    required this.playlist,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final String title = playlist['name'] ?? 'Playlist';
    final int trackCount = playlist['track_count'] ?? 0;
    final String? imageUrl = playlist['imageUrl'];
    final double similarity = playlist['similarity'] ?? 0.0;

    // Build the leading image widget
    final Widget leadingWidget = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.secondary.withValues(alpha: 0.6),
            colorScheme.primary.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: imageUrl != null
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildPlaceholderIcon(),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                );
              },
            )
          : _buildPlaceholderIcon(),
    );

    // Build the trailing match percentage badge
    final Widget trailingWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (similarity >= 85
                ? Colors.green
                : similarity >= 70
                    ? colorScheme.primary
                    : colorScheme.secondary)
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (similarity >= 85
                  ? Colors.green
                  : similarity >= 70
                      ? colorScheme.primary
                      : colorScheme.secondary)
              .withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        "${similarity.toStringAsFixed(0)}% Match",
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: similarity >= 85
              ? Colors.green
              : similarity >= 70
                  ? colorScheme.primary
                  : colorScheme.secondary,
        ),
      ),
    );

    return BaseTile(
      leading: leadingWidget,
      title: title,
      subtitle: "$trackCount tracks",
      trailing: trailingWidget,
      onTap: onTap,
    );
  }

  Widget _buildPlaceholderIcon() {
    return const Center(
      child: Icon(
        Icons.playlist_play_rounded,
        color: Colors.white,
        size: 32,
      ),
    );
  }
}
