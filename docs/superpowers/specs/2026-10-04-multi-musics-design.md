# Multi Musics — Design Spec

**Ngày:** 2026-10-04
**Trạng thái:** Chờ duyệt
**Design system:** [`design-system/multi-musics/MASTER.md`](../../../design-system/multi-musics/MASTER.md)

---

## 1. Mục tiêu

### Vấn đề
Nhạc hay của người dùng nằm rải rác ở Spotify, YouTube và SoundCloud; không có chỗ nào gom chúng lại thành một playlist chung.

### Kết quả mong muốn
Một app iOS cá nhân (Flutter, kiến trúc BLoC) cho phép:
1. Dán link bài hát từ Spotify / YouTube / SoundCloud để đưa vào thư viện.
2. Tạo playlist trộn bài từ nhiều nguồn.
3. Bấm play một playlist và nghe liền mạch qua các nguồn, kể cả khi tắt màn hình, điều khiển được từ màn hình khóa / Control Center / tai nghe.

### Tiêu chí thành công
- Một playlist gồm bài của cả 3 nguồn phát hết từ đầu đến cuối khi màn hình tắt, tự chuyển bài giữa các nguồn.
- Thêm một bài bằng link mất < 5 giây từ lúc dán đến lúc thấy trong thư viện.
- Khi một nguồn bị hỏng, người dùng biết ngay (thông báo trong app + CI hàng tuần) và có công cụ trong app để thử khắc phục.
- App không "chết" bất ngờ do hết hạn chứng chỉ: có tự gia hạn (SideStore) + thông báo trước 1 ngày.

### Người dùng & môi trường
- **Một người dùng duy nhất** (chủ app). Không phát hành App Store.
- **Thiết bị:** iPhone XS Max, iOS 18.7.10.
- **Máy dev:** Windows 11, không có Mac.
- **Tài khoản:** Spotify Premium; Apple ID miễn phí (không có Apple Developer Program).

## 2. Phạm vi

### Trong phạm vi v1
- Thêm bài bằng **dán link một bài** (YouTube, YouTube Music, YouTube Shorts, Spotify track, SoundCloud track kể cả link rút gọn `on.soundcloud.com`).
- Thư viện bài hát (lọc theo tên, lọc theo nguồn, xóa bài).
- Playlist: tạo, đổi tên, xóa, thêm/xóa bài, kéo thả sắp xếp, phát, phát trộn.
- Player: play/pause/next/prev/seek, shuffle, repeat (off/all/one), hàng đợi, mini player, màn hình Now Playing.
- Phát nền + điều khiển màn hình khóa / Control Center / tai nghe.
- Xử lý ngắt âm thanh (cuộc gọi, Siri, báo thức, chỉ đường, rút tai nghe…).
- Màn hình cấu hình nguồn + kiểm tra nguồn trong app.
- Hiển thị hạn chứng chỉ + local notification trước 1 ngày.
- Nhật ký lỗi trong app (xem / copy / share).
- CI (GitHub Actions) + build IPA chưa ký (GitHub Actions, Codemagic dự phòng) + cài qua SideStore.

### Ngoài phạm vi v1 (để sau — kiến trúc phải cho phép thêm mà không đập lại)
- Tìm kiếm bài trên các nguồn từ trong app.
- Import playlist / liked songs từ tài khoản Spotify / YouTube / SoundCloud.
- iOS Share Extension.
- Nghe offline / tải về / cache audio.
- Đồng bộ cloud, export/import backup.
- SideStore "source" JSON để tự báo cập nhật.
- Light theme.
- Link playlist / album (v1 báo "chưa hỗ trợ").

## 3. Ràng buộc nền tảng & hệ quả

| Ràng buộc | Hệ quả trong thiết kế |
|---|---|
| Không có Mac | Build iOS chỉ trên CI (macOS runner). Dev hàng ngày trên Windows desktop với `FAKE_SOURCES=true`. Không có Xcode console → cần nhật ký lỗi trong app. |
| Apple ID miễn phí | IPA build **không ký**, SideStore ký lại trên máy. Hết hạn 7 ngày → SideStore tự gia hạn + thông báo trong app. Tối đa 3 app sideload (SideStore chiếm 1). Không dùng App Group / Share Extension trong v1. |
| Spotify không cho lấy luồng audio | Bài Spotify phát bằng **app Spotify** thông qua Spotify iOS SDK (App Remote). Cần app Spotify đã cài + Premium. |
| iOS suspend app nền không phát âm thanh | Khi bài Spotify đang phát, app phát **audio im lặng (mixWithOthers)** để giữ app sống và tự chuyển sang bài kế tiếp. |
| App Remote cần mở app Spotify để kết nối | Nếu mất kết nối khi app đang ở nền → không kết nối lại được; dùng fallback (mục 7). |
| YouTube / SoundCloud không có API stream chính thức | Dùng `youtube_explode_dart` + resolver SoundCloud tự viết. Có thể hỏng bất cứ lúc nào → cấu hình trong app + fallback Piped + live test hàng tuần. |
| URL stream YouTube/SoundCloud hết hạn sau vài giờ, gắn IP | **Chỉ lưu link gốc + ID** trong DB; resolve URL stream lúc phát; prefetch bài kế. |
| Repo public | Không commit secret. Spotify Client ID nhập trong app (Settings), không nằm trong source. |

## 4. Kiến trúc

### 4.1 Nguyên tắc
- **UI → Bloc → Repository / PlaybackCoordinator.** Widget không gọi trực tiếp package bên ngoài.
- Dùng **`Bloc` (event-driven)** cho mọi feature (không trộn Cubit).
- Dependency injection bằng `RepositoryProvider` / `BlocProvider` của `flutter_bloc` (không thêm `get_it`).
- Mọi thứ trong `sources/` và `playback/` đi qua **interface** để có bản fake cho test và cho chạy desktop.
- Mỗi nguồn nhạc gói gọn trong resolver/engine riêng; thêm nguồn mới = thêm file, không sửa Coordinator.

### 4.2 Cấu trúc thư mục

```
lib/
├── main.dart                     # runZonedGuarded, logger, chọn real/fake theo --dart-define
├── app.dart                      # MaterialApp.router, theme, providers
├── core/
│   ├── theme/                    # ThemeData + ThemeExtension theo MASTER.md
│   ├── result.dart               # Result<T> = Ok | Err(Failure)
│   ├── failure.dart              # sealed class Failure
│   └── logging/app_logger.dart   # ring buffer → file
├── data/
│   ├── db/                       # drift: database.dart, tables.dart (+ .g.dart)
│   └── repositories/
│       ├── track_repository.dart
│       ├── playlist_repository.dart
│       └── settings_repository.dart
├── sources/
│   ├── source_type.dart          # enum SourceType { spotify, youtube, soundcloud }
│   ├── link_parser.dart          # String url → ParsedLink(source, sourceId) | Failure
│   ├── metadata/
│   │   ├── metadata_fetcher.dart # interface
│   │   ├── oembed_client.dart
│   │   └── spotify_web_api.dart  # /v1/tracks/{id} khi đã đăng nhập
│   └── resolvers/
│       ├── stream_resolver.dart  # interface: Future<Result<ResolvedStream>> resolve(Track)
│       ├── youtube_resolver.dart # youtube_explode (theo thứ tự client) → Piped fallback
│       ├── piped_client.dart
│       └── soundcloud_resolver.dart  # quản lý client_id + resolve stream
├── playback/
│   ├── playback_engine.dart      # interface (mục 4.4)
│   ├── audio_engine.dart         # just_audio — YouTube, SoundCloud
│   ├── spotify_engine.dart       # spotify_sdk App Remote
│   ├── keep_alive_player.dart    # audio im lặng mixWithOthers
│   ├── playback_coordinator.dart # hàng đợi, shuffle/repeat, chọn engine, prefetch, skip lỗi
│   ├── playback_state.dart
│   ├── interruption_handler.dart # audio_session: interruption, becomingNoisy
│   └── audio_handler.dart        # audio_service BaseAudioHandler ↔ Coordinator
├── platform/
│   └── provisioning.dart         # MethodChannel "multimusics/provisioning"
├── fakes/                        # Fake engines/resolvers/metadata + seed data cho desktop & test
└── features/
    ├── shell/                    # bottom tab + mini player
    ├── library/                  # LibraryBloc, AddTrackBloc, pages, widgets
    ├── playlists/                # PlaylistsBloc, PlaylistDetailBloc, pages, widgets
    ├── player/                   # PlayerBloc, mini player, Now Playing, queue sheet
    └── settings/                 # SettingsBloc, SourceDiagnosticsBloc, LogsBloc, pages
ios/Runner/
├── ProvisioningPlugin.swift      # đọc embedded.mobileprovision → ExpirationDate
├── Info.plist                    # UIBackgroundModes=audio, LSApplicationQueriesSchemes=spotify, URL scheme callback
assets/
├── fonts/BeVietnamPro-*.ttf
└── audio/silence.m4a             # ~10s im lặng, loop
```

### 4.3 Các Bloc

| Bloc | Event chính | State chính |
|---|---|---|
| `LibraryBloc` | `LibrarySubscribed`, `FilterChanged(text, sources)`, `TrackDeleted(id)` | danh sách track đã lọc |
| `AddTrackBloc` | `LinkSubmitted(url)`, `PlaylistsSelected(ids)`, `Confirmed` | `idle / resolving / preview(track, isExisting) / saving / done / error(failure)` |
| `PlaylistsBloc` | `PlaylistsSubscribed`, `PlaylistCreated(name)`, `PlaylistRenamed`, `PlaylistDeleted` | danh sách playlist + 4 ảnh bìa đầu |
| `PlaylistDetailBloc` | `Subscribed(id)`, `Renamed(name)`, `Deleted`, `EntryRemoved`, `EntryMoved(from, to)`, `PlayRequested(shuffle)` | playlist + entries + tổng thời lượng (`deleted` → trang tự đóng) |
| `PlayerBloc` | `PlayQueueRequested(tracks, startIndex, shuffle)`, `TogglePlay`, `Next`, `Previous`, `SeekTo`, `ShuffleToggled`, `RepeatCycled`, `QueueItemTapped` | ánh xạ từ `PlaybackState` của Coordinator |
| `SettingsBloc` | `Loaded`, `SpotifyConnectRequested`, `SpotifyDisconnectRequested`, `YouTubeClientOrderChanged`, `PipedUrlChanged`, `SoundCloudClientIdChanged`, `SoundCloudClientIdRefreshRequested`, `SpotifyFallbackChanged` | các cấu hình + trạng thái Spotify + hạn chứng chỉ |
| `SourceDiagnosticsBloc` | `TestRequested(url)` | `idle / testing(step) / passed(details) / failed(failure, log)` |
| `LogsBloc` | `Loaded`, `Cleared`, `ShareRequested` | danh sách dòng log |

### 4.4 PlaybackEngine & Coordinator

```dart
abstract interface class PlaybackEngine {
  bool canPlay(Track track);
  Future<Result<void>> load(Track track, {Duration start = Duration.zero});
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> stop();
  Stream<EngineEvent> get events; // positionChanged, durationKnown, playing, paused(reason), completed, failed(Failure)
}
```

`PauseReason` = `user | interruption | noisy | external`. Coordinator dùng nó để phân biệt "bị ngắt" với "hết bài".

`PlaybackCoordinator`:
- Giữ `queue` (List<Track>), `originalOrder`, `index`, `shuffle`, `repeatMode`.
- Chọn engine bằng `canPlay`. Khi đổi engine: `stop()` engine cũ trước khi `load()` engine mới.
- Prefetch: 15 giây trước khi hết bài, gọi `resolver.resolve(nextTrack)` (chỉ với nguồn cần resolve) và cache kết quả trong bộ nhớ.
- Phát ra `Stream<PlaybackState>` duy nhất `{currentTrack, queue, index, position, duration, status, shuffle, repeatMode, lastError, interruptedAt?}`.
- Khi lần đầu biết `duration` của một track mà DB chưa có → ghi vào DB.
- Là điểm vào duy nhất cho cả UI (qua `PlayerBloc`) và màn hình khóa (qua `audio_handler`).

### 4.5 SpotifyEngine chi tiết
- Kết nối: `SpotifySdk.connectToSpotifyRemote(clientId, redirectUrl)`; lần đầu sẽ chuyển sang app Spotify rồi quay về.
- Phát: `SpotifySdk.play(spotifyUri: 'spotify:track:<id>')`, rồi bật `KeepAlivePlayer` (just_audio riêng, loop `silence.m4a`, AVAudioSession category `playback` + option `mixWithOthers`).
- Theo dõi `subscribePlayerState()`:
  - track URI khác bài đang chờ (Spotify tự autoplay, hoặc người dùng bấm next/prev ở màn hình khóa — lúc này Now Playing do Spotify sở hữu) → `pause()` Spotify, phát `completed` → Coordinator chuyển **bài kế** trong hàng đợi của app. Mọi thay đổi track phát sinh từ phía Spotify đều được coi là "Next" (v1 không phân biệt prev).
  - `isPaused` và vị trí ≥ duration − 1.5s → `completed`.
  - `isPaused` trước đó → `paused(external)` (bị ngắt hoặc người dùng pause trong Spotify) — **không** chuyển bài.
- `stop()`: pause Spotify + tắt KeepAlivePlayer + trả AVAudioSession về `playback` không mix.

### 4.6 Lưu cấu hình & bí mật
- Bảng `settings` (key/value) cho: thứ tự client YouTube (mặc định `ios, android, tv`), URL Piped (mặc định rỗng = tắt), `client_id` SoundCloud (cache + override thủ công), Spotify Client ID, Spotify Redirect URI (mặc định `multimusics://spotify-callback`), fallback Spotify (`youtubeSearch` mặc định | `skip`).
- Token Spotify (access token + thời điểm hết hạn) lưu trong Keychain qua `flutter_secure_storage`.

### 4.7 Package chính
`flutter_bloc`, `bloc_test`, `equatable`, `go_router`, `drift` + `drift_dev` + `build_runner` + `sqlite3_flutter_libs`, `just_audio`, `audio_service`, `audio_session`, `spotify_sdk`, `youtube_explode_dart`, `http`, `flutter_secure_storage`, `flutter_local_notifications`, `connectivity_plus`, `cached_network_image`, `lucide_icons_flutter`, `simple_icons`, `package_info_plus`, `share_plus`, `path_provider`, `mocktail`.
Phiên bản Flutter: stable mới nhất lúc khởi tạo, ghi cố định trong `pubspec.yaml` (`environment.flutter`) và CI đọc từ đó.

## 5. Dữ liệu

### 5.1 Schema (drift / SQLite)

```
tracks
  id                  INTEGER PK AUTOINCREMENT
  source              TEXT NOT NULL            -- 'spotify' | 'youtube' | 'soundcloud'
  source_id           TEXT NOT NULL            -- YouTube videoId | Spotify track id | SoundCloud 'user/slug'
  original_url        TEXT NOT NULL
  title               TEXT NOT NULL
  artist              TEXT NULL
  artwork_url         TEXT NULL
  duration_ms         INTEGER NULL             -- điền khi phát lần đầu
  unavailable_reason  TEXT NULL                -- chỉ set cho lỗi vĩnh viễn (xóa / private / chặn vùng)
  added_at            DATETIME NOT NULL
  UNIQUE(source, source_id)

playlists
  id          INTEGER PK AUTOINCREMENT
  name        TEXT NOT NULL
  created_at  DATETIME NOT NULL
  updated_at  DATETIME NOT NULL

playlist_entries
  id           INTEGER PK AUTOINCREMENT
  playlist_id  INTEGER NOT NULL REFERENCES playlists(id) ON DELETE CASCADE
  track_id     INTEGER NOT NULL REFERENCES tracks(id)    ON DELETE CASCADE
  position     INTEGER NOT NULL
  INDEX(playlist_id, position)

settings
  key    TEXT PK
  value  TEXT NOT NULL
```

- Một track có thể nằm trong nhiều playlist và lặp lại trong cùng playlist (mỗi entry có `id` riêng).
- Sắp xếp lại: cập nhật `position` của các entry bị ảnh hưởng trong một transaction.
- **Không bao giờ lưu URL stream.** Chỉ lưu link gốc + ID; URL stream được resolve khi phát.

### 5.2 Luồng: dán link → thêm bài
1. Sheet "Thêm bài" → nút **Dán** (`Clipboard.getData`) → `AddTrackBloc.LinkSubmitted(url)`.
2. `LinkParser` nhận diện:
   - YouTube: `youtube.com/watch?v=`, `youtu.be/`, `music.youtube.com/watch?v=`, `youtube.com/shorts/`, `m.youtube.com`.
   - Spotify: `open.spotify.com/track/<id>`, `open.spotify.com/intl-xx/track/<id>`, `spotify:track:<id>`.
   - SoundCloud: `soundcloud.com/<user>/<slug>`, `m.soundcloud.com/...`, `on.soundcloud.com/<code>` (follow redirect để lấy URL đầy đủ).
   - Link playlist/album/sets → `UnsupportedLink("Bản này chưa hỗ trợ playlist/album — hãy dán link 1 bài")`.
   - Còn lại → `InvalidLink`.
3. Nếu `(source, source_id)` đã tồn tại → state `preview(track, isExisting: true)`.
4. Lấy metadata:
   - YouTube / SoundCloud → oEmbed (`title`, `author_name` → artist, `thumbnail_url`).
   - Spotify → Web API `/v1/tracks/{id}` nếu có token (title, artists, album art, duration); không có token → oEmbed (title, ảnh; artist để trống).
5. Hiện preview; người dùng chọn 0..n playlist → `Confirmed` → lưu track + entries (append cuối playlist) trong một transaction.

### 5.3 Luồng: phát
1. `PlayerBloc.PlayQueueRequested(tracks, startIndex, shuffle)` → Coordinator.
2. Coordinator chọn engine theo nguồn:
   - **AudioEngine**: lấy từ cache prefetch hoặc `resolver.resolve(track)` → `just_audio.setAudioSource(uri, headers)` → `play()`.
   - **SpotifyEngine**: như mục 4.5.
3. Hết bài → bài kế theo shuffle/repeat → đổi engine nếu khác nguồn.
4. `PlaybackState` → `PlayerBloc` → UI; đồng thời → `audio_handler` cập nhật `MediaItem` + `PlaybackState` cho màn hình khóa.
5. Lệnh từ màn hình khóa/tai nghe → `audio_handler` → Coordinator (cùng đường với nút trong app).

### 5.4 Ngắt âm thanh (`audio_session`)
| Tình huống | Hành vi |
|---|---|
| Interruption begin (cuộc gọi, Siri, báo thức, app khác chiếm audio) | pause, ghi `interruptedAt`, `PauseReason.interruption` |
| Interruption end + `shouldResume` | play tiếp đúng vị trí |
| Interruption end không có `shouldResume`, hoặc không nhận được end (TikTok/Facebook/Instagram thường không báo) | giữ pause; nút play sẵn ở Control Center / mini player. **Không** tự thử phát lại. |
| Duck (chỉ đường) | giảm âm lượng còn ~30%, khôi phục khi kết thúc |
| `becomingNoisy` (rút tai nghe, ngắt Bluetooth) | pause, `PauseReason.noisy`, không tự phát tiếp |
| Bài Spotify | app Spotify tự xử lý ngắt; SpotifyEngine chỉ báo `paused(external)`, không chuyển bài |

## 6. Cấu hình nguồn trong app

Màn **Cài đặt → Nguồn**:

| Nguồn | Cấu hình |
|---|---|
| YouTube | Danh sách client của `youtube_explode_dart` có thể bật/tắt + kéo thả thứ tự (mặc định `ios → android → tv`). URL instance Piped (tùy chọn) làm fallback: `GET {piped}/streams/{videoId}` → chọn audio stream bitrate cao nhất. |
| SoundCloud | `client_id` hiện tại (chỉ đọc) + nút **Lấy lại tự động** (tải `soundcloud.com`, tìm các script `a-v2.sndcdn.com/assets/*.js`, regex `client_id:"([a-zA-Z0-9]{32})"`) + ô override thủ công. |
| Spotify | Client ID, Redirect URI, nút Kết nối / Ngắt kết nối, trạng thái (chưa cài app / chưa kết nối / đã kết nối), hiển thị **bundle ID thực tế** của app (từ `package_info_plus`) để khai báo đúng trên Spotify Dashboard. Tùy chọn fallback khi không kết nối được: *Tìm trên YouTube* (mặc định) / *Bỏ qua*. |

Màn **Cài đặt → Kiểm tra nguồn**: dán một link → chạy parse → metadata → resolve → phát thử 3 giây (âm lượng nhỏ) → hiện từng bước ✅/❌ cùng thông điệp lỗi và log liên quan. Có sẵn 3 link mẫu (1 mỗi nguồn) để bấm thử nhanh.

Giới hạn: cấu hình chỉ đổi tham số/fallback; nếu thay đổi phía YouTube/SoundCloud đòi sửa code thì phải cập nhật package và build lại.

## 7. Xử lý lỗi

### 7.1 Phân loại
```dart
sealed class Failure {
  InvalidLink, UnsupportedLink,
  Network,                         // timeout, offline
  TrackUnavailable(reason),        // vĩnh viễn: xóa / private / chặn vùng → ghi tracks.unavailable_reason
  ExtractionFailed(source, detail),// resolver hỏng
  StreamExpired,                   // HTTP 403 khi đang phát
  SpotifyNotInstalled, SpotifyNotPremium, SpotifyNotConfigured, SpotifyDisconnected,
  Unknown(error, stack),
}
```

### 7.2 Chính sách
- **Thêm bài:** lỗi hiện ngay trong sheet, cạnh nút Dán.
- **Resolve YouTube:** thử lần lượt các client đã bật → Piped (nếu cấu hình) → `ExtractionFailed` / `TrackUnavailable`.
- **Bài không phát được:** snackbar "Bỏ qua: <tên bài> (<lý do>)" + tự chuyển bài kế. Bài lỗi vĩnh viễn hiện icon ⚠️ trong list.
- **Chống skip dây chuyền:** 3 bài liên tiếp lỗi → dừng phát, banner "Nguồn <X> có vẻ đang lỗi" + nút mở *Kiểm tra nguồn*.
- **URL stream hết hạn (403)** khi play lại / seek: resolve lại và phát tiếp tại vị trí cũ, không báo người dùng (tối đa 1 lần cho mỗi lần phát; lần 2 thất bại → xử lý như bài lỗi).
- **Mất mạng giữa bài:** phát hết buffer, chuyển trạng thái `waitingForNetwork`; `connectivity_plus` báo có mạng lại trong vòng 5 phút → tự resume; quá 5 phút → giữ pause.
- **Spotify tới lượt mà chưa kết nối:** thử `connectToSpotifyRemote` 1 lần (thành công nếu Spotify còn chạy nền) → thất bại thì theo cấu hình fallback: tìm `"<artist> - <title>"` qua `youtube_explode_dart` search, lấy kết quả video đầu tiên, phát (không lưu kết quả vào DB) / hoặc bỏ qua. Lần tới app vào foreground → tự kết nối lại.
- **Spotify chưa cài / không Premium / chưa cấu hình Client ID:** báo ngay ở màn Cài đặt khi bấm Kết nối, và khi gặp bài Spotify thì xử lý như fallback.

### 7.3 Nhật ký
- `AppLogger`: ring buffer 500 dòng, ghi xuống `ApplicationSupport/logs.txt` (flush mỗi 2 giây và khi app vào nền).
- Ghi: thêm bài, resolve (nguồn, client dùng, thời gian), đổi engine, mọi `Failure`, interruption, kết nối Spotify, crash (`FlutterError.onError`, `PlatformDispatcher.instance.onError`, `runZonedGuarded`).
- **Cài đặt → Nhật ký**: xem, Copy, Share (`share_plus`), Xóa.

## 8. Hạn chứng chỉ (sideload)
- `ProvisioningPlugin.swift`: đọc `Bundle.main.path(forResource: "embedded", ofType: "mobileprovision")`, cắt đoạn từ `<?xml` đến `</plist>`, parse bằng `PropertyListSerialization`, trả `ExpirationDate` (ISO 8601) qua MethodChannel `multimusics/provisioning`. Không có file (chạy debug/simulator/desktop) → trả `null`.
- Mỗi lần app khởi động: lấy ngày hết hạn → hủy notification cũ → đặt `flutter_local_notifications` lúc `ExpirationDate − 24h` (nếu còn ở tương lai) với nội dung "Multi Musics sẽ hết hạn lúc <giờ>. Mở SideStore để gia hạn."
- **Cài đặt → Hạn chứng chỉ**: ngày giờ hết hạn + số ngày/giờ còn lại; < 24h thì tô đỏ.

## 9. Giao diện
Chi tiết token, font, icon, motion và checklist: [`design-system/multi-musics/MASTER.md`](../../../design-system/multi-musics/MASTER.md).

- **Điều hướng:** bottom tab 3 mục — Thư viện · Playlist · Cài đặt; **mini player** cố định phía trên tab bar khi có bài trong hàng đợi.
- **Thư viện:** nút **+** trên app bar; ô lọc theo tên; chip lọc nguồn; list (ảnh 48pt, tên, nghệ sĩ, badge nguồn, ⚠️ nếu lỗi); vuốt trái → *Thêm vào playlist* / *Xóa* (xác nhận khi xóa).
- **Sheet Thêm bài:** nút Dán lớn; preview (ảnh, tên, nghệ sĩ, nguồn, "Đã có trong thư viện" nếu trùng); chọn playlist (multi-select); lỗi hiện inline.
- **Playlist:** lưới 2 cột, ảnh bìa ghép 2×2 từ 4 bài đầu (ít hơn 4 thì dùng ảnh bài đầu / placeholder); nút tạo mới.
- **Chi tiết playlist:** header ảnh ghép + tên + số bài + tổng thời lượng (bỏ qua bài chưa biết thời lượng); nút **Phát** và **Trộn bài**; long-press kéo thả sắp xếp; menu đổi tên / xóa.
- **Now Playing** (modal toàn màn hình, vuốt xuống để đóng): ảnh bìa lớn; nền gradient theo ảnh bìa; tên/nghệ sĩ; dòng "Đang phát từ <Nguồn>" kèm logo; thanh tua; prev / play-pause / next; shuffle / repeat; nút Hàng đợi → bottom sheet danh sách bài (chạm để nhảy tới).
- **Cài đặt:** Spotify · Nguồn · Kiểm tra nguồn · Hạn chứng chỉ · Nhật ký · Phiên bản app.
- Mọi list có trạng thái loading (skeleton), rỗng (có hướng dẫn), lỗi.
- Lần đầu dán, iOS hỏi quyền dán; hướng dẫn trong empty state của sheet: *Cài đặt iOS → Multi Musics → Dán từ app khác → Cho phép*.

## 10. Kiểm thử

| Tầng | Công cụ | Phạm vi |
|---|---|---|
| Unit | `flutter_test`, `mocktail` | `LinkParser` (bảng ≥ 30 URL hợp lệ/không hợp lệ), parse oEmbed & Spotify Web API (fixture JSON), `YouTubeResolver` thứ tự client → Piped, `SoundCloudResolver` (lấy client_id từ fixture HTML/JS, thử lại khi 401), `PlaybackCoordinator` với fake engine (queue, shuffle, repeat off/all/one, đổi engine, prefetch, skip lỗi, dừng sau 3 lỗi, 403 → resolve lại, interruption vs completed, mất mạng/có mạng), `SpotifyEngine` logic phát hiện hết bài/autoplay qua fake player-state stream, tính lịch notification hết hạn |
| DB | drift `NativeDatabase.memory()` | chống trùng track, cascade xóa, sắp xếp lại `position`, entries lặp |
| Bloc | `bloc_test` | mỗi Bloc ở mục 4.3: event → chuỗi state, kể cả nhánh lỗi |
| Widget | `flutter_test` + mock Bloc | Thư viện, Sheet thêm bài, Chi tiết playlist, Now Playing, Cài đặt → Nguồn: loading/empty/error/data |
| Live (`@Tags(['live'])`) | mạng thật | YouTube resolve 1 video ổn định, SoundCloud lấy client_id + resolve 1 track, oEmbed 3 nguồn. Không chạy trong `ci.yml`. |
| Thủ công trên iPhone | `docs/manual-test-checklist.md` | phát nền tắt màn hình qua 3 nguồn; màn hình khóa/Control Center/AirPods; cuộc gọi; Siri; chỉ đường; rút tai nghe; Spotify kết nối/mất kết nối/fallback; thông báo hết hạn; quyền dán |

Dev trên Windows: `flutter run -d windows --dart-define=FAKE_SOURCES=true` → dùng `lib/fakes/` (engine giả mô phỏng tiến độ phát, resolver giả, seed ~20 bài + 3 playlist). `flutter test` chạy được trên Windows (cần `sqlite3.dll` cho drift test — dùng `sqlite3_flutter_libs`/hướng dẫn trong README).

## 11. CI/CD & phân phối

**Repo:** GitHub, **public**. Không commit secret.

| Workflow | Runner | Trigger | Bước |
|---|---|---|---|
| `.github/workflows/ci.yml` | `ubuntu-latest` | push, pull_request | setup Flutter (version từ `pubspec.yaml`) → `pub get` → `dart run build_runner build -d` → `flutter analyze` → `flutter test --exclude-tags live` |
| `.github/workflows/live-sources.yml` | `ubuntu-latest` | cron thứ Hai 02:00 UTC, `workflow_dispatch` | `flutter test --tags live` (fail → GitHub gửi email) |
| `.github/workflows/release.yml` | `macos-latest` | push tag `v*` | `scripts/build_unsigned_ipa.sh` → tạo GitHub Release với `multi-musics-<tag>.ipa` |
| `codemagic.yaml` (`ios-unsigned`) | Codemagic `mac_mini_m2` | thủ công | `scripts/build_unsigned_ipa.sh` → artifact IPA (+ email) |

`scripts/build_unsigned_ipa.sh`: `flutter pub get` → `build_runner` → `flutter test --exclude-tags live` → `flutter build ios --release --no-codesign --build-name=<tag không có v> --build-number=<số commit>` → tạo `Payload/`, copy `build/ios/iphoneos/Runner.app` → `zip -r multi-musics-<tag>.ipa Payload`.

**Cài đặt lên iPhone:**
1. (Một lần) Cài SideStore theo hướng dẫn chính thức (cần PC Windows lần đầu để tạo pairing file), cài app VPN nội bộ mà SideStore yêu cầu.
2. `git tag vX.Y.Z && git push --tags` → chờ `release.yml` xong.
3. SideStore → **+** → dán URL IPA của GitHub Release → cài. SideStore tự gia hạn mỗi 7 ngày.

**Thiết lập Spotify (một lần):** tạo app trên Spotify Developer Dashboard, chọn iOS SDK, thêm Redirect URI `multimusics://spotify-callback`, khai báo bundle ID **đúng như app hiển thị ở Cài đặt → Spotify** (SideStore có thể thêm hậu tố vào bundle ID), thêm email tài khoản Spotify của mình vào danh sách user (development mode). Nhập Client ID vào app.

## 12. Rủi ro đã biết

| Rủi ro | Mức | Giảm thiểu |
|---|---|---|
| YouTube đổi cơ chế làm `youtube_explode_dart` hỏng | Cao | Nhiều client + Piped fallback, live test hàng tuần, cập nhật package & build lại |
| SoundCloud đổi `client_id`/cơ chế | Trung bình | Tự lấy lại client_id, override thủ công, live test |
| Spotify App Remote mất kết nối khi app ở nền | Trung bình | Thử kết nối lại 1 lần → fallback YouTube search/bỏ qua; tự kết nối lại khi foreground |
| Audio im lặng giữ app sống làm tốn pin hơn | Thấp | Chỉ bật trong lúc bài Spotify phát |
| SideStore/Apple thay đổi cơ chế sideload | Trung bình | Thông báo hết hạn trước 1 ngày; Codemagic + Sideloadly là đường dự phòng |
| Spotify thay đổi chính sách Developer (development mode) | Thấp–Trung bình | Bài Spotify vẫn phát được qua fallback YouTube search |
| Vi phạm ToS YouTube/SoundCloud khi tách audio | Chấp nhận | App chỉ dùng cá nhân, không phân phối |
