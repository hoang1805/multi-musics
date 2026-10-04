import 'package:flutter_test/flutter_test.dart';
import 'package:multi_musics/core/format/duration_format.dart';

void main() {
  group('formatTrackDuration', () {
    test('minutes and seconds', () {
      expect(formatTrackDuration(const Duration(seconds: 185)), '3:05');
    });

    test('hours when at least one hour', () {
      expect(
        formatTrackDuration(const Duration(hours: 1, minutes: 2, seconds: 9)),
        '1:02:09',
      );
    });
  });

  group('formatTotalDuration', () {
    test('hours and minutes', () {
      expect(formatTotalDuration(const Duration(minutes: 65)), '1 giờ 5 phút');
    });

    test('whole hours drop minutes', () {
      expect(formatTotalDuration(const Duration(minutes: 60)), '1 giờ');
    });

    test('under a minute floors to zero', () {
      expect(formatTotalDuration(const Duration(seconds: 59)), '0 phút');
    });

    test('minutes only', () {
      expect(formatTotalDuration(const Duration(minutes: 12, seconds: 40)), '12 phút');
    });
  });
}
