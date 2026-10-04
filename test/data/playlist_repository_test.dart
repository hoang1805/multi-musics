import 'package:flutter_test/flutter_test.dart';
import 'package:multi_musics/data/db/database.dart';
import 'package:multi_musics/data/repositories/playlist_repository.dart';
import 'package:multi_musics/data/repositories/track_repository.dart';
import 'package:multi_musics/sources/metadata/track_draft.dart';
import 'package:multi_musics/sources/source_type.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late TrackRepository tracks;
  late PlaylistRepository repo;

  Future<Track> track(String id, {String? artwork, int? durationMs}) =>
      tracks.insert(TrackDraft(
        source: SourceType.youtube,
        sourceId: id,
        originalUrl: 'https://youtu.be/$id',
        title: id,
        artworkUrl: artwork,
        durationMs: durationMs,
      ));

  Future<List<String>> order(int playlistId) async {
    final detail = await repo.watchDetail(playlistId).first;
    expect(
      detail!.items.map((i) => i.position).toList(),
      List.generate(detail.items.length, (i) => i),
      reason: 'positions must be contiguous from 0',
    );
    return detail.items.map((i) => i.track.title).toList();
  }

  setUp(() {
    db = openTestDatabase();
    tracks = TrackRepository(db);
    repo = PlaylistRepository(db);
  });

  tearDown(() => db.close());

  test('create then watchAll shows summary with 0 tracks', () async {
    final p = await repo.create('Chill');
    final all = await repo.watchAll().first;
    expect(all.single.playlist.id, p.id);
    expect(all.single.playlist.name, 'Chill');
    expect(all.single.trackCount, 0);
    expect(all.single.coverArtworks, isEmpty);
  });

  test('create trims name and rejects blank', () async {
    expect((await repo.create('  Chill  ')).name, 'Chill');
    expect(() => repo.create('   '), throwsArgumentError);
  });

  test('addTrackToPlaylists appends at end', () async {
    final p = await repo.create('P');
    for (final id in ['A', 'B', 'C']) {
      await repo.addTrackToPlaylists((await track(id)).id, [p.id]);
    }
    expect(await order(p.id), ['A', 'B', 'C']);
  });

  test('same track twice in one playlist creates two entries', () async {
    final p = await repo.create('P');
    final a = await track('A');
    await repo.addTrackToPlaylists(a.id, [p.id]);
    await repo.addTrackToPlaylists(a.id, [p.id]);
    expect(await order(p.id), ['A', 'A']);
  });

  test('moveEntry uses post-removal index semantics', () async {
    final p = await repo.create('P');
    for (final id in ['A', 'B', 'C']) {
      await repo.addTrackToPlaylists((await track(id)).id, [p.id]);
    }
    await repo.moveEntry(p.id, 0, 1);
    expect(await order(p.id), ['B', 'A', 'C']);
    await repo.moveEntry(p.id, 2, 0);
    expect(await order(p.id), ['C', 'B', 'A']);
  });

  test('removeEntry renumbers', () async {
    final p = await repo.create('P');
    for (final id in ['A', 'B', 'C']) {
      await repo.addTrackToPlaylists((await track(id)).id, [p.id]);
    }
    final b = (await repo.watchDetail(p.id).first)!.items[1];
    await repo.removeEntry(b.entryId);
    expect(await order(p.id), ['A', 'C']);
  });

  test('deleting track cascades entries', () async {
    final p = await repo.create('P');
    final a = await track('A');
    final b = await track('B');
    await repo.addTrackToPlaylists(a.id, [p.id]);
    await repo.addTrackToPlaylists(b.id, [p.id]);
    await tracks.delete(a.id);
    expect(await order(p.id), ['B']);
    expect((await repo.watchAll().first).single.trackCount, 1);
  });

  test('delete playlist keeps tracks', () async {
    final p = await repo.create('P');
    final a = await track('A');
    await repo.addTrackToPlaylists(a.id, [p.id]);
    await repo.delete(p.id);
    expect(await repo.watchAll().first, isEmpty);
    expect(await tracks.watchAll().first, hasLength(1));
  });

  test('coverArtworks takes first 4 non-null by position', () async {
    final p = await repo.create('P');
    final ids = ['A', 'B', 'C', 'D', 'E', 'F'];
    for (final id in ids) {
      final art = id == 'B' ? null : 'art-$id';
      await repo.addTrackToPlaylists((await track(id, artwork: art)).id, [p.id]);
    }
    final summary = (await repo.watchAll().first).single;
    expect(summary.trackCount, 6);
    expect(summary.coverArtworks, ['art-A', 'art-C', 'art-D', 'art-E']);
  });

  test('watchDetail emits null after delete', () async {
    final p = await repo.create('P');
    await repo.delete(p.id);
    expect(await repo.watchDetail(p.id).first, isNull);
  });

  test('knownDuration sums only known durations', () async {
    final p = await repo.create('P');
    await repo.addTrackToPlaylists((await track('A', durationMs: 60000)).id, [p.id]);
    await repo.addTrackToPlaylists((await track('B')).id, [p.id]);
    await repo.addTrackToPlaylists((await track('C', durationMs: 30000)).id, [p.id]);
    final detail = (await repo.watchDetail(p.id).first)!;
    expect(detail.knownDuration, const Duration(seconds: 90));
  });

  test('rename updates name and updatedAt ordering', () async {
    final a = await repo.create('A');
    await repo.create('B');
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    await repo.rename(a.id, ' A2 ');
    final all = await repo.watchAll().first;
    expect(all.first.playlist.name, 'A2');
  });
}
