import 'package:flutter/material.dart';
import 'package:si_kesa/config/theme_config.dart';
import 'package:si_kesa/models/disiplin_model.dart';
import 'package:si_kesa/utils/date_formatter.dart';
import 'package:si_kesa/widgets/sub_page_header.dart';

class DisiplinSiswaScreen extends StatelessWidget {
  const DisiplinSiswaScreen({super.key});

  // Data dummy sementara. Nanti diganti data dari backend.
  static const _nama = 'Aji Ariya';

  static final List<DisiplinModel> _data = [
    DisiplinModel(
      tanggal: DateTime(2026, 9, 29),
      jenisPelanggaran: 'Datang terlambat 20 menit tanpa keterangan',
    ),
    DisiplinModel(
      tanggal: DateTime(2026, 9, 22),
      jenisPelanggaran: 'Bolos sekolah hari ini dan sering tidak masuk',
    ),
    DisiplinModel(
      tanggal: DateTime(2026, 9, 15),
      jenisPelanggaran: 'Bolos sekolah hari ini dan sering tidak masuk',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Terbaru di atas
    final data = [..._data]..sort((a, b) => b.tanggal.compareTo(a.tanggal));

    return Scaffold(
      body: Column(
        children: [
          const SubPageHeader(title: 'Rekap Kedisiplinan'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
              children: [
                const Text(
                  'Rekap Kedisiplinan Siswa',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.headerGreen,
                  ),
                ),
                const SizedBox(height: 24),
                if (data.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Text(
                        'Belum ada catatan kedisiplinan.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  )
                else
                  ...data.map(_item),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(DisiplinModel d) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            _nama,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            d.jenisPelanggaran,
            style: const TextStyle(fontSize: 13, color: AppColors.textDark),
          ),
          const SizedBox(height: 6),
          Text(
            DateFormatter.lengkap(d.tanggal),
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}