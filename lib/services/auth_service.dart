import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:si_kesa/services/api_client.dart';
import 'package:si_kesa/services/wali_service.dart';
import 'package:si_kesa/utils/storage_keys.dart';

enum PeranSesi { guru, wali }

/// Sesi aplikasi. Wali: login NISN saja, token pendek (60 menit). Guru: login username + password, token 8 jam.
/// Tidak ada refresh token. Token disimpan di penyimpanan aman Android, tidak pernah ditulis ke log.
class AuthService {
  AuthService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  /// POST /api/wali/login. Gagal -> ApiException (401 dengan pesan generik, 429 bila terlalu sering).
  static Future<void> loginWali(String nisn) async {
    final data = await ApiClient.instance.post(
      '/api/wali/login',
      body: {'nisn': nisn},
      auth: false,
    ) as Map<String, dynamic>;

    final token = data['token'] as String;
    final expiresIn = (data['expires_in'] as num).toInt();

    WaliService.hapusCache();
    await _storage.write(key: StorageKeys.waliToken, value: token);
    await _storage.write(
        key: StorageKeys.waliHabisPada, value: _batasWaktu(expiresIn).toIso8601String());
  }

  /// Menyimpan sesi Guru setelah login berhasil (dipanggil dari layar Login Guru).
  static Future<void> simpanSesiGuru({required String token, required int expiresIn}) async {
    await _storage.write(key: StorageKeys.guruToken, value: token);
    await _storage.write(
        key: StorageKeys.guruHabisPada, value: _batasWaktu(expiresIn).toIso8601String());
  }

  // Sisakan 30 detik agar token tidak dipakai tepat saat kedaluwarsa.
  static DateTime _batasWaktu(int expiresIn) =>
      DateTime.now().add(Duration(seconds: expiresIn > 30 ? expiresIn - 30 : expiresIn));

  /// Token Wali yang masih berlaku, atau null (sekaligus membersihkan token yang sudah habis).
  static Future<String?> token() async {
    final t = await _storage.read(key: StorageKeys.waliToken);
    if (t == null) return null;
    final habis = DateTime.tryParse(await _storage.read(key: StorageKeys.waliHabisPada) ?? '');
    if (habis == null || DateTime.now().isAfter(habis)) {
      await _hapusWali();
      return null;
    }
    return t;
  }

  /// Token Guru yang masih berlaku, atau null (sekaligus membersihkan token yang sudah habis).
  static Future<String?> tokenGuru() async {
    final t = await _storage.read(key: StorageKeys.guruToken);
    if (t == null) return null;
    final habis = DateTime.tryParse(await _storage.read(key: StorageKeys.guruHabisPada) ?? '');
    if (habis == null || DateTime.now().isAfter(habis)) {
      await _hapusGuru();
      return null;
    }
    return t;
  }

  /// Token yang dipasang di header Authorization: Bearer (Guru lebih dulu, lalu Wali).
  static Future<String?> tokenAktif() async => await tokenGuru() ?? await token();

  /// Siapa yang sedang masuk, atau null bila belum ada sesi yang berlaku.
  static Future<PeranSesi?> peran() async {
    if (await tokenGuru() != null) return PeranSesi.guru;
    if (await token() != null) return PeranSesi.wali;
    return null;
  }

  static Future<bool> punyaSesi() async => (await peran()) != null;

  static Future<void> _hapusWali() async {
    await _storage.delete(key: StorageKeys.waliToken);
    await _storage.delete(key: StorageKeys.waliHabisPada);
    WaliService.hapusCache();
  }

  static Future<void> _hapusGuru() async {
    await _storage.delete(key: StorageKeys.guruToken);
    await _storage.delete(key: StorageKeys.guruHabisPada);
  }

  /// Keluar: hapus token lokal saja. Server tidak mencabut token (KONTRAK_API.md bagian 7 butir 3).
  static Future<void> keluar() async {
    await _hapusWali();
    await _hapusGuru();
  }
}