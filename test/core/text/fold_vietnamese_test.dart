import 'package:flutter_test/flutter_test.dart';
import 'package:multi_musics/core/text/fold_vietnamese.dart';

void main() {
  test('lowercases and strips all Vietnamese diacritics', () {
    expect(foldVietnamese('Mưa Đêm Ướt Át'), 'mua dem uot at');
    expect(foldVietnamese('Hạ Vũ'), 'ha vu');
  });

  test('covers every vowel family and tone', () {
    expect(
      foldVietnamese('àáảãạ ăằắẳẵặ âầấẩẫậ èéẻẽẹ êềếểễệ ìíỉĩị'),
      'aaaaa aaaaaa aaaaaa eeeee eeeeee iiiii',
    );
    expect(
      foldVietnamese('òóỏõọ ôồốổỗộ ơờớởỡợ ùúủũụ ưừứửữự ỳýỷỹỵ đĐ'),
      'ooooo oooooo oooooo uuuuu uuuuuu yyyyy dd',
    );
    expect(foldVietnamese('ÀÁẢÃẠ ỲÝỶỸỴ'), 'aaaaa yyyyy');
  });

  test('handles decomposed (NFD) text: base letter + combining marks', () {
    // "Mưa Đêm" with ư = u + U+031B, ê = e + U+0302, plus a tone mark.
    const nfd = 'Mưa Đêm Hạ';
    expect(foldVietnamese(nfd), 'mua dem ha');
  });

  test('leaves plain ASCII alone except case', () {
    expect(foldVietnamese('Rick Astley 2024'), 'rick astley 2024');
  });
}
