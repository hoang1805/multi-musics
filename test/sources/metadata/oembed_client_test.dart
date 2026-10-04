import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:multi_musics/core/failure.dart';
import 'package:multi_musics/core/result.dart';
import 'package:multi_musics/sources/link_parser.dart';
import 'package:multi_musics/sources/metadata/oembed_client.dart';
import 'package:multi_musics/sources/metadata/track_draft.dart';
import 'package:multi_musics/sources/source_type.dart';

String fixture(String name) => File('test/fixtures/$name').readAsStringSync();

const youtube = ParsedLink(
  source: SourceType.youtube,
  sourceId: 'dQw4w9WgXcQ',
  canonicalUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
);
const spotify = ParsedLink(
  source: SourceType.spotify,
  sourceId: '4uLU6hMCjMI75M1A2tKUQC',
  canonicalUrl: 'https://open.spotify.com/track/4uLU6hMCjMI75M1A2tKUQC',
);
const soundcloud = ParsedLink(
  source: SourceType.soundcloud,
  sourceId: 'forss/flickermood',
  canonicalUrl: 'https://soundcloud.com/forss/flickermood',
);

void main() {
  Future<Result<TrackDraft>> fetchWith(
    ParsedLink link,
    Future<http.Response> Function(http.Request) handler,
  ) {
    final client = OEmbedClient(httpClient: MockClient(handler));
    return client.fetch(link, originalUrl: 'pasted');
  }

  TrackDraft okValue(Result<TrackDraft> r) => (r as Ok<TrackDraft>).value;
  Failure errValue(Result<TrackDraft> r) => (r as Err<TrackDraft>).failure;

  test('YouTube: maps fields and strips " - Topic"', () async {
    late Uri requested;
    final result = await fetchWith(youtube, (req) async {
      requested = req.url;
      return http.Response(fixture('oembed_youtube.json'), 200);
    });
    expect(requested.host, 'www.youtube.com');
    expect(requested.path, '/oembed');
    expect(requested.queryParameters['url'], youtube.canonicalUrl);
    expect(requested.toString(), contains('url=https%3A%2F%2Fwww.youtube.com'));
    expect(
      okValue(result),
      const TrackDraft(
        source: SourceType.youtube,
        sourceId: 'dQw4w9WgXcQ',
        originalUrl: 'pasted',
        title: 'Rick Astley - Never Gonna Give You Up (Official Video) (4K Remaster)',
        artist: 'Rick Astley',
        artworkUrl: 'https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
      ),
    );
  });

  test('SoundCloud: strips " by <author>" from title', () async {
    final result = await fetchWith(soundcloud, (req) async {
      expect(req.url.host, 'soundcloud.com');
      return http.Response(fixture('oembed_soundcloud.json'), 200);
    });
    final draft = okValue(result);
    expect(draft.title, 'Flickermood');
    expect(draft.artist, 'Forss');
    expect(draft.artworkUrl, startsWith('https://i1.sndcdn.com/'));
  });

  test('Spotify: no artist, artwork from fixture', () async {
    final result = await fetchWith(spotify, (req) async {
      expect(req.url.host, 'open.spotify.com');
      return http.Response(fixture('oembed_spotify.json'), 200);
    });
    final draft = okValue(result);
    expect(draft.title, 'Never Gonna Give You Up');
    expect(draft.artist, isNull);
    expect(
      draft.artworkUrl,
      'https://image-cdn-ak.spotifycdn.com/image/ab67616d00001e02255e131abc1410833be95673',
    );
  });

  test('404 is TrackUnavailable', () async {
    final result = await fetchWith(youtube, (_) async => http.Response('Not Found', 404));
    expect(
      errValue(result),
      const TrackUnavailable('Bài không tồn tại hoặc đang ở chế độ riêng tư'),
    );
  });

  test('401 is TrackUnavailable', () async {
    final result = await fetchWith(youtube, (_) async => http.Response('', 401));
    expect(errValue(result), isA<TrackUnavailable>());
  });

  test('503 is NetworkFailure', () async {
    final result = await fetchWith(youtube, (_) async => http.Response('', 503));
    expect(errValue(result), const NetworkFailure());
  });

  test('socket error is NetworkFailure', () async {
    final result = await fetchWith(
      youtube,
      (_) async => throw const SocketException('offline'),
    );
    expect(errValue(result), const NetworkFailure());
  });

  test('malformed JSON is UnknownFailure', () async {
    final result = await fetchWith(youtube, (_) async => http.Response('not json', 200));
    expect(errValue(result), isA<UnknownFailure>());
  });

  test('missing title is UnknownFailure', () async {
    final result = await fetchWith(youtube, (_) async => http.Response('{}', 200));
    expect(errValue(result), isA<UnknownFailure>());
  });
}
