import 'package:flutter/material.dart';
import 'package:si_kesa/widgets/guru_login_form.dart';
import 'package:si_kesa/widgets/login_header.dart';
import 'package:si_kesa/widgets/role_toggle.dart';
import 'package:si_kesa/widgets/siswa_login_form.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  LoginRole _role = LoginRole.guru;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const LoginHeader(),
            Transform.translate(
              offset: const Offset(0, -28),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: RoleToggle(
                  selected: _role,
                  onChanged: (r) => setState(() => _role = r),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
             child: _role == LoginRole.guru
                  ? const GuruLoginForm()
                  : const WaliLoginForm(),
            ),
          ],
        ),
      ),
    );
  }
}