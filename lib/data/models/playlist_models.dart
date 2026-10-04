import 'package:equatable/equatable.dart';

import '../db/database.dart';

class PlaylistSummary extends Equatable {
  const PlaylistSummary({
    required this.playlist,
    required this.trackCount,
    required this.coverArtworks,
  });

  final Playlist playlist;
  final int trackCount;

  /// Up to 4 non-null artwork URLs, in playlist order.
  final List<String> coverArtworks;

  @override
  List<Object?> get props => [playlist, trackCount, coverArtworks];
}

class PlaylistItem extends Equatable {
  const PlaylistItem({
    required this.entryId,
    required this.position,
    required this.track,
  });

  final int entryId;
  final int position;
  final Track track;

  @override
  List<Object?> get props => [entryId, position, track];
}

class PlaylistDetail extends Equatable {
  const PlaylistDetail({required this.playlist, required this.items});

  final Playlist playlist;
  final List<PlaylistItem> items;

  /// Sum of the durations that are known; unknown ones are skipped.
  Duration get knownDuration => Duration(
        milliseconds: items.fold(0, (sum, i) => sum + (i.track.durationMs ?? 0)),
      );

  @override
  List<Object?> get props => [playlist, items];
}
