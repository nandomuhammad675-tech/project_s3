import 'package:flutter/material.dart';
import 'package:si_kesa/widgets/notifikasi.dart';

/// Dipakai untuk menu yang layarnya belum dibuat. Hapus pemanggilan ini saat layarnya sudah ada.
void tampilkanBelumTersedia(BuildContext context, String nama) {
  tampilkanNotifikasi(context, 'Halaman $nama belum tersedia.');
}