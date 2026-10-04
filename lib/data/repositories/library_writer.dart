import '../../sources/metadata/track_draft.dart';
import '../db/database.dart';
import 'playlist_repository.dart';
import 'track_repository.dart';

/// Saves a track and its playlist entries atomically.
class LibraryWriter {
  LibraryWriter(this._db, this._tracks, this._playlists);

  final AppDatabase _db;
  final TrackRepository _tracks;
  final PlaylistRepository _playlists;

  Future<Track> addToLibrary(TrackDraft draft, {List<int> playlistIds = const []}) {
    return _db.transaction(() async {
      final track = await _tracks.insert(draft);
      if (playlistIds.isNotEmpty) {
        await _playlists.addTrackToPlaylists(track.id, playlistIds);
      }
      return track;
    });
  }
}
