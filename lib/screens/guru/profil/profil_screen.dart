import 'package:flutter/material.dart';
import 'package:si_kesa/config/api_config.dart';
import 'package:si_kesa/config/theme_config.dart';
import 'package:si_kesa/models/guru_model.dart';
import 'package:si_kesa/screens/auth/login_screen.dart';
import 'package:si_kesa/screens/guru/profil/ganti_password_screen.dart';
import 'package:si_kesa/services/api_client.dart';
import 'package:si_kesa/services/auth_service.dart';
import 'package:si_kesa/services/guru_service.dart';
import 'package:si_kesa/widgets/error_state.dart';
import 'package:si_kesa/widgets/loading_indicator.dart';
import 'package:si_kesa/widgets/layar_berheader.dart';

/// Profil Akun Guru. Data dari GET /api/guru/me (hanya dibaca; perubahan data guru lewat Admin).
/// Yang bisa dilakukan Guru di sini: mengganti kata sandi dan keluar akun.
class ProfilGuruScreen extends StatefulWidget {
  final bool showBack;
  const ProfilGuruScreen({super.key, this.showBack = true});

  @override
  State<ProfilGuruScreen> createState() => _ProfilGuruScreenState();
}

class _ProfilGuruScreenState extends State<ProfilGuruScreen> {
  late Future<GuruModel> _profil = GuruService.me();
  

  void _muatUlang() => setState(() => _profil = GuruService.me());

  Future<void> _keluar() async {
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
            child: const Text('Keluar', style: TextStyle(color: Color(0xFFFF0000))),
          ),
        ],
      ),
    );
    if (yakin != true) return;

    await AuthService.keluar(); // hapus token tersimpan
    if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _gantiSandi() async {
    final berhasil = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const GantiPasswordScreen()),
    );
    if (berhasil == true && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Kata sandi berhasil diganti.')));
    }
  }

  /// NIP 18 digit ditampilkan per bagian: 19850312 201001 2 015. Selain itu apa adanya.
  String _formatNip(String nip) {
    final n = nip.replaceAll(RegExp(r'\s'), '');
    if (n.length != 18) return nip;
    return '${n.substring(0, 8)} ${n.substring(8, 14)} ${n.substring(14, 15)} ${n.substring(15)}';
  }

  String _isi(String v) => v.isEmpty ? '-' : v;

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayarBerheader(
        title: 'Profil Akun',
        showBack: widget.showBack,
        builder: (tinggiHeader) => FutureBuilder<GuruModel>(
          future: _profil,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return Padding(
                padding: EdgeInsets.only(top: tinggiHeader),
                child: const LoadingIndicator(),
              );
            }
            if (snap.hasError) {
              // Saat data gagal dimuat, tombol keluar tetap tersedia di bawah pesan galat.
              return Padding(
                padding: EdgeInsets.only(top: tinggiHeader),
                child: Column(
                  children: [
                    Expanded(
                      child: ErrorState(
                        message: pesanDariError(snap.error!),
                        onRetry: _muatUlang,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                      child: _tombolKeluar(),
                    ),
                  ],
                ),
              );
            }
            final g = snap.data!;
            return RefreshIndicator(
              color: AppColors.primary,
              edgeOffset: tinggiHeader,
              onRefresh: () async {
                _muatUlang();
                try {
                  await _profil;
                } catch (_) {
                  // Kegagalan tampil lewat ErrorState.
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(24, tinggiHeader + 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: _avatar(g.fotoProfil)),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        g.nama,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _label('Username'),
                    _kolom(_isi(g.username)),
                    const SizedBox(height: 14),
                    _label('NIP'),
                    _kolom(_isi(_formatNip(g.nip))),
                    const SizedBox(height: 14),
                    _label('Email'),
                    _kolom(_isi(g.email)),
                    const SizedBox(height: 14),
                    _label('No.Telp'),
                    _kolom(_isi(g.noTelepon)),
                    const SizedBox(height: 14),
                    _label('Kata Sandi'),
                    _kolom(
                      '**********',
                      onTap: _gantiSandi,
                      akhir: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.edit_outlined, size: 22, color: AppColors.textDark),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _tombolKeluar(),
                                        const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _tombolKeluar() {
    return SizedBox(
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _avatar(String? foto) {
    final bawaan = Container(
      width: 74,
      height: 74,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Color(0xFF3F7F2A), shape: BoxShape.circle),
      child: const Icon(Icons.person_outline, size: 48, color: Colors.white),
    );

    return Container(
      width: 96,
      height: 96,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Color(0xFFDADADA), shape: BoxShape.circle),
      child: foto == null
          ? bawaan
          : ClipOval(
              child: Image.network(
                '${ApiConfig.baseUrl}/$foto',
                width: 96,
                height: 96,
                fit: BoxFit.cover,
                // Foto belum ada di server / gagal dimuat: pakai ikon bawaan.
                errorBuilder: (_, _, _) => bawaan,
              ),
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

  Widget _kolom(String isi, {Widget? akhir, VoidCallback? onTap}) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          height: 48,
          padding: const EdgeInsets.only(left: 14, right: 4),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  isi,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppColors.textHint),
                ),
              ),
              ?akhir,
            ],
          ),
        ),
      ),
    );
  }
}