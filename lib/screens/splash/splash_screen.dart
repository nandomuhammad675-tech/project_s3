import 'package:flutter/material.dart';
import 'package:si_kesa/config/theme_config.dart';
import 'package:si_kesa/screens/auth/login_screen.dart';
import 'package:si_kesa/screens/guru/guru_main_screen.dart';
import 'package:si_kesa/screens/wali/siswa_main_screen.dart';
import 'package:si_kesa/services/auth_service.dart';

/// Layar pertama aplikasi. Menampilkan logo sebentar sambil mengecek sesi:
/// ada token Guru -> portal Guru, ada token Wali -> portal Wali, selain itu ke login.
/// Token yang sudah mati ketahuan di layar berikutnya (401 -> kembali ke Login).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  /// Lama minimal splash tampil (ubah di sini kalau mau lebih cepat/lambat).
  static const Duration _durasiMinimal = Duration(milliseconds: 2500);

  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();

  late final Animation<double> _fade =
      CurvedAnimation(parent: _anim, curve: Curves.easeOut);
  late final Animation<double> _skala = Tween<double>(begin: 0.8, end: 1.0)
      .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutBack));

  @override
  void initState() {
    super.initState();
    _lanjut();
  }

  Future<void> _lanjut() async {
    // Cek sesi dan tunggu durasi minimal berjalan bersamaan.
    final cekSesi = AuthService.peran().then<Peran?>((p) => p, onError: (_) => null);
    await Future<void>.delayed(_durasiMinimal);
    final peran = await cekSesi;
    if (!mounted) return;

    final Widget tujuan = switch (peran) {
      Peran.guru => const GuruMainScreen(),
      Peran.wali => const SiswaMainScreen(),
      null => const LoginScreen(),
    };

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => tujuan,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.headerGreen, Color(0xFF3F4C27)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: FadeTransition(
                    opacity: _fade,
                    child: ScaleTransition(
                      scale: _skala,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/logo_sekolah.png',
                            height: 110,
                            cacheHeight: 330,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'SI-KESA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'SD Negeri Kedungsari 1',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              FadeTransition(
                opacity: _fade,
                child: const Padding(
                  padding: EdgeInsets.only(bottom: 48),
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.navActive),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
