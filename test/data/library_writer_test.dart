import 'package:flutter_test/flutter_test.dart';
import 'package:multi_musics/data/db/database.dart';
import 'package:multi_musics/data/repositories/library_writer.dart';
import 'package:multi_musics/data/repositories/playlist_repository.dart';
import 'package:multi_musics/data/repositories/track_repository.dart';
import 'package:multi_musics/sources/metadata/track_draft.dart';
import 'package:multi_musics/sources/source_type.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late TrackRepository tracks;
  late PlaylistRepository playlists;
  late LibraryWriter writer;

  const draft = TrackDraft(
    source: SourceType.spotify,
    sourceId: '4uLU6hMCjMI75M1A2tKUQC',
    originalUrl: 'https://open.spotify.com/track/4uLU6hMCjMI75M1A2tKUQC',
    title: 'Song',
  );

  setUp(() {
    db = openTestDatabase();
    tracks = TrackRepository(db);
    playlists = PlaylistRepository(db);
    writer = LibraryWriter(db, tracks, playlists);
  });

  tearDown(() => db.close());

  test('addToLibrary with playlists writes both', () async {
    final p1 = await playlists.create('One');
    final p2 = await playlists.create('Two');
    final track = await writer.addToLibrary(draft, playlistIds: [p1.id, p2.id]);
    expect(track.title, 'Song');
    expect((await playlists.watchDetail(p1.id).first)!.items.single.track.id, track.id);
    expect((await playlists.watchDetail(p2.id).first)!.items.single.track.id, track.id);
  });

  test('unknown playlist rolls back the whole write', () async {
    await expectLater(
      writer.addToLibrary(draft, playlistIds: [999]),
      throwsA(anything),
    );
    expect(await tracks.watchAll().first, isEmpty);
  });
}
