import 'package:flutter/material.dart';
import 'package:si_kesa/config/theme_config.dart';
import 'package:si_kesa/models/nilai_model.dart';
import 'package:si_kesa/services/api_client.dart';
import 'package:si_kesa/services/wali_service.dart';
import 'package:si_kesa/widgets/error_state.dart';
import 'package:si_kesa/widgets/loading_indicator.dart';
import 'package:si_kesa/widgets/semester_toggle.dart';
import 'package:si_kesa/widgets/app_header.dart';
import 'package:si_kesa/widgets/sub_page_header.dart';

class NilaiSiswaScreen extends StatefulWidget {
  final bool showBack;
  final VoidCallback? onBack;
  const NilaiSiswaScreen({super.key, this.showBack = true, this.onBack});

  @override
  State<NilaiSiswaScreen> createState() => _NilaiSiswaScreenState();
}

class _NilaiSiswaScreenState extends State<NilaiSiswaScreen> {
  int _tab = 0; // 0 = UH, 1 = ASTS, 2 = ASAS

  static const _tabLabel = ['UH', 'ASTS', 'ASAS'];
  static const double _lebarKolom = 58;

  late Future<NilaiResult> _future = WaliService.nilai();
  String? _semester; // null = ikut semester_aktif dari server
  List<NilaiMapel> _data = const []; // nilai pada semester yang dipilih

  void _muatUlang() {
    setState(() {
      _future = WaliService.nilai();
    });
  }

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
        return ['ASTS'];
      default:
        return ['ASAS'];
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
        return [m.asts];
      default:
        return [m.asas];
    }
  }

  @override
  Widget build(BuildContext context) {
    final tinggi = AppHeader.tinggi(context); // tinggi header gelombang
    return Scaffold(
      body: Stack(children: [
Positioned.fill(child: FutureBuilder<NilaiResult>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return Padding(padding: EdgeInsets.only(top: tinggi), child: const LoadingIndicator());
                }
                if (snap.hasError) {
                  return Padding(
                    padding: EdgeInsets.only(top: tinggi),
                    child: ErrorState(message: pesanDariError(snap.error!), onRetry: _muatUlang),
                  );
                }
                final hasil = snap.data!;
                _semester ??= hasil.semesterAktif;
                _data = hasil.items.where((m) => m.semester == _semester).toList();

                return ListView(
                  padding: EdgeInsets.fromLTRB(16, 24 + tinggi, 16, 24),
                  children: [
                    _pilihSemester(hasil.tahunAjaran, hasil.semesterAktif),
                    const SizedBox(height: 18),
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
                );
              },
            )),
Positioned(top: 0, left: 0, right: 0, child: SubPageHeader(title: 'Rekap Nilai', showBack: widget.showBack, onBack: widget.onBack)),
]),
    );
  }

  Widget _pilihSemester(String tahunAjaran, String semesterAktif) {
    return SemesterToggle(
      tahunAjaran: tahunAjaran,
      semester: _semester ?? semesterAktif,
      semesterAktif: semesterAktif,
      onChanged: (v) => setState(() => _semester = v),
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