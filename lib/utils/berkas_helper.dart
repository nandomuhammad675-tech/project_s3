// Simpan/bagikan berkas Excel: cara kerjanya dipilih otomatis sesuai platform.
// HP (Android/iOS): menu Bagikan. Web: unduh langsung lewat browser.
export 'berkas_helper_io.dart' if (dart.library.js_interop) 'berkas_helper_web.dart';

/// Huruf, angka, dan minus saja (aman untuk nama berkas).
String namaBerkasAman(String s) => s.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-');