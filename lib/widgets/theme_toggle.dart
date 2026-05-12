import 'package:flutter/material.dart';

class ThemeToggle extends StatelessWidget {
  final Function(ThemeMode) onThemeChanged;

  const ThemeToggle({super.key, required this.onThemeChanged});

  @override
  Widget build(BuildContext context) {

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return IconButton(
      onPressed: () {
        if(isDarkMode) {
          onThemeChanged(ThemeMode.light);
        } else {
          onThemeChanged(ThemeMode.dark);
        }
      }, 
      icon: Icon(
        isDarkMode ? Icons.light_mode : Icons.dark_mode,
        color: Theme.of(context).colorScheme.onSurface,
      )
    );
  }
}