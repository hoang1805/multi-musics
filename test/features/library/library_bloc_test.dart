import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multi_musics/data/db/database.dart';
import 'package:multi_musics/data/repositories/track_repository.dart';
import 'package:multi_musics/features/library/bloc/library_bloc.dart';
import 'package:multi_musics/sources/source_type.dart';

import '../../helpers/fixtures.dart';

class MockTrackRepository extends Mock implements TrackRepository {}

void main() {
  late MockTrackRepository repo;
  late StreamController<List<Track>> tracks;

  final mua = makeTrack(1, title: 'Mưa Tháng Sáu', artist: 'Văn Mai Hương');
  final dem = makeTrack(2, title: 'Đêm Trăng', source: SourceType.soundcloud);
  final rick = makeTrack(3, title: 'Never Gonna', artist: 'Rick', source: SourceType.spotify);

  setUp(() {
    repo = MockTrackRepository();
    tracks = StreamController<List<Track>>();
    when(() => repo.watchAll()).thenAnswer((_) => tracks.stream);
    when(() => repo.delete(any())).thenAnswer((_) async {});
  });

  // close() never completes on a never-listened controller; do not await it.
  tearDown(() {
    tracks.close();
  });

  LibraryBloc subscribed() {
    final bloc = LibraryBloc(tracks: repo)..add(const LibrarySubscriptionRequested());
    tracks.add([mua, dem, rick]);
    return bloc;
  }

  blocTest<LibraryBloc, LibraryState>(
    'subscription emits ready with all tracks',
    build: () => LibraryBloc(tracks: repo),
    act: (b) {
      b.add(const LibrarySubscriptionRequested());
      tracks.add([mua, dem]);
    },
    expect: () => [LibraryState(status: LibraryStatus.ready, all: [mua, dem])],
  );

  test('initial state is loading', () {
    expect(LibraryBloc(tracks: repo).state.status, LibraryStatus.loading);
  });

  blocTest<LibraryBloc, LibraryState>(
    '"mua" finds "Mưa" (diacritic-insensitive)',
    build: subscribed,
    act: (b) => b.add(const LibraryQueryChanged('mua')),
    skip: 1,
    verify: (b) => expect(b.state.visible, [mua]),
  );

  blocTest<LibraryBloc, LibraryState>(
    '"dem" finds "Đêm"',
    build: subscribed,
    act: (b) => b.add(const LibraryQueryChanged('  DEM ')),
    skip: 1,
    verify: (b) => expect(b.state.visible, [dem]),
  );

  blocTest<LibraryBloc, LibraryState>(
    'query matches artist too',
    build: subscribed,
    act: (b) => b.add(const LibraryQueryChanged('huong')),
    skip: 1,
    verify: (b) => expect(b.state.visible, [mua]),
  );

  blocTest<LibraryBloc, LibraryState>(
    'source toggle filters, toggling again shows all',
    build: subscribed,
    act: (b) => b.add(const LibrarySourceToggled(SourceType.soundcloud)),
    skip: 1,
    verify: (b) => expect(b.state.visible, [dem]),
  );

  blocTest<LibraryBloc, LibraryState>(
    'toggling the same source twice clears the filter',
    build: subscribed,
    act: (b) => b
      ..add(const LibrarySourceToggled(SourceType.soundcloud))
      ..add(const LibrarySourceToggled(SourceType.soundcloud)),
    skip: 2,
    verify: (b) => expect(b.state.visible, [mua, dem, rick]),
  );

  blocTest<LibraryBloc, LibraryState>(
    'delete calls repository',
    build: subscribed,
    act: (b) => b.add(const LibraryTrackDeleted(2)),
    verify: (_) => verify(() => repo.delete(2)).called(1),
  );
}
