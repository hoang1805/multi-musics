import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../sources/source_type.dart';
import 'tables.dart';

export 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Tracks, Playlists, PlaylistEntries, Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  static AppDatabase openDefault() =>
      AppDatabase(driftDatabase(name: 'multi_musics'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
