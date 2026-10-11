import 'package:flutter/material.dart';
import 'package:si_kesa/config/theme_config.dart';

/// Potongan gelombang di bagian bawah header.
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()..lineTo(0, size.height - 24);
    path.quadraticBezierTo(
      size.width * 0.25, size.height,
      size.width * 0.5, size.height - 14,
    );
    path.quadraticBezierTo(
      size.width * 0.78, size.height - 32,
      size.width, size.height - 10,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Header induk: SEMUA ukuran header diatur di sini saja.
class AppHeader extends StatelessWidget {
  /// Isi bagian kiri (judul, tombol kembali, dll).
  final Widget left;

  const AppHeader({super.key, required this.left});

  // ===== Atur ukuran header di sini (berlaku untuk semua layar) =====
  static const double _tinggiHijau = 104;
  static const double _tebalGaris = 8;
  static const double _tinggiLogo = 60;
  static const String _logo = 'assets/images/logo_sekolah.png';
  // ===================================================================

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        // Lapisan emas di belakang (garis gelombang tipis)
        ClipPath(
          clipper: WaveClipper(),
          child: Container(
            height: _tinggiHijau + _tebalGaris + top,
            color: const Color(0xFFB5A55A),
          ),
        ),
        // Lapisan hijau olive di depan
        ClipPath(
          clipper: WaveClipper(),
          child: Container(
            height: _tinggiHijau + top,
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(16, top + 6, 16, 0),
            color: AppColors.headerGreen,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: left),
                Padding(
                  padding: const EdgeInsets.only(top: 8), // naikkan angka = logo makin turun
                  child: Image.asset(
                    _logo,
                    height: _tinggiLogo,
                    cacheHeight: (_tinggiLogo * 3).toInt(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}