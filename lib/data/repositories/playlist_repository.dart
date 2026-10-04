import 'package:drift/drift.dart';

import '../db/database.dart';
import '../models/playlist_models.dart';

class PlaylistRepository {
  PlaylistRepository(this._db);

  final AppDatabase _db;

  /// Most recently changed first.
  Stream<List<PlaylistSummary>> watchAll() {
    final query = _db.select(_db.playlists).join([
      leftOuterJoin(
        _db.playlistEntries,
        _db.playlistEntries.playlistId.equalsExp(_db.playlists.id),
      ),
      leftOuterJoin(
        _db.tracks,
        _db.tracks.id.equalsExp(_db.playlistEntries.trackId),
      ),
    ])
      ..orderBy([
        OrderingTerm.desc(_db.playlists.updatedAt),
        OrderingTerm.desc(_db.playlists.id),
        OrderingTerm.asc(_db.playlistEntries.position),
      ]);

    return query.watch().map((rows) {
      final order = <int>[];
      final playlists = <int, Playlist>{};
      final counts = <int, int>{};
      final covers = <int, List<String>>{};
      for (final row in rows) {
        final playlist = row.readTable(_db.playlists);
        if (!playlists.containsKey(playlist.id)) {
          order.add(playlist.id);
          playlists[playlist.id] = playlist;
          counts[playlist.id] = 0;
          covers[playlist.id] = [];
        }
        final track = row.readTableOrNull(_db.tracks);
        if (track == null) continue;
        counts[playlist.id] = counts[playlist.id]! + 1;
        final cover = covers[playlist.id]!;
        if (track.artworkUrl != null && cover.length < 4) cover.add(track.artworkUrl!);
      }
      return [
        for (final id in order)
          PlaylistSummary(
            playlist: playlists[id]!,
            trackCount: counts[id]!,
            coverArtworks: covers[id]!,
          ),
      ];
    });
  }

  Future<Playlist> create(String name) async {
    final now = DateTime.now();
    final id = await _db.into(_db.playlists).insert(PlaylistsCompanion.insert(
          name: _validName(name),
          createdAt: now,
          updatedAt: now,
        ));
    return (_db.select(_db.playlists)..where((p) => p.id.equals(id))).getSingle();
  }

  Future<void> rename(int id, String name) {
    return (_db.update(_db.playlists)..where((p) => p.id.equals(id))).write(
      PlaylistsCompanion(
        name: Value(_validName(name)),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> delete(int id) =>
      (_db.delete(_db.playlists)..where((p) => p.id.equals(id))).go();

  /// Emits `null` when the playlist does not exist.
  Stream<PlaylistDetail?> watchDetail(int id) {
    final query = _db.select(_db.playlists).join([
      leftOuterJoin(
        _db.playlistEntries,
        _db.playlistEntries.playlistId.equalsExp(_db.playlists.id),
      ),
      leftOuterJoin(
        _db.tracks,
        _db.tracks.id.equalsExp(_db.playlistEntries.trackId),
      ),
    ])
      ..where(_db.playlists.id.equals(id))
      ..orderBy([OrderingTerm.asc(_db.playlistEntries.position)]);

    return query.watch().map((rows) {
      if (rows.isEmpty) return null;
      final items = <PlaylistItem>[];
      for (final row in rows) {
        final entry = row.readTableOrNull(_db.playlistEntries);
        final track = row.readTableOrNull(_db.tracks);
        if (entry == null || track == null) continue;
        // Display index, not the stored value: deleting a track cascades its
        // entries and can leave gaps, which every write path renumbers away.
        items.add(PlaylistItem(entryId: entry.id, position: items.length, track: track));
      }
      return PlaylistDetail(playlist: rows.first.readTable(_db.playlists), items: items);
    });
  }

  /// Appends [trackId] to the end of each playlist.
  Future<void> addTrackToPlaylists(int trackId, List<int> playlistIds) {
    return _db.transaction(() async {
      for (final playlistId in playlistIds) {
        final maxPosition = _db.playlistEntries.position.max();
        final current = await (_db.selectOnly(_db.playlistEntries)
              ..addColumns([maxPosition])
              ..where(_db.playlistEntries.playlistId.equals(playlistId)))
            .map((row) => row.read(maxPosition))
            .getSingle();
        await _db.into(_db.playlistEntries).insert(PlaylistEntriesCompanion.insert(
              playlistId: playlistId,
              trackId: trackId,
              position: (current ?? -1) + 1,
            ));
        await _touch(playlistId);
      }
    });
  }

  Future<void> removeEntry(int entryId) {
    return _db.transaction(() async {
      final entry = await (_db.select(_db.playlistEntries)
            ..where((e) => e.id.equals(entryId)))
          .getSingleOrNull();
      if (entry == null) return;
      await (_db.delete(_db.playlistEntries)..where((e) => e.id.equals(entryId))).go();
      final remaining = await _entries(entry.playlistId);
      await _renumber(remaining);
      await _touch(entry.playlistId);
    });
  }

  /// Same semantics as `list.insert(toIndex, list.removeAt(fromIndex))`.
  Future<void> moveEntry(int playlistId, int fromIndex, int toIndex) {
    return _db.transaction(() async {
      final entries = await _entries(playlistId);
      entries.insert(toIndex, entries.removeAt(fromIndex));
      await _renumber(entries);
      await _touch(playlistId);
    });
  }

  Future<List<PlaylistEntry>> _entries(int playlistId) {
    return (_db.select(_db.playlistEntries)
          ..where((e) => e.playlistId.equals(playlistId))
          ..orderBy([(e) => OrderingTerm.asc(e.position)]))
        .get();
  }

  Future<void> _renumber(List<PlaylistEntry> ordered) async {
    for (var i = 0; i < ordered.length; i++) {
      if (ordered[i].position == i) continue;
      await (_db.update(_db.playlistEntries)..where((e) => e.id.equals(ordered[i].id)))
          .write(PlaylistEntriesCompanion(position: Value(i)));
    }
  }

  Future<void> _touch(int playlistId) {
    return (_db.update(_db.playlists)..where((p) => p.id.equals(playlistId)))
        .write(PlaylistsCompanion(updatedAt: Value(DateTime.now())));
  }

  static String _validName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError.value(name, 'name', 'must not be blank');
    return trimmed;
  }
}
