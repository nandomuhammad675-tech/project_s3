import 'package:flutter/material.dart';
import 'package:si_kesa/config/theme_config.dart';
import 'package:si_kesa/models/guru_disiplin_model.dart';
import 'package:si_kesa/services/api_client.dart';
import 'package:si_kesa/services/disiplin_service.dart';
import 'package:si_kesa/utils/date_formatter.dart';
import 'package:si_kesa/widgets/error_state.dart';
import 'package:si_kesa/widgets/loading_indicator.dart';
import 'package:si_kesa/widgets/layar_berheader.dart';

/// Kedisiplinan Guru: ringkasan angka dan form catat pelanggaran.
/// [catatan] terisi = mode ubah (dibuka dari Rekap); kembali dengan hasil true bila tersimpan.
/// Tidak ada tombol hapus (server tidak menyediakannya).
class DisiplinGuruScreen extends StatefulWidget {
  final CatatanDisiplinModel? catatan;
  const DisiplinGuruScreen({super.key, this.catatan});

  @override
  State<DisiplinGuruScreen> createState() => _DisiplinGuruScreenState();
}

class _DisiplinGuruScreenState extends State<DisiplinGuruScreen> {
  static const Color _merah = Color(0xFFB03A2E);

  List<SiswaKelasModel> _siswa = const [];
  List<CatatanDisiplinModel> _catatan = const [];
  bool _memuat = true;
  String? _galatMuat;

  final _jenis = TextEditingController();
  final _isi = TextEditingController();

  int? _idSiswa;
  DateTime _tanggal = DateTime.now();
  bool _menyimpan = false;
  String? _pesan;

  bool get _mengubah => widget.catatan != null;

  @override
  void initState() {
    super.initState();
    final c = widget.catatan;
    if (c != null) {
      // Mode ubah: isi form dari catatan, tidak perlu memuat daftar siswa.
      _idSiswa = c.idSiswa;
      _tanggal = c.tanggal;
      _jenis.text = c.jenisPelanggaran;
      _isi.text = c.catatan;
      _memuat = false;
    } else {
      _muat();
    }
  }

  @override
  void dispose() {
    _jenis.dispose();
    _isi.dispose();
    super.dispose();
  }

  // ===================== Data =====================

  /// [senyap] true = muat ulang tanpa mengganti layar dengan indikator/galat (setelah simpan).
  Future<void> _muat({bool senyap = false}) async {
    try {
      final hasil = await Future.wait<dynamic>([
        DisiplinService.siswa(),
        DisiplinService.daftar(),
      ]);
      if (!mounted) return;
      setState(() {
        _siswa = hasil[0] as List<SiswaKelasModel>;
        _catatan = hasil[1] as List<CatatanDisiplinModel>;
        _memuat = false;
        _galatMuat = null;
      });
    } catch (e) {
      if (!mounted || senyap) return;
      setState(() {
        _galatMuat = pesanDariError(e);
        _memuat = false;
      });
    }
  }

  void _cobaLagi() {
    setState(() {
      _memuat = true;
      _galatMuat = null;
    });
    _muat();
  }

  /// Siswa aktif yang punya minimal satu catatan.
  int get _adaCatatan {
    final ids = _catatan.map((c) => c.idSiswa).toSet();
    return _siswa.where((s) => ids.contains(s.idSiswa)).length;
  }

  int get _disiplin => _siswa.length - _adaCatatan;

  // ===================== Form =====================

  void _kosongkanForm() {
    setState(() {
      _idSiswa = null;
      _tanggal = DateTime.now();
      _jenis.clear();
      _isi.clear();
      _pesan = null;
      _menyimpan = false;
    });
  }

  Future<void> _pilihTanggal() async {
    final sekarang = DateTime.now();
    final dipilih = await showDatePicker(
      context: context,
      initialDate: _tanggal.isAfter(sekarang) ? sekarang : _tanggal,
      firstDate: DateTime(2020),
      lastDate: sekarang,
    );
    if (dipilih != null) setState(() => _tanggal = dipilih);
  }

  String? _validasi() {
    if (_idSiswa == null) return 'Pilih siswa terlebih dahulu.';
    if (_jenis.text.trim().isEmpty) return 'Jenis pelanggaran wajib diisi.';
    if (_isi.text.trim().isEmpty) return 'Catatan wajib diisi.';
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

    final jenis = _jenis.text.trim();
    final isi = _isi.text.trim();

    try {
      if (_mengubah) {
        await DisiplinService.ubah(widget.catatan!.idCatatan,
            tanggal: _tanggal, jenis: jenis, catatan: isi);
        if (!mounted) return;
        Navigator.of(context).pop(true); // Rekap yang menampilkan pesan sukses
        return;
      }

      await DisiplinService.tambah(idSiswa: _idSiswa!, tanggal: _tanggal, jenis: jenis, catatan: isi);
      if (!mounted) return;
      _kosongkanForm();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Catatan kedisiplinan tersimpan.')));
      await _muat(senyap: true); // segarkan angka di atas
    } catch (e) {
      if (!mounted) return;
      String pesan;
      if (e is ApiException) {
        // Tanpa kode status = jaringan putus/timeout: isian tetap di layar.
        pesan = e.statusCode == null
            ? 'Belum tersimpan. Periksa koneksi lalu coba lagi.'
            : (e.errors.values.firstOrNull ?? e.message);
      } else {
        pesan = pesanDariError(e);
      }
      setState(() {
        _menyimpan = false;
        _pesan = pesan;
      });
    }
  }

  // ===================== Tampilan =====================

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayarBerheader(title: 'Kedisiplinan', builder: _isiLayar),
    );
  }

  Widget _isiLayar(double tinggiHeader) {
    if (_memuat) {
      return Padding(
        padding: EdgeInsets.only(top: tinggiHeader),
        child: const LoadingIndicator(),
      );
    }
    if (_galatMuat != null) {
      return Padding(
        padding: EdgeInsets.only(top: tinggiHeader),
        child: ErrorState(message: _galatMuat!, onRetry: _cobaLagi),
      );
    }

    final daftar = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20, tinggiHeader + 20, 20, 32),
      children: [
        if (!_mengubah) ...[
          _statistik(),
          const SizedBox(height: 28),
        ],
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            _mengubah ? 'Ubah Catatan' : 'Catat Pelanggaran',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.headerGreen,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 2, bottom: 12),
          child: Text(
            _mengubah
                ? 'Perbaiki catatan kedisiplinan murid'
                : 'Tambahkan catatan kedisiplinan murid',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ),
        _kartuForm(),
      ],
    );

    if (_mengubah) return daftar; // mode ubah: tidak ada data yang perlu disegarkan

    return RefreshIndicator(
      color: AppColors.primary,
      edgeOffset: tinggiHeader,
      onRefresh: () => _muat(senyap: true),
      child: daftar,
    );
  }

  Widget _statistik() {
    return Row(
      children: [
        Expanded(child: _angka('$_disiplin', 'Siswa Disiplin', AppColors.headerGreen)),
        Container(width: 1, height: 56, color: AppColors.border),
        Expanded(child: _angka('$_adaCatatan', 'Ada Catatan', _merah)),
      ],
    );
  }

  Widget _angka(String nilai, String label, Color warna) {
    return Column(
      children: [
        Text(nilai, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: warna)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textDark)),
      ],
    );
  }

  Widget _kartuForm() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Nama Siswa'),
          _pilihSiswa(),
          const SizedBox(height: 16),
          _label('Tanggal'),
          InkWell(
            onTap: _menyimpan ? null : _pilihTanggal,
            child: Container(
              height: 48,
              alignment: Alignment.centerLeft,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormatter.lengkap(_tanggal),
                      style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                    ),
                  ),
                  const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textDark),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _label('Jenis Pelanggaran'),
          TextField(
            controller: _jenis,
            enabled: !_menyimpan,
            maxLength: 100,
            style: const TextStyle(fontSize: 14, color: AppColors.textDark),
            decoration: _garis('Contoh: Terlambat, tidak memakai seragam'),
          ),
          const SizedBox(height: 16),
          _label('Catatan Kedisiplinan'),
          TextField(
            controller: _isi,
            enabled: !_menyimpan,
            maxLength: 2000,
            minLines: 1,
            maxLines: 4,
            keyboardType: TextInputType.multiline,
            style: const TextStyle(fontSize: 14, color: AppColors.textDark),
            decoration: _garis('Tulis keterangan  pelanggaran siswa'),
          ),
          if (_pesan != null) ...[
            const SizedBox(height: 12),
            Text(_pesan!, style: const TextStyle(fontSize: 13, color: AppColors.accentRed)),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _menyimpan ? null : () => Navigator.of(context).maybePop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textDark,
                      backgroundColor: AppColors.white,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _menyimpan ? null : _simpan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primary,
                      disabledForegroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: _menyimpan
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : Text(
                            _mengubah ? 'Perbarui' : 'Simpan',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Mode tambah: dropdown siswa aktif. Mode ubah: nama dikunci (server melarang ganti siswa).
  Widget _pilihSiswa() {
    if (_mengubah) {
      return Container(
        height: 48,
        alignment: Alignment.centerLeft,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Text(
          widget.catatan!.namaSiswa,
          style: const TextStyle(fontSize: 14, color: AppColors.textHint),
        ),
      );
    }
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          value: _idSiswa,
          hint: const Text('Pilih Siswa', style: TextStyle(fontSize: 14, color: AppColors.textHint)),
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textDark),
          style: const TextStyle(fontSize: 14, color: AppColors.textDark),
          items: _siswa
              .map((s) => DropdownMenuItem<int>(
                    value: s.idSiswa,
                    child: Text(s.label, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: _menyimpan ? null : (v) => setState(() => _idSiswa = v),
        ),
      ),
    );
  }

  Widget _label(String teks) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(teks, style: const TextStyle(fontSize: 12, color: AppColors.textDark)),
    );
  }

  InputDecoration _garis(String hint) {
    const garis = UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border));
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, color: AppColors.textHint),
      counterText: '',
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      border: garis,
      enabledBorder: garis,
      disabledBorder: garis,
      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
    );
  }
}