import 'package:flutter/material.dart';
import 'package:si_kesa/config/theme_config.dart';

/// Jenis notifikasi: menentukan warna dan ikon.
enum JenisNotifikasi { berhasil, gagal, peringatan, info }

/// Membuat SnackBar bergaya aplikasi: melayang, membulat, ada ikon dan warna sesuai jenis.
SnackBar buatNotifikasi(String pesan, {JenisNotifikasi jenis = JenisNotifikasi.info}) {
  final (Color warna, IconData ikon) = switch (jenis) {
    JenisNotifikasi.berhasil => (const Color(0xFF2E7D32), Icons.check_circle_rounded),
    JenisNotifikasi.gagal => (AppColors.accentRed, Icons.error_rounded),
    JenisNotifikasi.peringatan => (AppColors.primary, Icons.warning_amber_rounded),
    JenisNotifikasi.info => (AppColors.textDark, Icons.info_rounded),
  };
  return SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: warna,
    elevation: 6,
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    duration: Duration(seconds: jenis == JenisNotifikasi.gagal ? 4 : 3),
    content: Row(
      children: [
        Icon(ikon, color: Colors.white, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            pesan,
            style: const TextStyle(
              fontSize: 13,
              height: 1.3,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Menampilkan notifikasi memakai BuildContext (menggantikan notifikasi yang sedang tampil).
void tampilkanNotifikasi(
  BuildContext context,
  String pesan, {
  JenisNotifikasi jenis = JenisNotifikasi.info,
}) {
  tampilkanNotifikasiDi(ScaffoldMessenger.of(context), pesan, jenis: jenis);
}

/// Sama seperti di atas, tetapi memakai ScaffoldMessengerState langsung
/// (dipakai saat tidak ada BuildContext, misalnya dari main.dart).
void tampilkanNotifikasiDi(
  ScaffoldMessengerState messenger,
  String pesan, {
  JenisNotifikasi jenis = JenisNotifikasi.info,
}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(buatNotifikasi(pesan, jenis: jenis));
}
