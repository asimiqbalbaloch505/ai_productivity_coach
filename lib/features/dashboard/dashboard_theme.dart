import 'package:flutter/material.dart';

/// Local tokens for the dashboard module only.
/// Colors were sampled from the shared "daywise" Dashboard design (Today screen).
class DashColors {
  static const Color background = Color(0xFFFCF6E9); // cream page
  static const Color surface = Color(0xFFFFFDF7); // cards
  static const Color border = Color(0xFFE4DCCB);
  static const Color divider = Color(0xFFF2EEE3);
  static const Color primary = Color(0xFF007C46); // deep green
  static const Color navPill = Color(0xFFE3EAD9);
  static const Color lavender = Color(0xFFE8E6FF); // "Your day, simplified"
  static const Color lavenderText = Color(0xFF272644);
  static const Color avatarBg = Color(0xFFF4ECDD);
  static const Color textDark = Color(0xFF0C1827);
  static const Color textMuted = Color(0xFF4A586A);
  static const Color checkBorder = Color(0xFFCBC4B2);
  static const Color dotPending = Color(0xFF0083A5);
  static const Color dotDone = Color(0xFF4BA47C);
  static const Color dotOverdue = Color(0xFFC2410C);
  static const Color progressTrack = Color(0xFFEDE7DA);
}

class DashDims {
  static const double pagePad = 22;
  static const double cardRadius = 14;
  static const double bigCardRadius = 20;
  static const double gap = 8;
}

class DashText {
  static const TextStyle logo = TextStyle(
      fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: DashColors.textDark);
  static const TextStyle greeting = TextStyle(
      fontSize: 26, fontWeight: FontWeight.w700, height: 1.2, color: DashColors.textDark);
  static const TextStyle subtitle =
      TextStyle(fontSize: 15, height: 1.4, color: DashColors.textMuted);
  static const TextStyle section = TextStyle(
      fontSize: 18, fontWeight: FontWeight.w700, color: DashColors.textDark);
  static const TextStyle body =
      TextStyle(fontSize: 15, height: 1.5, color: DashColors.lavenderText);
  static const TextStyle rowTitle = TextStyle(
      fontSize: 15, fontWeight: FontWeight.w600, color: DashColors.textDark);
  static const TextStyle small =
      TextStyle(fontSize: 13, color: DashColors.textMuted);
}
