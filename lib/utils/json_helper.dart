/// Angka dari JSON bisa datang sebagai int, double, atau String; samakan menjadi int?.
int? asInt(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  return int.tryParse('$v');
}
