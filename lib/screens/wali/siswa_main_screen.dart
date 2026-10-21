import 'package:flutter/material.dart';
import 'package:si_kesa/screens/wali/absensi_screen.dart';
import 'package:si_kesa/screens/wali/dashboard_screen.dart';
import 'package:si_kesa/screens/wali/disiplin_screen.dart';
import 'package:si_kesa/screens/wali/nilai_screen.dart';
import 'package:si_kesa/screens/wali/profil_siswa_screen.dart';
import 'package:si_kesa/widgets/siswa_bottom_nav.dart';

/// Cangkang Wali Murid: semua halaman utama ada di sini sehingga
/// bottom nav (footer) selalu tampil. Urutan: Home, Nilai, Absen, Disiplin, Profil.
class SiswaMainScreen extends StatefulWidget {
  const SiswaMainScreen({super.key});

  @override
  State<SiswaMainScreen> createState() => _SiswaMainScreenState();
}

class _SiswaMainScreenState extends State<SiswaMainScreen> {
  int _index = 0;
  final Set<int> _dibuka = {0}; // tab dimuat saat pertama dibuka

  Widget _halaman(int i) {
    if (!_dibuka.contains(i)) return const SizedBox.shrink();
    switch (i) {
      case 0:
        return SiswaDashboardScreen(onBukaTab: _pindah);
      case 1:
        return NilaiSiswaScreen(onBack: () => _pindah(0));
      case 2:
        return AbsensiSiswaScreen(onBack: () => _pindah(0));
      case 3:
        return DisiplinSiswaScreen(onBack: () => _pindah(0));
      default:
        return ProfilSiswaScreen(onBack: () => _pindah(0));
    }
  }

  void _pindah(int i) => setState(() {
        _dibuka.add(i);
        _index = i;
      });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _index == 0,
      // Tombol kembali HP: dari tab lain ke Home dulu
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _pindah(0);
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: List.generate(5, _halaman),
        ),
        bottomNavigationBar: SiswaBottomNav(
          currentIndex: _index,
          onTap: _pindah,
        ),
      ),
    );
  }
}