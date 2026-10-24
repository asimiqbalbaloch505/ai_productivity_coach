// lib/features/habits/habit_styles.dart
// Local colours / styles for the Habits module, sampled from the daywise
// designs (Screen 3 "Habits" and Screen 14 "Build a habit").
// Kept inside this folder on purpose – no shared styling files.

import 'package:flutter/material.dart';

class HabitColors {
  static const Color background = Color(0xFFFCF6E9);
  static const Color card = Color(0xFFFFFDF8);
  static const Color cardBorder = Color(0xFFEDE7DB);
  static const Color momentumCard = Color(0xFFE3EAD9);
  static const Color primary = Color(0xFF007C46);
  static const Color primaryDark = Color(0xFF0B5A33);
  static const Color amber = Color(0xFFC78707);
  static const Color track = Color(0xFFD5E0CC);
  static const Color textDark = Color(0xFF0C1827);
  static const Color textMuted = Color(0xFF5F6B7A);
  static const Color danger = Color(0xFFC0392B);
}

class HabitStyles {
  static const double screenPadding = 20;

  static BoxDecoration cardDecoration({double radius = 14}) => BoxDecoration(
    color: HabitColors.card,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: HabitColors.cardBorder),
  );
}