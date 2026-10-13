import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:si_kesa/services/api_client.dart';
import 'package:si_kesa/services/wali_service.dart';
import 'package:si_kesa/utils/storage_keys.dart';

/// Siapa yang sedang login di HP ini.
enum Peran { guru, wali }

class AuthService {
  AuthService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // ===================== Wali Murid =====================

  /// POST /api/wali/login. Gagal -> ApiException (401 pesan generik, 429 bila terlalu sering).
  static Future<void> loginWali(String nisn) async {
    final data = await ApiClient.instance.post(
      '/api/wali/login',
      body: {'nisn': nisn},
      auth: false,
    ) as Map<String, dynamic>;

    await _simpanToken(StorageKeys.waliToken, StorageKeys.waliHabisPada, data);
  }

  // ===================== Guru =====================

  /// POST /api/auth/login. Hanya role 'guru' yang boleh masuk lewat aplikasi ini.
  static Future<void> loginGuru(String username, String password) async {
    final data = await ApiClient.instance.post(
      '/api/auth/login',
      body: {'username': username, 'password': password},
      auth: false,
    ) as Map<String, dynamic>;

    final user = data['user'] as Map<String, dynamic>;
    if (user['role'] != 'guru') {
      // Akun Admin ditolak, token TIDAK disimpan sama sekali.
      throw const ApiException('Aplikasi ini hanya untuk Guru');
    }
    await _simpanToken(StorageKeys.guruToken, StorageKeys.guruHabisPada, data);
  }

  // ===================== Bersama =====================

  static Future<void> _simpanToken(
    String kunciToken,
    String kunciHabis,
    Map<String, dynamic> data,
  ) async {
    final token = data['token'] as String;
    final expiresIn = (data['expires_in'] as num).toInt();
    // Sisakan 30 detik agar token tidak dipakai tepat saat kedaluwarsa.
    final habis = DateTime.now()
        .add(Duration(seconds: expiresIn > 30 ? expiresIn - 30 : expiresIn));

    await keluar(); // hapus sesi lama supaya hanya ada satu sesi (Guru ATAU Wali)
    await _storage.write(key: kunciToken, value: token);
    await _storage.write(key: kunciHabis, value: habis.toIso8601String());
  }

  /// Token yang masih berlaku, atau null (sekaligus membersihkan yang sudah habis).
  static Future<String?> _bacaToken(String kunciToken, String kunciHabis) async {
    final t = await _storage.read(key: kunciToken);
    if (t == null) return null;
    final habis = DateTime.tryParse(await _storage.read(key: kunciHabis) ?? '');
    if (habis == null || DateTime.now().isAfter(habis)) {
      await _storage.delete(key: kunciToken);
      await _storage.delete(key: kunciHabis);
      return null;
    }
    return t;
  }

  /// Dipakai ApiClient di setiap request: token Wali atau Guru, mana yang ada.
  static Future<String?> token() async =>
      await _bacaToken(StorageKeys.waliToken, StorageKeys.waliHabisPada) ??
      await _bacaToken(StorageKeys.guruToken, StorageKeys.guruHabisPada);

  /// Untuk gerbang awal aplikasi: harus ke Beranda Guru, Beranda Wali, atau Login.
  static Future<Peran?> peran() async {
    if (await _bacaToken(StorageKeys.guruToken, StorageKeys.guruHabisPada) != null) {
      return Peran.guru;
    }
    if (await _bacaToken(StorageKeys.waliToken, StorageKeys.waliHabisPada) != null) {
      return Peran.wali;
    }
    return null;
  }

  static Future<bool> punyaSesi() async => (await token()) != null;

  /// Keluar: hapus token lokal saja. Server tidak mencabut token.
  static Future<void> keluar() async {
    await _storage.delete(key: StorageKeys.waliToken);
    await _storage.delete(key: StorageKeys.waliHabisPada);
    await _storage.delete(key: StorageKeys.guruToken);
    await _storage.delete(key: StorageKeys.guruHabisPada);
    WaliService.hapusCache();
  }
}