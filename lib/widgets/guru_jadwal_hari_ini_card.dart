import 'package:flutter/material.dart';
import 'package:si_kesa/config/theme_config.dart';
import 'package:si_kesa/models/jadwal_model.dart';
import 'package:si_kesa/services/api_client.dart';
import 'package:si_kesa/services/jadwal_service.dart';
import 'package:si_kesa/utils/date_formatter.dart';
import 'package:si_kesa/widgets/empty_state.dart';
import 'package:si_kesa/widgets/error_state.dart';
import 'package:si_kesa/widgets/loading_indicator.dart';

/// Kartu "Jadwal Hari Ini" di Beranda Guru. Punya tiga keadaan: memuat, kosong, gagal (Coba Lagi).
/// Buat ulang dengan Key baru untuk menyegarkan (tarik layar ke bawah).
class GuruJadwalHariIniCard extends StatefulWidget {
  final String semester; // ganjil | genap
  final String namaKelas;
  final VoidCallback onLihatSemua;

  const GuruJadwalHariIniCard({
    super.key,
    required this.semester,
    required this.namaKelas,
    required this.onLihatSemua,
  });

  @override
  State<GuruJadwalHariIniCard> createState() => _GuruJadwalHariIniCardState();
}

class _GuruJadwalHariIniCardState extends State<GuruJadwalHariIniCard> {
  static const _batasTampil = 5;

  final DateTime _sekarang = DateTime.now();
  late Future<List<JadwalModel>> _jadwal = JadwalService.hariIni(semester: widget.semester);

  void _muatUlang() => setState(() => _jadwal = JadwalService.hariIni(semester: widget.semester));

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBeige,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.headerGreen,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.event_note, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Jadwal Hari Ini',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              InkWell(
                onTap: widget.onLihatSemua,
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 14), // sentuhan >= 48 dp
                  child: Text(
                    'Lihat Semua',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    DateFormatter.lengkap(_sekarang),
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                FutureBuilder<List<JadwalModel>>(
                  future: _jadwal,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const SizedBox(height: 120, child: LoadingIndicator());
                    }
                    if (snap.hasError) {
                      return ErrorState(message: pesanDariError(snap.error!), onRetry: _muatUlang);
                    }
                    final data = snap.data!;
                    if (data.isEmpty) {
                      return EmptyState(
                        icon: Icons.event_busy,
                        message: _sekarang.weekday == DateTime.sunday
                            ? 'Hari Minggu libur.'
                            : 'Tidak ada jadwal pelajaran hari ini.',
                      );
                    }
                    final tampil = data.take(_batasTampil).toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${data.length} Mata Pelajaran',
                          style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              for (var i = 0; i < tampil.length; i++) ...[
                                if (i > 0) const Divider(height: 1, color: AppColors.border),
                                _BarisJadwal(jadwal: tampil[i], namaKelas: widget.namaKelas),
                              ],
                            ],
                          ),
                        ),
                        if (data.length > _batasTampil)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '+${data.length - _batasTampil} pelajaran lainnya',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BarisJadwal extends StatelessWidget {
  final JadwalModel jadwal;
  final String namaKelas;

  const _BarisJadwal({required this.jadwal, required this.namaKelas});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: IntrinsicHeight(
        child: Row(
          children: [
            const Icon(Icons.access_time_filled, size: 22, color: AppColors.textDark),
            const SizedBox(width: 6),
            Text(
              jadwal.rentangJam,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const VerticalDivider(width: 20, thickness: 1, color: AppColors.border),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    jadwal.mapel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    'Kelas $namaKelas',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}