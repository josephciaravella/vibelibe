import 'package:flutter/material.dart';
import 'package:vibelibe/screens/login.dart';
import 'package:vibelibe/theme/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://erwavrhxrqyrzslxrfgs.supabase.co',
    anonKey: 'sb_publishable_JeoSW6CrB6lPBwXyvOE4oA_mN9wkFh5',
  );
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
      home: Login(),
    );
  }
}
