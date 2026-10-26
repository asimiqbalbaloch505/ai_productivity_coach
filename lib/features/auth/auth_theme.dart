import 'package:flutter/material.dart';

class AuthTheme {
  static const cream = Color(0xFFFBF6EA);
  static const green = Color(0xFF00834D);
  static const border = Color(0xFFE9E0D1);
  static const muted = Color(0xFF747D86);
  static const ink = Color(0xFF172334);

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: cream,
    colorScheme: ColorScheme.fromSeed(
      seedColor: green,
      primary: green,
      surface: cream,
    ),
    fontFamily: 'Roboto',
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFFFFDF9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      hintStyle: const TextStyle(fontSize: 12, color: muted),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: green),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: Colors.red),
      ),
    ),
  );

  static Widget logo() => const Text(
    'daywise',
    style: TextStyle(
      color: green,
      fontSize: 13,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
    ),
  );

  static Widget heading(String text) => Text(
    text,
    style: const TextStyle(
      color: ink,
      fontSize: 20,
      height: 1.2,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.6,
    ),
  );

  static Widget label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        color: ink,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  static Widget primaryButton({
    required String text,
    required VoidCallback? onPressed,
  }) => SizedBox(
    width: double.infinity,
    height: 42,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: green,
        foregroundColor: Colors.white,
        disabledBackgroundColor: green.withOpacity(0.5),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ),
  );

  static Widget outlineButton({
    required String text,
    required VoidCallback? onPressed,
  }) => SizedBox(
    width: double.infinity,
    height: 42,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11)),
    ),
  );

  static Widget link(String text, VoidCallback onTap) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.all(5),
      child: Text(text, style: const TextStyle(fontSize: 10, color: muted)),
    ),
  );
}
