import 'package:flutter/material.dart';
import 'package:si_kesa/config/theme_config.dart';
import 'package:si_kesa/screens/auth/login_screen.dart';
import 'package:si_kesa/screens/wali/dashboard_screen.dart';
import 'package:si_kesa/screens/wali/siswa_main_screen.dart';

void main() {
  runApp(const SiKesaApp());
}

class SiKesaApp extends StatelessWidget {
  const SiKesaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SI-KESA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SiswaMainScreen(),
    );
  }
}