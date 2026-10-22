import 'package:flutter/material.dart';
import 'package:si_kesa/config/theme_config.dart';
import 'package:si_kesa/screens/guru/guru_main_screen.dart';
import 'package:si_kesa/services/api_client.dart';
import 'package:si_kesa/services/auth_service.dart';
import 'package:si_kesa/widgets/app_text_field.dart';
import 'package:si_kesa/widgets/primary_button.dart';

class GuruLoginForm extends StatefulWidget {
  const GuruLoginForm({super.key});

  @override
  State<GuruLoginForm> createState() => _GuruLoginFormState();
}

class _GuruLoginFormState extends State<GuruLoginForm> {
  final _usernameC = TextEditingController();
  final _passwordC = TextEditingController();
  bool _loading = false;
  String? _pesan;

  // Tombol aktif hanya jika username dan password terisi dan tidak sedang memproses

  @override
  void dispose() {
    _usernameC.dispose();
    _passwordC.dispose();
    super.dispose();
  }

    Future<void> _submit() async {
    if (_loading) return; // cegah ketukan ganda

    final username = _usernameC.text.trim();
    final sandi = _passwordC.text;
    if (username.isEmpty && sandi.isEmpty) {
      setState(() => _pesan = 'NIP/Username dan kata sandi Silakan isi dulu.');
      return;
    }
    if (username.isEmpty) {
      setState(() => _pesan = 'NIP/Username belum diisi. Silakan isi dulu ya.');
      return;
    }
    if (sandi.isEmpty) {
      setState(() => _pesan = 'Kata sandi belum diisi. Silakan isi dulu ya.');
      return;
    }

    setState(() {
      _loading = true;
      _pesan = null;
    });
    try {
      await AuthService.loginGuru(username, sandi);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const GuruMainScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _passwordC.clear(); // sesuai dokumen: gagal -> kosongkan password
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
          'Masuk ke akun Guru',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 28),
        AppTextField(
          label: 'NIP/Username',
          hint: 'Masukkan NIP atau Username',
          controller: _usernameC,
          enabled: !_loading,
          onChanged: (_) => setState(() => _pesan = null),
        ),
        const SizedBox(height: 20),
        AppTextField(
          label: 'Kata Sandi',
          hint: 'Masukkan Kata Sandi',
          controller: _passwordC,
          isPassword: true,
          enabled: !_loading,
          onChanged: (_) => setState(() => _pesan = null),
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
          onPressed: _submit,
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