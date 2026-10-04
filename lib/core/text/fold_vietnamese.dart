const _groups = {
  'a': 'àáảãạăằắẳẵặâầấẩẫậ',
  'e': 'èéẻẽẹêềếểễệ',
  'i': 'ìíỉĩị',
  'o': 'òóỏõọôồốổỗộơờớởỡợ',
  'u': 'ùúủũụưừứửữự',
  'y': 'ỳýỷỹỵ',
  'd': 'đ',
};

final Map<int, String> _fold = {
  for (final MapEntry(key: base, value: chars) in _groups.entries)
    for (final rune in chars.runes) rune: base,
};

/// Lowercase without Vietnamese diacritics, so "mua" matches "Mưa".
String foldVietnamese(String s) {
  final buffer = StringBuffer();
  for (final rune in s.toLowerCase().runes) {
    buffer.write(_fold[rune] ?? String.fromCharCode(rune));
  }
  return buffer.toString();
}
