import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:multi_musics/core/widgets/track_tile.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/pump_app.dart';

void main() {
  testWidgets('very long title at 2x text scale does not overflow', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpApp(
      tester,
      TrackTile(track: makeTrack(1, title: 'Mưa ' * 50, artist: 'Nghệ sĩ ' * 20)),
      textScale: 2.0,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows warning icon for unavailable track', (tester) async {
    await pumpApp(tester, TrackTile(track: makeTrack(1, unavailableReason: 'Đã xóa')));
    expect(find.byIcon(LucideIcons.triangleAlert), findsOneWidget);
  });

  testWidgets('shows known duration and source label', (tester) async {
    await pumpApp(tester, TrackTile(track: makeTrack(1, durationMs: 185000)));
    expect(find.textContaining('3:05'), findsOneWidget);
    // InkWell merges the row into one semantics node; the source is part of it.
    expect(find.bySemanticsLabel(RegExp('YouTube')), findsOneWidget);
    expect(find.byIcon(LucideIcons.triangleAlert), findsNothing);
  });

  testWidgets('calls onTap', (tester) async {
    var tapped = false;
    await pumpApp(tester, TrackTile(track: makeTrack(1), onTap: () => tapped = true));
    await tester.tap(find.byType(TrackTile));
    expect(tapped, isTrue);
  });
}
