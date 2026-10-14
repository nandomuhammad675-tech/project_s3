import 'package:flutter/material.dart';
import 'package:si_kesa/widgets/app_header.dart';
import 'package:si_kesa/widgets/sub_page_header.dart';

/// Kerangka layar dengan header gelombang, mengikuti pola Beranda Guru:
/// isi (yang digulir) ada di belakang, header tetap di depan, jadi tidak ada garis potong putih
/// di bawah gelombang. [builder] menerima tinggi header; isi wajib memberi padding atas sebesar itu.
class LayarBerheader extends StatelessWidget {
  final String title;
  final bool showBack;
  final Widget Function(double tinggiHeader) builder;

  const LayarBerheader({
    super.key,
    required this.title,
    required this.builder,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    final tinggiHeader = AppHeader.tinggi(context);
    return Stack(
      children: [
        Positioned.fill(child: builder(tinggiHeader)),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SubPageHeader(title: title, showBack: showBack),
        ),
      ],
    );
  }
}