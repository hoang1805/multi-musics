import 'dart:async';
import 'dart:collection';
import 'dart:io';

enum LogLevel {
  info('I'),
  warn('W'),
  error('E');

  const LogLevel(this.symbol);

  final String symbol;
}

class LogLine {
  const LogLine({
    required this.time,
    required this.level,
    required this.tag,
    required this.message,
    this.error,
    this.stackTrace,
  });

  final DateTime time;
  final LogLevel level;
  final String tag;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  /// `2026-10-04T22:48:47.123 [I] tag: message | error`, then the stack trace
  /// on following lines indented by two spaces.
  String format() {
    final buffer = StringBuffer()
      ..write(_timestamp(time))
      ..write(' [${level.symbol}] $tag: $message');
    if (error != null) buffer.write(' | $error');
    if (stackTrace != null) {
      for (final frame in stackTrace.toString().trimRight().split('\n')) {
        buffer.write('\n  $frame');
      }
    }
    return buffer.toString();
  }

  static String _timestamp(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    final ms = t.millisecond.toString().padLeft(3, '0');
    return '${t.year.toString().padLeft(4, '0')}-${two(t.month)}-${two(t.day)}'
        'T${two(t.hour)}:${two(t.minute)}:${two(t.second)}.$ms';
  }
}

/// Ring buffer of the most recent log records, optionally persisted to a file
/// so they can be read from the in-app log screen (there is no Xcode console).
class AppLogger {
  AppLogger._(this._file, this._capacity, Iterable<String> initial) {
    _records.addAll(initial);
    _trim();
    if (_file != null) {
      _timer = Timer.periodic(const Duration(seconds: 2), (_) {
        if (_dirty) unawaited(flush());
      });
    }
  }

  AppLogger.memory({int capacity = 500}) : this._(null, capacity, const []);

  static Future<AppLogger> open(File file, {int capacity = 500}) async {
    final initial = await file.exists()
        ? _parseRecords(await file.readAsString())
        : const <String>[];
    return AppLogger._(file, capacity, initial);
  }

  final File? _file;
  final int _capacity;
  final ListQueue<String> _records = ListQueue();
  Timer? _timer;
  bool _dirty = false;

  List<String> get lines => List.unmodifiable(_records);

  void info(String tag, String message) => _add(LogLevel.info, tag, message);

  void warn(String tag, String message) => _add(LogLevel.warn, tag, message);

  void error(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) =>
      _add(LogLevel.error, tag, message, error, stackTrace);

  Future<void> flush() async {
    final file = _file;
    if (file == null) return;
    _dirty = false;
    await file.parent.create(recursive: true);
    await file.writeAsString(_records.join('\n'), flush: true);
  }

  Future<void> clear() async {
    _records.clear();
    _dirty = true;
    await flush();
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  void _add(
    LogLevel level,
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    _records.add(LogLine(
      time: DateTime.now(),
      level: level,
      tag: tag,
      message: message,
      error: error,
      stackTrace: stackTrace,
    ).format());
    _trim();
    _dirty = true;
  }

  void _trim() {
    while (_records.length > _capacity) {
      _records.removeFirst();
    }
  }

  /// Lines indented by two spaces continue the previous record (stack frames).
  static List<String> _parseRecords(String content) {
    final records = <String>[];
    for (final line in content.split('\n')) {
      if (line.isEmpty) continue;
      if (line.startsWith('  ') && records.isNotEmpty) {
        records[records.length - 1] = '${records.last}\n$line';
      } else {
        records.add(line);
      }
    }
    return records;
  }
}
