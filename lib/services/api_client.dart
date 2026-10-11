import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;
import 'package:si_kesa/config/api_config.dart';

/// Kegagalan dari server atau jaringan. [message] aman ditampilkan apa adanya ke pengguna.
class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final Map<String, String> errors;

  const ApiException(this.message, {this.statusCode, this.errors = const {}});

  bool get unauthorized => statusCode == 401;

  @override
  String toString() => message;
}

String pesanDariError(Object e) =>
    e is ApiException ? e.message : 'Terjadi gangguan, coba lagi.';

/// Klien HTTP tunggal. Membungkus respons {success, message, data} sehingga pemanggil
/// langsung menerima `data`, atau ApiException bila gagal (KONTRAK_API.md bagian 0).
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  final http.Client _client = http.Client();

  /// Mengambil token tersimpan (null bila belum login atau sudah habis).
  Future<String?> Function()? tokenProvider;

  /// Dipanggil bila request ber-token dibalas 401 (sesi habis, atau siswa tidak lagi aktif).
  void Function()? onUnauthorized;

  Future<dynamic> get(String path, {Map<String, String?>? query, bool auth = true}) =>
      _kirim('GET', path, query: query, auth: auth);

  Future<dynamic> post(String path, {Map<String, dynamic>? body, bool auth = true}) =>
      _kirim('POST', path, body: body, auth: auth);

  Uri _uri(String path, Map<String, String?>? query) {
    final params = <String, String>{};
    query?.forEach((k, v) {
      if (v != null && v.isNotEmpty) params[k] = v;
    });
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    return params.isEmpty ? uri : uri.replace(queryParameters: params);
  }

  Future<dynamic> _kirim(
    String method,
    String path, {
    Map<String, String?>? query,
    Map<String, dynamic>? body,
    required bool auth,
  }) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (method == 'POST') headers['Content-Type'] = 'application/json';
    if (auth) {
      final token = await tokenProvider?.call();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }

    final uri = _uri(path, query);
    final http.Response res;
    try {
      final permintaan = method == 'GET'
          ? _client.get(uri, headers: headers)
          : _client.post(uri, headers: headers, body: jsonEncode(body ?? <String, dynamic>{}));
      res = await permintaan.timeout(ApiConfig.timeout);
    } on TimeoutException {
      throw const ApiException('Server tidak merespons. Coba lagi.');
    } on SocketException {
      throw const ApiException('Tidak dapat terhubung ke server. Periksa koneksi internet.');
    } on http.ClientException {
      throw const ApiException('Tidak dapat terhubung ke server. Periksa koneksi internet.');
    }
    return _tangani(res, auth);
  }

  dynamic _tangani(http.Response res, bool auth) {
    Map<String, dynamic>? json;
    try {
      final d = jsonDecode(utf8.decode(res.bodyBytes));
      if (d is Map<String, dynamic>) json = d;
    } catch (_) {
      // Bukan JSON (mis. halaman error Apache); ditangani sebagai gangguan di bawah.
    }

    final kode = res.statusCode;
    if (kode >= 200 && kode < 300 && json != null && json['success'] == true) {
      return json['data'];
    }

    if (kode == 401 && auth) onUnauthorized?.call();

    final m = json?['message'];
    var pesan = m is String ? m : 'Terjadi gangguan, coba lagi.';
    if (kode >= 500) pesan = 'Terjadi gangguan, coba lagi.';

    final errors = <String, String>{};
    final e = json?['errors'];
    if (e is Map) {
      e.forEach((k, v) => errors['$k'] = '$v');
    }
    throw ApiException(pesan, statusCode: kode, errors: errors);
  }
}
