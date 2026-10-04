/// `3:05`, or `1:02:09` from one hour up.
String formatTrackDuration(Duration d) {
  String two(int v) => v.toString().padLeft(2, '0');
  final hours = d.inHours;
  final minutes = d.inMinutes.remainder(60);
  final seconds = d.inSeconds.remainder(60);
  if (hours > 0) return '$hours:${two(minutes)}:${two(seconds)}';
  return '$minutes:${two(seconds)}';
}

/// `0 phút`, `12 phút`, `1 giờ`, `1 giờ 5 phút` — floored to the minute.
String formatTotalDuration(Duration d) {
  final hours = d.inHours;
  final minutes = d.inMinutes.remainder(60);
  if (hours == 0) return '$minutes phút';
  if (minutes == 0) return '$hours giờ';
  return '$hours giờ $minutes phút';
}
