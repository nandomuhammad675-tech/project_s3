import 'package:si_kesa/models/guru_model.dart';
import 'package:si_kesa/services/api_client.dart';

/// Endpoint Guru yang umum. Scope kelas selalu dari token di server (tidak ada id_kelas dari layar).
class GuruService {
  GuruService._();

  static final ApiClient _api = ApiClient.instance;

  /// GET /api/guru/me. 401 ditangani global (hapus token, ke Login).
  static Future<GuruModel> me() async {
    final d = await _api.get('/api/guru/me');
    return uraiData(() => GuruModel.fromJson(d as Map<String, dynamic>));
  }
}