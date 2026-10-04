import 'package:flutter_test/flutter_test.dart';
import 'package:multi_musics/core/widgets/source_badge.dart';
import 'package:multi_musics/sources/source_type.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('exposes source name to screen readers', (tester) async {
    await pumpApp(tester, const SourceBadge(source: SourceType.youtube));
    expect(find.bySemanticsLabel('YouTube'), findsOneWidget);
    expect(find.text('YouTube'), findsNothing);
  });

  testWidgets('shows label when requested', (tester) async {
    await pumpApp(
      tester,
      const SourceBadge(source: SourceType.soundcloud, showLabel: true),
    );
    expect(find.text('SoundCloud'), findsOneWidget);
  });
}
