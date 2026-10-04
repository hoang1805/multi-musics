import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:multi_musics/data/db/database.dart';

AppDatabase openTestDatabase() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}
