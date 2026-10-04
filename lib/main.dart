import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'core/logging/app_logger.dart';

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

    runApp(const MaterialApp(home: Scaffold()));
  }, (error, stack) {
    logger.error('crash', 'Zone', error, stack);
  });
}
