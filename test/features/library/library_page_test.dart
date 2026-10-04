import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multi_musics/core/widgets/skeleton_list.dart';
import 'package:multi_musics/core/widgets/track_tile.dart';
import 'package:multi_musics/features/library/bloc/library_bloc.dart';
import 'package:multi_musics/features/library/view/library_page.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/pump_app.dart';

class MockLibraryBloc extends MockBloc<LibraryEvent, LibraryState> implements LibraryBloc {}

void main() {
  late MockLibraryBloc bloc;

  setUp(() => bloc = MockLibraryBloc());

  Future<void> pump(WidgetTester tester, LibraryState state) {
    when(() => bloc.state).thenReturn(state);
    return pumpApp(
      tester,
      BlocProvider<LibraryBloc>.value(
        value: bloc,
        child: LibraryPage(onAddPressed: () {}, onAddToPlaylist: (_) {}),
      ),
    );
  }

  testWidgets('loading shows skeleton', (tester) async {
    await pump(tester, const LibraryState());
    expect(find.byType(SkeletonList), findsOneWidget);
  });

  testWidgets('empty library shows empty state', (tester) async {
    await pump(tester, const LibraryState(status: LibraryStatus.ready));
    expect(find.text('Chưa có bài nào'), findsOneWidget);
    expect(
      find.text('Bấm + để dán link từ Spotify, YouTube hoặc SoundCloud'),
      findsOneWidget,
    );
  });

  testWidgets('filter with no match shows message', (tester) async {
    await pump(
      tester,
      LibraryState(status: LibraryStatus.ready, all: [makeTrack(1)], query: 'zzz'),
    );
    expect(find.text('Không có bài nào khớp'), findsOneWidget);
  });

  testWidgets('renders one tile per track with stable keys', (tester) async {
    await pump(
      tester,
      LibraryState(status: LibraryStatus.ready, all: [makeTrack(1), makeTrack(2)]),
    );
    expect(find.byType(TrackTile), findsNWidgets(2));
    expect(find.byKey(const ValueKey(1)), findsOneWidget);
  });

  testWidgets('typing in filter sends LibraryQueryChanged', (tester) async {
    await pump(tester, LibraryState(status: LibraryStatus.ready, all: [makeTrack(1)]));
    await tester.enterText(find.byType(TextField), 'mua');
    verify(() => bloc.add(const LibraryQueryChanged('mua'))).called(1);
  });

  testWidgets('delete asks for confirmation then sends event', (tester) async {
    await pump(tester, LibraryState(status: LibraryStatus.ready, all: [makeTrack(7)]));
    await tester.drag(find.byKey(const ValueKey(7)), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Xóa bài này?'), findsOneWidget);
    expect(find.text('Bài sẽ bị gỡ khỏi mọi playlist.'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Xóa'));
    await tester.pumpAndSettle();
    verify(() => bloc.add(const LibraryTrackDeleted(7))).called(1);
  });
}
