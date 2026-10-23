import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:si_kesa/screens/guru/absensi/absensi_screen.dart';
import 'package:si_kesa/screens/guru/dashboard_screen.dart';
import 'package:si_kesa/screens/guru/jadwal/jadwal_mengajar_screen.dart';
import 'package:si_kesa/screens/guru/profil/profil_screen.dart';
import 'package:si_kesa/widgets/guru_bottom_nav.dart';
import 'package:si_kesa/widgets/guru_shell_scope.dart';

/// Kerangka aplikasi Guru: bilah bawah (Home, Jadwal, Absen, Profil) selalu tampil.
/// Tiap tab punya Navigator sendiri, jadi halaman fitur yang dibuka dari tab itu
/// tampil di dalam tab tanpa menutupi bilah bawah.
/// Ikon tab hanya menyala saat pengguna berada di halaman utama tab itu.
class GuruMainScreen extends StatefulWidget {
  const GuruMainScreen({super.key});

  @override
  State<GuruMainScreen> createState() => _GuruMainScreenState();
}

class _GuruMainScreenState extends State<GuruMainScreen> {
  static const _jumlahTab = 4;

  int _index = 0;
  final List<GlobalKey<NavigatorState>> _kunci =
      List.generate(_jumlahTab, (_) => GlobalKey<NavigatorState>());
  final List<bool> _dibuka = [true, false, false, false]; // tab dimuat saat pertama dibuka
  final List<int> _kedalaman = List.filled(_jumlahTab, 0); // jumlah halaman di atas halaman utama tab

  late final List<_PengamatTab> _pengamat = List.generate(
    _jumlahTab,
    (i) => _PengamatTab((dalam) {
      // Ditunda ke akhir frame supaya aman dipanggil di tengah proses navigasi.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _kedalaman[i] != dalam) setState(() => _kedalaman[i] = dalam);
      });
    }),
  );

  Widget _halamanUtama(int i) => switch (i) {
        0 => const GuruDashboardScreen(),
        1 => const JadwalMengajarGuruScreen(),
        2 => const AbsensiGuruScreen(),
        _ => const ProfilGuruScreen(),
      };

  /// Tampilkan halaman utama tab [i] (dipakai ikon bilah bawah dan menu di Beranda).
  void _pindah(int i) {
    _kunci[i].currentState?.popUntil((r) => r.isFirst);
    if (i != _index) {
      setState(() {
        _dibuka[i] = true;
        _index = i;
      });
    }
  }

  /// Tombol kembali HP: tutup halaman di tab aktif; bila sudah di halaman utama tab,
  /// pindah ke Home; bila sudah di Home, keluar aplikasi.
  Future<void> _kembali() async {
    final nav = _kunci[_index].currentState;
    if (nav != null && await nav.maybePop()) return;
    if (!mounted) return;
    if (_index != 0) {
      setState(() => _index = 0);
      return;
    }
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    // Saat keyboard terbuka, bilah bawah disembunyikan supaya tidak ikut naik menutupi isian.
    final keyboardTerbuka = MediaQuery.of(context).viewInsets.bottom > 0;
    // -1 = tidak ada ikon yang menyala (sedang di dalam halaman fitur).
    final ikonAktif = _kedalaman[_index] > 0 ? -1 : _index;

    return GuruShellScope(
      onPindah: _pindah,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _kembali();
        },
        child: Scaffold(
          resizeToAvoidBottomInset: false, // keyboard ditangani Scaffold di tiap halaman
          body: IndexedStack(
            index: _index,
            children: [
              for (var i = 0; i < _jumlahTab; i++)
                if (_dibuka[i])
                  Navigator(
                    key: _kunci[i],
                    observers: [_pengamat[i]],
                    onGenerateRoute: (_) => MaterialPageRoute(
                      builder: (_) => _halamanUtama(i),
                    ),
                  )
                else
                  const SizedBox.shrink(),
            ],
          ),
          bottomNavigationBar:
              keyboardTerbuka ? null : GuruBottomNav(currentIndex: ikonAktif, onTap: _pindah),
        ),
      ),
    );
  }
}

/// Menghitung berapa halaman fitur yang terbuka di atas halaman utama sebuah tab.
/// Dialog dan lembar bawah (bukan PageRoute) tidak dihitung.
class _PengamatTab extends NavigatorObserver {
  _PengamatTab(this.saatUbah);

  final ValueChanged<int> saatUbah;
  int _dalam = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null && route is PageRoute) {
      _dalam++;
      saatUbah(_dalam);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute && _dalam > 0) {
      _dalam--;
      saatUbah(_dalam);
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute && _dalam > 0) {
      _dalam--;
      saatUbah(_dalam);
    }
  }
}