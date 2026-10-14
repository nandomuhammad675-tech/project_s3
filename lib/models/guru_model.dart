import 'package:si_kesa/models/kelas_model.dart';

/// GET /api/guru/me. [kelas] null = Guru belum ditetapkan sebagai wali kelas pada tahun ajaran aktif.
class GuruModel {
  final String nama;
  final String username;
  final String nip;
  final String email;
  final String noTelepon;

  /// Path relatif di server (mis. "uploads/guru/x.jpg"); null bila belum ada foto.
  final String? fotoProfil;
  final KelasModel? kelas;

  const GuruModel({
    required this.nama,
    this.username = '',
    this.nip = '',
    this.email = '',
    this.noTelepon = '',
    this.fotoProfil,
    this.kelas,
  });

  bool get adaKelas => kelas != null;

  factory GuruModel.fromJson(Map<String, dynamic> j) {
    final g = j['guru'];
    final t = j['tahun_ajaran'];
    final k = j['kelas'];
    String teks(String kunci) => g is Map ? '${g[kunci] ?? ''}' : '';
    final foto = g is Map ? g['foto_profil'] : null;
    return GuruModel(
      nama: teks('nama_guru'),
      username: teks('username'),
      nip: teks('nip'),
      email: teks('email'),
      noTelepon: teks('no_telepon'),
      fotoProfil: foto is String && foto.isNotEmpty ? foto : null,
      kelas: k is Map<String, dynamic>
          ? KelasModel.fromJson(k, tahun: t is Map<String, dynamic> ? t : null)
          : null,
    );
  }
}