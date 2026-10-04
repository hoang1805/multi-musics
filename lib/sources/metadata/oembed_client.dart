import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/failure.dart';
import '../../core/result.dart';
import '../link_parser.dart';
import '../source_type.dart';
import 'metadata_fetcher.dart';
import 'track_draft.dart';

/// Title / artist / artwork from each source's public oEmbed endpoint — no
/// API keys needed.
class OEmbedClient implements MetadataFetcher {
  OEmbedClient({required http.Client httpClient}) : _http = httpClient;

  final http.Client _http;

  static const _timeout = Duration(seconds: 10);
  static const _unavailable =
      TrackUnavailable('Bài không tồn tại hoặc đang ở chế độ riêng tư');

  static Uri endpoint(ParsedLink link) => switch (link.source) {
        SourceType.youtube => Uri.https('www.youtube.com', '/oembed',
            {'format': 'json', 'url': link.canonicalUrl}),
        SourceType.soundcloud => Uri.https('soundcloud.com', '/oembed',
            {'format': 'json', 'url': link.canonicalUrl}),
        SourceType.spotify =>
          Uri.https('open.spotify.com', '/oembed', {'url': link.canonicalUrl}),
      };

  @override
  Future<Result<TrackDraft>> fetch(
    ParsedLink link, {
    required String originalUrl,
  }) async {
    final http.Response response;
    try {
      response = await _http.get(endpoint(link)).timeout(_timeout);
    } on SocketException {
      return const Err(NetworkFailure());
    } on TimeoutException {
      return const Err(NetworkFailure());
    } on http.ClientException {
      return const Err(NetworkFailure());
    }

    final status = response.statusCode;
    if (status == 401 || status == 403 || status == 404) return const Err(_unavailable);
    if (status >= 500) return const Err(NetworkFailure());
    if (status != 200) return Err(UnknownFailure('oEmbed HTTP $status'));

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } on Object catch (e, st) {
      return Err(UnknownFailure(e, st));
    }

    var title = json['title'];
    if (title is! String || title.isEmpty) {
      return const Err(UnknownFailure('oEmbed response without title'));
    }
    var artist = link.source == SourceType.spotify ? null : json['author_name'] as String?;

    if (link.source == SourceType.youtube && artist != null && artist.endsWith(' - Topic')) {
      artist = artist.substring(0, artist.length - ' - Topic'.length);
    }
    if (link.source == SourceType.soundcloud && artist != null) {
      final suffix = ' by $artist';
      if (title.endsWith(suffix)) title = title.substring(0, title.length - suffix.length);
    }

    return Ok(TrackDraft(
      source: link.source,
      sourceId: link.sourceId,
      originalUrl: originalUrl,
      title: title,
      artist: artist,
      artworkUrl: json['thumbnail_url'] as String?,
    ));
  }
}
