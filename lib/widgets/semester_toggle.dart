import 'package:flutter/material.dart';
import 'package:si_kesa/config/theme_config.dart';

/// Pemilih semester Ganjil/Genap (dipakai Rekap Nilai dan Riwayat Absen).
/// [semesterAktif] diberi penanda "Berjalan".
class SemesterToggle extends StatelessWidget {
  final String tahunAjaran;
  final String semester; // 'ganjil' | 'genap'
  final String? semesterAktif;
  final ValueChanged<String> onChanged;

  const SemesterToggle({
    super.key,
    required this.tahunAjaran,
    required this.semester,
    required this.onChanged,
    this.semesterAktif,
  });

  static const _pilihan = [('ganjil', 'Ganjil'), ('genap', 'Genap')];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school_outlined,
                  size: 18, color: AppColors.textHint),
              const SizedBox(width: 8),
              Text(
                'Tahun Ajaran $tahunAjaran',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.toggleBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: _pilihan.map((p) {
                final aktif = semester == p.$1;
                final berjalan = semesterAktif == p.$1;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onChanged(p.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: aktif ? AppColors.headerGreen : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Semester ${p.$2}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  aktif ? FontWeight.w600 : FontWeight.w500,
                              color: aktif ? Colors.white : AppColors.textTab,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            berjalan ? 'Berjalan' : ' ',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: aktif
                                  ? Colors.white70
                                  : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
