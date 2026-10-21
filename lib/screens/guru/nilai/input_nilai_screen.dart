import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:si_kesa/config/theme_config.dart';
import 'package:si_kesa/models/guru_disiplin_model.dart';
import 'package:si_kesa/models/kelas_model.dart';
import 'package:si_kesa/models/mapel_model.dart';
import 'package:si_kesa/models/nilai_guru_model.dart';
import 'package:si_kesa/services/api_client.dart';
import 'package:si_kesa/services/disiplin_service.dart';
import 'package:si_kesa/services/guru_service.dart';
import 'package:si_kesa/services/nilai_service.dart';
import 'package:si_kesa/widgets/empty_state.dart';
import 'package:si_kesa/widgets/error_state.dart';
import 'package:si_kesa/widgets/layar_berheader.dart';
import 'package:si_kesa/widgets/loading_indicator.dart';

/// Input Nilai Guru: pilih semester, kategori (UH/ASTS/ASAS), mata pelajaran, lalu isi nilai tiap siswa.
/// Nilai yang sudah ada tampil dan diperbaiki lewat PUT; yang belum ada disimpan lewat POST.
/// Hapus hanya untuk UH (ASTS/ASAS tidak bisa dihapus).
class InputNilaiGuruScreen extends StatefulWidget {
  const InputNilaiGuruScreen({super.key});

  @override
  State<InputNilaiGuruScreen> createState() => _InputNilaiGuruScreenState();
}

class _InputNilaiGuruScreenState extends State<InputNilaiGuruScreen> {
  static const _jenisList = [('UH', 'UH'), ('ASTS', 'ASTS'), ('ASAS', 'ASAS')];

  KelasModel? _kelas;
  List<MapelModel> _mapel = const [];
  List<SiswaKelasModel> _siswa = const [];
  List<NilaiGuruBaris> _ada = const [];

  final Map<int, TextEditingController> _isi = {};
  final _nomor = TextEditingController();

  String _semester = 'ganjil';
  String _jenis = 'UH';
  int? _idMapel;

  bool _memuat = true;
  String? _galat;
  bool _memuatNilai = false;
  String? _galatNilai;
  bool _menyimpan = false;
  Map<int, String> _salah = {};
  String? _pesanNomor;
  int _versi = 0; // menolak jawaban lama bila pilihan diganti cepat

  @override
  void initState() {
    super.initState();
    _muatAwal();
  }

  @override
  void dispose() {
    _nomor.dispose();
    for (final c in _isi.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ===================== Data =====================

  Future<void> _muatAwal() async {
    setState(() {
      _memuat = true;
      _galat = null;
    });
    try {
      final h = await Future.wait<dynamic>([
        GuruService.me(),
        NilaiService.mapel(),
        DisiplinService.siswa(),
      ]);
      if (!mounted) return;
      final kelas = (h[0] as dynamic).kelas as KelasModel?;
      final mapel = h[1] as List<MapelModel>;
      final siswa = h[2] as List<SiswaKelasModel>;
      setState(() {
        _kelas = kelas;
        _mapel = mapel;
        _siswa = siswa;
        if (kelas != null && (kelas.semester == 'ganjil' || kelas.semester == 'genap')) {
          _semester = kelas.semester;
        }
        _idMapel = mapel.isEmpty ? null : mapel.first.id;
        for (final s in siswa) {
          _isi.putIfAbsent(s.idSiswa, () => TextEditingController());
        }
        _memuat = false;
      });
      _muatNilai();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _galat = pesanDariError(e);
        _memuat = false;
      });
    }
  }

  /// [senyap] true = hanya menyegarkan data tersimpan (setelah simpan/hapus),
  /// tanpa indikator dan tanpa menimpa isian di layar.
  Future<void> _muatNilai({bool senyap = false}) async {
    final idMapel = _idMapel;
    if (idMapel == null) return;
    final versi = ++_versi;
    if (!senyap) {
      setState(() {
        _memuatNilai = true;
        _galatNilai = null;
      });
    }
    try {
      final h = await NilaiService.daftar(idMapel: idMapel, semester: _semester);
      if (!mounted || versi != _versi) return;
      setState(() {
        _ada = h;
        _memuatNilai = false;
        if (!senyap) {
          _nomor.text = '${_nomorBerikut()}';
          _isiUlang();
        }
      });
    } catch (e) {
      if (!mounted || versi != _versi) return;
      if (senyap) return;
      setState(() {
        _galatNilai = pesanDariError(e);
        _memuatNilai = false;
      });
    }
  }

  /// Nomor UH berikutnya (terbesar yang ada + 1).
  int _nomorBerikut() {
    var maks = 0;
    for (final b in _ada) {
      if (b.jenis == 'UH' && (b.nomorUh ?? 0) > maks) maks = b.nomorUh!;
    }
    return maks + 1;
  }

  /// Nilai tersimpan untuk siswa pada pilihan sekarang (jenis, dan nomor bila UH).
  NilaiGuruBaris? _cari(int idSiswa) {
    final n = int.tryParse(_nomor.text.trim());
    for (final b in _ada) {
      if (b.idSiswa != idSiswa || b.jenis != _jenis) continue;
      if (_jenis == 'UH' && b.nomorUh != n) continue;
      return b;
    }
    return null;
  }

  /// Isi kolom nilai dari data tersimpan (kosong bila belum ada).
  void _isiUlang() {
    for (final s in _siswa) {
      _isi[s.idSiswa]?.text = _cari(s.idSiswa)?.nilai.toString() ?? '';
    }
    _salah = {};
    _pesanNomor = null;
  }

  // ===================== Aksi =====================

  void _info(String pesan) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(pesan)));
  }

  Future<void> _simpan() async {
    if (_menyimpan) return; // cegah ketukan ganda
    final idMapel = _idMapel;
    if (idMapel == null) {
      _info('Pilih mata pelajaran terlebih dahulu.');
      return;
    }

    int? nomor;
    if (_jenis == 'UH') {
      nomor = int.tryParse(_nomor.text.trim());
      if (nomor == null || nomor < 1) {
        setState(() => _pesanNomor = 'Nomor UH wajib diisi');
        return;
      }
    }

    final salah = <int, String>{};
    final tugas = <(SiswaKelasModel, int, NilaiGuruBaris?)>[];
    for (final s in _siswa) {
      final teks = _isi[s.idSiswa]!.text.trim();
      if (teks.isEmpty) continue;
      final n = int.tryParse(teks);
      if (n == null || n < 0 || n > 100) {
        salah[s.idSiswa] = 'Nilai harus antara 0 dan 100';
        continue;
      }
      final lama = _cari(s.idSiswa);
      if (lama != null && lama.nilai == n) continue; // tidak berubah
      tugas.add((s, n, lama));
    }

    setState(() {
      _pesanNomor = null;
      _salah = salah;
    });
    if (salah.isNotEmpty) {
      _info('Periksa nilai yang bertanda merah.');
      return;
    }
    if (tugas.isEmpty) {
      _info('Belum ada nilai yang diisi atau diubah.');
      return;
    }

    setState(() => _menyimpan = true);
    var gagal = 0;
    String? pesanGagal;
    for (final t in tugas) {
      try {
        if (t.$3 == null) {
          await NilaiService.tambah(
            idSiswa: t.$1.idSiswa,
            idMapel: idMapel,
            semester: _semester,
            jenis: _jenis,
            nomorUh: nomor,
            nilai: t.$2,
          );
        } else {
          await NilaiService.ubah(t.$3!.idNilai, t.$2);
        }
      } catch (e) {
        gagal++;
        pesanGagal ??= pesanDariError(e);
        salah[t.$1.idSiswa] = 'Belum tersimpan';
        // Jaringan putus: berhenti, isian tetap di layar.
        if (e is ApiException && e.statusCode == null) break;
      }
    }
    if (!mounted) return;
    setState(() {
      _menyimpan = false;
      _salah = salah;
    });
    await _muatNilai(senyap: true);
    if (!mounted) return;
    setState(() {});
    _info(gagal == 0 ? 'Nilai tersimpan' : 'Belum tersimpan ($gagal siswa). $pesanGagal');
  }

  Future<void> _hapus(SiswaKelasModel s, NilaiGuruBaris b) async {
    final ya = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus nilai UH?'),
        content: Text('Nilai UH-${b.nomorUh} milik ${s.nama} akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ya != true) return;
    try {
      await NilaiService.hapus(b.idNilai);
      if (!mounted) return;
      _isi[s.idSiswa]?.clear();
      await _muatNilai(senyap: true);
      if (!mounted) return;
      setState(() {});
      _info('Nilai UH dihapus');
    } catch (e) {
      if (!mounted) return;
      _info(pesanDariError(e));
    }
  }

  // ===================== Tampilan =====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayarBerheader(title: 'Input Nilai', builder: _isiLayar),
    );
  }

  Widget _isiLayar(double tinggiHeader) {
    Widget isi;
    if (_memuat) {
      isi = const LoadingIndicator();
    } else if (_galat != null) {
      isi = ErrorState(message: _galat!, onRetry: _muatAwal);
    } else if (_kelas == null) {
      isi = const EmptyState(
        message: 'Anda belum ditetapkan sebagai wali kelas pada tahun ajaran aktif. Hubungi Admin.',
        icon: Icons.info_outline,
      );
    } else {
      isi = _form();
    }

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(12, tinggiHeader + 16, 12, 24),
      children: [isi],
    );
  }

  Widget _form() {
    final ta = _kelas?.tahunAjaran ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _kartu(
                'Pilih Semester',
                _dropdown<String>(
                  nilai: _semester,
                  pilihan: [('ganjil', 'Ganjil $ta'.trim()), ('genap', 'Genap $ta'.trim())],
                  saatUbah: _menyimpan
                      ? null
                      : (v) {
                          if (v == null || v == _semester) return;
                          setState(() => _semester = v);
                          _muatNilai();
                        },
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _kartu(
                'Pilih Kategori Penilaian',
                _dropdown<String>(
                  nilai: _jenis,
                  pilihan: _jenisList,
                  saatUbah: _menyimpan
                      ? null
                      : (v) {
                          if (v == null || v == _jenis) return;
                          setState(() {
                            _jenis = v;
                            if (v == 'UH' && _nomor.text.trim().isEmpty) {
                              _nomor.text = '${_nomorBerikut()}';
                            }
                            _isiUlang();
                          });
                        },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _kartu(
                'Pilih Mata Pelajaran',
                _dropdown<int>(
                  nilai: _idMapel,
                  petunjuk: 'Pilih',
                  pilihan: [for (final m in _mapel) (m.id, m.nama)],
                  saatUbah: _menyimpan
                      ? null
                      : (v) {
                          if (v == null || v == _idMapel) return;
                          setState(() => _idMapel = v);
                          _muatNilai();
                        },
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _jenis == 'UH' ? _kartu('Nomor UH', _kolomNomor()) : const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _daftarSiswa(),
        const SizedBox(height: 22),
        _tombol(),
      ],
    );
  }

  Widget _kartu(String label, Widget isi) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),
          const SizedBox(height: 6),
          isi,
        ],
      ),
    );
  }

  Widget _dropdown<T>({
    required T? nilai,
    required List<(T, String)> pilihan,
    required ValueChanged<T?>? saatUbah,
    String? petunjuk,
  }) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: nilai,
          isExpanded: true,
          hint: petunjuk == null
              ? null
              : Text(petunjuk, style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textDark),
          style: const TextStyle(fontSize: 12, color: AppColors.textDark, fontFamily: 'Poppins'),
          items: [
            for (final p in pilihan)
              DropdownMenuItem<T>(
                value: p.$1,
                child: Text(p.$2, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: saatUbah,
        ),
      ),
    );
  }

  Widget _kolomNomor() {
    return SizedBox(
      height: _pesanNomor == null ? 40 : 62,
      child: TextField(
        controller: _nomor,
        enabled: !_menyimpan,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        maxLength: 3,
        style: const TextStyle(fontSize: 12, color: AppColors.textDark),
        onChanged: (_) => setState(_isiUlang),
        decoration: InputDecoration(
          isDense: true,
          counterText: '',
          hintText: 'Contoh: 1',
          errorText: _pesanNomor,
          errorStyle: const TextStyle(fontSize: 10),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border),
          ),
        ),
      ),
    );
  }

  Widget _daftarSiswa() {
    if (_idMapel == null) {
      return const EmptyState(message: 'Belum ada mata pelajaran.');
    }
    if (_memuatNilai) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: LoadingIndicator());
    }
    if (_galatNilai != null) {
      return ErrorState(message: _galatNilai!, onRetry: _muatNilai);
    }
    if (_siswa.isEmpty) {
      return const EmptyState(message: 'Belum ada siswa aktif di kelas ini.');
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: AppColors.cardBeige,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: const Row(
              children: [
                SizedBox(width: 34, child: Text('No.', style: _gayaKepala)),
                Expanded(child: Text('Nama Siswa', style: _gayaKepala)),
                SizedBox(
                  width: 96,
                  child: Text('Nilai', textAlign: TextAlign.center, style: _gayaKepala),
                ),
              ],
            ),
          ),
          for (var i = 0; i < _siswa.length; i++) _baris(_siswa[i], i, i == _siswa.length - 1),
        ],
      ),
    );
  }

  static const _gayaKepala =
      TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark);

  Widget _baris(SiswaKelasModel s, int i, bool terakhir) {
    final salah = _salah[s.idSiswa];
    final ada = _cari(s.idSiswa);
    final bisaHapus = _jenis == 'UH' && ada != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        border: terakhir ? null : const Border(bottom: BorderSide(color: Color(0xFFEFEBDD))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 34,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                '${s.nomorAbsen ?? i + 1}.',
                style: const TextStyle(fontSize: 13, color: AppColors.textDark),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, right: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.nama,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  if (salah != null)
                    Text(salah, style: const TextStyle(fontSize: 11, color: AppColors.accentRed)),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 56,
            child: TextField(
              controller: _isi[s.idSiswa],
              enabled: !_menyimpan,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 3,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
              onChanged: (_) {
                if (_salah.containsKey(s.idSiswa)) setState(() => _salah.remove(s.idSiswa));
              },
              decoration: InputDecoration(
                isDense: true,
                counterText: '',
                hintText: '-',
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: salah != null ? AppColors.accentRed : AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: salah != null ? AppColors.accentRed : AppColors.border),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 40,
            height: 40,
            child: bisaHapus
                ? IconButton(
                    padding: EdgeInsets.zero,
                    tooltip: 'Hapus nilai UH',
                    icon: const Icon(Icons.delete_outline, color: AppColors.accentRed, size: 22),
                    onPressed: _menyimpan ? null : () => _hapus(s, ada),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _tombol() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 110,
          height: 44,
          child: OutlinedButton(
            onPressed: _menyimpan ? null : () => Navigator.of(context).maybePop(),
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.textDark,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Batal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 110,
          height: 44,
          child: ElevatedButton(
            onPressed: (_menyimpan || _memuatNilai || _idMapel == null) ? null : _simpan,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
              disabledForegroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _menyimpan
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text('Simpan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}