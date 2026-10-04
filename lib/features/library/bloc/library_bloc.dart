import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/text/fold_vietnamese.dart';
import '../../../data/db/database.dart';
import '../../../data/repositories/track_repository.dart';
import '../../../sources/source_type.dart';

part 'library_event.dart';
part 'library_state.dart';

class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  LibraryBloc({required this._tracks}) : super(const LibraryState()) {
    on<LibrarySubscriptionRequested>(_onSubscribed, transformer: restartable());
    on<LibraryQueryChanged>((e, emit) => emit(state.copyWith(query: e.query)));
    on<LibrarySourceToggled>(_onSourceToggled);
    on<LibraryTrackDeleted>((e, _) => _tracks.delete(e.trackId));
  }

  final TrackRepository _tracks;

  Future<void> _onSubscribed(
    LibrarySubscriptionRequested event,
    Emitter<LibraryState> emit,
  ) {
    return emit.forEach<List<Track>>(
      _tracks.watchAll(),
      onData: (tracks) => state.copyWith(status: LibraryStatus.ready, all: tracks),
    );
  }

  void _onSourceToggled(LibrarySourceToggled event, Emitter<LibraryState> emit) {
    final sources = Set.of(state.sources);
    if (!sources.remove(event.source)) sources.add(event.source);
    emit(state.copyWith(sources: sources));
  }
}
