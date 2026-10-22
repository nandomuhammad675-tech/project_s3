import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

const String _mimeXlsx = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

/// Menyimpan [bytes] sebagai berkas sementara, lalu membuka menu Bagikan
/// (simpan ke Drive/File, kirim WhatsApp, atau buka di aplikasi Excel).
Future<void> bagikanExcel(Uint8List bytes, String namaFile) async {
  final dir = await getTemporaryDirectory();
  final berkas = File('${dir.path}/$namaFile');
  await berkas.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(berkas.path, mimeType: _mimeXlsx, name: namaFile)],
      subject: namaFile,
    ),
  );
}