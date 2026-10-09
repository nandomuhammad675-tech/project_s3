import 'package:flutter/material.dart';
import 'package:si_kesa/config/theme_config.dart';

class SiswaBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const SiswaBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    (Icons.home_rounded, 'Home'),
    (Icons.pending_actions, 'Kedisiplinan'),
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
              final active = i == currentIndex;
              final color = active ? Colors.white : Colors.white60;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_items[i].$1, color: color, size: 28),
                      const SizedBox(height: 2),
                      Text(
                        _items[i].$2,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              active ? FontWeight.w600 : FontWeight.w400,
                          color: color,
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