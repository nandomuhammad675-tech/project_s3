import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:si_kesa/services/api_client.dart';
import 'package:si_kesa/services/wali_service.dart';
import 'package:si_kesa/utils/storage_keys.dart';

/// Sesi Wali Murid: login NISN saja (tanpa password), token 60 menit tanpa refresh.
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
    // Sisakan 30 detik agar token tidak dipakai tepat saat kedaluwarsa.
    final habis = DateTime.now().add(Duration(seconds: expiresIn > 30 ? expiresIn - 30 : expiresIn));

    WaliService.hapusCache();
    await _storage.write(key: StorageKeys.waliToken, value: token);
    await _storage.write(key: StorageKeys.waliHabisPada, value: habis.toIso8601String());
  }

  /// Token yang masih berlaku, atau null (sekaligus membersihkan token yang sudah habis).
  static Future<String?> token() async {
    final t = await _storage.read(key: StorageKeys.waliToken);
    if (t == null) return null;
    final habis = DateTime.tryParse(await _storage.read(key: StorageKeys.waliHabisPada) ?? '');
    if (habis == null || DateTime.now().isAfter(habis)) {
      await keluar();
      return null;
    }
    return t;
  }

  static Future<bool> punyaSesi() async => (await token()) != null;

  /// Keluar: hapus token lokal saja. Server tidak mencabut token (KONTRAK_API.md bagian 7 butir 3).
  static Future<void> keluar() async {
    await _storage.delete(key: StorageKeys.waliToken);
    await _storage.delete(key: StorageKeys.waliHabisPada);
    WaliService.hapusCache();
  }
}
