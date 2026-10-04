import 'package:flutter_test/flutter_test.dart';
import 'package:multi_musics/core/failure.dart';
import 'package:multi_musics/core/result.dart';
import 'package:multi_musics/sources/source_type.dart';

void main() {
  group('Failure.message', () {
    test('UnsupportedLink has exact copy', () {
      expect(
        const UnsupportedLink().message,
        'Bản này chưa hỗ trợ playlist/album — hãy dán link 1 bài',
      );
    });

    test('ExtractionFailed names the source', () {
      expect(
        const ExtractionFailed(SourceType.youtube, 'x').message,
        'Không lấy được bài từ YouTube.',
      );
    });

    test('TrackUnavailable returns its reason', () {
      expect(
        const TrackUnavailable('Video đã bị xóa').message,
        'Video đã bị xóa',
      );
    });
  });

  test('failures compare by value', () {
    expect(const NetworkFailure(), const NetworkFailure());
    expect(
      const ExtractionFailed(SourceType.soundcloud, 'a'),
      isNot(const ExtractionFailed(SourceType.soundcloud, 'b')),
    );
  });

  test('Result is exhaustively matchable', () {
    const Result<int> result = Ok(1);
    final value = switch (result) {
      Ok(:final value) => value,
      Err() => -1,
    };
    expect(value, 1);
  });

  test('SourceType display names', () {
    expect(SourceType.spotify.displayName, 'Spotify');
    expect(SourceType.youtube.displayName, 'YouTube');
    expect(SourceType.soundcloud.displayName, 'SoundCloud');
  });
}
