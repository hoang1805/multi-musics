import 'dart:io';

import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Lets plugins that cache to disk (cached_network_image) run in widget tests.
class FakePathProvider extends PathProviderPlatform with MockPlatformInterfaceMixin {
  FakePathProvider() : _root = Directory.systemTemp.createTempSync('mm_paths').path;

  final String _root;

  @override
  Future<String?> getTemporaryPath() async => _root;

  @override
  Future<String?> getApplicationSupportPath() async => _root;

  @override
  Future<String?> getApplicationDocumentsPath() async => _root;

  @override
  Future<String?> getApplicationCachePath() async => _root;
}
