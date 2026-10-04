part of 'add_track_bloc.dart';

sealed class AddTrackEvent extends Equatable {
  const AddTrackEvent();

  @override
  List<Object?> get props => const [];
}

final class AddTrackLinkSubmitted extends AddTrackEvent {
  const AddTrackLinkSubmitted(this.input);

  final String input;

  @override
  List<Object?> get props => [input];
}

final class AddTrackPlaylistToggled extends AddTrackEvent {
  const AddTrackPlaylistToggled(this.playlistId);

  final int playlistId;

  @override
  List<Object?> get props => [playlistId];
}

final class AddTrackConfirmed extends AddTrackEvent {
  const AddTrackConfirmed();
}

final class AddTrackReset extends AddTrackEvent {
  const AddTrackReset();
}
