import 'package:equatable/equatable.dart';

import '../source_type.dart';

/// A track's metadata before it is saved to the library.
class TrackDraft extends Equatable {
  const TrackDraft({
    required this.source,
    required this.sourceId,
    required this.originalUrl,
    required this.title,
    this.artist,
    this.artworkUrl,
    this.durationMs,
  });

  final SourceType source;
  final String sourceId;
  final String originalUrl;
  final String title;
  final String? artist;
  final String? artworkUrl;
  final int? durationMs;

  @override
  List<Object?> get props =>
      [source, sourceId, originalUrl, title, artist, artworkUrl, durationMs];
}
