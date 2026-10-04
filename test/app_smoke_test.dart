import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_musics/app.dart';
import 'package:multi_musics/app_dependencies.dart';
import 'package:multi_musics/core/logging/app_logger.dart';
import 'package:multi_musics/core/widgets/track_tile.dart';

import 'helpers/test_database.dart';

void main() {
  testWidgets('demo app: library, playlists tab, playlist detail', (tester) async {
    // iPhone XS Max logical size.
    tester.view.physicalSize = const Size(1242, 2688);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final deps = (await tester.runAsync(() async {
      final deps = await AppDependencies.create(
        fake: true,
        logger: AppLogger.memory(),
        db: openTestDatabase(),
      );
      // No network images in tests: the image cache needs platform plugins
      // (sqflite on macOS/iOS) that do not exist under flutter_test.
      await deps.db.customStatement('UPDATE tracks SET artwork_url = NULL');
      return deps;
    }))!;

    Future<void> settle() async {
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    await tester.pumpWidget(MultiMusicsApp(deps));
    await settle();

    expect(find.text('Thư viện'), findsWidgets);
    expect(find.byType(TrackTile), findsWidgets);

    await tester.tap(find.text('Playlist').last);
    await settle();
    expect(find.text('Chill tối'), findsOneWidget);

    await tester.tap(find.text('Chill tối'));
    await settle();
    expect(find.textContaining(RegExp(r'^\d+ bài · ')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    // Let drift's stream-cleanup timers (fake zone) fire before closing the
    // database, otherwise close() waits forever.
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(deps.dispose);
  });
}
