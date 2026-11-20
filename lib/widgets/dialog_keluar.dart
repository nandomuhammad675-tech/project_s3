import 'package:flutter/material.dart';
import 'package:si_kesa/config/theme_config.dart';

/// Dialog konfirmasi keluar akun, gayanya disamakan dengan dialog keluar di PWA Admin:
/// logo sekolah, judul, penjelasan singkat, tombol Batal dan "Ya, Keluar".
/// Mengembalikan true bila pengguna memilih "Ya, Keluar"; false/null bila batal atau ditutup.
Future<bool?> tampilkanDialogKeluar(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: AppColors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tombol tutup (X) di pojok kanan atas
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Navigator.of(ctx).pop(false),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 20, color: AppColors.textMuted),
                ),
              ),
            ),
            Image.asset(
              'assets/images/logo_sekolah.png',
              height: 64,
              cacheHeight: 192,
            ),
            const SizedBox(height: 14),
            const Text(
              'Keluar dari SI-KESA?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sesi Anda akan diakhiri. Anda perlu masuk kembali untuk membuka aplikasi.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, height: 1.45, color: AppColors.textMuted),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textDark,
                        backgroundColor: AppColors.toggleBg,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shadowColor: AppColors.primary.withValues(alpha: 0.45),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Ya, Keluar', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}