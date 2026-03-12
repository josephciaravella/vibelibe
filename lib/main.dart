import 'package:flutter/material.dart';
import 'package:vibelibe/screens/login.dart';
import 'package:vibelibe/theme/theme.dart';
void main() {
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
