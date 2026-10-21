import 'package:flutter/material.dart';
import 'package:si_kesa/config/theme_config.dart';
import 'package:si_kesa/models/absensi_guru_model.dart';
import 'package:si_kesa/models/absensi_model.dart';
import 'package:si_kesa/services/absensi_service.dart';
import 'package:si_kesa/services/api_client.dart';
import 'package:si_kesa/utils/date_formatter.dart';
import 'package:si_kesa/widgets/empty_state.dart';
import 'package:si_kesa/widgets/error_state.dart';
import 'package:si_kesa/widgets/layar_berheader.dart';
import 'package:si_kesa/widgets/loading_indicator.dart';

/// Absensi Harian Guru (Dokumen 02 bagian 2.5).
/// Alur: pilih tanggal -> Tandai Semua Hadir -> ubah yang tidak hadir -> Simpan.
/// Satu permintaan untuk seluruh siswa; tombol Simpan mati saat proses (cegah ketukan ganda).
/// Hari Minggu dan hari libur: Simpan mati. Hari Sabtu boleh diisi.
class AbsensiGuruScreen extends StatefulWidget {
  const AbsensiGuruScreen({super.key});

  @override
  State<AbsensiGuruScreen> createState() => _AbsensiGuruScreenState();
}

class _AbsensiGuruScreenState extends State<AbsensiGuruScreen> {
  static const _hijauHadir = Color(0xFF00D632);
  static const _emasIzin = Color(0xFFB5A55A);

  List<AbsensiBaris> _siswa = const [];
  final Map<int, StatusKehadiran> _status = {}; // id_siswa -> pilihan (tidak ada = belum diisi)
  DateTime _tanggal = _tanpaJam(DateTime.now());

  bool _memuat = true; // memuat daftar siswa (pertama kali)
  String? _galat;
  bool _memuatTanggal = false; // memuat isian untuk tanggal terpilih
  String? _galatTanggal;

  bool _libur = false;
  // Keadaan di server (untuk menentukan mana yang baru (POST) dan mana yang dikoreksi (PUT)).
  final Map<int, int> _idAbsensi = {}; // id_siswa -> id_absensi (hanya yang sudah tercatat)
  final Map<int, StatusKehadiran> _statusServer = {}; // id_siswa -> status tersimpan
  bool _menyimpan = false;
  bool _perluCekUlang = false; // simpan gagal/bentrok: cocokkan lagi dengan server sebelum simpan ulang
  int _versi = 0; // menolak jawaban lama bila tanggal diganti cepat

  final _cariCtrl = TextEditingController();
  String _cari = '';

  static DateTime _tanpaJam(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Tanggal ini sudah pernah diabsen (ada catatan di server) -> tombol "Perbarui".
  bool get _sudahAda => _idAbsensi.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _muat(awal: true);
  }

  @override
  void dispose() {
    _cariCtrl.dispose();
    super.dispose();
  }

  // ===================== Data =====================

  void _terapkanServer(AbsensiHari h) {
    _idAbsensi.clear();
    _statusServer.clear();
    for (final x in h.items) {
      if (x.idAbsensi != null && x.status != null) {
        _idAbsensi[x.idSiswa] = x.idAbsensi!;
        _statusServer[x.idSiswa] = x.status!;
      }
    }
  }

  /// Memuat siswa + isian untuk tanggal terpilih (satu panggilan GET /api/guru/absensi).
  /// [awal] true = pertama kali (layar penuh memuat); selain itu hanya area daftar.
  Future<void> _muat({bool awal = false}) async {
    final versi = ++_versi;
    final tgl = _tanggal;
    setState(() {
      if (awal) {
        _memuat = true;
        _galat = null;
      } else {
        _memuatTanggal = true;
        _galatTanggal = null;
      }
    });
    try {
      final h = await AbsensiService.lihat(tgl);
      if (!mounted || versi != _versi) return;
      setState(() {
        _siswa = h.items;
        _libur = h.libur;
        _terapkanServer(h);
        _status
          ..clear()
          ..addAll(_statusServer);
        _perluCekUlang = false;
        _memuat = false;
        _memuatTanggal = false;
      });
    } catch (e) {
      if (!mounted || versi != _versi) return;
      setState(() {
        if (awal) {
          _galat = pesanDariError(e);
        } else {
          _galatTanggal = pesanDariError(e);
        }
        _memuat = false;
        _memuatTanggal = false;
      });
    }
  }

  Future<void> _pilihTanggal() async {
    if (_menyimpan) return;
    final dipilih = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (dipilih == null || !mounted) return;
    setState(() => _tanggal = _tanpaJam(dipilih));
    _muat();
  }

  void _semuaHadir() {
    setState(() {
      for (final s in _siswa) {
        _status[s.idSiswa] = StatusKehadiran.hadir;
      }
    });
  }

  Future<bool?> _konfirmasi(int belum, bool masaDepan) {
    final baris = <String>[
      if (belum > 0) '$belum siswa belum diisi dan tidak akan disimpan.',
      if (masaDepan) 'Tanggal ini ada di masa depan.',
    ];
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Simpan absensi?'),
        content: Text(baris.join('\n')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan')),
        ],
      ),
    );
  }

  /// Siswa baru dikirim sekali jalan (POST, transaksi); siswa yang sudah tercatat dan berubah
  /// dikoreksi satu per satu (PUT). Yang sudah berhasil dicatat, tidak dikirim ulang saat mencoba lagi.
  Future<void> _simpan() async {
    if (_menyimpan || _libur) return;

    final isi = <int, StatusKehadiran>{
      for (final s in _siswa)
        if (_status[s.idSiswa] != null) s.idSiswa: _status[s.idSiswa]!,
    };
    if (isi.isEmpty) {
      _pesan('Pilih status kehadiran siswa dulu.');
      return;
    }
    final belum = _siswa.length - isi.length;
    final masaDepan = _tanggal.isAfter(_tanpaJam(DateTime.now()));
    if (belum > 0 || masaDepan) {
      final lanjut = await _konfirmasi(belum, masaDepan);
      if (lanjut != true || !mounted) return;
    }

    setState(() => _menyimpan = true);
    try {
      if (_perluCekUlang) {
        // Simpan sebelumnya gagal/bentrok: cocokkan dulu dengan isi di server (pilihan di layar tetap).
        final h = await AbsensiService.lihat(_tanggal);
        _terapkanServer(h);
      }

      final baru = <int, StatusKehadiran>{
        for (final e in isi.entries)
          if (!_idAbsensi.containsKey(e.key)) e.key: e.value,
      };
      final koreksi = <int>[
        for (final e in isi.entries)
          if (_idAbsensi.containsKey(e.key) && _statusServer[e.key] != e.value) e.key,
      ];
      if (baru.isEmpty && koreksi.isEmpty) {
        if (!mounted) return;
        setState(() => _menyimpan = false);
        _pesan('Tidak ada perubahan untuk disimpan.');
        return;
      }

      if (baru.isNotEmpty) {
        await AbsensiService.simpanBaru(_tanggal, baru);
        // Ambil id_absensi yang baru dibuat server supaya koreksi berikutnya bisa dilakukan.
        _terapkanServer(await AbsensiService.lihat(_tanggal));
      }
      for (final id in koreksi) {
        await AbsensiService.ubah(_idAbsensi[id]!, isi[id]!);
        _statusServer[id] = isi[id]!;
      }

      if (!mounted) return;
      setState(() {
        _menyimpan = false;
        _perluCekUlang = false;
      });
      _pesan('Absensi tersimpan');
    } on ApiException catch (e) {
      if (!mounted) return;
      final jaringan = e.statusCode == null || e.statusCode! >= 500;
      setState(() {
        _menyimpan = false;
        // Jaringan putus atau 409 (sudah ada): cocokkan lagi dengan server di percobaan berikutnya.
        if (jaringan || e.statusCode == 409) _perluCekUlang = true;
      });
      // Isian tetap di layar. 409/422: pesan server apa adanya.
      _pesan(jaringan ? 'Belum tersimpan. Periksa koneksi lalu coba lagi.' : e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _menyimpan = false;
        _perluCekUlang = true;
      });
      _pesan('Belum tersimpan. Periksa koneksi lalu coba lagi.');
    }
  }

  void _pesan(String teks) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(teks)));
  }

  int _hitung(StatusKehadiran st) =>
      _siswa.where((s) => _status[s.idSiswa] == st).length;

  int get _belumDiisi => _siswa.where((s) => _status[s.idSiswa] == null).length;

  // ===================== Tampilan =====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayarBerheader(title: 'Absensi Harian', builder: _isiLayar),
      bottomNavigationBar: _bilahBawah(),
    );
  }

  Widget _isiLayar(double tinggiHeader) {
    if (_memuat) {
      return Padding(padding: EdgeInsets.only(top: tinggiHeader), child: const LoadingIndicator());
    }
    if (_galat != null) {
      return Padding(
        padding: EdgeInsets.only(top: tinggiHeader),
        child: ErrorState(message: _galat!, onRetry: () => _muat(awal: true)),
      );
    }
    if (_siswa.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: tinggiHeader),
        child: const EmptyState(message: 'Belum ada siswa aktif di kelas ini.'),
      );
    }

    final kata = _cari.trim().toLowerCase();
    final tampil = kata.isEmpty
        ? _siswa
        : _siswa.where((s) => s.nama.toLowerCase().contains(kata)).toList();

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(16, tinggiHeader + 16, 16, 20),
      children: [
        _kartuTanggal(),
        const SizedBox(height: 18),
        const Text(
          'Ringkasan Kehadiran',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
        const SizedBox(height: 10),
        _ringkasan(),
        const SizedBox(height: 16),
        _kolomCari(),
        const SizedBox(height: 14),
        if (_memuatTanggal)
          const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: LoadingIndicator())
        else if (_galatTanggal != null)
          ErrorState(message: _galatTanggal!, onRetry: _muat)
        else if (_libur)
          _bannerLibur()
        else ...[
          Align(alignment: Alignment.centerRight, child: _tombolSemuaHadir()),
          const SizedBox(height: 12),
          if (tampil.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('Siswa tidak ditemukan.', style: TextStyle(color: AppColors.textMuted)),
              ),
            )
          else
            for (final s in tampil) _kartuSiswa(s),
        ],
      ],
    );
  }

  Widget _kartuTanggal() {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: _menyimpan ? null : _pilihTanggal,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
            boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.headerGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.calendar_month, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tanggal Absensi',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  Text(
                    DateFormatter.lengkap(_tanggal),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.keyboard_arrow_down, color: AppColors.textDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ringkasan() {
    Widget kotak(String label, int jumlah, Color warna) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: warna, width: 1.6),
            ),
            child: Column(
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textDark)),
                Text(
                  '$jumlah',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        );

    return Row(
      children: [
        kotak('Hadir', _hitung(StatusKehadiran.hadir), _hijauHadir),
        const SizedBox(width: 10),
        kotak('Izin', _hitung(StatusKehadiran.izin), AppColors.accentOrange),
        const SizedBox(width: 10),
        kotak('Sakit', _hitung(StatusKehadiran.sakit), AppColors.accentBlue),
        const SizedBox(width: 10),
        kotak('Alfa', _hitung(StatusKehadiran.alpa), AppColors.accentRed),
      ],
    );
  }

  Widget _kolomCari() {
    return TextField(
      controller: _cariCtrl,
      onChanged: (v) => setState(() => _cari = v),
      style: const TextStyle(fontSize: 13, color: AppColors.textDark),
      decoration: InputDecoration(
        hintText: 'Cari nama siswa...',
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textHint),
        prefixIcon: const Icon(Icons.search, color: AppColors.textDark),
        suffixIcon: _cari.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  _cariCtrl.clear();
                  setState(() => _cari = '');
                },
              ),
        filled: true,
        fillColor: AppColors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: AppColors.headerGreen),
        ),
      ),
    );
  }

  Widget _tombolSemuaHadir() {
    return ElevatedButton(
      onPressed: _menyimpan ? null : _semuaHadir,
      style: ElevatedButton.styleFrom(
        backgroundColor: _hijauHadir,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(0, 38),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: const Text(
        'Tandai Semua Hadir',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _bannerLibur() {
    final minggu = _tanggal.weekday == DateTime.sunday;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBeige,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accentOrange),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.accentOrange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              minggu
                  ? 'Hari Minggu libur, absensi tidak dapat diisi.'
                  : 'Hari libur, absensi tidak dapat diisi.',
              style: const TextStyle(fontSize: 13, color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kartuSiswa(AbsensiBaris s) {
    final nomor = s.nomorAbsen ?? (_siswa.indexOf(s) + 1);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: AppColors.headerGreen, shape: BoxShape.circle),
                child: Text(
                  '$nomor',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.nama,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _tombolStatus(s, StatusKehadiran.hadir, 'Hadir', _hijauHadir, _hijauHadir),
              _tombolStatus(s, StatusKehadiran.izin, 'Izin', _emasIzin, AppColors.accentOrange),
              _tombolStatus(s, StatusKehadiran.sakit, 'Sakit', AppColors.headerGreen, AppColors.accentBlue),
              _tombolStatus(s, StatusKehadiran.alpa, 'Alfa', AppColors.accentRed, AppColors.accentRed,
                  terakhir: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tombolStatus(
    AbsensiBaris s,
    StatusKehadiran st,
    String label,
    Color warnaTeks,
    Color warnaAktif, {
    bool terakhir = false,
  }) {
    final aktif = _status[s.idSiswa] == st;
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: terakhir ? 0 : 8),
        child: Material(
          color: aktif ? warnaAktif : AppColors.white,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: _menyimpan ? null : () => setState(() => _status[s.idSiswa] = st),
            child: Container(
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: aktif ? warnaAktif : AppColors.textMuted),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: aktif ? Colors.white : warnaTeks,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Bilah bawah yang selalu terlihat: jumlah belum diisi + Simpan/Perbarui.
  Widget? _bilahBawah() {
    if (_memuat || _galat != null || _siswa.isEmpty) return null;
    if (MediaQuery.viewInsetsOf(context).bottom > 0) return null; // keyboard terbuka

    final belum = _belumDiisi;
    final bisa = !_menyimpan && !_libur && !_memuatTanggal && _galatTanggal == null;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _libur
                      ? ''
                      : belum == 0
                          ? 'Semua siswa sudah diisi'
                          : 'Belum diisi: $belum siswa',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: bisa ? _simpan : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.headerGreen,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.border,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _menyimpan
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text(
                          _sudahAda ? 'Perbarui' : 'Simpan',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}