import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:multi_musics/core/failure.dart';
import 'package:multi_musics/core/result.dart';
import 'package:multi_musics/sources/link_parser.dart';
import 'package:multi_musics/sources/source_type.dart';

const yt = 'dQw4w9WgXcQ';
const sp = '4uLU6hMCjMI75M1A2tKUQC';

void main() {
  final offline = LinkParser(
    httpClient: MockClient((_) async => throw StateError('no network in table tests')),
  );

  Future<Result<ParsedLink>> parse(String input) => offline.parse(input);

  void expectLink(String input, SourceType source, String id, String canonical) {
    test('parses "$input"', () async {
      final result = await parse(input);
      expect(result, isA<Ok<ParsedLink>>());
      final link = (result as Ok<ParsedLink>).value;
      expect(link, ParsedLink(source: source, sourceId: id, canonicalUrl: canonical));
    });
  }

  void expectFailure(String input, Failure failure) {
    test('rejects "$input" with ${failure.runtimeType}', () async {
      final result = await parse(input);
      expect(result, isA<Err<ParsedLink>>());
      expect((result as Err<ParsedLink>).failure, failure);
    });
  }

  group('YouTube', () {
    const canonical = 'https://www.youtube.com/watch?v=$yt';
    for (final input in [
      'https://www.youtube.com/watch?v=$yt',
      'https://youtube.com/watch?v=$yt',
      'https://youtu.be/$yt?si=abc',
      'https://m.youtube.com/watch?v=$yt&t=30s',
      'https://music.youtube.com/watch?v=$yt&feature=share',
      'https://www.youtube.com/shorts/$yt',
      'https://www.youtube.com/live/$yt?feature=share',
      'https://www.youtube.com/embed/$yt',
      'https://www.youtube.com/watch?v=$yt&list=PLx',
      'http://www.youtube.com/watch?feature=share&v=$yt',
      '  Nghe bài này nè https://youtu.be/$yt.  \n',
    ]) {
      expectLink(input, SourceType.youtube, yt, canonical);
    }
    expectFailure('https://www.youtube.com/playlist?list=PLx', const UnsupportedLink());
    expectFailure('https://www.youtube.com/@channel', const UnsupportedLink());
    expectFailure('https://www.youtube.com/channel/UCabc', const UnsupportedLink());
    expectFailure('https://youtu.be/short', const InvalidLink());
    expectFailure('https://www.youtube.com/watch?v=', const InvalidLink());
  });

  group('Spotify', () {
    const canonical = 'https://open.spotify.com/track/$sp';
    for (final input in [
      'https://open.spotify.com/track/$sp',
      'https://open.spotify.com/track/$sp?si=x',
      'https://open.spotify.com/intl-vi/track/$sp',
      'spotify:track:$sp',
      'Check this out: https://open.spotify.com/track/$sp?si=1',
    ]) {
      expectLink(input, SourceType.spotify, sp, canonical);
    }
    expectFailure('https://open.spotify.com/album/$sp', const UnsupportedLink());
    expectFailure('https://open.spotify.com/playlist/$sp', const UnsupportedLink());
    expectFailure('https://open.spotify.com/artist/$sp', const UnsupportedLink());
    expectFailure('https://open.spotify.com/episode/$sp', const UnsupportedLink());
    expectFailure('https://open.spotify.com/track/short', const InvalidLink());
  });

  group('SoundCloud', () {
    const canonical = 'https://soundcloud.com/artist/song-name';
    for (final input in [
      'https://soundcloud.com/Artist/Song-Name?in=x',
      'https://m.soundcloud.com/artist/song-name',
      'https://www.soundcloud.com/artist/song-name/',
    ]) {
      expectLink(input, SourceType.soundcloud, 'artist/song-name', canonical);
    }
    expectFailure('https://soundcloud.com/artist/sets/album', const UnsupportedLink());
    expectFailure('https://soundcloud.com/artist', const UnsupportedLink());
    expectFailure('https://soundcloud.com/artist/likes', const UnsupportedLink());
    expectFailure('https://soundcloud.com/discover/x', const InvalidLink());
  });

  group('garbage', () {
    expectFailure('', const InvalidLink());
    expectFailure('hello', const InvalidLink());
    expectFailure('https://example.com/x', const InvalidLink());
  });

  group('short links', () {
    test('follows on.soundcloud.com redirect', () async {
      final requests = <http.BaseRequest>[];
      final parser = LinkParser(
        httpClient: MockClient((request) async {
          requests.add(request);
          return http.Response('', 302, headers: {
            'location': 'https://soundcloud.com/artist/song-name?utm=1',
          });
        }),
      );
      final result = await parser.parse('https://on.soundcloud.com/abc');
      expect(
        (result as Ok<ParsedLink>).value,
        const ParsedLink(
          source: SourceType.soundcloud,
          sourceId: 'artist/song-name',
          canonicalUrl: 'https://soundcloud.com/artist/song-name',
        ),
      );
      expect(requests.single.followRedirects, isFalse);
    });

    test('network error becomes NetworkFailure', () async {
      final parser = LinkParser(
        httpClient: MockClient((_) async => throw const SocketException('offline')),
      );
      final result = await parser.parse('https://on.soundcloud.com/abc');
      expect((result as Err<ParsedLink>).failure, const NetworkFailure());
    });

    test('redirect to unknown host is InvalidLink', () async {
      final parser = LinkParser(
        httpClient: MockClient((_) async =>
            http.Response('', 301, headers: {'location': 'https://example.com/'})),
      );
      final result = await parser.parse('https://spotify.link/xyz');
      expect((result as Err<ParsedLink>).failure, const InvalidLink());
    });
  });
}
