import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_musics/core/theme/app_theme.dart';

Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  double textScale = 1,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(body: child),
        ),
      ),
    ),
  );
}
