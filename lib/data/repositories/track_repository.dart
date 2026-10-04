import 'package:drift/drift.dart';

import '../../sources/metadata/track_draft.dart';
import '../../sources/source_type.dart';
import '../db/database.dart';

class TrackRepository {
  TrackRepository(this._db);

  final AppDatabase _db;

  /// Newest first; ties (same second) broken by id.
  Stream<List<Track>> watchAll() {
    return (_db.select(_db.tracks)
          ..orderBy([
            (t) => OrderingTerm.desc(t.addedAt),
            (t) => OrderingTerm.desc(t.id),
          ]))
        .watch();
  }

  Future<Track?> findBySource(SourceType source, String sourceId) {
    return (_db.select(_db.tracks)
          ..where((t) => t.source.equalsValue(source) & t.sourceId.equals(sourceId)))
        .getSingleOrNull();
  }

  /// Returns the existing track unchanged when (source, sourceId) is taken.
  Future<Track> insert(TrackDraft draft) async {
    await _db.into(_db.tracks).insert(
          TracksCompanion.insert(
            source: draft.source,
            sourceId: draft.sourceId,
            originalUrl: draft.originalUrl,
            title: draft.title,
            artist: Value(draft.artist),
            artworkUrl: Value(draft.artworkUrl),
            durationMs: Value(draft.durationMs),
            addedAt: DateTime.now(),
          ),
          mode: InsertMode.insertOrIgnore,
        );
    return (await findBySource(draft.source, draft.sourceId))!;
  }

  Future<void> delete(int id) =>
      (_db.delete(_db.tracks)..where((t) => t.id.equals(id))).go();
}
