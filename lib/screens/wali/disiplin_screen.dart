import 'package:flutter/material.dart';
import 'package:si_kesa/config/theme_config.dart';
import 'package:si_kesa/models/disiplin_model.dart';
import 'package:si_kesa/services/api_client.dart';
import 'package:si_kesa/services/wali_service.dart';
import 'package:si_kesa/utils/date_formatter.dart';
import 'package:si_kesa/widgets/error_state.dart';
import 'package:si_kesa/widgets/loading_indicator.dart';
import 'package:si_kesa/widgets/app_header.dart';
import 'package:si_kesa/widgets/sub_page_header.dart';

class DisiplinSiswaScreen extends StatefulWidget {
  final bool showBack;
  final VoidCallback? onBack;
  const DisiplinSiswaScreen({super.key, this.showBack = true, this.onBack});

  @override
  State<DisiplinSiswaScreen> createState() => _DisiplinSiswaScreenState();
}

class _DisiplinSiswaScreenState extends State<DisiplinSiswaScreen> {
  late Future<_Data> _future = _muat();

  Future<_Data> _muat() async {
    final profil = await WaliService.profil();
    final hasil = await WaliService.disiplin();
    return _Data(profil.nama, hasil.items);
  }

  void _muatUlang() {
    setState(() {
      _future = _muat();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tinggi = AppHeader.tinggi(context); // tinggi header gelombang
    return Scaffold(
      body: Stack(children: [
Positioned.fill(child: FutureBuilder<_Data>(
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
                final d = snap.data!;
                // Terbaru di atas
                final data = [...d.items]..sort((a, b) => b.tanggal.compareTo(a.tanggal));

                return ListView(
                  padding: EdgeInsets.fromLTRB(20, 28 + tinggi, 20, 24),
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
                      ...data.map((x) => _item(d.nama, x)),
                  ],
                );
              },
            )),
Positioned(top: 0, left: 0, right: 0, child: SubPageHeader(title: 'Rekap Kedisiplinan', showBack: widget.showBack, onBack: widget.onBack)),
]),
    );
  }

  Widget _item(String nama, DisiplinModel d) {
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
          Text(
            nama,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            d.jenisPelanggaran,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          if (d.catatan.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              d.catatan,
              style: const TextStyle(fontSize: 13, color: AppColors.textDark),
            ),
          ],
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

class _Data {
  final String nama;
  final List<DisiplinModel> items;
  const _Data(this.nama, this.items);
}