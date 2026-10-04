part of 'add_track_bloc.dart';

enum AddTrackStatus { idle, resolving, preview, saving, done, failure }

final class AddTrackState extends Equatable {
  const AddTrackState({
    this.status = AddTrackStatus.idle,
    this.draft,
    this.existing,
    this.selectedPlaylistIds = const {},
    this.failure,
    this.saved,
  });

  final AddTrackStatus status;
  final TrackDraft? draft;

  /// Set when the pasted link is already in the library.
  final Track? existing;
  final Set<int> selectedPlaylistIds;
  final Failure? failure;
  final Track? saved;

  @override
  List<Object?> get props =>
      [status, draft, existing, selectedPlaylistIds, failure, saved];
}
