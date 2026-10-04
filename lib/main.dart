import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'app_dependencies.dart';
import 'core/logging/app_logger.dart';

const _fakeSources = bool.fromEnvironment('FAKE_SOURCES');

Future<void> main() async {
  late final AppLogger logger;

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    final supportDir = await getApplicationSupportDirectory();
    logger = await AppLogger.open(File('${supportDir.path}/logs.txt'));
    logger.info('app', 'start');

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      logger.error('crash', 'FlutterError', details.exception, details.stack);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      logger.error('crash', 'PlatformDispatcher', error, stack);
      return true;
    };
    AppLifecycleListener(onPause: () => unawaited(logger.flush()));

    final deps = await AppDependencies.create(fake: _fakeSources, logger: logger);
    runApp(MultiMusicsApp(deps));
  }, (error, stack) {
    logger.error('crash', 'Zone', error, stack);
  });
}
