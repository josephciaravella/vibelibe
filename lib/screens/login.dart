import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibelibe/widgets/footer.dart';
import 'package:vibelibe/services/spotify_service.dart';
import 'package:vibelibe/widgets/theme_toggle.dart';

class Login extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;
  
  const Login({super.key, required this.onThemeChanged});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
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
        leading: ThemeToggle(onThemeChanged: widget.onThemeChanged),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainer,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // App Logo / Title
                      Icon(
                        Icons.graphic_eq_rounded,
                        size: 72,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "vibelibe",
                        textAlign: TextAlign.center,
                        style: textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                          letterSpacing: -1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Discover the true essence of your\nSpotify listening habits.",
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.8),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 48),
                      
                      // Login Card / Action Area
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withValues(alpha: 0.05),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                        child: Column(
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                await Supabase.instance.client.auth.signOut();
                                await SpotifyService().signInWithSpotify();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24.0,
                                  vertical: 18.0,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'lib/assets/spotify_black.png',
                                    width: 24,
                                    height: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    "Continue with Spotify",
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "You will be redirected to Spotify to securely log in.",
                              textAlign: TextAlign.center,
                              style: textTheme.bodySmall?.copyWith(
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
          ),
        ),
      ),
      bottomNavigationBar: const Footer(),
    );
  }
}
