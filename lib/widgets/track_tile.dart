import 'package:flutter/material.dart';

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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.transparent,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Track Artwork / Icon Placeholder Container
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.8),
                        colorScheme.secondary.withValues(alpha: 0.8),
                      ],
                    ),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildPlaceholderIcon(colorScheme),
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
                      : _buildPlaceholderIcon(colorScheme),
                ),
              ),
              const SizedBox(width: 16),
              
              // Track details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                        letterSpacing: 0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      artists,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (album.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        album,
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w300,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon(ColorScheme colorScheme) {
    return Center(
      child: Icon(
        Icons.audiotrack,
        color: colorScheme.onPrimary,
        size: 30,
      ),
    );
  }
}
