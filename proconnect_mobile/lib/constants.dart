import 'package:flutter/material.dart';

// API
const String apiBaseUrl = 'http://localhost:8080'; // macOS desktop test
// iOS simulator ise: 'http://127.0.0.1:8080'

// Renkler
const Color kPrimary = Color(0xFF19A15F);
const Color kPrimaryDark = Color(0xFF0B7A45);
const Color kAccent = Color(0xFF0F4B2F);
const Color kBg = Color(0xFFF5F2EE);
const Color kCard = Colors.white;
const Color kInk = Color(0xFF0F1A14);
const Color kMuted = Color(0xFF5C5C5C);
const Color kStar = Color(0xFFFFC107);
const Color kDanger = Color(0xFFDC3545);
const Color kWarning = Color(0xFFF0AD4E);
const Color kSuccess = Color(0xFF28A745);

// Tema
ThemeData appTheme() {
  return ThemeData(
    primaryColor: kPrimary,
    scaffoldBackgroundColor: kBg,
    fontFamily: 'Roboto',
    colorScheme: ColorScheme.fromSeed(
      seedColor: kPrimary,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kCard,
      foregroundColor: kInk,
      elevation: 0.5,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: kInk,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        fontFamily: 'Roboto',
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kPrimary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
    cardTheme: CardThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: kCard,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: kCard,
      selectedItemColor: kPrimary,
      unselectedItemColor: kMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 10,
    ),
  );
}
