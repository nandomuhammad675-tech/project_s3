import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

const String _mimeXlsx = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

/// Web: berkas langsung terunduh lewat browser (masuk folder Download).
Future<void> bagikanExcel(Uint8List bytes, String namaFile) async {
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: _mimeXlsx));
  final url = web.URL.createObjectURL(blob);
  final tautan = web.HTMLAnchorElement()
    ..href = url
    ..download = namaFile;
  web.document.body?.append(tautan);
  tautan.click();
  tautan.remove();
  web.URL.revokeObjectURL(url);
}