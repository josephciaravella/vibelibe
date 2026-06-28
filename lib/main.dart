import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vibelibe/screens/song_search.dart';
import 'package:vibelibe/screens/login.dart';
import 'package:vibelibe/screens/vibe_onboarding.dart';
import 'package:vibelibe/theme/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://erwavrhxrqyrzslxrfgs.supabase.co',
    anonKey: 'sb_publishable_JeoSW6CrB6lPBwXyvOE4oA_mN9wkFh5',
  );

  await Supabase.instance.client.auth.signOut();
  runApp(VibeLibe());
}

class VibeLibe extends StatefulWidget {
  const VibeLibe({super.key});

  @override
  State<VibeLibe> createState() => _VibeLibeState();
}

class _VibeLibeState extends State<VibeLibe> {
  ThemeMode _themeMode = ThemeMode.system;

  void toggleTheme(ThemeMode newMode) {
    setState(() {
      _themeMode = newMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: SolarizedTheme.lightTheme,
      darkTheme: SolarizedTheme.darkTheme,
      themeMode: _themeMode,
      home: AuthGateway(onThemeChanged: toggleTheme),
    );
  }
}

class AuthGateway extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;

  const AuthGateway({super.key, required this.onThemeChanged});

  @override
  State<AuthGateway> createState() => _AuthGatewayState();
}

class _AuthGatewayState extends State<AuthGateway> {
  StreamSubscription<AuthState>? _authSubscription;
  Session? _session;
  bool _isLoading = true;
  bool? _hasVibes;

  @override
  void initState() {
    super.initState();
    // Get the current session synchronously on startup if available
    _session = Supabase.instance.client.auth.currentSession;
    _isLoading = false;
    if (_session != null) {
      _checkUserVibes();
    }

    // Listen to stream updates
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      final event = data.event;

      if (event == AuthChangeEvent.signedIn && session != null) {
        final providerToken = session.providerToken;
        final providerRefreshToken = session.providerRefreshToken;

        if (providerToken != null) {
          try {
            await Supabase.instance.client
                .from('user_spotify_tokens')
                .upsert({
                  'user_id': session.user.id,
                  'access_token': providerToken,
                  'refresh_token': providerRefreshToken,
                  'updated_at': DateTime.now().toUtc().toIso8601String(),
                });
            print('Spotify tokens successfully saved to the database!');
          } catch (e) {
            print('Error saving token: $e');
          }
        }
      }

      if (mounted) {
        setState(() {
          _session = session;
          if (session == null) {
            _hasVibes = null;
          } else {
            _checkUserVibes();
          }
        });
      }
    });
  }

  Future<void> _checkUserVibes() async {
    final userId = _session?.user.id;
    if (userId == null) return;
    try {
      print("Checking database for vibes of user: $userId");
      final response = await Supabase.instance.client
          .from('playlist_vibes')
          .select('id')
          .eq('user_id', userId)
          .limit(1);

      print("Vibes query response: $response (found: ${response.isNotEmpty})");

      if (mounted) {
        setState(() {
          _hasVibes = response.isNotEmpty;
        });
      }
    } catch (e) {
      print("Error checking user vibes: $e");
      // Fallback to true to prevent screen blocking
      if (mounted) {
        setState(() {
          _hasVibes = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_session != null) {
      if (_hasVibes == null) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      if (_hasVibes == true) {
        return SongSearch(onThemeChanged: widget.onThemeChanged);
      } else {
        return VibeOnboarding(
          onThemeChanged: widget.onThemeChanged,
          onComplete: () {
            setState(() {
              _hasVibes = true;
            });
          },
        );
      }
    } else {
      return Login(onThemeChanged: widget.onThemeChanged);
    }
  }
}