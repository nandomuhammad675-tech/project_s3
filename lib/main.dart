import 'package:flutter/material.dart';
import 'package:si_kesa/config/theme_config.dart';
import 'package:si_kesa/screens/auth/login_screen.dart';
import 'package:si_kesa/screens/splash/splash_screen.dart';
import 'package:si_kesa/services/api_client.dart';
import 'package:si_kesa/services/auth_service.dart';
import 'package:si_kesa/widgets/notifikasi.dart';

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
    final messenger = _messengerKey.currentState;
    if (messenger != null) {
      tampilkanNotifikasiDi(
        messenger,
        'Sesi berakhir. Silakan masuk lagi.',
        jenis: JenisNotifikasi.peringatan,
      );
    }
  } finally {
    _sesiBerakhirDiproses = false;
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ApiClient.instance.tokenProvider = AuthService.token;
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
      home: const SplashScreen(),
    );
  }
}
