part of 'playlist_detail_bloc.dart';

sealed class PlaylistDetailEvent extends Equatable {
  const PlaylistDetailEvent();

  @override
  List<Object?> get props => const [];
}

final class PlaylistDetailSubscriptionRequested extends PlaylistDetailEvent {
  const PlaylistDetailSubscriptionRequested(this.playlistId);

  final int playlistId;

  @override
  List<Object?> get props => [playlistId];
}

final class PlaylistDetailRenamed extends PlaylistDetailEvent {
  const PlaylistDetailRenamed(this.name);

  final String name;

  @override
  List<Object?> get props => [name];
}

final class PlaylistDetailDeleted extends PlaylistDetailEvent {
  const PlaylistDetailDeleted();
}

final class PlaylistDetailEntryRemoved extends PlaylistDetailEvent {
  const PlaylistDetailEntryRemoved(this.entryId);

  final int entryId;

  @override
  List<Object?> get props => [entryId];
}

/// Indices from `ReorderableListView.onReorderItem`: `newIndex` is already
/// adjusted for the removed item (same as `list.insert(new, list.removeAt(old))`).
final class PlaylistDetailEntryMoved extends PlaylistDetailEvent {
  const PlaylistDetailEntryMoved(this.oldIndex, this.newIndex);

  final int oldIndex;
  final int newIndex;

  @override
  List<Object?> get props => [oldIndex, newIndex];
}
