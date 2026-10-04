import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multi_musics/core/failure.dart';
import 'package:multi_musics/data/db/database.dart';
import 'package:multi_musics/data/models/playlist_models.dart';
import 'package:multi_musics/features/library/bloc/add_track_bloc.dart';
import 'package:multi_musics/features/library/view/add_track_sheet.dart';
import 'package:multi_musics/sources/metadata/track_draft.dart';
import 'package:multi_musics/sources/source_type.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/pump_app.dart';

class MockAddTrackBloc extends MockBloc<AddTrackEvent, AddTrackState>
    implements AddTrackBloc {}

const draft = TrackDraft(
  source: SourceType.youtube,
  sourceId: 'dQw4w9WgXcQ',
  originalUrl: 'https://youtu.be/dQw4w9WgXcQ',
  title: 'Never Gonna Give You Up',
  artist: 'Rick Astley',
);

final playlists = [
  PlaylistSummary(
    playlist: Playlist(
      id: 11,
      name: 'Chill tối',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    ),
    trackCount: 0,
    coverArtworks: const [],
  ),
];

void main() {
  late MockAddTrackBloc bloc;

  setUp(() => bloc = MockAddTrackBloc());

  Future<void> pump(WidgetTester tester, AddTrackState state) {
    when(() => bloc.state).thenReturn(state);
    return pumpApp(
      tester,
      BlocProvider<AddTrackBloc>.value(
        value: bloc,
        child: SingleChildScrollView(child: AddTrackSheetView(playlists: playlists)),
      ),
    );
  }

  testWidgets('idle shows paste button and paste-permission hint', (tester) async {
    await pump(tester, const AddTrackState());
    expect(find.text('Thêm bài'), findsOneWidget);
    expect(find.text('Dán link'), findsOneWidget);
    expect(find.textContaining('Dán từ app khác → Cho phép'), findsOneWidget);
  });

  testWidgets('failure shows message inline', (tester) async {
    await pump(
      tester,
      const AddTrackState(status: AddTrackStatus.failure, failure: UnsupportedLink()),
    );
    expect(
      find.text('Bản này chưa hỗ trợ playlist/album — hãy dán link 1 bài'),
      findsOneWidget,
    );
  });

  testWidgets('existing track: chip, "Đóng", toggling a playlist', (tester) async {
    await pump(
      tester,
      AddTrackState(status: AddTrackStatus.preview, draft: draft, existing: makeTrack(1)),
    );
    expect(find.text('Đã có trong thư viện'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Đóng'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey(11)));
    verify(() => bloc.add(const AddTrackPlaylistToggled(11))).called(1);
  });

  testWidgets('existing track with selection shows "Lưu"', (tester) async {
    await pump(
      tester,
      AddTrackState(
        status: AddTrackStatus.preview,
        draft: draft,
        existing: makeTrack(1),
        selectedPlaylistIds: const {11},
      ),
    );
    expect(find.widgetWithText(FilledButton, 'Lưu'), findsOneWidget);
  });

  testWidgets('new track: "Thêm" confirms', (tester) async {
    await pump(tester, const AddTrackState(status: AddTrackStatus.preview, draft: draft));
    expect(find.text('Never Gonna Give You Up'), findsOneWidget);
    expect(find.text('Đã có trong thư viện'), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, 'Thêm'));
    verify(() => bloc.add(const AddTrackConfirmed())).called(1);
  });
}
