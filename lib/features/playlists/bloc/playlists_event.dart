part of 'playlists_bloc.dart';

sealed class PlaylistsEvent extends Equatable {
  const PlaylistsEvent();

  @override
  List<Object?> get props => const [];
}

final class PlaylistsSubscriptionRequested extends PlaylistsEvent {
  const PlaylistsSubscriptionRequested();
}

final class PlaylistsCreated extends PlaylistsEvent {
  const PlaylistsCreated(this.name);

  final String name;

  @override
  List<Object?> get props => [name];
}

final class PlaylistsTrackAdded extends PlaylistsEvent {
  const PlaylistsTrackAdded(this.trackId, this.playlistIds);

  final int trackId;
  final List<int> playlistIds;

  @override
  List<Object?> get props => [trackId, playlistIds];
}
