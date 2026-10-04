part of 'playlist_detail_bloc.dart';

enum PlaylistDetailStatus { loading, ready, notFound, deleted }

final class PlaylistDetailState extends Equatable {
  const PlaylistDetailState({
    this.status = PlaylistDetailStatus.loading,
    this.detail,
  });

  final PlaylistDetailStatus status;
  final PlaylistDetail? detail;

  @override
  List<Object?> get props => [status, detail];
}
