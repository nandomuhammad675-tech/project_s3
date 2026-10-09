class NilaiMapel {
  final String mapel;
  final List<int?> uh; // UH-1, UH-2, ... (null = belum ada nilai)
  final int? uts;
  final int? uas;

  const NilaiMapel({
    required this.mapel,
    this.uh = const [],
    this.uts,
    this.uas,
  });
}