import 'package:flutter/material.dart';
import 'package:si_kesa/screens/guru/dashboard_screen.dart';
import 'package:si_kesa/utils/ui_helper.dart';
import 'package:si_kesa/widgets/guru_bottom_nav.dart';

/// Kerangka aplikasi Guru: isi layar + bilah bawah (Home, Jadwal, Absen, Profil).
class GuruMainScreen extends StatefulWidget {
  const GuruMainScreen({super.key});

  @override
  State<GuruMainScreen> createState() => _GuruMainScreenState();
}

class _GuruMainScreenState extends State<GuruMainScreen> {
  final int _index = 0;

  static const _nama = ['Home', 'Jadwal', 'Absen', 'Profil'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const GuruDashboardScreen(),
      bottomNavigationBar: GuruBottomNav(
        currentIndex: _index,
        onTap: (i) {
          if (i == 0) return; // sudah di Home
          // TODO: push layar Jadwal / Absensi / Profil bila sudah dibuat.
          tampilkanBelumTersedia(context, _nama[i]);
        },
      ),
    );
  }
}