import 'package:http/http.dart' as http;

import 'core/logging/app_logger.dart';
import 'data/db/database.dart';
import 'data/repositories/library_writer.dart';
import 'data/repositories/playlist_repository.dart';
import 'data/repositories/track_repository.dart';
import 'fakes/demo_seed.dart';
import 'fakes/fake_metadata_fetcher.dart';
import 'sources/link_parser.dart';
import 'sources/metadata/metadata_fetcher.dart';
import 'sources/metadata/oembed_client.dart';

class AppDependencies {
  AppDependencies._({
    required this.db,
    required this.logger,
    required this.tracks,
    required this.playlists,
    required this.writer,
    required this.linkParser,
    required this.metadata,
    required this._httpClient,
  });

  /// `fake: true` swaps metadata for [FakeMetadataFetcher] and seeds demo data
  /// into an empty library. Link parsing stays real.
  static Future<AppDependencies> create({
    required bool fake,
    required AppLogger logger,
    AppDatabase? db,
  }) async {
    final database = db ?? AppDatabase.openDefault();
    final httpClient = http.Client();
    final tracks = TrackRepository(database);
    final playlists = PlaylistRepository(database);
    final deps = AppDependencies._(
      db: database,
      logger: logger,
      tracks: tracks,
      playlists: playlists,
      writer: LibraryWriter(database, tracks, playlists),
      linkParser: LinkParser(httpClient: httpClient),
      metadata: fake ? FakeMetadataFetcher() : OEmbedClient(httpClient: httpClient),
      httpClient: httpClient,
    );
    if (fake) await seedDemoData(deps);
    logger.info('app', 'dependencies ready (fake: $fake)');
    return deps;
  }

  final AppDatabase db;
  final AppLogger logger;
  final TrackRepository tracks;
  final PlaylistRepository playlists;
  final LibraryWriter writer;
  final LinkParser linkParser;
  final MetadataFetcher metadata;
  final http.Client _httpClient;

  Future<void> dispose() async {
    _httpClient.close();
    logger.dispose();
    await db.close();
  }
}
