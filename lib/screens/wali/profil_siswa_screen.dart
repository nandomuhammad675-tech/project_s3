import 'package:flutter/material.dart';
import 'package:si_kesa/config/theme_config.dart';
import 'package:si_kesa/models/siswa_model.dart';
import 'package:si_kesa/screens/auth/login_screen.dart';
import 'package:si_kesa/services/api_client.dart';
import 'package:si_kesa/services/auth_service.dart';
import 'package:si_kesa/services/wali_service.dart';
import 'package:si_kesa/widgets/error_state.dart';
import 'package:si_kesa/widgets/loading_indicator.dart';
import 'package:si_kesa/widgets/sub_page_header.dart';

class ProfilSiswaScreen extends StatefulWidget {
  final bool showBack;
  const ProfilSiswaScreen({super.key, this.showBack = true});

  @override
  State<ProfilSiswaScreen> createState() => _ProfilSiswaScreenState();
}

class _ProfilSiswaScreenState extends State<ProfilSiswaScreen> {
  late Future<SiswaModel> _profil = WaliService.profil();
  bool _tampilSandi = false;

  void _muatUlang() {
    setState(() {
      _profil = WaliService.profil(refresh: true);
    });
  }

  Future<void> _keluar() async {
    // Konfirmasi dulu (sesuai dokumen)
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar akun?'),
        content: const Text('Anda harus masuk lagi untuk membuka aplikasi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Keluar',
              style: TextStyle(color: Color(0xFFFF0000)),
            ),
          ),
        ],
      ),
    );

    if (yakin != true) return;
    await AuthService.keluar(); // hapus token tersimpan
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SubPageHeader(title: 'Profil Akun', showBack: widget.showBack),
          Expanded(
            child: FutureBuilder<SiswaModel>(
              future: _profil,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const LoadingIndicator();
                }
                if (snap.hasError) {
                  return ErrorState(message: pesanDariError(snap.error!), onRetry: _muatUlang);
                }
                final s = snap.data!;
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: _avatar()),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          s.nama,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textHint,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      _label('NISN'),
                      _kolom(s.nisn),
                      const SizedBox(height: 14),
                      _label('Kelas'),
                      _kolom(s.namaKelas),
                      const SizedBox(height: 14),
                      _label('Kata Sandi'),
                      // Kata sandi tampilan = NISN (keputusan sekolah; bukan password tersimpan di server)
                      _kolom(
                        _tampilSandi ? s.nisn : '*' * s.nisn.length,
                        akhir: IconButton(
                          icon: Icon(
                            _tampilSandi
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textDark,
                          ),
                          onPressed: () =>
                              setState(() => _tampilSandi = !_tampilSandi),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Tombol Keluar Akun menempel di bawah (tetap tersedia walau data gagal dimuat)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _keluar,
                  icon: const Icon(Icons.logout, size: 20),
                  label: const Text(
                    'Keluar Akun',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF0000),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar() {
    return Container(
      width: 96,
      height: 96,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFFDADADA),
        shape: BoxShape.circle,
      ),
      child: Container(
        width: 74,
        height: 74,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Color(0xFF3F7F2A),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.person_outline, size: 48, color: Colors.white),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _kolom(String isi, {Widget? akhir}) {
    return Container(
      height: 46,
      padding: const EdgeInsets.only(left: 14, right: 4),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              isi,
              style: const TextStyle(fontSize: 13, color: AppColors.textHint),
            ),
          ),
          ?akhir,
        ],
      ),
    );
  }
}
