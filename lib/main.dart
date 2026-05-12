import 'package:flutter/material.dart';
import 'package:vibelibe/screens/analysis.dart';
import 'package:vibelibe/screens/login.dart';
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

class AuthGateway extends StatelessWidget {
  final Function(ThemeMode) onThemeChanged;

  const AuthGateway({super.key, required this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      // Listen to auth state changes
      stream: Supabase.instance.client.auth.onAuthStateChange,

      // Build appropriate page based on auth state 
      builder: (context, snapshot) {
        // loading..
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        // check if there is a valid session currently
        final session = snapshot.hasData ? snapshot.data!.session : null;

        if (session != null) {
          return Analysis(onThemeChanged: onThemeChanged);
        } else {
          return Login(onThemeChanged: onThemeChanged);
        }
      },
    );
  }
}