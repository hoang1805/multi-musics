import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multi_musics/data/db/database.dart';
import 'package:multi_musics/data/models/playlist_models.dart';
import 'package:multi_musics/data/repositories/playlist_repository.dart';
import 'package:multi_musics/features/playlists/bloc/playlist_detail_bloc.dart';

import '../../helpers/fixtures.dart';

class MockPlaylistRepository extends Mock implements PlaylistRepository {}

final playlist = Playlist(id: 9, name: 'Chill', createdAt: DateTime(2026), updatedAt: DateTime(2026));

PlaylistDetail detailOf(List<String> titles) => PlaylistDetail(
      playlist: playlist,
      items: [
        for (final (i, t) in titles.indexed)
          PlaylistItem(entryId: 100 + t.codeUnitAt(0), position: i, track: makeTrack(i, title: t)),
      ],
    );

List<String> titles(PlaylistDetailState s) =>
    s.detail!.items.map((i) => i.track.title).toList();

void main() {
  late MockPlaylistRepository repo;
  late StreamController<PlaylistDetail?> stream;

  setUp(() {
    repo = MockPlaylistRepository();
    stream = StreamController();
    when(() => repo.watchDetail(9)).thenAnswer((_) => stream.stream);
    when(() => repo.moveEntry(any(), any(), any())).thenAnswer((_) async {});
    when(() => repo.rename(any(), any())).thenAnswer((_) async {});
    when(() => repo.delete(any())).thenAnswer((_) async {});
    when(() => repo.removeEntry(any())).thenAnswer((_) async {});
  });

  tearDown(() {
    stream.close();
  });

  PlaylistDetailBloc subscribed(List<String> items) {
    final bloc = PlaylistDetailBloc(playlists: repo)
      ..add(const PlaylistDetailSubscriptionRequested(9));
    stream.add(detailOf(items));
    return bloc;
  }

  blocTest<PlaylistDetailBloc, PlaylistDetailState>(
    'subscription emits ready',
    build: () => subscribed(['A', 'B']),
    expect: () => [PlaylistDetailState(status: PlaylistDetailStatus.ready, detail: detailOf(['A', 'B']))],
  );

  blocTest<PlaylistDetailBloc, PlaylistDetailState>(
    'dragging A down one slot (0→1) reorders optimistically',
    build: () => subscribed(['A', 'B', 'C']),
    act: (b) async {
      await Future<void>.delayed(Duration.zero);
      b.add(const PlaylistDetailEntryMoved(0, 1));
    },
    skip: 1,
    verify: (b) {
      expect(titles(b.state), ['B', 'A', 'C']);
      expect(b.state.detail!.items.map((i) => i.position), [0, 1, 2]);
      verify(() => repo.moveEntry(9, 0, 1)).called(1);
    },
  );

  blocTest<PlaylistDetailBloc, PlaylistDetailState>(
    'dragging C to top (2→0)',
    build: () => subscribed(['A', 'B', 'C']),
    act: (b) async {
      await Future<void>.delayed(Duration.zero);
      b.add(const PlaylistDetailEntryMoved(2, 0));
    },
    skip: 1,
    verify: (b) {
      expect(titles(b.state), ['C', 'A', 'B']);
      verify(() => repo.moveEntry(9, 2, 0)).called(1);
    },
  );

  blocTest<PlaylistDetailBloc, PlaylistDetailState>(
    'dropping in place does nothing',
    build: () => subscribed(['A', 'B']),
    act: (b) async {
      await Future<void>.delayed(Duration.zero);
      b.add(const PlaylistDetailEntryMoved(1, 1));
    },
    skip: 1,
    expect: () => <PlaylistDetailState>[],
    verify: (_) => verifyNever(() => repo.moveEntry(any(), any(), any())),
  );

  blocTest<PlaylistDetailBloc, PlaylistDetailState>(
    'rename calls repository',
    build: () => subscribed(['A']),
    act: (b) async {
      await Future<void>.delayed(Duration.zero);
      b.add(const PlaylistDetailRenamed('X'));
    },
    verify: (_) => verify(() => repo.rename(9, 'X')).called(1),
  );

  blocTest<PlaylistDetailBloc, PlaylistDetailState>(
    'delete emits deleted and stream null afterwards stays deleted',
    build: () => subscribed(['A']),
    act: (b) async {
      await Future<void>.delayed(Duration.zero);
      b.add(const PlaylistDetailDeleted());
      await Future<void>.delayed(Duration.zero);
      stream.add(null);
    },
    skip: 1,
    verify: (b) {
      expect(b.state.status, PlaylistDetailStatus.deleted);
      verify(() => repo.delete(9)).called(1);
    },
  );

  blocTest<PlaylistDetailBloc, PlaylistDetailState>(
    'null from stream without delete → notFound',
    build: () => PlaylistDetailBloc(playlists: repo),
    act: (b) {
      b.add(const PlaylistDetailSubscriptionRequested(9));
      stream.add(null);
    },
    expect: () => [const PlaylistDetailState(status: PlaylistDetailStatus.notFound)],
  );

  blocTest<PlaylistDetailBloc, PlaylistDetailState>(
    'remove entry calls repository',
    build: () => subscribed(['A']),
    act: (b) async {
      await Future<void>.delayed(Duration.zero);
      b.add(const PlaylistDetailEntryRemoved(165));
    },
    verify: (_) => verify(() => repo.removeEntry(165)).called(1),
  );
}
