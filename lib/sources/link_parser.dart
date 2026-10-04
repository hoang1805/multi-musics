import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;

import '../core/failure.dart';
import '../core/result.dart';
import 'source_type.dart';

class ParsedLink extends Equatable {
  const ParsedLink({
    required this.source,
    required this.sourceId,
    required this.canonicalUrl,
  });

  final SourceType source;
  final String sourceId;
  final String canonicalUrl;

  @override
  List<Object?> get props => [source, sourceId, canonicalUrl];
}

/// Turns pasted text into a single-track link from a supported source
/// (rules: spec §5.2).
class LinkParser {
  LinkParser({required http.Client httpClient}) : _http = httpClient;

  final http.Client _http;

  static final _token = RegExp(r'https?://\S+|spotify:track:[A-Za-z0-9]{22}');
  static final _trailingPunctuation = RegExp(r'''[.,)\]>"']+$''');
  static final _youtubeId = RegExp(r'^[A-Za-z0-9_-]{11}$');
  static final _spotifyId = RegExp(r'^[A-Za-z0-9]{22}$');
  static const _shortHosts = {'on.soundcloud.com', 'spotify.link'};
  static const _maxRedirects = 5;

  static const _soundCloudReservedUsers = {
    'discover', 'search', 'you', 'stream', 'upload', 'charts', 'pages', 'settings',
  };
  static const _soundCloudNonTrackPages = {
    'sets', 'likes', 'tracks', 'albums', 'reposts', 'popular-tracks', 'followers',
    'following',
  };

  Future<Result<ParsedLink>> parse(String input) async {
    final match = _token.firstMatch(input.trim());
    if (match == null) return const Err(InvalidLink());
    final token = match.group(0)!.replaceFirst(_trailingPunctuation, '');

    if (token.startsWith('spotify:track:')) {
      return _spotify(token.substring('spotify:track:'.length));
    }

    var uri = Uri.tryParse(token);
    if (uri == null) return const Err(InvalidLink());

    for (var hop = 0; _shortHosts.contains(uri!.host); hop++) {
      if (hop == _maxRedirects) return const Err(InvalidLink());
      final next = await _redirectTarget(uri);
      switch (next) {
        case Ok(:final value):
          uri = value;
        case Err(:final failure):
          return Err(failure);
      }
    }
    return _parseUri(uri);
  }

  Future<Result<Uri>> _redirectTarget(Uri uri) async {
    try {
      final request = http.Request('GET', uri)..followRedirects = false;
      final response = await _http.send(request).timeout(const Duration(seconds: 10));
      await response.stream.drain<void>();
      final location = response.headers['location'];
      if (location == null) return const Err(InvalidLink());
      return Ok(uri.resolve(location));
    } on IOException {
      // SocketException, HandshakeException / TlsException (captive portals), ...
      return const Err(NetworkFailure());
    } on TimeoutException {
      return const Err(NetworkFailure());
    } on http.ClientException {
      return const Err(NetworkFailure());
    }
  }

  Result<ParsedLink> _parseUri(Uri uri) {
    final host = uri.host.toLowerCase();
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    switch (host) {
      case 'youtu.be':
        return _youtube(segments.isEmpty ? '' : segments.first);
      case 'youtube.com' || 'www.youtube.com' || 'm.youtube.com' || 'music.youtube.com':
        if (segments.isEmpty) return const Err(InvalidLink());
        return switch (segments.first) {
          'watch' => _youtube(uri.queryParameters['v'] ?? ''),
          'shorts' || 'live' || 'embed' =>
            _youtube(segments.length > 1 ? segments[1] : ''),
          'playlist' || 'channel' || 'c' || 'user' => const Err(UnsupportedLink()),
          final first when first.startsWith('@') => const Err(UnsupportedLink()),
          _ => const Err(InvalidLink()),
        };
      case 'open.spotify.com':
        final path = segments.isNotEmpty && segments.first.startsWith('intl-')
            ? segments.skip(1).toList()
            : segments;
        if (path.length < 2) return const Err(InvalidLink());
        return switch (path.first) {
          'track' => _spotify(path[1]),
          'album' || 'playlist' || 'artist' || 'episode' || 'show' =>
            const Err(UnsupportedLink()),
          _ => const Err(InvalidLink()),
        };
      case 'soundcloud.com' || 'www.soundcloud.com' || 'm.soundcloud.com':
        return _soundCloud(segments.map((s) => s.toLowerCase()).toList());
      default:
        return const Err(InvalidLink());
    }
  }

  Result<ParsedLink> _youtube(String id) {
    if (!_youtubeId.hasMatch(id)) return const Err(InvalidLink());
    return Ok(ParsedLink(
      source: SourceType.youtube,
      sourceId: id,
      canonicalUrl: 'https://www.youtube.com/watch?v=$id',
    ));
  }

  Result<ParsedLink> _spotify(String id) {
    if (!_spotifyId.hasMatch(id)) return const Err(InvalidLink());
    return Ok(ParsedLink(
      source: SourceType.spotify,
      sourceId: id,
      canonicalUrl: 'https://open.spotify.com/track/$id',
    ));
  }

  Result<ParsedLink> _soundCloud(List<String> segments) {
    if (segments.isEmpty || _soundCloudReservedUsers.contains(segments.first)) {
      return const Err(InvalidLink());
    }
    if (segments.length != 2 || _soundCloudNonTrackPages.contains(segments[1])) {
      return const Err(UnsupportedLink());
    }
    final id = '${segments[0]}/${segments[1]}';
    return Ok(ParsedLink(
      source: SourceType.soundcloud,
      sourceId: id,
      canonicalUrl: 'https://soundcloud.com/$id',
    ));
  }
}
