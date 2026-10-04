import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/playlist_models.dart';
import '../../../data/repositories/playlist_repository.dart';

part 'playlists_event.dart';
part 'playlists_state.dart';

class PlaylistsBloc extends Bloc<PlaylistsEvent, PlaylistsState> {
  PlaylistsBloc({required this._playlists}) : super(const PlaylistsState()) {
    on<PlaylistsSubscriptionRequested>(_onSubscribed, transformer: restartable());
    on<PlaylistsCreated>(_onCreated);
    on<PlaylistsTrackAdded>(
      (e, _) => _playlists.addTrackToPlaylists(e.trackId, e.playlistIds),
    );
  }

  final PlaylistRepository _playlists;

  Future<void> _onSubscribed(
    PlaylistsSubscriptionRequested event,
    Emitter<PlaylistsState> emit,
  ) {
    return emit.forEach<List<PlaylistSummary>>(
      _playlists.watchAll(),
      onData: (list) => PlaylistsState(status: PlaylistsStatus.ready, playlists: list),
    );
  }

  Future<void> _onCreated(PlaylistsCreated event, Emitter<PlaylistsState> emit) async {
    final name = event.name.trim();
    if (name.isEmpty) return;
    await _playlists.create(name);
  }
}
