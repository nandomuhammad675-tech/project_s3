import 'package:flutter/material.dart';
import 'package:si_kesa/config/theme_config.dart';

/// Bilah bawah Guru sesuai desain: Home, Jadwal, Absen, Profil. Tab aktif berwarna emas.
class GuruBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const GuruBottomNav({super.key, required this.currentIndex, required this.onTap});

  static const _items = [
    (Icons.home_rounded, 'Home'),
    (Icons.edit_calendar, 'Jadwal'),
    (Icons.fact_check, 'Absen'),
    (Icons.person, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.headerGreen,
      child: SafeArea(
        top: false, // ruang bawah mengikuti tombol navigasi HP
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_items.length, (i) {
              final aktif = i == currentIndex;
              final warna = aktif ? AppColors.navActive : Colors.white;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_items[i].$1, color: warna, size: 28),
                      const SizedBox(height: 2),
                      Text(
                        _items[i].$2,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: aktif ? FontWeight.w600 : FontWeight.w400,
                          color: warna,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}