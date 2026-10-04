import 'package:flutter_test/flutter_test.dart';
import 'package:multi_musics/data/db/database.dart';
import 'package:multi_musics/data/repositories/track_repository.dart';
import 'package:multi_musics/sources/metadata/track_draft.dart';
import 'package:multi_musics/sources/source_type.dart';

import '../helpers/test_database.dart';

TrackDraft draft(
  String sourceId, {
  SourceType source = SourceType.youtube,
  String title = 'Title',
}) =>
    TrackDraft(
      source: source,
      sourceId: sourceId,
      originalUrl: 'https://example.com/$sourceId',
      title: title,
    );

void main() {
  late AppDatabase db;
  late TrackRepository repo;

  setUp(() {
    db = openTestDatabase();
    repo = TrackRepository(db);
  });

  tearDown(() => db.close());

  test('insert then watchAll emits track', () async {
    final track = await repo.insert(draft('dQw4w9WgXcQ', title: 'Never'));
    final all = await repo.watchAll().first;
    expect(all.single.id, track.id);
    expect(all.single.title, 'Never');
    expect(all.single.source, SourceType.youtube);
  });

  test('insert duplicate returns existing and does not add row', () async {
    final first = await repo.insert(draft('dQw4w9WgXcQ', title: 'First'));
    final second = await repo.insert(draft('dQw4w9WgXcQ', title: 'Second'));
    expect(second.id, first.id);
    expect(second.title, 'First');
    expect(await repo.watchAll().first, hasLength(1));
  });

  test('same sourceId different source are distinct', () async {
    await repo.insert(draft('abc', source: SourceType.youtube));
    await repo.insert(draft('abc', source: SourceType.soundcloud));
    expect(await repo.watchAll().first, hasLength(2));
  });

  test('watchAll orders newest first', () async {
    final a = await repo.insert(draft('a'));
    final b = await repo.insert(draft('b'));
    final ids = (await repo.watchAll().first).map((t) => t.id).toList();
    expect(ids, [b.id, a.id]);
  });

  test('findBySource finds exact match only', () async {
    final a = await repo.insert(draft('a'));
    expect((await repo.findBySource(SourceType.youtube, 'a'))?.id, a.id);
    expect(await repo.findBySource(SourceType.spotify, 'a'), isNull);
  });

  test('delete removes track', () async {
    final a = await repo.insert(draft('a'));
    await repo.delete(a.id);
    expect(await repo.watchAll().first, isEmpty);
  });
}
