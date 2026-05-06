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

class VibeLibe extends StatelessWidget {
  const VibeLibe({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: SolarizedTheme.lightTheme,
      darkTheme: SolarizedTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: AuthGateway(),
    );
  }
}

class AuthGateway extends StatelessWidget {
  const AuthGateway({super.key});

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
          return Analysis();
        } else {
          return Login();
        }
      },
    );
  }
}