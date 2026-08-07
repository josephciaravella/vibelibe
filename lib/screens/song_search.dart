import 'dart:ui';
import 'dart:math' as math;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibelibe/widgets/theme_toggle.dart';
import 'package:vibelibe/widgets/search_results_sheet.dart';
import 'package:vibelibe/screens/vibe_analysis.dart';
import 'package:vibelibe/screens/vibe_onboarding.dart';

class SongSearch extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;

  const SongSearch({super.key, required this.onThemeChanged});

  @override
  State<SongSearch> createState() => _SongSearchState();
}

class _SongSearchState extends State<SongSearch> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSearching = false;
  
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _handleSearch(String query) async {
    if (query.trim().isEmpty) return;
    
    _focusNode.unfocus();
    setState(() {
      _isSearching = true;
    });

    final client = HttpClient();
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = 'https://api.deezer.com/search?q=$encodedQuery';
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final bytes = await response.fold<List<int>>([], (prev, elem) => prev..addAll(elem));
        final body = utf8.decode(bytes);
        final parsed = json.decode(body) as Map<String, dynamic>;
        final List<dynamic> dataList = parsed['data'] ?? [];
        
        // Map Deezer items to Spotify track object format
        final List<Map<String, dynamic>> trackList = dataList.map((item) {
          final artistName = item['artist']?['name'] ?? 'Unknown Artist';
          final albumTitle = item['album']?['title'] ?? 'Unknown Album';
          final coverUrl = item['album']?['cover_medium'] ?? '';
          
          return {
            'id': 'deezer_${item['id']}',
            'name': item['title'] ?? 'Unknown Track',
            'artists': [{'name': artistName}],
            'album': {
              'name': albumTitle,
              'images': coverUrl.isNotEmpty ? [{'url': coverUrl}] : [],
            },
            'preview_url': item['preview'] ?? '',
          };
        }).toList();

        if (trackList.isNotEmpty) {
          if (mounted) {
            _showSearchResults(trackList);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No tracks found for your search query.')),
            );
          }
        }
      } else {
        throw Exception("Server returned status ${response.statusCode}");
      }
    } catch (e) {
      print("Search failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search error: $e')),
        );
      }
    } finally {
      client.close();
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        _searchController.clear();
      }
    }
  }

  void _showSearchResults(List<dynamic> tracks) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.75,
          child: SearchResultsSheet(
            tracks: tracks,
            onTrackTap: (track) {
              // Close the bottom sheet
              Navigator.pop(context);
              
              // Navigate to the vibe analysis page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VibeAnalysis(
                    track: track,
                    onThemeChanged: widget.onThemeChanged,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: ThemeToggle(onThemeChanged: widget.onThemeChanged),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: colorScheme.onSurface.withValues(alpha: 0.7)),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
          )
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
          child: Column(
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _buildGlassSearchBar(colorScheme),
              ),
              Expanded(
                child: Center(
                  child: _isSearching
                      ? CircularProgressIndicator(color: colorScheme.primary)
                      : _buildIdleState(colorScheme),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VibeOnboarding(
                            onThemeChanged: widget.onThemeChanged,
                            isManualSync: true,
                            onComplete: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.sync_rounded),
                    label: const Text(
                      "Sync New Playlists",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.surface.withValues(alpha: 0.6),
                      foregroundColor: colorScheme.onSurface,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassSearchBar(ColorScheme colorScheme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            style: TextStyle(color: colorScheme.onSurface, fontSize: 16),
            cursorColor: colorScheme.primary,
            textInputAction: TextInputAction.search,
            onSubmitted: _handleSearch,
            decoration: InputDecoration(
              hintText: 'Search for a song...',
              hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
              prefixIcon: Icon(Icons.search, color: colorScheme.onSurface.withValues(alpha: 0.7)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIdleState(ColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(7, (index) {
              return AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  final t = _waveController.value;
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
        ),
        const SizedBox(height: 40),
        Text(
          "Type a song to find its vibe...",
          style: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.8),
            fontSize: 18,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
