import 'package:multi_musics/data/db/database.dart';
import 'package:multi_musics/sources/source_type.dart';

Track makeTrack(
  int id, {
  String? title,
  String? artist,
  SourceType source = SourceType.youtube,
  int? durationMs,
  String? unavailableReason,
}) =>
    Track(
      id: id,
      source: source,
      sourceId: 'src$id',
      originalUrl: 'https://example.com/$id',
      title: title ?? 'Track $id',
      artist: artist,
      artworkUrl: null,
      durationMs: durationMs,
      unavailableReason: unavailableReason,
      addedAt: DateTime(2026, 10, 4),
    );
