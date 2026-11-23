import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography: Inter for body, Poppins for headings/titles.
class AppTextStyles {
  AppTextStyles._();

  static TextTheme textTheme([TextTheme? base]) {
    return GoogleFonts.interTextTheme(base).copyWith(
      displayLarge: GoogleFonts.poppins(fontWeight: FontWeight.bold),
      displayMedium: GoogleFonts.poppins(fontWeight: FontWeight.bold),
      displaySmall: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      headlineLarge: GoogleFonts.poppins(fontWeight: FontWeight.w700),
      headlineMedium: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      headlineSmall: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      titleLarge: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.poppins(fontWeight: FontWeight.w500),
      titleSmall: GoogleFonts.poppins(fontWeight: FontWeight.w500),
    );
  }

  static TextStyle get button =>
      GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15);
}
