import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:si_kesa/config/theme_config.dart';
import 'package:si_kesa/screens/wali/siswa_main_screen.dart';
import 'package:si_kesa/services/api_client.dart';
import 'package:si_kesa/services/auth_service.dart';
import 'package:si_kesa/widgets/app_text_field.dart';
import 'package:si_kesa/widgets/primary_button.dart';

/// Login Wali Murid. Keputusan sekolah: tampilan memiliki kolom kata sandi, nilainya sama dengan NISN
/// (id = NISN, kata sandi = NISN). Itu hanya tampilan: server hanya menerima NISN (KONTRAK_API.md bagian 3)
/// dan tidak menyimpan password Wali. Pencocokan di bawah dilakukan di aplikasi dan BUKAN lapisan keamanan;
/// perlindungan sebenarnya tetap rate limit, token pendek, dan akses read-only satu siswa.
class WaliLoginForm extends StatefulWidget {
  const WaliLoginForm({super.key});

  @override
  State<WaliLoginForm> createState() => _WaliLoginFormState();
}

class _WaliLoginFormState extends State<WaliLoginForm> {
  final _nisnC = TextEditingController();
  final _passwordC = TextEditingController();
  bool _loading = false;
  String? _pesan;

  // Tombol aktif jika NISN tepat 10 digit, kata sandi terisi, dan tidak sedang memproses
  bool get _canSubmit =>
      _nisnC.text.length == 10 && _passwordC.text.isNotEmpty && !_loading;

  @override
  void dispose() {
    _nisnC.dispose();
    _passwordC.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Kata sandi harus sama dengan NISN; pesan sengaja sama dengan kegagalan login lain (tidak membocorkan apa pun).
    if (_passwordC.text != _nisnC.text) {
      setState(() => _pesan = 'NISN atau kata sandi salah.');
      return;
    }
    setState(() {
      _loading = true;
      _pesan = null;
    });
    try {
      await AuthService.loginWali(_nisnC.text.trim());
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SiswaMainScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _pesan = pesanDariError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Masuk ke akun Siswa',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 28),
        AppTextField(
          label: 'NISN',
          hint: 'Masukkan NISN',
          controller: _nisnC,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 10,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),
        AppTextField(
          label: 'Kata Sandi',
          hint: 'Masukkan Kata Sandi',
          controller: _passwordC,
          isPassword: true,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        if (_pesan != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              _pesan!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFFD32F2F)),
            ),
          ),
        const SizedBox(height: 44),
        PrimaryButton(
          label: 'Masuk',
          loading: _loading,
          onPressed: _canSubmit ? _submit : null,
        ),
        const SizedBox(height: 32),
        const Text(
          'Hubungi admin sekolah jika lupa akun',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
