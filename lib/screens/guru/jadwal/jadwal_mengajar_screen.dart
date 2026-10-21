import 'package:flutter/material.dart';
import 'package:si_kesa/config/theme_config.dart';
import 'package:si_kesa/models/guru_model.dart';
import 'package:si_kesa/models/jadwal_model.dart';
import 'package:si_kesa/models/kelas_model.dart';
import 'package:si_kesa/models/mapel_model.dart';
import 'package:si_kesa/services/api_client.dart';
import 'package:si_kesa/services/guru_service.dart';
import 'package:si_kesa/services/jadwal_service.dart';
import 'package:si_kesa/services/nilai_service.dart';
import 'package:si_kesa/utils/date_formatter.dart';
import 'package:si_kesa/widgets/empty_state.dart';
import 'package:si_kesa/widgets/error_state.dart';
import 'package:si_kesa/widgets/layar_berheader.dart';
import 'package:si_kesa/widgets/loading_indicator.dart';
import 'package:si_kesa/widgets/status_jadwal_chip.dart';

/// Jadwal Mengajar Guru: form tambah/ubah jadwal + jadwal satu minggu (Senin sampai Sabtu).
/// Jadwal milik kelas sendiri dan semester berjalan. Ketuk satu jadwal untuk mengubah atau menghapusnya.
class JadwalMengajarGuruScreen extends StatefulWidget {
  const JadwalMengajarGuruScreen({super.key});

  @override
  State<JadwalMengajarGuruScreen> createState() => _JadwalMengajarGuruScreenState();
}

class _JadwalMengajarGuruScreenState extends State<JadwalMengajarGuruScreen> {
  static const _hariList = [
    ('senin', 'Senin'),
    ('selasa', 'Selasa'),
    ('rabu', 'Rabu'),
    ('kamis', 'Kamis'),
    ('jumat', 'Jumat'),
    ('sabtu', 'Sabtu'),
  ];

  final _gulir = ScrollController();
  final _ket = TextEditingController();
  final DateTime _sekarang = DateTime.now();

  KelasModel? _kelas;
  List<MapelModel> _mapel = const [];
  List<JadwalModel> _jadwal = const [];
  bool _memuat = true;
  String? _galat;

  String? _hari;
  TimeOfDay? _mulai;
  TimeOfDay? _selesai;
  int? _idMapel;
  JadwalModel? _ubah; // terisi = mode ubah
  bool _menyimpan = false;
  String? _pesan;

  String get _semester => _kelas?.semester == 'genap' ? 'genap' : 'ganjil';

  @override
  void initState() {
    super.initState();
    _muat();
  }

  @override
  void dispose() {
    _gulir.dispose();
    _ket.dispose();
    super.dispose();
  }

  // ===================== Data =====================

  Future<void> _muat({bool tarik = false}) async {
    if (!tarik) {
      setState(() {
        _memuat = true;
        _galat = null;
      });
    }
    try {
      final h = await Future.wait<dynamic>([GuruService.me(), NilaiService.mapel()]);
      final kelas = (h[0] as GuruModel).kelas;
      var jadwal = const <JadwalModel>[];
      if (kelas != null) {
        jadwal = await JadwalService.daftar(semester: kelas.semester == 'genap' ? 'genap' : 'ganjil');
      }
      if (!mounted) return;
      setState(() {
        _kelas = kelas;
        _mapel = h[1] as List<MapelModel>;
        _jadwal = jadwal;
        _memuat = false;
        _galat = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _galat = pesanDariError(e);
        _memuat = false;
      });
    }
  }

  Future<void> _segarkanJadwal() async {
    try {
      final j = await JadwalService.daftar(semester: _semester);
      if (!mounted) return;
      setState(() => _jadwal = j);
    } catch (_) {
      // Daftar lama tetap tampil; tarik layar untuk mencoba lagi.
    }
  }

  // ===================== Form =====================

  static String _teksJam(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static TimeOfDay _urai(String jam) {
    final p = jam.split(':');
    return TimeOfDay(hour: int.tryParse(p[0]) ?? 0, minute: p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0);
  }

  Future<TimeOfDay?> _pilihJam(TimeOfDay? awal) {
    return showTimePicker(
      context: context,
      initialTime: awal ?? const TimeOfDay(hour: 7, minute: 0),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
  }

  void _kosongkanForm() {
    setState(() {
      _ubah = null;
      _hari = null;
      _mulai = null;
      _selesai = null;
      _idMapel = null;
      _ket.clear();
      _pesan = null;
    });
  }

  void _mulaiUbah(JadwalModel j) {
    if (_menyimpan) return;
    setState(() {
      _ubah = j;
      _hari = j.hari;
      _mulai = _urai(j.jamMulai);
      _selesai = _urai(j.jamSelesai);
      _idMapel = _mapel.any((m) => m.id == j.idMapel) ? j.idMapel : null;
      _ket.text = j.keterangan ?? '';
      _pesan = null;
    });
    if (_gulir.hasClients) {
      _gulir.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  void _info(String pesan) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(pesan)));
  }

  String? _validasi() {
    if (_hari == null) return 'Pilih hari terlebih dahulu.';
    if (_mulai == null) return 'Jam mulai wajib diisi.';
    if (_selesai == null) return 'Jam selesai wajib diisi.';
    if (_idMapel == null) return 'Pilih mata pelajaran terlebih dahulu.';
    final m = _mulai!.hour * 60 + _mulai!.minute;
    final s = _selesai!.hour * 60 + _selesai!.minute;
    if (s <= m) return 'Jam selesai harus setelah jam mulai';
    if (_ket.text.trim().length > 100) return 'Keterangan maksimal 100 karakter.';
    return null;
  }

  Future<void> _simpan() async {
    if (_menyimpan) return; // cegah ketukan ganda
    final salah = _validasi();
    if (salah != null) {
      setState(() => _pesan = salah);
      return;
    }
    setState(() {
      _menyimpan = true;
      _pesan = null;
    });
    final ket = _ket.text.trim();
    try {
      final target = _ubah;
      if (target == null) {
        await JadwalService.tambah(
          semester: _semester,
          idMapel: _idMapel!,
          hari: _hari!,
          jamMulai: _teksJam(_mulai!),
          jamSelesai: _teksJam(_selesai!),
          keterangan: ket,
        );
      } else {
        await JadwalService.ubah(
          target.id,
          semester: _semester,
          idMapel: _idMapel!,
          hari: _hari!,
          jamMulai: _teksJam(_mulai!),
          jamSelesai: _teksJam(_selesai!),
          keterangan: ket,
        );
      }
      if (!mounted) return;
      final ubah = _ubah != null;
      _kosongkanForm();
      setState(() => _menyimpan = false);
      await _segarkanJadwal();
      if (!mounted) return;
      _info(ubah ? 'Jadwal diperbarui' : 'Jadwal tersimpan');
    } catch (e) {
      if (!mounted) return;
      // 409 (jam bentrok) dan 422 tampil apa adanya; isian tetap di layar.
      setState(() {
        _menyimpan = false;
        _pesan = pesanDariError(e);
      });
    }
  }

  Future<void> _hapus() async {
    final target = _ubah;
    if (target == null || _menyimpan) return;
    final ya = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus jadwal?'),
        content: Text('${target.mapel} (${target.rentangJam}) akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ya != true) return;
    setState(() => _menyimpan = true);
    try {
      await JadwalService.hapus(target.id);
      if (!mounted) return;
      _kosongkanForm();
      setState(() => _menyimpan = false);
      await _segarkanJadwal();
      if (!mounted) return;
      _info('Jadwal dihapus');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _menyimpan = false;
        _pesan = pesanDariError(e);
      });
    }
  }

  // ===================== Tampilan =====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayarBerheader(title: 'Jadwal Mengajar', builder: _isiLayar),
    );
  }

  Widget _isiLayar(double tinggiHeader) {
    Widget isi;
    if (_memuat) {
      isi = const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: LoadingIndicator());
    } else if (_galat != null) {
      isi = ErrorState(message: _galat!, onRetry: _muat);
    } else if (_kelas == null) {
      isi = const EmptyState(
        message: 'Anda belum ditetapkan sebagai wali kelas pada tahun ajaran aktif. Hubungi Admin.',
        icon: Icons.info_outline,
      );
    } else {
      isi = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _kartuForm(),
          const SizedBox(height: 14),
          _kartuMingguan(),
        ],
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      edgeOffset: tinggiHeader,
      onRefresh: () => _muat(tarik: true),
      child: ListView(
        controller: _gulir,
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(16, tinggiHeader + 16, 16, 24),
        children: [isi],
      ),
    );
  }

  BoxDecoration get _gayaKartu => BoxDecoration(
        color: AppColors.cardBeige,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
      );

  Widget _ikonJudul(IconData ikon) => Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(color: AppColors.headerGreen, borderRadius: BorderRadius.circular(6)),
        child: Icon(ikon, color: Colors.white, size: 18),
      );

  Widget _kartuForm() {
    final mengubah = _ubah != null;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _gayaKartu,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _ikonJudul(mengubah ? Icons.edit_calendar : Icons.add_box_outlined),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mengubah ? 'Ubah Jadwal Mengajar' : 'Tambah Jadwal Mengajar',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
                    ),
                    Text(
                      mengubah
                          ? 'Ubah data lalu ketuk Perbarui'
                          : 'Isi data di bawah ini untuk menambahkan jadwal mengajar',
                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _isian(
                  Icons.calendar_today_outlined,
                  'Hari',
                  _dropdown<String>(
                    nilai: _hari,
                    petunjuk: 'Pilih Hari',
                    pilihan: _hariList,
                    saatUbah: _menyimpan ? null : (v) => setState(() => _hari = v),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _isian(
                  Icons.access_time,
                  'Jam Mulai',
                  _kolomJam(_mulai, (t) => setState(() => _mulai = t)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _isian(
                  Icons.menu_book_outlined,
                  'Mata Pelajaran',
                  _dropdown<int>(
                    nilai: _idMapel,
                    petunjuk: 'Pilih Mata Pelajaran',
                    pilihan: [for (final m in _mapel) (m.id, m.nama)],
                    saatUbah: _menyimpan ? null : (v) => setState(() => _idMapel = v),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _isian(
                  Icons.access_time_filled,
                  'Jam Selesai',
                  _kolomJam(_selesai, (t) => setState(() => _selesai = t)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _isian(Icons.school_outlined, 'Kelas', _kelasTerkunci())),
              const SizedBox(width: 10),
              Expanded(child: _isian(Icons.notes, 'Keterangan', _kolomKeterangan())),
            ],
          ),
          if (_pesan != null) ...[
            const SizedBox(height: 10),
            Text(_pesan!, style: const TextStyle(fontSize: 12, color: AppColors.accentRed)),
          ],
          const SizedBox(height: 12),
          _tombolForm(mengubah),
        ],
      ),
    );
  }

  Widget _isian(IconData ikon, String label, Widget isi) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(ikon, size: 16, color: AppColors.textDark),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        isi,
      ],
    );
  }

  BoxDecoration get _gayaKolom => BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      );

  Widget _dropdown<T>({
    required T? nilai,
    required List<(T, String)> pilihan,
    required ValueChanged<T?>? saatUbah,
    required String petunjuk,
  }) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: _gayaKolom,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: nilai,
          isExpanded: true,
          hint: Text(petunjuk,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textDark),
          style: const TextStyle(fontSize: 12, color: AppColors.textDark, fontFamily: 'Poppins'),
          items: [
            for (final p in pilihan)
              DropdownMenuItem<T>(value: p.$1, child: Text(p.$2, maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
          onChanged: saatUbah,
        ),
      ),
    );
  }

  Widget _kolomJam(TimeOfDay? nilai, ValueChanged<TimeOfDay> saatPilih) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: _menyimpan
          ? null
          : () async {
              final t = await _pilihJam(nilai);
              if (t != null) saatPilih(t);
            },
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.centerLeft,
        decoration: _gayaKolom,
        child: Row(
          children: [
            Expanded(
              child: Text(
                nilai == null ? 'Pilih Jam' : _teksJam(nilai),
                style: TextStyle(fontSize: nilai == null ? 11 : 12, color: nilai == null ? AppColors.textHint : AppColors.textDark),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: AppColors.textDark),
          ],
        ),
      ),
    );
  }

  Widget _kelasTerkunci() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9DA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Kelas ${_kelas?.nama ?? ''}',
              style: const TextStyle(fontSize: 12, color: AppColors.textDark),
            ),
          ),
          const Icon(Icons.lock_outline, size: 16, color: AppColors.textMuted),
        ],
      ),
    );
  }

  Widget _kolomKeterangan() {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: _ket,
        enabled: !_menyimpan,
        maxLength: 100,
        style: const TextStyle(fontSize: 12, color: AppColors.textDark),
        decoration: InputDecoration(
          counterText: '',
          hintText: 'Opsional',
          hintStyle: const TextStyle(fontSize: 11, color: AppColors.textHint),
          filled: true,
          fillColor: AppColors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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

  Widget _tombolForm(bool mengubah) {
    final simpan = SizedBox(
      height: 46,
      child: ElevatedButton(
        onPressed: _menyimpan ? null : _simpan,
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
            : Text(
                mengubah ? 'Perbarui' : 'Simpan Jadwal',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
      ),
    );
    if (!mengubah) return simpan;

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 46,
            child: OutlinedButton(
              onPressed: _menyimpan ? null : _hapus,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accentRed,
                side: const BorderSide(color: AppColors.accentRed),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Hapus', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 46,
            child: OutlinedButton(
              onPressed: _menyimpan ? null : _kosongkanForm,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textDark,
                backgroundColor: AppColors.white,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Batal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(flex: 2, child: simpan),
      ],
    );
  }

  // ----- Jadwal Mingguan -----

  /// Senin pada minggu berjalan (hari Minggu menampilkan minggu depan).
  DateTime get _seninMinggu {
    final h = DateTime(_sekarang.year, _sekarang.month, _sekarang.day);
    final selisih = _sekarang.weekday == DateTime.sunday ? 1 : -(_sekarang.weekday - 1);
    return DateTime(h.year, h.month, h.day + selisih);
  }

  Widget _kartuMingguan() {
    final senin = _seninMinggu;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _gayaKartu,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _ikonJudul(Icons.calendar_month),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Jadwal Mingguan',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
              ),
              const Text('Minggu Ini', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            ],
          ),
          const SizedBox(height: 10),
          if (_jadwal.isEmpty)
            const EmptyState(
              message: 'Jadwal belum diisi. Isi form di atas untuk menambah.',
              icon: Icons.event_note_outlined,
            )
          else
            for (var i = 0; i < 6; i++) _kartuHari(DateTime(senin.year, senin.month, senin.day + i)),
        ],
      ),
    );
  }

  Widget _kartuHari(DateTime tanggal) {
    final kunci = DateFormatter.hariApi(tanggal);
    final daftar = _jadwal.where((j) => j.hari == kunci).toList()
      ..sort((a, b) => a.jamMulai.compareTo(b.jamMulai));
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Text(
              DateFormatter.lengkap(tanggal),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          if (daftar.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Belum ada jadwal.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            )
          else
            for (var i = 0; i < daftar.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: AppColors.border),
              _barisJadwal(daftar[i], tanggal),
            ],
        ],
      ),
    );
  }

  Widget _barisJadwal(JadwalModel j, DateTime tanggal) {
    return InkWell(
      onTap: () => _mulaiUbah(j),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: IntrinsicHeight(
          child: Row(
            children: [
              const Icon(Icons.access_time_filled, size: 20, color: AppColors.textDark),
              const SizedBox(width: 6),
              Text(
                j.rentangJam,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textDark),
              ),
              const VerticalDivider(width: 18, thickness: 1, color: AppColors.border),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      j.mapel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark),
                    ),
                    Text(
                      'Kelas ${_kelas?.nama ?? ''}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textDark),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              StatusJadwalChip(status: j.statusPada(tanggal, _sekarang)),
            ],
          ),
        ),
      ),
    );
  }
}