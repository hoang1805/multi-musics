import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:multi_musics/core/logging/app_logger.dart';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('logger_test');
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  test('ring buffer drops oldest', () {
    final logger = AppLogger.memory(capacity: 3);
    for (var i = 0; i < 5; i++) {
      logger.info('t', 'msg$i');
    }
    expect(logger.lines, hasLength(3));
    expect(logger.lines.first, contains('msg2'));
    logger.dispose();
  });

  test('flush writes file and open reloads', () async {
    final file = File('${tmp.path}/logs.txt');
    final logger = await AppLogger.open(file);
    logger.info('a', 'first');
    logger.warn('b', 'second');
    await logger.flush();
    final written = List.of(logger.lines);
    logger.dispose();

    final reopened = await AppLogger.open(file);
    expect(reopened.lines, written);
    expect(reopened.lines.last, contains('[W] b: second'));
    reopened.dispose();
  });

  test('open survives a log file cut mid-character', () async {
    final file = File('${tmp.path}/logs.txt');
    // "Mư" with the 2-byte "ư" (C6 B0) truncated after its first byte.
    await file.writeAsBytes([...'2026 [I] t: M'.codeUnits, 0xC6]);
    final logger = await AppLogger.open(file);
    expect(logger.lines, hasLength(1));
    expect(logger.lines.single, startsWith('2026 [I] t: M'));
    logger.dispose();
  });

  test('error includes error text', () {
    final logger = AppLogger.memory();
    logger.error('t', 'm', StateError('boom'));
    expect(logger.lines.single, contains('[E] t: m | Bad state: boom'));
    logger.dispose();
  });

  test('line starts with ISO timestamp', () {
    final logger = AppLogger.memory();
    logger.info('tag', 'hello');
    expect(
      logger.lines.single,
      matches(RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3} \[I\] tag: hello$')),
    );
    logger.dispose();
  });
}
