import 'package:flutter/material.dart';
import 'package:si_kesa/config/theme_config.dart';
import 'package:si_kesa/screens/wali/dashboard_screen.dart';
import 'package:si_kesa/widgets/siswa_bottom_nav.dart';
import 'package:si_kesa/screens/wali/absensi_screen.dart';
import 'package:si_kesa/screens/wali/disiplin_screen.dart';
import 'package:si_kesa/screens/wali/profil_siswa_screen.dart';

class SiswaMainScreen extends StatefulWidget {
  const SiswaMainScreen({super.key});

  @override
  State<SiswaMainScreen> createState() => _SiswaMainScreenState();
}

class _SiswaMainScreenState extends State<SiswaMainScreen> {
  int _index = 0;

  // Tab selain Home masih placeholder, diganti saat layarnya dibuat
  late final List<Widget> _pages = [
    const SiswaDashboardScreen(),
    const _Placeholder('Kedisiplinan'),
    const SizedBox.shrink(),
    const _Placeholder('Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
            bottomNavigationBar: SiswaBottomNav(
        currentIndex: _index,
                        onTap: (i) {
          if (i == 1) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DisiplinSiswaScreen()),
            );
            return;
          }
          if (i == 2) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AbsensiSiswaScreen()),
            );
            return;
          }
          if (i == 3) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfilSiswaScreen()),
            );
            return;
          }
          setState(() => _index = i);
        },
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final String title;
  const _Placeholder(this.title);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Halaman $title',
        style: const TextStyle(fontSize: 18, color: AppColors.textDark),
      ),
    );
  }
}