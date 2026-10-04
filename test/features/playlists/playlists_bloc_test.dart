import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multi_musics/data/db/database.dart';
import 'package:multi_musics/data/models/playlist_models.dart';
import 'package:multi_musics/data/repositories/playlist_repository.dart';
import 'package:multi_musics/features/playlists/bloc/playlists_bloc.dart';

class MockPlaylistRepository extends Mock implements PlaylistRepository {}

PlaylistSummary summary(int id, {int count = 0}) => PlaylistSummary(
      playlist: Playlist(
        id: id,
        name: 'P$id',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
      trackCount: count,
      coverArtworks: const [],
    );

void main() {
  late MockPlaylistRepository repo;
  late StreamController<List<PlaylistSummary>> stream;

  setUp(() {
    repo = MockPlaylistRepository();
    stream = StreamController();
    when(() => repo.watchAll()).thenAnswer((_) => stream.stream);
    when(() => repo.create(any())).thenAnswer(
      (i) async => summary(1).playlist.copyWith(name: i.positionalArguments.first as String),
    );
    when(() => repo.addTrackToPlaylists(any(), any())).thenAnswer((_) async {});
  });

  tearDown(() {
    stream.close();
  });

  blocTest<PlaylistsBloc, PlaylistsState>(
    'subscription emits ready',
    build: () => PlaylistsBloc(playlists: repo),
    act: (b) {
      b.add(const PlaylistsSubscriptionRequested());
      stream.add([summary(1, count: 2)]);
    },
    expect: () => [
      PlaylistsState(status: PlaylistsStatus.ready, playlists: [summary(1, count: 2)]),
    ],
  );

  blocTest<PlaylistsBloc, PlaylistsState>(
    'create trims the name',
    build: () => PlaylistsBloc(playlists: repo),
    act: (b) => b.add(const PlaylistsCreated('  Chill  ')),
    verify: (_) => verify(() => repo.create('Chill')).called(1),
  );

  blocTest<PlaylistsBloc, PlaylistsState>(
    'blank name is ignored',
    build: () => PlaylistsBloc(playlists: repo),
    act: (b) => b.add(const PlaylistsCreated('   ')),
    verify: (_) => verifyNever(() => repo.create(any())),
  );

  blocTest<PlaylistsBloc, PlaylistsState>(
    'track added to playlists',
    build: () => PlaylistsBloc(playlists: repo),
    act: (b) => b.add(const PlaylistsTrackAdded(5, [1, 2])),
    verify: (_) => verify(() => repo.addTrackToPlaylists(5, [1, 2])).called(1),
  );
}
