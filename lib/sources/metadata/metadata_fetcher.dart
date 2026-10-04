import '../../core/result.dart';
import '../link_parser.dart';
import 'track_draft.dart';

abstract interface class MetadataFetcher {
  Future<Result<TrackDraft>> fetch(ParsedLink link, {required String originalUrl});
}
