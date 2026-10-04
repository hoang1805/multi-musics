import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/result.dart';
import '../../../data/db/database.dart';
import '../../../data/repositories/library_writer.dart';
import '../../../data/repositories/playlist_repository.dart';
import '../../../data/repositories/track_repository.dart';
import '../../../sources/link_parser.dart';
import '../../../sources/metadata/metadata_fetcher.dart';
import '../../../sources/metadata/track_draft.dart';

part 'add_track_event.dart';
part 'add_track_state.dart';

class AddTrackBloc extends Bloc<AddTrackEvent, AddTrackState> {
  AddTrackBloc({
    required LinkParser parser,
    required MetadataFetcher metadata,
    required TrackRepository tracks,
    required LibraryWriter writer,
    required PlaylistRepository playlists,
    required AppLogger logger,
  })  : _parser = parser,
        _metadata = metadata,
        _tracks = tracks,
        _writer = writer,
        _playlists = playlists,
        _logger = logger,
        super(const AddTrackState()) {
    // One event at a time: a toggle or confirm must see the finished preview,
    // and a double-tapped confirm must not save twice.
    on<AddTrackEvent>(
      (event, emit) => switch (event) {
        AddTrackLinkSubmitted() => _onSubmitted(event, emit),
        AddTrackPlaylistToggled() => _onToggled(event, emit),
        AddTrackConfirmed() => _onConfirmed(emit),
        AddTrackReset() => emit(const AddTrackState()),
      },
      transformer: sequential(),
    );
  }

  final LinkParser _parser;
  final MetadataFetcher _metadata;
  final TrackRepository _tracks;
  final LibraryWriter _writer;
  final PlaylistRepository _playlists;
  final AppLogger _logger;

  Future<void> _onSubmitted(
    AddTrackLinkSubmitted event,
    Emitter<AddTrackState> emit,
  ) async {
    emit(const AddTrackState(status: AddTrackStatus.resolving));
    final input = event.input.trim();

    final ParsedLink link;
    switch (await _parser.parse(input)) {
      case Ok(:final value):
        link = value;
      case Err(:final failure):
        return _fail(emit, failure, input);
    }

    final existing = await _tracks.findBySource(link.source, link.sourceId);
    if (existing != null) {
      emit(AddTrackState(
        status: AddTrackStatus.preview,
        existing: existing,
        draft: _draftOf(existing),
      ));
      return;
    }

    switch (await _metadata.fetch(link, originalUrl: input)) {
      case Ok(:final value):
        emit(AddTrackState(status: AddTrackStatus.preview, draft: value));
      case Err(:final failure):
        _fail(emit, failure, input);
    }
  }

  void _onToggled(AddTrackPlaylistToggled event, Emitter<AddTrackState> emit) {
    if (state.status != AddTrackStatus.preview) return;
    final selected = Set.of(state.selectedPlaylistIds);
    if (!selected.remove(event.playlistId)) selected.add(event.playlistId);
    emit(AddTrackState(
      status: state.status,
      draft: state.draft,
      existing: state.existing,
      selectedPlaylistIds: selected,
    ));
  }

  Future<void> _onConfirmed(Emitter<AddTrackState> emit) async {
    final draft = state.draft;
    if (state.status != AddTrackStatus.preview || draft == null) return;
    final existing = state.existing;
    final selected = state.selectedPlaylistIds.toList();
    emit(AddTrackState(
      status: AddTrackStatus.saving,
      draft: draft,
      existing: existing,
      selectedPlaylistIds: state.selectedPlaylistIds,
    ));
    try {
      final Track saved;
      if (existing != null) {
        if (selected.isNotEmpty) await _playlists.addTrackToPlaylists(existing.id, selected);
        saved = existing;
      } else {
        saved = await _writer.addToLibrary(draft, playlistIds: selected);
      }
      _logger.info('add-track', 'saved ${saved.source.name}:${saved.sourceId} '
          'to ${selected.length} playlist(s)');
      emit(AddTrackState(status: AddTrackStatus.done, draft: draft, saved: saved));
    } on Object catch (e, st) {
      _logger.error('add-track', 'save failed', e, st);
      emit(AddTrackState(
        status: AddTrackStatus.failure,
        draft: draft,
        existing: existing,
        failure: UnknownFailure(e, st),
      ));
    }
  }

  void _fail(Emitter<AddTrackState> emit, Failure failure, String input) {
    _logger.warn('add-track', '${failure.runtimeType} for "$input"');
    emit(AddTrackState(status: AddTrackStatus.failure, failure: failure));
  }

  static TrackDraft _draftOf(Track t) => TrackDraft(
        source: t.source,
        sourceId: t.sourceId,
        originalUrl: t.originalUrl,
        title: t.title,
        artist: t.artist,
        artworkUrl: t.artworkUrl,
        durationMs: t.durationMs,
      );
}
