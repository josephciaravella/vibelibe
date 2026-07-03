import 'package:flutter/material.dart';
import 'base_tile.dart';

class TrackTile extends StatelessWidget {
  final Map<dynamic, dynamic> track;
  final VoidCallback? onTap;

  const TrackTile({
    super.key,
    required this.track,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Extract metadata safely
    final String title = track['name'] ?? 'Unknown Track';
    
    final List<dynamic> artistsList = track['artists'] ?? [];
    final String artists = artistsList.isNotEmpty
        ? artistsList.map((a) => a['name'] ?? 'Unknown Artist').join(', ')
        : 'Unknown Artist';
        
    final String album = track['album']?['name'] ?? '';
    
    // Check if album cover image is available
    final List<dynamic> images = track['album']?['images'] ?? [];
    final String? imageUrl = images.isNotEmpty ? images[0]['url'] : null;

    // Build the leading image widget
    final Widget leadingWidget = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withValues(alpha: 0.8),
            colorScheme.secondary.withValues(alpha: 0.8),
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

    return BaseTile(
      leading: leadingWidget,
      title: title,
      subtitle: artists,
      caption: album.isNotEmpty ? album : null,
      onTap: onTap,
    );
  }

  Widget _buildPlaceholderIcon() {
    return const Center(
      child: Icon(
        Icons.audiotrack,
        color: Colors.white,
        size: 30,
      ),
    );
  }
}
