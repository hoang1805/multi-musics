import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multi_musics/core/widgets/track_tile.dart';
import 'package:multi_musics/data/models/playlist_models.dart';
import 'package:multi_musics/features/playlists/bloc/playlist_detail_bloc.dart';
import 'package:multi_musics/features/playlists/view/playlist_detail_page.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/pump_app.dart';
import 'playlist_detail_bloc_test.dart' show playlist;

class MockPlaylistDetailBloc extends MockBloc<PlaylistDetailEvent, PlaylistDetailState>
    implements PlaylistDetailBloc {}

void main() {
  late MockPlaylistDetailBloc bloc;

  setUp(() => bloc = MockPlaylistDetailBloc());

  Future<void> pump(WidgetTester tester, PlaylistDetailState state) {
    when(() => bloc.state).thenReturn(state);
    return pumpApp(
      tester,
      BlocProvider<PlaylistDetailBloc>.value(value: bloc, child: const PlaylistDetailView()),
    );
  }

  testWidgets('header shows count and known duration', (tester) async {
    await pump(
      tester,
      PlaylistDetailState(
        status: PlaylistDetailStatus.ready,
        detail: PlaylistDetail(playlist: playlist, items: [
          PlaylistItem(entryId: 1, position: 0, track: makeTrack(1, durationMs: 300000)),
          PlaylistItem(entryId: 2, position: 1, track: makeTrack(2, durationMs: 420000)),
          PlaylistItem(entryId: 3, position: 2, track: makeTrack(3)),
        ]),
      ),
    );
    expect(find.text('Chill'), findsOneWidget);
    expect(find.text('3 bài · 12 phút'), findsOneWidget);
    expect(find.byType(TrackTile), findsNWidgets(3));
    expect(find.byKey(const ValueKey(2)), findsOneWidget);
  });

  testWidgets('unknown durations are not shown as "0 phút"', (tester) async {
    await pump(
      tester,
      PlaylistDetailState(
        status: PlaylistDetailStatus.ready,
        detail: PlaylistDetail(playlist: playlist, items: [
          PlaylistItem(entryId: 1, position: 0, track: makeTrack(1)),
        ]),
      ),
    );
    expect(find.text('1 bài'), findsOneWidget);
    expect(find.textContaining('phút'), findsNothing);
  });

  testWidgets('empty playlist fits at the largest text size on iPhone', (tester) async {
    tester.view.physicalSize = const Size(1242, 2688);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    when(() => bloc.state).thenReturn(PlaylistDetailState(
      status: PlaylistDetailStatus.ready,
      detail: PlaylistDetail(playlist: playlist, items: const []),
    ));
    await pumpApp(
      tester,
      BlocProvider<PlaylistDetailBloc>.value(value: bloc, child: const PlaylistDetailView()),
      textScale: 3.1,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty playlist shows empty state', (tester) async {
    await pump(
      tester,
      PlaylistDetailState(
        status: PlaylistDetailStatus.ready,
        detail: PlaylistDetail(playlist: playlist, items: const []),
      ),
    );
    expect(find.text('Playlist trống'), findsOneWidget);
    expect(find.text('Thêm bài từ tab Thư viện'), findsOneWidget);
  });

  testWidgets('rename from menu sends PlaylistDetailRenamed', (tester) async {
    await pump(
      tester,
      PlaylistDetailState(
        status: PlaylistDetailStatus.ready,
        detail: PlaylistDetail(playlist: playlist, items: const []),
      ),
    );
    await tester.tap(find.byTooltip('Tùy chọn'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đổi tên'));
    await tester.pumpAndSettle();
    expect(find.text('Đổi tên playlist'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Chill 2');
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Lưu'));
    await tester.pumpAndSettle();
    verify(() => bloc.add(const PlaylistDetailRenamed('Chill 2'))).called(1);
  });

  testWidgets('delete from menu asks then sends PlaylistDetailDeleted', (tester) async {
    await pump(
      tester,
      PlaylistDetailState(
        status: PlaylistDetailStatus.ready,
        detail: PlaylistDetail(playlist: playlist, items: const []),
      ),
    );
    await tester.tap(find.byTooltip('Tùy chọn'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa playlist'));
    await tester.pumpAndSettle();
    expect(find.text('Xóa playlist "Chill"?'), findsOneWidget);
    expect(find.text('Các bài vẫn còn trong thư viện.'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Xóa'));
    await tester.pumpAndSettle();
    verify(() => bloc.add(const PlaylistDetailDeleted())).called(1);
  });
}
