import 'dart:math';

import '../app_dependencies.dart';
import '../sources/metadata/track_draft.dart';
import '../sources/source_type.dart';

const _demoTracks = [
  (SourceType.youtube, 'Mưa Tháng Sáu', 'Văn Mai Hương'),
  (SourceType.youtube, 'Đêm Trăng', 'Hà Anh Tuấn'),
  (SourceType.youtube, 'Thành Phố Buồn', 'Tuấn Vũ'),
  (SourceType.youtube, 'Lofi Chill Mix', 'Lofi Girl'),
  (SourceType.youtube, 'Bước Qua Nhau', 'Vũ.'),
  (SourceType.youtube, 'Workout Beats', 'Gym Radio'),
  (SourceType.youtube, 'Hà Nội Mùa Thu', 'Mỹ Linh'),
  (SourceType.soundcloud, 'Sài Gòn Đẹp Lắm', 'Ngọt'),
  (SourceType.soundcloud, 'Deep House Session', 'Kygo'),
  (SourceType.soundcloud, 'Ngày Mai Em Đi', 'Lê Hiếu'),
  (SourceType.soundcloud, 'Late Night Drive', 'Nightcall'),
  (SourceType.soundcloud, 'Phố Không Mùa', 'Bùi Anh Tuấn'),
  (SourceType.soundcloud, 'Run Faster', 'Pulse'),
  (SourceType.soundcloud, 'Ánh Nắng Của Anh', 'Đức Phúc'),
  (SourceType.spotify, 'Blinding Lights', 'The Weeknd'),
  (SourceType.spotify, 'Có Chàng Trai Viết Lên Cây', 'Phan Mạnh Quỳnh'),
  (SourceType.spotify, 'Stronger', 'Kanye West'),
  (SourceType.spotify, 'Sweet Night', 'V'),
  (SourceType.spotify, 'Em Gái Mưa', 'Hương Tràm'),
  (SourceType.spotify, 'Eye of the Tiger', 'Survivor'),
];

const _demoPlaylists = {
  'Chill tối': [3, 1, 10, 8, 17, 14],
  'Tập gym': [5, 12, 16, 19, 8],
  'Nhạc Việt': [0, 1, 9, 15, 18, 13, 6, 11],
};

String _sourceId(SourceType source, int i) => switch (source) {
      SourceType.youtube => 'demo${i.toString().padLeft(7, '0')}',
      SourceType.spotify => 'demo${i.toString().padLeft(18, '0')}',
      SourceType.soundcloud => 'demo-artist/demo-track-$i',
    };

/// Fills an empty library with 20 tracks and 3 mixed-source playlists.
Future<void> seedDemoData(AppDependencies deps) async {
  if ((await deps.tracks.watchAll().first).isNotEmpty) return;

  final random = Random(42);
  final ids = <int>[];
  for (final (i, (source, title, artist)) in _demoTracks.indexed) {
    final sourceId = _sourceId(source, i);
    final track = await deps.tracks.insert(TrackDraft(
      source: source,
      sourceId: sourceId,
      originalUrl: 'https://example.com/demo/$i',
      title: title,
      artist: artist,
      artworkUrl: 'https://picsum.photos/seed/mm$i/300/300',
      durationMs: (150 + random.nextInt(150)) * 1000,
    ));
    ids.add(track.id);
  }

  for (final MapEntry(key: name, value: indexes) in _demoPlaylists.entries) {
    final playlist = await deps.playlists.create(name);
    for (final index in indexes) {
      await deps.playlists.addTrackToPlaylists(ids[index], [playlist.id]);
    }
  }
  deps.logger.info('demo', 'seeded ${ids.length} tracks');
}
