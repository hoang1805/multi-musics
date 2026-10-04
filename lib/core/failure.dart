import 'package:equatable/equatable.dart';

import '../sources/source_type.dart';

/// Every error the app shows to the user. [message] is the Vietnamese copy.
sealed class Failure extends Equatable {
  const Failure();

  String get message;

  @override
  List<Object?> get props => const [];
}

final class InvalidLink extends Failure {
  const InvalidLink();

  @override
  String get message =>
      'Link không hợp lệ. Hãy dán link bài hát từ Spotify, YouTube hoặc SoundCloud.';
}

final class UnsupportedLink extends Failure {
  const UnsupportedLink();

  @override
  String get message => 'Bản này chưa hỗ trợ playlist/album — hãy dán link 1 bài';
}

final class NetworkFailure extends Failure {
  const NetworkFailure();

  @override
  String get message => 'Không có kết nối mạng. Thử lại sau.';
}

/// Permanent: deleted, private or region-blocked.
final class TrackUnavailable extends Failure {
  const TrackUnavailable(this.reason);

  final String reason;

  @override
  String get message => reason;

  @override
  List<Object?> get props => [reason];
}

final class ExtractionFailed extends Failure {
  const ExtractionFailed(this.source, this.detail);

  final SourceType source;
  final String detail;

  @override
  String get message => 'Không lấy được bài từ ${source.displayName}.';

  @override
  List<Object?> get props => [source, detail];
}

final class StreamExpired extends Failure {
  const StreamExpired();

  @override
  String get message => 'Link phát đã hết hạn.';
}

final class SpotifyNotInstalled extends Failure {
  const SpotifyNotInstalled();

  @override
  String get message => 'Chưa cài app Spotify.';
}

final class SpotifyNotPremium extends Failure {
  const SpotifyNotPremium();

  @override
  String get message => 'Cần tài khoản Spotify Premium.';
}

final class SpotifyNotConfigured extends Failure {
  const SpotifyNotConfigured();

  @override
  String get message => 'Chưa nhập Spotify Client ID trong Cài đặt.';
}

final class SpotifyDisconnected extends Failure {
  const SpotifyDisconnected();

  @override
  String get message => 'Mất kết nối với Spotify.';
}

final class UnknownFailure extends Failure {
  const UnknownFailure(this.error, [this.stackTrace]);

  final Object error;
  final StackTrace? stackTrace;

  @override
  String get message => 'Đã có lỗi xảy ra.';

  @override
  List<Object?> get props => [error];
}
