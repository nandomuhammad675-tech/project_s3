import 'package:flutter/material.dart';

/// Dipakai untuk menu yang layarnya belum dibuat. Hapus pemanggilan ini saat layarnya sudah ada.
void tampilkanBelumTersedia(BuildContext context, String nama) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('Halaman $nama belum tersedia.')));
}