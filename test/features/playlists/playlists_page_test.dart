import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multi_musics/features/playlists/bloc/playlists_bloc.dart';
import 'package:multi_musics/features/playlists/view/playlists_page.dart';
import 'package:multi_musics/features/playlists/widgets/playlist_cover.dart';

import '../../helpers/pump_app.dart';
import 'playlists_bloc_test.dart' show summary;

class MockPlaylistsBloc extends MockBloc<PlaylistsEvent, PlaylistsState>
    implements PlaylistsBloc {}

void main() {
  late MockPlaylistsBloc bloc;
  int? opened;

  setUp(() {
    bloc = MockPlaylistsBloc();
    opened = null;
  });

  Future<void> pump(WidgetTester tester, PlaylistsState state) {
    when(() => bloc.state).thenReturn(state);
    return pumpApp(
      tester,
      BlocProvider<PlaylistsBloc>.value(
        value: bloc,
        child: PlaylistsPage(onOpen: (id) => opened = id),
      ),
    );
  }

  testWidgets('empty shows empty state with create action', (tester) async {
    await pump(tester, const PlaylistsState(status: PlaylistsStatus.ready));
    expect(find.text('Chưa có playlist'), findsOneWidget);
    expect(find.text('Tạo playlist để gom bài từ nhiều nguồn'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Tạo playlist'), findsOneWidget);
  });

  testWidgets('grid shows one cell per playlist and opens on tap', (tester) async {
    await pump(
      tester,
      PlaylistsState(
        status: PlaylistsStatus.ready,
        playlists: [summary(1, count: 2), summary(2), summary(3)],
      ),
    );
    expect(find.byType(PlaylistCover), findsNWidgets(3));
    expect(find.text('2 bài'), findsOneWidget);
    expect(find.byKey(const ValueKey(1)), findsOneWidget);
    await tester.tap(find.text('P1'));
    expect(opened, 1);
  });

  testWidgets('create dialog sends PlaylistsCreated', (tester) async {
    await pump(tester, const PlaylistsState(status: PlaylistsStatus.ready));
    await tester.tap(find.byTooltip('Tạo playlist'));
    await tester.pumpAndSettle();
    expect(find.text('Playlist mới'), findsOneWidget);
    final create = find.widgetWithText(TextButton, 'Tạo');
    expect(tester.widget<TextButton>(create).onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'Tập gym');
    await tester.pump();
    await tester.tap(create);
    await tester.pumpAndSettle();
    verify(() => bloc.add(const PlaylistsCreated('Tập gym'))).called(1);
  });

  group('PlaylistCover', () {
    testWidgets('4 artworks render a 2x2 grid', (tester) async {
      await pumpApp(
        tester,
        const PlaylistCover(artworks: ['a', 'b', 'c', 'd'], size: 160),
      );
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('fewer than 4 artworks render a single image', (tester) async {
      await pumpApp(tester, const PlaylistCover(artworks: ['a'], size: 160));
      expect(find.byType(GridView), findsNothing);
    });
  });
}
