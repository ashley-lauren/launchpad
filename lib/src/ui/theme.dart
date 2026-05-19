import 'package:flutter/material.dart';

import '../models/launchpad_models.dart';

const List<int> _teamAccentPalette = [
  0xFF58A6FF,
  0xFF7EE787,
  0xFFFFC857,
  0xFFD2A8FF,
  0xFF79C0FF,
  0xFFFF7B72,
];

Color _teamAccentFromHex(String hex) {
  final cleanHex = hex.replaceAll('#', '');
  return Color(int.parse(cleanHex, radix: 16) | 0xFF000000);
}

Color teamAccentColor(Team team) {
  if (team.accentColor != null && team.accentColor!.isNotEmpty) {
    return _teamAccentFromHex(team.accentColor!);
  }

  final index = team.id.hashCode.abs() % _teamAccentPalette.length;
  return Color(_teamAccentPalette[index]);
}

Color teamAccentTint(Team team) => teamAccentColor(team).withOpacity(0.12);

ThemeData buildLaunchpadTheme() {
  const background = Color(0xFF0D1117);
  const surface = Color(0xFF161B22);
  const cyan = Color(0xFF00D7FF);
  const green = Color(0xFF7EE787);
  const amber = Color(0xFFFFC857);
  const blue = Color(0xFF79C0FF);

  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: cyan,
      secondary: green,
      tertiary: amber,
      surface: surface,
      onSurface: Color(0xFFE6EDF3),
    ),
    fontFamily: 'monospace',
    cardTheme: CardTheme(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF30363D)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF0D1117),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF30363D)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF30363D)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: cyan),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        side: WidgetStateProperty.all(
          const BorderSide(color: Color(0xFF30363D)),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return blue.withValues(alpha: 0.18);
          }
          return surface;
        }),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: cyan,
        foregroundColor: background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: blue),
    ),
    tabBarTheme: const TabBarTheme(
      labelColor: cyan,
      unselectedLabelColor: Color(0xFF8B949E),
      indicatorColor: cyan,
    ),
  );
}
