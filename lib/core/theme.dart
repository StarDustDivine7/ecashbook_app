import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final ThemeData ecTheme = ThemeData(
  primarySwatch: Colors.blue,
  textTheme: GoogleFonts.interTextTheme(),
  fontFamily: GoogleFonts.inter().fontFamily,
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF422F90),
    secondary: Color(0xFF5A4FCF),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF422F90),
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF422F90),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF422F90), width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  ),
);
