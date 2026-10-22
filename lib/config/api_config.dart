/// Alamat backend. Ubah lewat --dart-define, tanpa mengedit kode:
///   emulator Android : (default) http://10.0.2.2/si-kesa/backend/public
///   HP asli (satu Wi-Fi): flutter run --dart-define=API_BASE_URL=http://192.168.1.10/si-kesa/backend/public
/// Produksi wajib HTTPS (TDD bab 12).
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
        defaultValue: 'http://172.16.103.245/project_s3_web/backend/public',
  );

  static const Duration timeout = Duration(seconds: 20);
}