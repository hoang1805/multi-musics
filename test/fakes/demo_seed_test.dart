import 'package:flutter_test/flutter_test.dart';
import 'package:multi_musics/app_dependencies.dart';
import 'package:multi_musics/core/logging/app_logger.dart';
import 'package:multi_musics/fakes/demo_seed.dart';
import 'package:multi_musics/sources/source_type.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDependencies deps;

  setUp(() async {
    deps = await AppDependencies.create(
      fake: false,
      logger: AppLogger.memory(),
      db: openTestDatabase(),
    );
  });

  tearDown(() => deps.dispose());

  test('seeds 20 mixed-source tracks and 3 playlists', () async {
    await seedDemoData(deps);
    final tracks = await deps.tracks.watchAll().first;
    expect(tracks, hasLength(20));
    expect(tracks.where((t) => t.source == SourceType.youtube), hasLength(7));
    expect(tracks.where((t) => t.source == SourceType.soundcloud), hasLength(7));
    expect(tracks.where((t) => t.source == SourceType.spotify), hasLength(6));
    expect(tracks.map((t) => t.title), containsAll(['Mưa Tháng Sáu', 'Đêm Trăng']));

    final playlists = await deps.playlists.watchAll().first;
    expect(
      playlists.map((p) => p.playlist.name),
      unorderedEquals(['Chill tối', 'Tập gym', 'Nhạc Việt']),
    );
    for (final p in playlists) {
      expect(p.trackCount, inInclusiveRange(5, 8));
      final detail = await deps.playlists.watchDetail(p.playlist.id).first;
      expect(detail!.items.map((i) => i.track.source).toSet().length, greaterThan(1));
    }
  });

  test('second run is a no-op', () async {
    await seedDemoData(deps);
    await seedDemoData(deps);
    expect(await deps.tracks.watchAll().first, hasLength(20));
    expect(await deps.playlists.watchAll().first, hasLength(3));
  });
}
