import 'package:flutter/material.dart';
import 'package:si_kesa/config/theme_config.dart';
import 'package:si_kesa/models/nilai_model.dart';
import 'package:si_kesa/widgets/sub_page_header.dart';

class NilaiSiswaScreen extends StatefulWidget {
  const NilaiSiswaScreen({super.key});

  @override
  State<NilaiSiswaScreen> createState() => _NilaiSiswaScreenState();
}

class _NilaiSiswaScreenState extends State<NilaiSiswaScreen> {
  int _tab = 0; // 0 = UH, 1 = UTS, 2 = UAS

  static const _tabLabel = ['UH', 'UTS', 'UAS'];
  static const double _lebarKolom = 58;

  // Data dummy sementara. Nanti diganti data dari backend.
  static const List<NilaiMapel> _data = [
    NilaiMapel(mapel: 'Matematika', uh: [90, 90, 90], uts: 88, uas: 90),
    NilaiMapel(mapel: 'Bahasa Indonesia', uh: [80, 80, 80], uts: 82, uas: 85),
    NilaiMapel(mapel: 'IPA', uh: [88, 88, 88], uts: 85, uas: 87),
    NilaiMapel(mapel: 'IPS', uh: [77, 77, 77], uts: 75, uas: 80),
    NilaiMapel(mapel: 'Bahasa Inggris', uh: [60, 60, 60], uts: 65, uas: 70),
    NilaiMapel(mapel: 'PJOK', uh: [60, 60, 60], uts: 78, uas: 80),
    NilaiMapel(mapel: 'Seni Budaya', uh: [95, 95, 95], uts: 90, uas: 92),
  ];

  // Jumlah kolom UH mengikuti data terpanjang
  int get _jumlahUh => _data.fold<int>(
        0,
        (maks, m) => m.uh.length > maks ? m.uh.length : maks,
      );

  List<String> get _judulKolom {
    switch (_tab) {
      case 0:
        return List.generate(_jumlahUh, (i) => 'UH-${i + 1}');
      case 1:
        return ['UTS'];
      default:
        return ['UAS'];
    }
  }

  List<int?> _nilaiBaris(NilaiMapel m) {
    switch (_tab) {
      case 0:
        return List.generate(
          _jumlahUh,
          (i) => i < m.uh.length ? m.uh[i] : null,
        );
      case 1:
        return [m.uts];
      default:
        return [m.uas];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SubPageHeader(title: 'Rekap Nilai'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              children: [
                _tabBar(),
                const SizedBox(height: 22),
                if (_data.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Text(
                        'Belum ada nilai.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  )
                else
                  _tabel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBar() {
    return Row(
      children: List.generate(_tabLabel.length, (i) {
        final aktif = _tab == i;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == _tabLabel.length - 1 ? 0 : 10),
            child: GestureDetector(
              onTap: () => setState(() => _tab = i),
              child: Container(
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: aktif ? AppColors.headerGreen : AppColors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: aktif ? AppColors.headerGreen : AppColors.primary,
                  ),
                ),
                child: Text(
                  _tabLabel[i],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: aktif ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _tabel() {
    final judul = _judulKolom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Column(
          children: [
            // Baris judul kolom
            Container(
              color: const Color(0xFFF3EFE3),
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Text(
                        'Mata Pelajaran',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ),
                  ...judul.map(
                    (j) => SizedBox(
                      width: _lebarKolom,
                      child: Text(
                        j,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Baris mata pelajaran
            ..._data.map((m) {
              final nilai = _nilaiBaris(m);
              return IntrinsicHeight(
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFEEF0F4)),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 16, 8, 16),
                          child: Text(
                            m.mapel,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                      ),
                      ...nilai.map(
                        (n) => Container(
                          width: _lebarKolom,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            border: Border(
                              left: BorderSide(color: Color(0xFFEEF0F4)),
                            ),
                          ),
                          child: Text(
                            n?.toString() ?? '-',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: n == null
                                  ? AppColors.textMuted
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}