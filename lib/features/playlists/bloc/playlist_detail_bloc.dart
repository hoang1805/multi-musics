import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/playlist_models.dart';
import '../../../data/repositories/playlist_repository.dart';

part 'playlist_detail_event.dart';
part 'playlist_detail_state.dart';

class PlaylistDetailBloc extends Bloc<PlaylistDetailEvent, PlaylistDetailState> {
  PlaylistDetailBloc({required this._playlists}) : super(const PlaylistDetailState()) {
    on<PlaylistDetailSubscriptionRequested>(_onSubscribed, transformer: restartable());
    on<PlaylistDetailRenamed>((e, _) => _playlists.rename(_id, e.name));
    on<PlaylistDetailDeleted>(_onDeleted);
    on<PlaylistDetailEntryRemoved>(_onEntryRemoved);
    on<PlaylistDetailEntryMoved>(_onEntryMoved);
  }

  final PlaylistRepository _playlists;
  late int _id;
  bool _deleted = false;

  Future<void> _onSubscribed(
    PlaylistDetailSubscriptionRequested event,
    Emitter<PlaylistDetailState> emit,
  ) {
    _id = event.playlistId;
    return emit.forEach<PlaylistDetail?>(
      _playlists.watchDetail(_id),
      onData: (detail) {
        if (detail != null) {
          return PlaylistDetailState(status: PlaylistDetailStatus.ready, detail: detail);
        }
        return _deleted
            ? state
            : const PlaylistDetailState(status: PlaylistDetailStatus.notFound);
      },
    );
  }

  Future<void> _onDeleted(
    PlaylistDetailDeleted event,
    Emitter<PlaylistDetailState> emit,
  ) async {
    _deleted = true;
    await _playlists.delete(_id);
    emit(PlaylistDetailState(status: PlaylistDetailStatus.deleted, detail: state.detail));
  }

  /// Optimistic: the row leaves immediately, the stream confirms it.
  Future<void> _onEntryRemoved(
    PlaylistDetailEntryRemoved event,
    Emitter<PlaylistDetailState> emit,
  ) async {
    final detail = state.detail;
    if (detail != null) {
      emit(_withItems(detail, [
        for (final item in detail.items)
          if (item.entryId != event.entryId) item,
      ]));
    }
    await _playlists.removeEntry(event.entryId);
  }

  /// Takes `ReorderableListView.onReorderItem` indices (already adjusted).
  Future<void> _onEntryMoved(
    PlaylistDetailEntryMoved event,
    Emitter<PlaylistDetailState> emit,
  ) async {
    final detail = state.detail;
    if (detail == null) return;
    final from = event.oldIndex;
    final to = event.newIndex;
    if (from == to) return;

    final items = List.of(detail.items);
    items.insert(to, items.removeAt(from));
    emit(_withItems(detail, items));
    await _playlists.moveEntry(_id, from, to);
  }

  PlaylistDetailState _withItems(PlaylistDetail detail, List<PlaylistItem> items) {
    return PlaylistDetailState(
      status: state.status,
      detail: PlaylistDetail(
        playlist: detail.playlist,
        items: [
          for (final (i, item) in items.indexed)
            PlaylistItem(entryId: item.entryId, position: i, track: item.track),
        ],
      ),
    );
  }
}
