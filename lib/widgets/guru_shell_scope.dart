import 'package:flutter/widgets.dart';

/// Dipasang di kerangka Guru supaya layar mana pun (mis. Beranda) bisa berpindah ke tab bilah bawah
/// tanpa membuka salinan layar baru.
class GuruShellScope extends InheritedWidget {
  const GuruShellScope({super.key, required this.onPindah, required super.child});

  final void Function(int tab) onPindah;

  /// Pindah ke tab: 0 Home, 1 Jadwal, 2 Absen, 3 Profil.
  static void pindahTab(BuildContext context, int tab) {
    context.getInheritedWidgetOfExactType<GuruShellScope>()?.onPindah(tab);
  }

  @override
  bool updateShouldNotify(GuruShellScope oldWidget) => false;
}