import 'package:flutter/material.dart';
import 'package:si_kesa/widgets/app_header.dart';

class SubPageHeader extends StatelessWidget {
  final String title;
  final bool showBack;
  final VoidCallback? onBack;

  const SubPageHeader({
    super.key,
    required this.title,
    this.showBack = true,
    this.onBack,
  });

  /// Ada halaman sebelumnya: mundur satu halaman.
  /// Halaman utama sebuah tab: sama dengan tombol kembali HP (pindah ke Home).
  static void _kembali(BuildContext context) {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
      return;
    }
    Navigator.of(context, rootNavigator: true).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return AppHeader(
      left: Padding(
        padding: const EdgeInsets.only(top: 10), // naikkan angka = judul & panah makin turun
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              if (showBack)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onBack ?? () => _kembali(context),
                  child: const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}