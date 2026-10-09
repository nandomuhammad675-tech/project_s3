import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:si_kesa/config/theme_config.dart';
import 'package:si_kesa/widgets/app_text_field.dart';
import 'package:si_kesa/widgets/primary_button.dart';

class WaliLoginForm extends StatefulWidget {
  const WaliLoginForm({super.key});

  @override
  State<WaliLoginForm> createState() => _WaliLoginFormState();
}

class _WaliLoginFormState extends State<WaliLoginForm> {
  final _nisnC = TextEditingController();
  final _passwordC = TextEditingController();

  // Tombol aktif jika NISN tepat 10 digit dan kata sandi terisi
  bool get _canSubmit =>
      _nisnC.text.length == 10 && _passwordC.text.isNotEmpty;

  @override
  void dispose() {
    _nisnC.dispose();
    _passwordC.dispose();
    super.dispose();
  }

  void _submit() {
    // Sementara: logika login dibuat di Langkah 5e
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Login belum disambungkan')),
    );
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
        const SizedBox(height: 80),
        PrimaryButton(
          label: 'Masuk',
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