import 'package:drift/drift.dart';

import '../../sources/source_type.dart';

@DataClassName('Track')
class Tracks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get source => textEnum<SourceType>()();
  TextColumn get sourceId => text()();
  TextColumn get originalUrl => text()();
  TextColumn get title => text()();
  TextColumn get artist => text().nullable()();
  TextColumn get artworkUrl => text().nullable()();
  IntColumn get durationMs => integer().nullable()();

  /// Only set for permanent failures (deleted / private / region-blocked).
  TextColumn get unavailableReason => text().nullable()();
  DateTimeColumn get addedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {source, sourceId},
      ];
}

@DataClassName('Playlist')
class Playlists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

@DataClassName('PlaylistEntry')
@TableIndex(name: 'playlist_entries_position', columns: {#playlistId, #position})
class PlaylistEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get playlistId =>
      integer().references(Playlists, #id, onDelete: KeyAction.cascade)();
  IntColumn get trackId =>
      integer().references(Tracks, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();
}

@DataClassName('SettingRow')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
