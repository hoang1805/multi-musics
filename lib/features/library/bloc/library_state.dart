part of 'library_bloc.dart';

enum LibraryStatus { loading, ready }

final class LibraryState extends Equatable {
  const LibraryState({
    this.status = LibraryStatus.loading,
    this.all = const [],
    this.query = '',
    this.sources = const {},
  });

  final LibraryStatus status;
  final List<Track> all;
  final String query;

  /// Empty means every source.
  final Set<SourceType> sources;

  List<Track> get visible {
    final needle = foldVietnamese(query.trim());
    return [
      for (final track in all)
        if ((sources.isEmpty || sources.contains(track.source)) &&
            (needle.isEmpty ||
                foldVietnamese('${track.title} ${track.artist ?? ''}').contains(needle)))
          track,
    ];
  }

  LibraryState copyWith({
    LibraryStatus? status,
    List<Track>? all,
    String? query,
    Set<SourceType>? sources,
  }) {
    return LibraryState(
      status: status ?? this.status,
      all: all ?? this.all,
      query: query ?? this.query,
      sources: sources ?? this.sources,
    );
  }

  @override
  List<Object?> get props => [status, all, query, sources];
}
