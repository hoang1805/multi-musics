part of 'playlists_bloc.dart';

enum PlaylistsStatus { loading, ready }

final class PlaylistsState extends Equatable {
  const PlaylistsState({
    this.status = PlaylistsStatus.loading,
    this.playlists = const [],
  });

  final PlaylistsStatus status;
  final List<PlaylistSummary> playlists;

  @override
  List<Object?> get props => [status, playlists];
}
