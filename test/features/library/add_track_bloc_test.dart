import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multi_musics/core/failure.dart';
import 'package:multi_musics/core/logging/app_logger.dart';
import 'package:multi_musics/core/result.dart';
import 'package:multi_musics/data/db/database.dart';
import 'package:multi_musics/data/repositories/library_writer.dart';
import 'package:multi_musics/data/repositories/playlist_repository.dart';
import 'package:multi_musics/data/repositories/track_repository.dart';
import 'package:multi_musics/features/library/bloc/add_track_bloc.dart';
import 'package:multi_musics/sources/link_parser.dart';
import 'package:multi_musics/sources/metadata/metadata_fetcher.dart';
import 'package:multi_musics/sources/metadata/track_draft.dart';
import 'package:multi_musics/sources/source_type.dart';

import '../../helpers/test_database.dart';

class MockMetadataFetcher extends Mock implements MetadataFetcher {}

const ytLink = ParsedLink(
  source: SourceType.youtube,
  sourceId: 'dQw4w9WgXcQ',
  canonicalUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
);

const ytDraft = TrackDraft(
  source: SourceType.youtube,
  sourceId: 'dQw4w9WgXcQ',
  originalUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
  title: 'Never Gonna Give You Up',
  artist: 'Rick Astley',
);

void main() {
  late AppDatabase db;
  late TrackRepository tracks;
  late PlaylistRepository playlists;
  late LibraryWriter writer;
  late MockMetadataFetcher metadata;
  late AppLogger logger;

  setUpAll(() => registerFallbackValue(ytLink));

  setUp(() {
    db = openTestDatabase();
    tracks = TrackRepository(db);
    playlists = PlaylistRepository(db);
    writer = LibraryWriter(db, tracks, playlists);
    metadata = MockMetadataFetcher();
    logger = AppLogger.memory();
    when(() => metadata.fetch(any(), originalUrl: any(named: 'originalUrl')))
        .thenAnswer((_) async => const Ok(ytDraft));
  });

  tearDown(() async {
    logger.dispose();
    await db.close();
  });

  AddTrackBloc build() => AddTrackBloc(
        parser: LinkParser(httpClient: MockClient((_) async => throw StateError('offline'))),
        metadata: metadata,
        tracks: tracks,
        writer: writer,
        playlists: playlists,
        logger: logger,
      );

  blocTest<AddTrackBloc, AddTrackState>(
    'valid new link → resolving, preview(draft)',
    build: build,
    act: (b) => b.add(const AddTrackLinkSubmitted('  https://youtu.be/dQw4w9WgXcQ?si=x ')),
    expect: () => [
      const AddTrackState(status: AddTrackStatus.resolving),
      const AddTrackState(status: AddTrackStatus.preview, draft: ytDraft),
    ],
    verify: (_) => verify(
      () => metadata.fetch(ytLink, originalUrl: 'https://youtu.be/dQw4w9WgXcQ?si=x'),
    ).called(1),
  );

  blocTest<AddTrackBloc, AddTrackState>(
    'invalid link → failure(InvalidLink), metadata not called',
    build: build,
    act: (b) => b.add(const AddTrackLinkSubmitted('hello')),
    expect: () => [
      const AddTrackState(status: AddTrackStatus.resolving),
      const AddTrackState(status: AddTrackStatus.failure, failure: InvalidLink()),
    ],
    verify: (_) {
      verifyNever(() => metadata.fetch(any(), originalUrl: any(named: 'originalUrl')));
      expect(logger.lines.single, contains('add-track'));
    },
  );

  blocTest<AddTrackBloc, AddTrackState>(
    'empty clipboard → failure(InvalidLink)',
    build: build,
    act: (b) => b.add(const AddTrackLinkSubmitted('')),
    expect: () => [
      const AddTrackState(status: AddTrackStatus.resolving),
      const AddTrackState(status: AddTrackStatus.failure, failure: InvalidLink()),
    ],
  );

  group('existing track (different URL form of the same video)', () {
    late Track existing;

    blocTest<AddTrackBloc, AddTrackState>(
      'youtu.be link resolves to the watch?v= track already saved',
      setUp: () async {
        existing = await tracks.insert(ytDraft);
      },
      build: build,
      act: (b) => b.add(const AddTrackLinkSubmitted('https://youtu.be/dQw4w9WgXcQ')),
      expect: () => [
        const AddTrackState(status: AddTrackStatus.resolving),
        isA<AddTrackState>()
            .having((s) => s.status, 'status', AddTrackStatus.preview)
            .having((s) => s.existing?.id, 'existing.id', existing.id)
            .having((s) => s.draft?.title, 'draft.title', ytDraft.title),
      ],
      verify: (_) =>
          verifyNever(() => metadata.fetch(any(), originalUrl: any(named: 'originalUrl'))),
    );
  });

  blocTest<AddTrackBloc, AddTrackState>(
    'metadata failure → failure(NetworkFailure)',
    setUp: () {
      when(() => metadata.fetch(any(), originalUrl: any(named: 'originalUrl')))
          .thenAnswer((_) async => const Err(NetworkFailure()));
    },
    build: build,
    act: (b) => b.add(const AddTrackLinkSubmitted('https://youtu.be/dQw4w9WgXcQ')),
    expect: () => [
      const AddTrackState(status: AddTrackStatus.resolving),
      const AddTrackState(status: AddTrackStatus.failure, failure: NetworkFailure()),
    ],
  );

  blocTest<AddTrackBloc, AddTrackState>(
    'unexpected exception → failure(UnknownFailure), never stuck in resolving',
    setUp: () {
      when(() => metadata.fetch(any(), originalUrl: any(named: 'originalUrl')))
          .thenThrow(StateError('boom'));
    },
    build: build,
    act: (b) => b.add(const AddTrackLinkSubmitted('https://youtu.be/dQw4w9WgXcQ')),
    expect: () => [
      const AddTrackState(status: AddTrackStatus.resolving),
      isA<AddTrackState>()
          .having((s) => s.status, 'status', AddTrackStatus.failure)
          .having((s) => s.failure, 'failure', isA<UnknownFailure>()),
    ],
  );

  blocTest<AddTrackBloc, AddTrackState>(
    'toggle twice removes selection',
    build: build,
    seed: () => const AddTrackState(status: AddTrackStatus.preview, draft: ytDraft),
    act: (b) => b
      ..add(const AddTrackPlaylistToggled(1))
      ..add(const AddTrackPlaylistToggled(1)),
    expect: () => [
      const AddTrackState(
        status: AddTrackStatus.preview,
        draft: ytDraft,
        selectedPlaylistIds: {1},
      ),
      const AddTrackState(status: AddTrackStatus.preview, draft: ytDraft),
    ],
  );

  blocTest<AddTrackBloc, AddTrackState>(
    'toggle ignored outside preview',
    build: build,
    act: (b) => b.add(const AddTrackPlaylistToggled(1)),
    expect: () => <AddTrackState>[],
  );

  test('confirm new track with playlists saves track and entries', () async {
    final p1 = await playlists.create('One');
    final p2 = await playlists.create('Two');
    final bloc = build();
    bloc
      ..add(const AddTrackLinkSubmitted('https://youtu.be/dQw4w9WgXcQ'))
      ..add(AddTrackPlaylistToggled(p1.id))
      ..add(AddTrackPlaylistToggled(p2.id))
      ..add(const AddTrackConfirmed());
    final done = await bloc.stream.firstWhere((s) => s.status == AddTrackStatus.done);
    expect(done.saved?.title, ytDraft.title);
    for (final p in [p1, p2]) {
      final detail = await playlists.watchDetail(p.id).first;
      expect(detail!.items.single.track.id, done.saved!.id);
    }
    await bloc.close();
  });

  test('confirm existing track without playlists adds nothing', () async {
    final existing = await tracks.insert(ytDraft);
    final p1 = await playlists.create('One');
    final bloc = build();
    bloc
      ..add(const AddTrackLinkSubmitted('https://youtu.be/dQw4w9WgXcQ'))
      ..add(const AddTrackConfirmed());
    final states = await bloc.stream.take(4).toList();
    expect(states.map((s) => s.status), [
      AddTrackStatus.resolving,
      AddTrackStatus.preview,
      AddTrackStatus.saving,
      AddTrackStatus.done,
    ]);
    expect(states.last.saved?.id, existing.id);
    expect((await playlists.watchDetail(p1.id).first)!.items, isEmpty);
    await bloc.close();
  });

  blocTest<AddTrackBloc, AddTrackState>(
    'resubmit clears previous selection',
    build: build,
    seed: () => const AddTrackState(
      status: AddTrackStatus.preview,
      draft: ytDraft,
      selectedPlaylistIds: {1, 2},
    ),
    act: (b) => b.add(const AddTrackLinkSubmitted('https://youtu.be/dQw4w9WgXcQ')),
    expect: () => [
      const AddTrackState(status: AddTrackStatus.resolving),
      const AddTrackState(status: AddTrackStatus.preview, draft: ytDraft),
    ],
  );

  blocTest<AddTrackBloc, AddTrackState>(
    'reset returns to idle',
    build: build,
    seed: () => const AddTrackState(status: AddTrackStatus.preview, draft: ytDraft),
    act: (b) => b.add(const AddTrackReset()),
    expect: () => [const AddTrackState()],
  );
}
