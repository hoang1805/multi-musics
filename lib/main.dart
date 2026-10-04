import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'app_dependencies.dart';
import 'core/logging/app_logger.dart';
import 'core/theme/app_theme.dart';

const _fakeSources = bool.fromEnvironment('FAKE_SOURCES');

Future<void> main() async {
  // Nullable: the zone handler can fire before the logger exists.
  AppLogger? logger;

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    final log = await _openLogger();
    logger = log;
    log.info('app', 'start');

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      log.error('crash', 'FlutterError', details.exception, details.stack);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      log.error('crash', 'PlatformDispatcher', error, stack);
      return true;
    };
    AppLifecycleListener(onPause: () => unawaited(log.flush()));

    try {
      final deps = await AppDependencies.create(fake: _fakeSources, logger: log);
      runApp(MultiMusicsApp(deps));
    } on Object catch (e, st) {
      log.error('app', 'startup failed', e, st);
      await log.flush();
      runApp(_StartupErrorApp(error: e));
    }
  }, (error, stack) {
    logger?.error('crash', 'Zone', error, stack);
  });
}

Future<AppLogger> _openLogger() async {
  try {
    final supportDir = await getApplicationSupportDirectory();
    return await AppLogger.open(File('${supportDir.path}/logs.txt'));
  } on Object {
    return AppLogger.memory();
  }
}

/// Shown instead of a blank screen when the app cannot start.
class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.dark(),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Không khởi động được', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                SelectableText('$error'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
