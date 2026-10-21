import 'package:flutter/material.dart';
import 'package:si_kesa/screens/guru/dashboard_screen.dart';
import 'package:si_kesa/screens/guru/profil/profil_screen.dart';
import 'package:si_kesa/widgets/guru_bottom_nav.dart';
import 'package:si_kesa/screens/guru/absensi/absensi_screen.dart';
import 'package:si_kesa/screens/guru/jadwal/jadwal_mengajar_screen.dart';

/// Kerangka aplikasi Guru: isi layar + bilah bawah (Home, Jadwal, Absen, Profil).
class GuruMainScreen extends StatefulWidget {
  const GuruMainScreen({super.key});

  @override
  State<GuruMainScreen> createState() => _GuruMainScreenState();
}

class _GuruMainScreenState extends State<GuruMainScreen> {
  int _index = 0;
  bool _profilDibuka = false; // Profil baru dimuat saat tab-nya pertama kali dibuka



  void _pindah(int i) {
  if (i == 2) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AbsensiGuruScreen()),
    );
    return;
  }
    if (i == 1) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const JadwalMengajarGuruScreen()),
    );
    return;
  }
  setState(() {
    if (i == 3) _profilDibuka = true;
    _index = i;
  });
}

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _index == 0,
      // Tombol kembali HP: dari tab Profil kembali ke Home dulu.
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _pindah(0);
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index == 3 ? 1 : 0,
          children: [
            const GuruDashboardScreen(),
            if (_profilDibuka) const ProfilGuruScreen() else const SizedBox.shrink(),
          ],
        ),
        bottomNavigationBar: GuruBottomNav(currentIndex: _index, onTap: _pindah),
      ),
    );
  }
}