part of 'library_bloc.dart';

sealed class LibraryEvent extends Equatable {
  const LibraryEvent();

  @override
  List<Object?> get props => const [];
}

final class LibrarySubscriptionRequested extends LibraryEvent {
  const LibrarySubscriptionRequested();
}

final class LibraryQueryChanged extends LibraryEvent {
  const LibraryQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class LibrarySourceToggled extends LibraryEvent {
  const LibrarySourceToggled(this.source);

  final SourceType source;

  @override
  List<Object?> get props => [source];
}

final class LibraryTrackDeleted extends LibraryEvent {
  const LibraryTrackDeleted(this.trackId);

  final int trackId;

  @override
  List<Object?> get props => [trackId];
}
