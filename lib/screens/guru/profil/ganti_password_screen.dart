import 'package:flutter/material.dart';
import 'package:si_kesa/services/api_client.dart';
import 'package:si_kesa/services/auth_service.dart';
import 'package:si_kesa/widgets/app_text_field.dart';
import 'package:si_kesa/widgets/primary_button.dart';
import 'package:si_kesa/widgets/layar_berheader.dart';

/// Ganti kata sandi Guru (PUT /api/auth/password). Berhasil -> kembali ke Profil dengan hasil true.
/// Server menerbitkan token baru; AuthService menyimpannya, jadi sesi tetap berjalan.
class GantiPasswordScreen extends StatefulWidget {
  const GantiPasswordScreen({super.key});

  @override
  State<GantiPasswordScreen> createState() => _GantiPasswordScreenState();
}

class _GantiPasswordScreenState extends State<GantiPasswordScreen> {
  final _lama = TextEditingController();
  final _baru = TextEditingController();
  final _ulang = TextEditingController();

  bool _loading = false;
  String? _pesan; // pesan galat di atas tombol

  @override
  void dispose() {
    _lama.dispose();
    _baru.dispose();
    _ulang.dispose();
    super.dispose();
  }

  String? _validasi() {
    if (_lama.text.isEmpty) return 'Password lama wajib diisi.';
    if (_baru.text.length < 8) return 'Password baru minimal 8 karakter.';
    if (_baru.text.length > 72) return 'Password baru maksimal 72 karakter.';
    if (_baru.text == _lama.text) return 'Password baru tidak boleh sama dengan password lama.';
    if (_baru.text != _ulang.text) return 'Konfirmasi password baru tidak sama.';
    return null;
  }

  Future<void> _simpan() async {
    final salah = _validasi();
    if (salah != null) {
      setState(() => _pesan = salah);
      return;
    }
    setState(() {
      _loading = true;
      _pesan = null;
    });
    try {
      await AuthService.gantiPasswordGuru(_lama.text, _baru.text);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      // 422 membawa pesan per-kolom (mis. "Password lama salah."); selain itu pesan umum.
      final err = e is ApiException ? (e.errors.values.firstOrNull ?? e.message) : pesanDariError(e);
      setState(() {
        _loading = false;
        _pesan = err;
      });
    }
  }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayarBerheader(
        title: 'Ganti Kata Sandi',
        builder: (tinggiHeader) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, tinggiHeader + 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                label: 'Password Lama',
                hint: 'Masukkan password lama',
                controller: _lama,
                isPassword: true,
                enabled: !_loading,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Password Baru',
                hint: 'Minimal 8 karakter',
                controller: _baru,
                isPassword: true,
                enabled: !_loading,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Ulangi Password Baru',
                hint: 'Ketik ulang password baru',
                controller: _ulang,
                isPassword: true,
                enabled: !_loading,
              ),
              if (_pesan != null) ...[
                const SizedBox(height: 14),
                Text(
                  _pesan!,
                  style: const TextStyle(fontSize: 13, color: Color(0xFFE53935)),
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(label: 'Simpan', loading: _loading, onPressed: _simpan),
            ],
          ),
        ),
      ),
    );
  }
}