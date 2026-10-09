import 'package:flutter/material.dart';
import 'package:si_kesa/widgets/app_header.dart';

class SiswaHeader extends StatelessWidget {
  const SiswaHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppHeader(
      left: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Portal Siswa',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'Selamat Datang SI-KESA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'Semoga Harimu Menyenangkan!',
            style: TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }
}