import 'package:flutter/material.dart';
import 'package:si_kesa/config/theme_config.dart';
import 'package:si_kesa/screens/auth/login_screen.dart';
import 'package:si_kesa/screens/guru/guru_main_screen.dart';
import 'package:si_kesa/screens/wali/siswa_main_screen.dart';
import 'package:si_kesa/services/api_client.dart';
import 'package:si_kesa/services/auth_service.dart';

final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> _messengerKey = GlobalKey<ScaffoldMessengerState>();
bool _sesiBerakhirDiproses = false;

/// Server membalas 401 pada request ber-token (token habis, atau siswa tidak lagi aktif):
/// hapus token lokal lalu kembali ke layar login (KONTRAK_API.md bagian 0).
Future<void> _sesiBerakhir() async {
  if (_sesiBerakhirDiproses) return; // beberapa request bisa gagal bersamaan
  _sesiBerakhirDiproses = true;
  try {
    await AuthService.keluar();
    _navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
    _messengerKey.currentState?.showSnackBar(
      const SnackBar(content: Text('Sesi berakhir. Silakan masuk lagi.')),
    );
  } finally {
    _sesiBerakhirDiproses = false;
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ApiClient.instance.tokenProvider = AuthService.tokenAktif;
  ApiClient.instance.onUnauthorized = _sesiBerakhir;
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
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: _messengerKey,
      home: const _GerbangAwal(),
    );
  }
}

/// Layar pertama: ada token Guru -> portal Guru, ada token Wali -> portal Wali, selain itu ke login.
/// Token yang sudah mati ketahuan di layar berikutnya (401 -> kembali ke Login).
class _GerbangAwal extends StatefulWidget {
  const _GerbangAwal();

  @override
  State<_GerbangAwal> createState() => _GerbangAwalState();
}

class _GerbangAwalState extends State<_GerbangAwal> {
  late final Future<PeranSesi?> _sesi = AuthService.peran();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PeranSesi?>(
      future: _sesi,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        switch (snap.data) {
          case PeranSesi.guru:
            return const GuruMainScreen();
          case PeranSesi.wali:
            return const SiswaMainScreen();
          case null:
            return const LoginScreen();
        }
      },
    );
  }
}