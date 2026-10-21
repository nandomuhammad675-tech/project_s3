import 'package:si_kesa/utils/json_helper.dart';

/// GET /api/guru/mapel : { id_mapel, kode_mapel, nama_mapel }
class MapelModel {
  final int id;
  final String nama;

  const MapelModel({required this.id, required this.nama});

  factory MapelModel.fromJson(Map<String, dynamic> j) => MapelModel(
        id: asInt(j['id_mapel']) ?? 0,
        nama: '${j['nama_mapel'] ?? ''}',
      );
}