import '../core/result.dart';
import '../sources/link_parser.dart';
import '../sources/metadata/metadata_fetcher.dart';
import '../sources/metadata/track_draft.dart';

/// Deterministic metadata for demo mode — no network.
class FakeMetadataFetcher implements MetadataFetcher {
  @override
  Future<Result<TrackDraft>> fetch(ParsedLink link, {required String originalUrl}) async {
    final seed = link.sourceId.replaceAll('/', '-');
    return Ok(TrackDraft(
      source: link.source,
      sourceId: link.sourceId,
      originalUrl: originalUrl,
      title: 'Bài demo ${link.sourceId}',
      artist: 'Nghệ sĩ demo',
      artworkUrl: 'https://picsum.photos/seed/$seed/300/300',
    ));
  }
}
