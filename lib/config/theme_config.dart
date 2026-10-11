import 'package:flutter/material.dart';

/// Kumpulan warna dari desain Figma.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFE8963C);    // oranye: tombol & tab aktif
  static const Color headerGreen = Color(0xFF4B5A2F); // hijau olive (perkiraan)
  static const Color textDark = Color(0xFF4A2E06);   // judul & label
  static const Color textTab = Color(0xFF4A4636);    // tab tidak aktif
  static const Color textHint = Color(0xFF847743);   // placeholder input
  static const Color textMuted = Color(0xFF8A8368);  // teks bantuan bawah
  static const Color border = Color(0xFFD8D2BC);     // garis tepi input & toggle
  static const Color toggleBg = Color(0xFFFBF8F1);   // latar kotak toggle
  static const Color white = Color(0xFFFFFFFF);
}

/// Tema global aplikasi.
class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: AppColors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
        ),
      );
}