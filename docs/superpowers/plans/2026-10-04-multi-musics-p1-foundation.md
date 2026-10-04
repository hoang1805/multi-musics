# Multi Musics — Kế hoạch 1: Nền móng, Thư viện & Playlist

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** App Flutter chạy được trên Windows (dữ liệu thật + chế độ demo) và cài được lên iPhone qua SideStore: dán link → thêm bài vào thư viện → tạo và sắp xếp playlist trộn nguồn. Chưa phát nhạc.

**Architecture:** Kiến trúc BLoC (event-driven `Bloc`) theo các tầng UI → Bloc → Repository/Service. Dữ liệu lưu bằng drift/SQLite, dùng trực tiếp data class mà drift sinh ra làm model. Link được nhận diện bởi `LinkParser`, metadata lấy qua oEmbed, cả hai đều sau interface để có bản fake. CI chạy trên GitHub Actions (Ubuntu). IPA chưa ký được build trên GitHub Actions (macOS), có Codemagic dự phòng.

**Tech Stack:** Flutter (stable, ghi cố định trong `pubspec.yaml`), `flutter_bloc`, `bloc_test`, `equatable`, `go_router`, `drift` + `drift_flutter` + `drift_dev` + `build_runner`, `http`, `cached_network_image`, `lucide_icons_flutter`, `simple_icons`, `package_info_plus`, `path_provider`, `mocktail`.

**Spec:** [`docs/superpowers/specs/2026-10-04-multi-musics-design.md`](../specs/2026-10-04-multi-musics-design.md) · **Design system:** [`design-system/multi-musics/MASTER.md`](../../../design-system/multi-musics/MASTER.md)

## Lộ trình (các kế hoạch sau viết khi kế hoạch trước xong)

| Kế hoạch | Kết quả |
|---|---|
| **1 (tài liệu này)** | Thư viện + playlist + dán link + CI + IPA đầu tiên lên iPhone qua SideStore |
| 2 | Phát YouTube/SoundCloud: resolvers, `PlaybackEngine`, `AudioEngine`, `PlaybackCoordinator`, `audio_service`, ngắt âm thanh, mất mạng, mini player, Now Playing, hàng đợi, `live-sources.yml`, engine giả cho desktop |
| 3 | Spotify: kết nối/token, `SpotifyEngine` + `KeepAlivePlayer`, metadata qua Web API, fallback tìm trên YouTube |
| 4 | Cài đặt nâng cao: cấu hình nguồn, Kiểm tra nguồn, hạn chứng chỉ + thông báo, màn Nhật ký, `docs/manual-test-checklist.md` |

## Global Constraints

- Chỉ có dark theme. Mọi màu, font, khoảng cách lấy từ `AppTheme`/`AppColors` theo `MASTER.md`. Không viết `Color(0xFF…)` hay `TextStyle(fontSize: …)` trực tiếp trong widget.
- Font: Be Vietnam Pro (400/500/600/700), đóng gói trong `assets/fonts/`. Không dùng `google_fonts`.
- Icon: `lucide_icons_flutter`. Logo nguồn dùng `simple_icons`. Không dùng emoji làm icon.
- Touch target tối thiểu 44×44pt. Tôn trọng safe area. Mọi list dùng `ValueKey(id)` cho từng item.
- Dùng `Bloc` có event (không dùng Cubit). Widget không gọi repository hay package bên ngoài trực tiếp.
- **Không lưu URL stream vào DB.** Chỉ lưu link gốc và ID.
- Repo public: không commit secret, không commit email.
- Toàn bộ chữ hiển thị trên UI là tiếng Việt, đúng nguyên văn trong kế hoạch này.
- Lệnh test: `flutter test --exclude-tags live`. Tag `live` được khai báo trong `dart_test.yaml`.
- Sau mỗi lần sửa bảng drift: `dart run build_runner build -d`. File `*.g.dart` **được commit** vào repo.

## Review Focus

1. **Link dán vào có kèm rác:** khoảng trắng, xuống dòng, chữ giới thiệu ("Nghe bài này https://…"), tham số theo dõi (`?si=`, `&t=30s`, `&list=…`, `&feature=share`). Vẫn phải nhận diện đúng bài → test ở Task 6.
2. **Cùng một bài dán bằng nhiều dạng link** (`youtu.be/X` và `youtube.com/watch?v=X`, `open.spotify.com/intl-vi/track/Y` và `spotify:track:Y`). Phải ra cùng một track, không tạo bài trùng → test ở Task 6 và Task 8.
3. **Lọc tiếng Việt không dấu:** gõ `mua` phải tìm thấy "Mưa", gõ `dem` phải tìm thấy "Đêm" → test ở Task 9.
4. **Kéo thả sắp xếp** với quy ước chỉ số của `ReorderableListView` (kéo xuống 1 ô thì `newIndex = oldIndex + 2`). Sau khi kéo hoặc xóa, `position` phải liên tục từ 0 → test ở Task 5 và Task 12.
5. **Tên bài rất dài + Dynamic Type lớn nhất:** `TrackTile` không được tràn (overflow) → test ở Task 9.

---

### Task 1: Môi trường, khung dự án, các kiểu lõi, CI

**Files:**
- Create: (bằng `flutter create`) `pubspec.yaml`, `lib/main.dart`, `ios/`, `windows/`
- Create: `analysis_options.yaml`, `dart_test.yaml`, `.gitignore` (bổ sung), `README.md`
- Create: `lib/core/result.dart`, `lib/core/failure.dart`, `lib/sources/source_type.dart`
- Create: `.github/workflows/ci.yml`
- Test: `test/core/failure_test.dart`
- Delete: `test/widget_test.dart` (file mẫu của template)

**Interfaces:**
- Produces:
  - `enum SourceType { spotify, youtube, soundcloud }` với `String get displayName` (`'Spotify'`, `'YouTube'`, `'SoundCloud'`).
  - `sealed class Result<T>`; `final class Ok<T>(T value)`; `final class Err<T>(Failure failure)`.
  - `sealed class Failure extends Equatable` với `String get message`. Các lớp con và nguyên văn `message`:
    - `InvalidLink()`: "Link không hợp lệ. Hãy dán link bài hát từ Spotify, YouTube hoặc SoundCloud."
    - `UnsupportedLink()`: "Bản này chưa hỗ trợ playlist/album — hãy dán link 1 bài"
    - `NetworkFailure()`: "Không có kết nối mạng. Thử lại sau."
    - `TrackUnavailable(String reason)`: trả về `reason`
    - `ExtractionFailed(SourceType source, String detail)`: "Không lấy được bài từ ${source.displayName}."
    - `StreamExpired()`: "Link phát đã hết hạn."
    - `SpotifyNotInstalled()`: "Chưa cài app Spotify."
    - `SpotifyNotPremium()`: "Cần tài khoản Spotify Premium."
    - `SpotifyNotConfigured()`: "Chưa nhập Spotify Client ID trong Cài đặt."
    - `SpotifyDisconnected()`: "Mất kết nối với Spotify."
    - `UnknownFailure(Object error, [StackTrace? stackTrace])`: "Đã có lỗi xảy ra."

- [ ] **Step 1: Cài Flutter SDK trên Windows** (hỏi người dùng trước khi tải và cài). Tải bản Flutter stable mới nhất, giải nén vào `C:\dev\flutter`, thêm `C:\dev\flutter\bin` vào PATH của user. Cài Visual Studio 2022 với workload "Desktop development with C++" (cần để chạy `-d windows`).
  Run: `flutter doctor -v`
  Expected: dòng `Flutter` và `Visual Studio` có ✓. Các mục Android, Xcode, Chrome báo lỗi thì bỏ qua.

- [ ] **Step 2: Tạo dự án**
  Run: `flutter create --org dev.multimusics --project-name multi_musics --platforms ios,windows .`
  Sau đó thêm vào `pubspec.yaml` mục `environment: flutter: "<phiên bản đúng như `flutter --version` in ra>"` (CI đọc phiên bản từ đây). Xóa `test/widget_test.dart`.

- [ ] **Step 3: Thêm dependencies**
  Run: `flutter pub add flutter_bloc equatable go_router drift drift_flutter http cached_network_image lucide_icons_flutter simple_icons package_info_plus path_provider` và `flutter pub add --dev bloc_test mocktail drift_dev build_runner`
  `analysis_options.yaml`: include `package:flutter_lints/flutter.yaml`, bật `strict-casts`, `strict-raw-types`, loại trừ `**/*.g.dart`. Viết `dart_test.yaml` với `tags: { live: {} }`. Thêm `build/` và `.dart_tool/` vào `.gitignore` nếu chưa có.

- [ ] **Step 4: Viết test thất bại** `test/core/failure_test.dart`
  - `UnsupportedLink().message == 'Bản này chưa hỗ trợ playlist/album — hãy dán link 1 bài'`
  - `ExtractionFailed(SourceType.youtube, 'x').message == 'Không lấy được bài từ YouTube.'`
  - `TrackUnavailable('Video đã bị xóa').message == 'Video đã bị xóa'`
  - `NetworkFailure() == NetworkFailure()` (Equatable)
  - `switch (Ok(1) as Result<int>) { Ok(:final value) => value, Err() => -1 } == 1`

- [ ] **Step 5: Chạy test để thấy thất bại.** Run: `flutter test test/core/failure_test.dart`. Expected: FAIL do chưa có các kiểu này.

- [ ] **Step 6: Viết `result.dart`, `failure.dart`, `source_type.dart`** theo khối Interfaces ở trên.

- [ ] **Step 7: Viết `.github/workflows/ci.yml`.** Trigger `push`, `pull_request`. Runner `ubuntu-latest`. Các bước: `actions/checkout@v4` → `sudo apt-get update && sudo apt-get install -y libsqlite3-dev` → `subosito/flutter-action@v2` (`channel: stable`, `flutter-version-file: pubspec.yaml`, `cache: true`) → `flutter pub get` → `dart run build_runner build -d` → `flutter analyze` → `flutter test --exclude-tags live`.

- [ ] **Step 8: README.md**, gồm các mục: yêu cầu (Flutter, VS C++), lệnh chạy desktop `flutter run -d windows --dart-define=FAKE_SOURCES=true`, lệnh test, lệnh codegen, và đường dẫn tới spec.

- [ ] **Step 9: Kiểm tra.** Run: `flutter analyze && flutter test --exclude-tags live`. Expected: `No issues found!` và `All tests passed!`

- [ ] **Step 10: Commit.** `git add -A && git commit -m "chore: scaffold Flutter project with core types and CI"`

---

### Task 2: AppLogger và các hook bắt lỗi khi khởi động

**Files:**
- Create: `lib/core/logging/app_logger.dart`
- Modify: `lib/main.dart`
- Test: `test/core/logging/app_logger_test.dart`

**Interfaces:**
- Produces:
  - `enum LogLevel { info, warn, error }`
  - `class LogLine { final DateTime time; final LogLevel level; final String tag; final String message; }` với `String format()` → `2026-10-04T22:48:47.123 [I] tag: message` (ký hiệu cấp độ là `I`, `W`, `E`). Nếu có error thì nối thêm ` | <error>`, và stack trace nằm ở các dòng tiếp theo.
  - `class AppLogger`:
    - `static Future<AppLogger> open(File file, {int capacity = 500})`: đọc tối đa `capacity` dòng cuối của file đã có (giữ nguyên dạng text).
    - `AppLogger.memory({int capacity = 500})`: không ghi file (dùng cho test và desktop).
    - Các hàm `info(String tag, String message)`, `warn(...)`, `error(String tag, String message, [Object? error, StackTrace? stackTrace])`.
    - `List<String> get lines`, `Future<void> flush()`, `Future<void> clear()`, `void dispose()`.
    - Có timer tự `flush` mỗi 2 giây nếu có dòng mới. `flush` ghi đè cả file bằng nội dung ring buffer hiện tại.

- [ ] **Step 1: Viết test thất bại**
  - `ring buffer drops oldest`: capacity 3, ghi 5 dòng → `lines.length == 3` và dòng đầu chứa `msg2`.
  - `flush writes file and open reloads`: logger ghi vào file tạm, `flush()`, rồi `AppLogger.open(file)` → `lines` bằng đúng các dòng cũ.
  - `error includes error text`: `error('t', 'm', StateError('boom'))` → dòng chứa `[E] t: m | Bad state: boom`.

- [ ] **Step 2: Chạy test, thấy FAIL.** Run: `flutter test test/core/logging/app_logger_test.dart`

- [ ] **Step 3: Viết `AppLogger`** theo khối Interfaces.

- [ ] **Step 4: Chạy test, thấy PASS.**

- [ ] **Step 5: Viết `main.dart`**, bọc toàn bộ trong `runZonedGuarded`. Mở logger tại `getApplicationSupportDirectory()/logs.txt`. Gán `FlutterError.onError` và `PlatformDispatcher.instance.onError` để gọi `logger.error('crash', …)`. `WidgetsBinding` lắng nghe `AppLifecycleState.paused` thì gọi `flush()`. Tạm thời `runApp` một `MaterialApp` placeholder, Task 13 sẽ thay.
  Run: `flutter run -d windows`. Expected: app mở ra, file `logs.txt` được tạo trong thư mục app support.

- [ ] **Step 6: Commit.** `git commit -am "feat: add AppLogger with crash hooks"` (nhớ `git add` file mới).

---

### Task 3: Theme, font và các widget dùng chung

**Files:**
- Create: `assets/fonts/BeVietnamPro-{Regular,Medium,SemiBold,Bold}.ttf`, `assets/fonts/OFL.txt` (tải từ `https://github.com/google/fonts/tree/main/ofl/bevietnampro`)
- Modify: `pubspec.yaml` (khai báo font family `BeVietnamPro` với weight 400/500/600/700)
- Create: `lib/core/theme/app_colors.dart`, `lib/core/theme/app_theme.dart`, `lib/core/theme/app_spacing.dart`
- Create: `lib/core/widgets/source_badge.dart`, `artwork_image.dart`, `empty_state.dart`, `skeleton_list.dart`
- Create: `lib/core/format/duration_format.dart`
- Test: `test/core/theme/app_theme_test.dart`, `test/core/widgets/source_badge_test.dart`, `test/core/format/duration_format_test.dart`, `test/helpers/pump_app.dart`

**Interfaces:**
- Produces:
  - `class AppColors extends ThemeExtension<AppColors>` với các field `background, surface, muted, border, onBackground, mutedForeground, accent, onAccent, destructive, sourceSpotify, sourceYouTube, sourceSoundCloud`. Giá trị lấy đúng hex trong MASTER.md. Có thêm `Color sourceColor(SourceType)`.
  - `abstract final class AppSpacing { xs=4, sm=8, md=16, lg=24, xl=32, xxl=48; screenPadding=16; radiusCard=12, radiusArtwork=8, radiusSheet=20; minTouch=44 }`
  - `abstract final class AppTheme { static ThemeData dark(); }`: Material 3, brightness dark, `fontFamily: 'BeVietnamPro'`, `scaffoldBackgroundColor = background`, `ColorScheme(primary: accent, onPrimary: onAccent, surface: surface, error: destructive, …)`, gắn extension `AppColors`. Text theme: `displaySmall` 28/w700, `titleLarge` 22/w600, `titleMedium` 16/w600, `bodyMedium` 14/w400, `labelSmall` 12/w500.
  - `SourceBadge({required SourceType source, bool showLabel = false})`: logo `SimpleIcons.spotify`, `.youtube` hoặc `.soundcloud` tô theo màu nguồn, bọc `Semantics(label: source.displayName)`. Nếu `simple_icons` không có logo đó thì dùng icon `LucideIcons.music` và luôn hiện label.
  - `ArtworkImage({String? url, required double size, double radius = AppSpacing.radiusArtwork})`: `CachedNetworkImage`, placeholder và lỗi đều là ô màu `muted` có icon nhạc, kích thước luôn cố định.
  - `EmptyState({required IconData icon, required String title, required String message, Widget? action})`
  - `SkeletonList({int count = 8})`: các dòng giả, cao 56 (bằng `TrackTile` ở Task 9).
  - `String formatTrackDuration(Duration d)`: `3:05`, hoặc `1:02:09` khi ≥ 1 giờ. `String formatTotalDuration(Duration d)`: `0 phút`, `12 phút`, `1 giờ`, `1 giờ 5 phút` (làm tròn xuống theo phút).
  - `test/helpers/pump_app.dart`: `Future<void> pumpApp(WidgetTester t, Widget child, {double textScale = 1})`, bọc `MaterialApp(theme: AppTheme.dark(), home: Scaffold(body: child))` và `MediaQuery` có `textScaler`.

- [ ] **Step 1: Viết test thất bại**
  - `app_theme_test`: `AppTheme.dark().extension<AppColors>()!.accent == const Color(0xFF818CF8)`; `AppTheme.dark().textTheme.titleMedium!.fontFamily` chứa `BeVietnamPro`; `brightness == Brightness.dark`.
  - `duration_format_test`: `formatTrackDuration(Duration(seconds: 185)) == '3:05'`; `formatTrackDuration(Duration(hours:1, minutes:2, seconds:9)) == '1:02:09'`; `formatTotalDuration(Duration(minutes: 65)) == '1 giờ 5 phút'`; `formatTotalDuration(Duration(minutes: 60)) == '1 giờ'`; `formatTotalDuration(Duration(seconds: 59)) == '0 phút'`.
  - `source_badge_test`: `SourceBadge(source: SourceType.youtube)` có `Semantics` label `YouTube`. `showLabel: true` thì hiện chữ "YouTube".

- [ ] **Step 2: Chạy test, thấy FAIL.**
- [ ] **Step 3: Viết theme, spacing, format và các widget** theo khối Interfaces.
- [ ] **Step 4: Chạy test, thấy PASS.** Run: `flutter test test/core`
- [ ] **Step 5: Commit.** `git add -A && git commit -m "feat: add dark theme, fonts and shared widgets"`

---

### Task 4: Database và TrackRepository

**Files:**
- Create: `lib/data/db/tables.dart`, `lib/data/db/database.dart` (+ `database.g.dart` do codegen sinh ra)
- Create: `lib/data/repositories/track_repository.dart`
- Create: `lib/sources/metadata/track_draft.dart`
- Test: `test/helpers/test_database.dart`, `test/data/track_repository_test.dart`

**Interfaces:**
- Consumes: `SourceType` (Task 1).
- Produces:
  - Các bảng đúng như spec mục 5.1. `tracks.source` là `textEnum<SourceType>()`. Có ràng buộc `UNIQUE(source, source_id)`. Data class sinh ra tên là `Track`, `Playlist`, `PlaylistEntry`, `SettingRow` (bảng `settings` tạo sẵn để khỏi phải migrate, nhưng chưa có repository).
  - `playlist_entries` có 2 FK `ON DELETE CASCADE` và index `(playlist_id, position)`.
  - `class AppDatabase extends _$AppDatabase`: `AppDatabase(QueryExecutor e)`, `static AppDatabase openDefault()` (dùng `driftDatabase(name: 'multi_musics')`), `schemaVersion = 1`. `MigrationStrategy.beforeOpen` chạy `PRAGMA foreign_keys = ON`.
  - `class TrackDraft extends Equatable { SourceType source; String sourceId; String originalUrl; String title; String? artist; String? artworkUrl; int? durationMs; }`
  - `class TrackRepository(AppDatabase db)`:
    - `Stream<List<Track>> watchAll()`: sắp theo `addedAt` giảm dần, nếu bằng nhau thì theo `id` giảm dần.
    - `Future<Track?> findBySource(SourceType source, String sourceId)`
    - `Future<Track> insert(TrackDraft draft)`: nếu đã có `(source, sourceId)` thì trả về bài cũ, không ghi đè. `addedAt = DateTime.now()`.
    - `Future<void> delete(int id)`
  - `test/helpers/test_database.dart`: `AppDatabase openTestDatabase()` → `AppDatabase(NativeDatabase.memory())`.

- [ ] **Step 1: Viết test thất bại** `track_repository_test.dart`
  - `insert then watchAll emits track`
  - `insert duplicate returns existing and does not add row`: insert 2 lần cùng `(youtube, 'dQw4w9WgXcQ')` khác title → cùng `id`, title là của lần đầu, `watchAll` có 1 phần tử.
  - `same sourceId different source are distinct`
  - `watchAll orders newest first`
  - `delete removes track`

- [ ] **Step 2: Viết `tables.dart`, `database.dart`, `track_draft.dart`**, rồi chạy `dart run build_runner build -d`.
- [ ] **Step 3: Chạy test, thấy FAIL** (chưa có `TrackRepository`). Run: `flutter test test/data/track_repository_test.dart`. Nếu báo lỗi không nạp được `sqlite3.dll` trên Windows: tải "Precompiled Binaries for Windows" (x64) ở sqlite.org, chép `sqlite3.dll` vào `C:\dev\sqlite\`, thêm thư mục đó vào PATH, ghi chú vào README rồi chạy lại.
- [ ] **Step 4: Viết `TrackRepository`.**
- [ ] **Step 5: Chạy test, thấy PASS.**
- [ ] **Step 6: Commit.** `git add -A && git commit -m "feat: add drift database and TrackRepository"`

---

### Task 5: PlaylistRepository và LibraryWriter

**Files:**
- Create: `lib/data/models/playlist_models.dart`, `lib/data/repositories/playlist_repository.dart`, `lib/data/repositories/library_writer.dart`
- Test: `test/data/playlist_repository_test.dart`, `test/data/library_writer_test.dart`

**Interfaces:**
- Consumes: `AppDatabase`, `Track`, `Playlist`, `PlaylistEntry`, `TrackRepository`, `TrackDraft` (Task 4).
- Produces:
  - `class PlaylistSummary extends Equatable { Playlist playlist; int trackCount; List<String> coverArtworks; }`: `coverArtworks` lấy tối đa 4 `artworkUrl` khác null đầu tiên theo `position`.
  - `class PlaylistItem extends Equatable { int entryId; int position; Track track; }`
  - `class PlaylistDetail extends Equatable { Playlist playlist; List<PlaylistItem> items; Duration get knownDuration; }`: `knownDuration` là tổng `durationMs` của các bài đã biết thời lượng.
  - `class PlaylistRepository(AppDatabase db)`:
    - `Stream<List<PlaylistSummary>> watchAll()`: sắp theo `updatedAt` giảm dần.
    - `Future<Playlist> create(String name)`
    - `Future<void> rename(int id, String name)`
    - `Future<void> delete(int id)`
    - `Stream<PlaylistDetail?> watchDetail(int id)`: trả `null` nếu playlist không tồn tại.
    - `Future<void> addTrackToPlaylists(int trackId, List<int> playlistIds)`: thêm vào cuối mỗi playlist, `position = max + 1`.
    - `Future<void> removeEntry(int entryId)`: sau khi xóa, đánh số lại `position` thành 0..n-1.
    - `Future<void> moveEntry(int playlistId, int fromIndex, int toIndex)`: ngữ nghĩa giống `list.insert(toIndex, list.removeAt(fromIndex))` (`toIndex` tính **sau khi** đã gỡ phần tử), chạy trong transaction, sau đó `position` liên tục 0..n-1.
    - Mọi thao tác ghi đều cập nhật `playlists.updatedAt` của playlist bị ảnh hưởng.
    - Tên playlist được trim. Tên rỗng thì ném `ArgumentError` (Bloc kiểm tra trước nên thực tế không xảy ra).
  - `class LibraryWriter(AppDatabase db, TrackRepository tracks, PlaylistRepository playlists)` với `Future<Track> addToLibrary(TrackDraft draft, {List<int> playlistIds = const []})`: `insert` cộng `addTrackToPlaylists` trong cùng một `db.transaction`.

- [ ] **Step 1: Viết test thất bại**
  - `create then watchAll shows summary with 0 tracks`
  - `addTrackToPlaylists appends at end` → các position là 0, 1, 2.
  - `same track twice in one playlist creates two entries`
  - `moveEntry down by one`: [A,B,C], `moveEntry(p, 0, 1)` → [B,A,C]. `moveEntry(p, 2, 0)` → [C,B,A]. Position luôn là 0,1,2.
  - `removeEntry renumbers`: [A,B,C] xóa B → [A,C], position 0,1.
  - `deleting track cascades entries`: xóa track bằng `TrackRepository.delete` → entry biến mất, `trackCount` giảm.
  - `delete playlist keeps tracks`
  - `coverArtworks takes first 4 non-null by position`
  - `watchDetail emits null after delete`
  - `knownDuration sums only known durations`
  - `library_writer_test`: `addToLibrary with playlists writes both`. Khi `playlistIds` chứa ID không tồn tại thì lỗi FK, cả transaction phải rollback, track **không** được tạo.

- [ ] **Step 2: Chạy test, thấy FAIL.**
- [ ] **Step 3: Viết model, `PlaylistRepository`, `LibraryWriter`.** Dùng các query join trong drift để lấy summary và detail.
- [ ] **Step 4: Chạy test, thấy PASS.** Run: `flutter test test/data`
- [ ] **Step 5: Commit.** `git add -A && git commit -m "feat: add PlaylistRepository and LibraryWriter"`

---

### Task 6: LinkParser

**Files:**
- Create: `lib/sources/link_parser.dart`
- Test: `test/sources/link_parser_test.dart`

**Interfaces:**
- Consumes: `SourceType`, `Result`, `Failure` (Task 1).
- Produces:
  - `class ParsedLink extends Equatable { SourceType source; String sourceId; String canonicalUrl; }`
  - `class LinkParser({required http.Client httpClient})` với `Future<Result<ParsedLink>> parse(String input)`.

**Quy tắc** (theo spec mục 5.2):
1. Trim input. Lấy token đầu tiên khớp `https?://\S+` hoặc `spotify:track:[A-Za-z0-9]{22}`, bỏ dấu câu dính ở cuối (`.,)]>"'`). Không tìm thấy → `InvalidLink`.
2. Host rút gọn là `on.soundcloud.com` hoặc `spotify.link`: gửi `http.Request('GET')` với `followRedirects = false`, đọc header `location`, lặp tối đa 5 lần, sau đó parse lại URL cuối. Lỗi mạng → `NetworkFailure`. Không ra được URL hợp lệ → `InvalidLink`.
3. **YouTube** (host `youtube.com`, `www.`, `m.`, `music.youtube.com`, `youtu.be`). Video ID khớp `^[A-Za-z0-9_-]{11}$`, lấy từ `?v=`, `/shorts/<id>`, `/live/<id>`, `/embed/<id>` hoặc path của `youtu.be/<id>`. Các path `/playlist`, `/channel/`, `/@…`, `/c/` → `UnsupportedLink`. `watch?v=X&list=Y` → vẫn là bài X. canonical: `https://www.youtube.com/watch?v=<id>`.
4. **Spotify** (`open.spotify.com`, có thể có tiền tố `/intl-xx/`; hoặc URI `spotify:track:`). Track ID khớp `^[A-Za-z0-9]{22}$`. Path `/album/`, `/playlist/`, `/artist/`, `/episode/`, `/show/` → `UnsupportedLink`. canonical: `https://open.spotify.com/track/<id>`.
5. **SoundCloud** (`soundcloud.com`, `www.`, `m.`). Path phải có đúng 2 đoạn `<user>/<slug>`, bỏ query. Đoạn đầu thuộc `{discover, search, you, stream, upload, charts, pages, settings}` → `InvalidLink`. Đoạn hai thuộc `{sets, likes, tracks, albums, reposts, popular-tracks, followers, following}`, hoặc path chỉ có 1 đoạn, hoặc có `/sets/` → `UnsupportedLink`. `sourceId = '<user>/<slug>'` (chữ thường). canonical: `https://soundcloud.com/<user>/<slug>`.
6. Các host khác → `InvalidLink`.

- [ ] **Step 1: Viết test thất bại** dạng bảng (≥ 30 dòng, mỗi dòng gồm input và kết quả mong đợi), tối thiểu có:
  - `https://www.youtube.com/watch?v=dQw4w9WgXcQ`, `https://youtu.be/dQw4w9WgXcQ?si=abc`, `https://m.youtube.com/watch?v=dQw4w9WgXcQ&t=30s`, `https://music.youtube.com/watch?v=dQw4w9WgXcQ&feature=share`, `https://www.youtube.com/shorts/dQw4w9WgXcQ`, `https://www.youtube.com/watch?v=dQw4w9WgXcQ&list=PLx` → tất cả ra `(youtube, 'dQw4w9WgXcQ')`.
  - `https://www.youtube.com/playlist?list=PLx` → `UnsupportedLink`. `https://www.youtube.com/@channel` → `UnsupportedLink`.
  - `https://open.spotify.com/track/4uLU6hMCjMI75M1A2tKUQC?si=x`, `https://open.spotify.com/intl-vi/track/4uLU6hMCjMI75M1A2tKUQC`, `spotify:track:4uLU6hMCjMI75M1A2tKUQC` → `(spotify, '4uLU6hMCjMI75M1A2tKUQC')`.
  - `https://open.spotify.com/album/…`, `/playlist/…` → `UnsupportedLink`.
  - `https://soundcloud.com/Artist/Song-Name?in=x`, `https://m.soundcloud.com/artist/song-name` → `(soundcloud, 'artist/song-name')`.
  - `https://soundcloud.com/artist/sets/album` và `https://soundcloud.com/artist` → `UnsupportedLink`. `https://soundcloud.com/discover/x` → `InvalidLink`.
  - `'  Nghe bài này nè https://youtu.be/dQw4w9WgXcQ.  \n'` → youtube `dQw4w9WgXcQ`.
  - `''`, `'hello'`, `https://example.com/x`, `https://youtu.be/short` → `InvalidLink`.
  - Link rút gọn: `MockClient` trả về `302` kèm `location: https://soundcloud.com/artist/song-name` cho `https://on.soundcloud.com/abc` → `(soundcloud, 'artist/song-name')`. `MockClient` ném `SocketException` → `NetworkFailure`.

- [ ] **Step 2: Chạy test, thấy FAIL.**
- [ ] **Step 3: Viết `LinkParser`** theo các quy tắc ở trên.
- [ ] **Step 4: Chạy test, thấy PASS.** Run: `flutter test test/sources/link_parser_test.dart`
- [ ] **Step 5: Commit.** `git add -A && git commit -m "feat: add LinkParser for YouTube, Spotify, SoundCloud links"`

---

### Task 7: OEmbedClient (metadata)

**Files:**
- Create: `lib/sources/metadata/metadata_fetcher.dart`, `lib/sources/metadata/oembed_client.dart`
- Create: `test/fixtures/oembed_youtube.json`, `oembed_soundcloud.json`, `oembed_spotify.json` (lấy từ response thật của 3 endpoint bên dưới)
- Test: `test/sources/metadata/oembed_client_test.dart`

**Interfaces:**
- Consumes: `ParsedLink` (Task 6), `TrackDraft` (Task 4).
- Produces:
  - `abstract interface class MetadataFetcher { Future<Result<TrackDraft>> fetch(ParsedLink link, {required String originalUrl}); }`
  - `class OEmbedClient({required http.Client httpClient}) implements MetadataFetcher`

**Quy tắc:**
- Endpoint (truyền `url = link.canonicalUrl`, nhớ URL-encode):
  - YouTube: `https://www.youtube.com/oembed?format=json&url=…`
  - SoundCloud: `https://soundcloud.com/oembed?format=json&url=…`
  - Spotify: `https://open.spotify.com/oembed?url=…`
- Ánh xạ: `title` → title. `author_name` → artist (Spotify thì artist = `null`). `thumbnail_url` → artworkUrl.
- YouTube: bỏ hậu tố `" - Topic"` ở cuối artist.
- SoundCloud: nếu title kết thúc bằng `" by <author_name>"` thì cắt phần đó đi.
- Timeout 10 giây. Mã 401, 403, 404 → `TrackUnavailable('Bài không tồn tại hoặc đang ở chế độ riêng tư')`. Mã 5xx, `SocketException`, `TimeoutException`, `http.ClientException` → `NetworkFailure`. JSON hỏng hoặc thiếu `title` → `UnknownFailure`.

- [ ] **Step 1: Viết test thất bại** dùng `MockClient` và fixture:
  - YouTube fixture có `author_name: "Rick Astley - Topic"` → artist `'Rick Astley'`.
  - SoundCloud fixture có `title: "Song Name by Artist"`, `author_name: "Artist"` → title `'Song Name'`.
  - Spotify → artist `null`, `artworkUrl` khớp fixture.
  - Request gửi đi có `url` đã encode của canonical URL.
  - 404 → `TrackUnavailable`. 503 → `NetworkFailure`. `SocketException` → `NetworkFailure`. Body `'not json'` → `UnknownFailure`.
- [ ] **Step 2: Chạy test, thấy FAIL.**
- [ ] **Step 3: Viết `OEmbedClient`.**
- [ ] **Step 4: Chạy test, thấy PASS.**
- [ ] **Step 5: Commit.** `git add -A && git commit -m "feat: add oEmbed metadata fetcher"`

---

### Task 8: AddTrackBloc

**Files:**
- Create: `lib/features/library/bloc/add_track_bloc.dart` (+ `add_track_event.dart`, `add_track_state.dart`)
- Test: `test/features/library/add_track_bloc_test.dart`

**Interfaces:**
- Consumes: `LinkParser.parse` (Task 6), `MetadataFetcher.fetch` (Task 7), `TrackRepository.findBySource` (Task 4), `LibraryWriter.addToLibrary`, `PlaylistRepository.addTrackToPlaylists` (Task 5), `AppLogger` (Task 2).
- Produces:
  - Events: `AddTrackLinkSubmitted(String input)`, `AddTrackPlaylistToggled(int playlistId)`, `AddTrackConfirmed()`, `AddTrackReset()`.
  - `enum AddTrackStatus { idle, resolving, preview, saving, done, failure }`
  - `class AddTrackState extends Equatable { AddTrackStatus status; TrackDraft? draft; Track? existing; Set<int> selectedPlaylistIds; Failure? failure; Track? saved; }`
  - Hàm khởi tạo: `AddTrackBloc({required LinkParser parser, required MetadataFetcher metadata, required TrackRepository tracks, required LibraryWriter writer, required PlaylistRepository playlists, required AppLogger logger})`

**Hành vi:**
- `LinkSubmitted`: emit `resolving` → parse. Nếu lỗi thì emit `failure`. Nếu `findBySource` thấy bài đã có thì emit `preview(existing: track, draft: <tạo từ track>)`, **không** gọi metadata. Ngược lại thì gọi `fetch(parsed, originalUrl: <input đã trim>)` rồi emit `preview(draft)` hoặc `failure`. Mỗi lần submit mới thì xóa lựa chọn playlist cũ. Mọi `Failure` đều được ghi qua `logger.warn('add-track', …)`.
- `PlaylistToggled`: bật hoặc tắt ID trong `selectedPlaylistIds` (chỉ khi đang ở `preview`).
- `Confirmed`: emit `saving`. Nếu là bài đã có thì `addTrackToPlaylists(existing.id, selected)` (bỏ qua nếu không chọn playlist nào). Nếu là bài mới thì `writer.addToLibrary(draft, playlistIds: selected)`. Xong thì emit `done(saved: track)`. Lỗi bất ngờ → `failure(UnknownFailure)`.
- `Reset` → trạng thái ban đầu (`idle`).

- [ ] **Step 1: Viết test thất bại** (`bloc_test`, mock bằng `mocktail`):
  - `valid new link → [resolving, preview(draft)]`
  - `invalid link → [resolving, failure(InvalidLink)]` và **không** gọi metadata.
  - `existing track → [resolving, preview(existing)]`, metadata không được gọi. Review Focus #2: `youtu.be/X` khi bài `watch?v=X` đã có thì vẫn ra `existing`.
  - `metadata failure → [resolving, failure(NetworkFailure)]`
  - `toggle twice removes selection`
  - `confirm new with playlists calls addToLibrary(draft, playlistIds: [1,2]) → [saving, done]`
  - `confirm existing with no playlists → [saving, done]` và không gọi `addTrackToPlaylists`.
  - `resubmit clears previous selection`
- [ ] **Step 2: Chạy test, thấy FAIL.**
- [ ] **Step 3: Viết Bloc.**
- [ ] **Step 4: Chạy test, thấy PASS.**
- [ ] **Step 5: Commit.** `git add -A && git commit -m "feat: add AddTrackBloc"`

---

### Task 9: LibraryBloc và trang Thư viện

**Files:**
- Create: `lib/core/text/fold_vietnamese.dart`, `lib/core/widgets/track_tile.dart`
- Create: `lib/features/library/bloc/library_bloc.dart` (+ event, state)
- Create: `lib/features/library/view/library_page.dart`
- Test: `test/core/text/fold_vietnamese_test.dart`, `test/core/widgets/track_tile_test.dart`, `test/features/library/library_bloc_test.dart`, `test/features/library/library_page_test.dart`

**Interfaces:**
- Consumes: `TrackRepository.watchAll`, `delete` (Task 4); `ArtworkImage`, `EmptyState`, `SkeletonList`, `SourceBadge`, `formatTrackDuration` (Task 3).
- Produces:
  - `TrackTile({required Track track, VoidCallback? onTap, Widget? trailing})`: ảnh 48, tên (`titleMedium`, 1 dòng, ellipsis), dòng phụ gồm `artist ?? ''` và thời lượng nếu biết (`mutedForeground`, 1 dòng, ellipsis), `SourceBadge` ở cuối dòng. Bài có `unavailableReason != null` thì hiện thêm icon `LucideIcons.triangleAlert` màu `destructive`. Chiều cao tối thiểu 56. Dùng ở cả Thư viện và Chi tiết playlist.
  - `String foldVietnamese(String s)`: chuyển về chữ thường, bỏ dấu tiếng Việt bằng bảng ánh xạ đầy đủ (a/ă/â, e/ê, i, o/ô/ơ, u/ư, y với 5 dấu thanh, và `đ` → `d`).
  - Events: `LibrarySubscriptionRequested()`, `LibraryQueryChanged(String query)`, `LibrarySourceToggled(SourceType source)`, `LibraryTrackDeleted(int trackId)`.
  - `class LibraryState extends Equatable { LibraryStatus status (loading|ready); List<Track> all; String query; Set<SourceType> sources; List<Track> get visible; }`: `sources` rỗng nghĩa là lấy tất cả nguồn. `visible` lọc các bài mà `foldVietnamese(title + ' ' + (artist ?? ''))` chứa `foldVietnamese(query.trim())`.
  - `LibraryPage`: tiêu đề "Thư viện", nút `+` (tooltip "Thêm bài") gọi callback `onAddPressed` (Task 10 nối vào sheet). Ô lọc có hint "Lọc theo tên bài, nghệ sĩ". Hàng chip 3 nguồn. Danh sách `TrackTile` có `ValueKey(track.id)`, bọc trong `Dismissible`:
    - **Vuốt sang trái** (nền `destructive`, icon thùng rác): xóa bài. `confirmDismiss` mở hộp thoại xác nhận.
    - **Vuốt sang phải** (nền `accent`, icon `LucideIcons.listPlus`): thêm vào playlist. `confirmDismiss` gọi callback `onAddToPlaylist(track)` (Task 11 nối vào) rồi trả `false` để dòng bật về chỗ cũ.
    - *(Lệch nhỏ so với spec mục 9, vốn ghi "vuốt trái → 2 hành động": `Dismissible` không hỗ trợ 2 hành động cùng một hướng, và cách này giúp không phải thêm package.)*
  - Chữ trên UI:
    - Trạng thái rỗng: `EmptyState(title: 'Chưa có bài nào', message: 'Bấm + để dán link từ Spotify, YouTube hoặc SoundCloud')`
    - Lọc không ra kết quả: "Không có bài nào khớp"
    - Hộp thoại xóa: tiêu đề "Xóa bài này?", nội dung "Bài sẽ bị gỡ khỏi mọi playlist.", nút "Hủy" / "Xóa"
  - Đang `loading` thì hiện `SkeletonList`.

- [ ] **Step 1: Viết test thất bại**
  - `fold_vietnamese_test`: `foldVietnamese('Mưa Đêm Ướt Át') == 'mua dem uot at'`; `foldVietnamese('Hạ Vũ') == 'ha vu'`.
  - `track_tile_test` (Review Focus #5): track tên dài 200 ký tự, `textScale: 2.0`, khung rộng 375 → `tester.takeException() == null`. Track có `unavailableReason` → tìm thấy icon `LucideIcons.triangleAlert`. `durationMs: 185000` → hiện "3:05".
  - `library_bloc_test`: sau subscription thì `ready` với dữ liệu từ stream. Query `mua` ra "Mưa", query `dem` ra "Đêm" (Review Focus #3). Bật nguồn `youtube` thì chỉ còn bài YouTube, bật lại lần nữa thì hiện lại tất cả. Event xóa gọi `tracks.delete(id)`.
  - `library_page_test` (MockBloc): `loading` → có `SkeletonList`. `ready` và rỗng → có chữ "Chưa có bài nào". Có dữ liệu → đúng số `TrackTile`. Gõ vào ô lọc → bloc nhận `LibraryQueryChanged`.
- [ ] **Step 2: Chạy test, thấy FAIL.**
- [ ] **Step 3: Viết `foldVietnamese`, `LibraryBloc`, `LibraryPage`.**
- [ ] **Step 4: Chạy test, thấy PASS.**
- [ ] **Step 5: Commit.** `git add -A && git commit -m "feat: add Library page with Vietnamese-insensitive filter"`

---

### Task 10: Sheet Thêm bài

**Files:**
- Create: `lib/features/library/view/add_track_sheet.dart`
- Test: `test/features/library/add_track_sheet_test.dart`

**Interfaces:**
- Consumes: `AddTrackBloc` (Task 8); danh sách playlist qua `PlaylistsBloc` state (Task 11). *(Nếu làm task này trước Task 11 thì truyền `List<PlaylistSummary>` qua tham số. Đề xuất: sheet nhận tham số `List<PlaylistSummary> playlists` để không phụ thuộc vào Bloc.)*
- Produces: `Future<Track?> showAddTrackSheet(BuildContext context, {required List<PlaylistSummary> playlists})`. Hàm này tự tạo `AddTrackBloc` lấy từ các repository trong context, và trả về bài đã lưu (hoặc `null` nếu người dùng đóng sheet).

**UI** (bottom sheet, góc trên bo `radiusSheet`, tôn trọng safe area):
- Tiêu đề "Thêm bài". Nút lớn "Dán link" (icon `LucideIcons.clipboardPaste`) đọc `Clipboard.getData('text/plain')` rồi gửi `LinkSubmitted`. Clipboard trống thì gửi `LinkSubmitted('')`, kết quả là `InvalidLink`.
- Ghi chú nhỏ bên dưới nút: "Lần đầu iOS sẽ hỏi quyền dán. Để không bị hỏi lại: Cài đặt iOS → Multi Musics → Dán từ app khác → Cho phép."
- `resolving`: hàng preview dạng skeleton. `failure`: dòng chữ `failure.message` màu `destructive`, nằm ngay dưới nút Dán.
- `preview`: ảnh 64, tên, nghệ sĩ, `SourceBadge(showLabel: true)`. Nếu là bài đã có thì thêm chip "Đã có trong thư viện". Tiếp theo là mục "Thêm vào playlist" với các `CheckboxListTile` (key `ValueKey(playlistId)`), sau đó nút chính: "Thêm" cho bài mới; "Lưu" cho bài đã có mà có chọn playlist; "Đóng" cho bài đã có mà không chọn playlist nào.
- `done`: đóng sheet, trả về track, gọi `HapticFeedback.lightImpact()`. Bên gọi hiện snackbar "Đã thêm: <title>".

- [ ] **Step 1: Viết test thất bại** (MockBloc được inject qua một constructor nội bộ `AddTrackSheetView(bloc)`):
  - Trạng thái `failure(UnsupportedLink())` → hiện đúng message.
  - `preview` với `existing` → có chip "Đã có trong thư viện" và nút "Đóng". Bấm vào một checkbox playlist → bloc nhận `AddTrackPlaylistToggled(id)`.
  - `preview` bài mới → có nút "Thêm". Bấm → bloc nhận `AddTrackConfirmed`.
- [ ] **Step 2: Chạy test, thấy FAIL.**
- [ ] **Step 3: Viết sheet.**
- [ ] **Step 4: Chạy test, thấy PASS.**
- [ ] **Step 5: Commit.** `git add -A && git commit -m "feat: add Add Track sheet"`

---

### Task 11: PlaylistsBloc, trang Playlist, sheet "Thêm vào playlist"

**Files:**
- Create: `lib/features/playlists/bloc/playlists_bloc.dart` (+ event, state)
- Create: `lib/features/playlists/view/playlists_page.dart`, `lib/features/playlists/widgets/playlist_cover.dart`, `lib/features/playlists/view/add_to_playlist_sheet.dart`, `lib/features/playlists/view/playlist_name_dialog.dart`
- Test: `test/features/playlists/playlists_bloc_test.dart`, `test/features/playlists/playlists_page_test.dart`

**Interfaces:**
- Consumes: `PlaylistRepository.watchAll`, `create`, `addTrackToPlaylists` (Task 5).
- Produces:
  - Events: `PlaylistsSubscriptionRequested()`, `PlaylistsCreated(String name)`, `PlaylistsTrackAdded(int trackId, List<int> playlistIds)`.
  - `class PlaylistsState extends Equatable { PlaylistsStatus status (loading|ready); List<PlaylistSummary> playlists; }`
  - Đổi tên và xóa nằm ở `PlaylistDetailBloc` (Task 12), vì UI chỉ có các thao tác này ở trang chi tiết. Đây là điểm lệch nhỏ so với bảng ở spec mục 4.3.
  - `Future<String?> showPlaylistNameDialog(BuildContext, {String title = 'Playlist mới', String initial = '', String confirmLabel = 'Tạo'})`: ô nhập có label "Tên playlist", trim, tối đa 100 ký tự. Nút xác nhận bị vô hiệu khi tên rỗng. Hai nút "Hủy" và `confirmLabel`.
  - `PlaylistCover({required List<String> artworks, required double size})`: có 0 ảnh thì hiện placeholder, 1–3 ảnh thì hiện ảnh đầu, đủ 4 ảnh thì ghép lưới 2×2.
  - `PlaylistsPage({required void Function(int playlistId) onOpen})`: tiêu đề "Playlist", nút `+` (tooltip "Tạo playlist"). Lưới 2 cột gồm cover, tên (1 dòng) và "<n> bài". Item có key `ValueKey(playlist.id)`.
    - Trạng thái rỗng: `EmptyState(title: 'Chưa có playlist', message: 'Tạo playlist để gom bài từ nhiều nguồn', action: nút 'Tạo playlist')`.
  - `Future<void> showAddToPlaylistSheet(BuildContext, Track track)`: danh sách playlist có checkbox, nút "Thêm" → gửi `PlaylistsTrackAdded`, snackbar "Đã thêm vào <n> playlist". Có một dòng "Tạo playlist mới" ở trên cùng để tạo nhanh.

- [ ] **Step 1: Viết test thất bại**
  - Bloc: subscription → `ready`. `PlaylistsCreated('  Chill  ')` → `repo.create('Chill')`. `PlaylistsCreated('   ')` → không gọi repo. `PlaylistsTrackAdded(5, [1,2])` → `addTrackToPlaylists(5, [1,2])`.
  - Page: rỗng → có chữ "Chưa có playlist". 3 playlist → 3 ô, ô đầu hiện "2 bài". Bấm vào một ô → `onOpen(id)`.
- [ ] **Step 2: Chạy test, thấy FAIL.**
- [ ] **Step 3: Viết các file trên.**
- [ ] **Step 4: Chạy test, thấy PASS.**
- [ ] **Step 5: Commit.** `git add -A && git commit -m "feat: add Playlists page and add-to-playlist sheet"`

---

### Task 12: PlaylistDetailBloc và trang chi tiết playlist

**Files:**
- Create: `lib/features/playlists/bloc/playlist_detail_bloc.dart` (+ event, state)
- Create: `lib/features/playlists/view/playlist_detail_page.dart`
- Test: `test/features/playlists/playlist_detail_bloc_test.dart`, `test/features/playlists/playlist_detail_page_test.dart`

**Interfaces:**
- Consumes: `PlaylistRepository.watchDetail`, `rename`, `delete`, `removeEntry`, `moveEntry` (Task 5); `TrackTile`, `PlaylistCover`, `showPlaylistNameDialog`, `formatTotalDuration`.
- Produces:
  - Events: `PlaylistDetailSubscriptionRequested(int playlistId)`, `PlaylistDetailRenamed(String name)`, `PlaylistDetailDeleted()`, `PlaylistDetailEntryRemoved(int entryId)`, `PlaylistDetailEntryMoved(int oldIndex, int newIndex)`. `PlayRequested` sẽ được thêm ở Kế hoạch 2.
  - `class PlaylistDetailState extends Equatable { PlaylistDetailStatus status (loading|ready|notFound|deleted); PlaylistDetail? detail; }`
  - `EntryMoved` nhận **chỉ số thô từ `ReorderableListView.onReorder`**. Bloc tự chỉnh: `if (newIndex > oldIndex) newIndex -= 1`. Sau đó emit ngay danh sách đã sắp lại (cập nhật lạc quan, tránh UI bị nháy) rồi mới gọi `moveEntry(playlistId, oldIndex, newIndex)`.
  - `Deleted` → gọi `repo.delete` → emit `deleted`. Khi stream trả `null` mà trước đó chưa ở trạng thái `deleted` → emit `notFound`.
  - `PlaylistDetailPage({required int playlistId})`:
    - Header gồm `PlaylistCover` 160, tên (`displaySmall`), dòng "<n> bài · <formatTotalDuration(knownDuration)>".
    - Menu (icon `LucideIcons.ellipsis`, tooltip "Tùy chọn") có "Đổi tên" (mở dialog với tiêu đề "Đổi tên playlist", nút "Lưu") và "Xóa playlist" (hộp thoại xác nhận: tiêu đề `Xóa playlist "<name>"?`, nội dung "Các bài vẫn còn trong thư viện.", nút "Hủy" / "Xóa").
    - Danh sách dùng `ReorderableListView.builder`, mỗi item có key `ValueKey(entryId)`, `TrackTile` cộng tay kéo. Vuốt để gỡ khỏi playlist (không cần xác nhận, có snackbar "Đã gỡ khỏi playlist"). Gọi `HapticFeedback.selectionClick()` khi bắt đầu kéo.
    - Playlist trống: `EmptyState(title: 'Playlist trống', message: 'Thêm bài từ tab Thư viện')`.
    - `deleted` hoặc `notFound` → `context.pop()`.

- [ ] **Step 1: Viết test thất bại**
  - Bloc: subscription → `ready(detail)`. Review Focus #4: với [A,B,C], `EntryMoved(0, 2)` (kéo A xuống 1 ô) → emit thứ tự [B,A,C] và gọi `moveEntry(id, 0, 1)`; `EntryMoved(2, 0)` → [C,A,B] và gọi `moveEntry(id, 2, 0)`. `Renamed('X')` → `rename`. `Deleted` → `[deleted]` và gọi `delete`. Stream phát `null` → `notFound`.
  - Page: header hiện "3 bài · 12 phút". Trạng thái rỗng hiện "Playlist trống". Mỗi item có key `ValueKey(entryId)`.
- [ ] **Step 2: Chạy test, thấy FAIL.**
- [ ] **Step 3: Viết Bloc và trang.**
- [ ] **Step 4: Chạy test, thấy PASS.**
- [ ] **Step 5: Commit.** `git add -A && git commit -m "feat: add Playlist detail with reorder, rename, delete"`

---

### Task 13: App shell, router, DI, chế độ demo trên desktop

**Files:**
- Create: `lib/app.dart`, `lib/app_dependencies.dart`, `lib/features/shell/app_shell.dart`, `lib/features/settings/view/settings_page.dart`
- Create: `lib/fakes/fake_metadata_fetcher.dart`, `lib/fakes/demo_seed.dart`
- Modify: `lib/main.dart`
- Test: `test/app_smoke_test.dart`, `test/fakes/demo_seed_test.dart`

**Interfaces:**
- Consumes: tất cả các task trước.
- Produces:
  - `class AppDependencies { AppDatabase db; AppLogger logger; TrackRepository tracks; PlaylistRepository playlists; LibraryWriter writer; LinkParser linkParser; MetadataFetcher metadata; static Future<AppDependencies> create({required bool fake, required AppLogger logger, AppDatabase? db}); }`
    - Với `fake = true`: dùng `FakeMetadataFetcher` và gọi `seedDemoData` nếu thư viện trống. `LinkParser` vẫn là bản thật.
  - `MultiMusicsApp(AppDependencies deps)`: `MultiRepositoryProvider` cho mọi dependency; `BlocProvider` cấp app cho `LibraryBloc` và `PlaylistsBloc` (đã subscribe sẵn). Dùng `MaterialApp.router(theme: AppTheme.dark(), title: 'Multi Musics')`.
  - Router (`go_router`, `StatefulShellRoute.indexedStack`), `initialLocation: '/library'`:
    - `/library`
    - `/playlists`, với route con `/playlists/:id` mở `PlaylistDetailPage`
    - `/settings`
  - `AppShell`: `NavigationBar` gồm 3 mục "Thư viện" (`LucideIcons.library`), "Playlist" (`LucideIcons.listMusic`), "Cài đặt" (`LucideIcons.settings`). Chừa một `SizedBox.shrink()` phía trên NavigationBar làm chỗ cho mini player ở Kế hoạch 2.
  - Nối các callback: `LibraryPage.onAddPressed` → `showAddTrackSheet` (playlists lấy từ `PlaylistsBloc.state`) → snackbar "Đã thêm: <title>". `onAddToPlaylist` → `showAddToPlaylistSheet`. `PlaylistsPage.onOpen` → `context.go('/playlists/$id')`.
  - `SettingsPage`: tạm thời chỉ có tiêu đề "Cài đặt" và dòng "Phiên bản <version> (<buildNumber>)" lấy từ `package_info_plus`.
  - `FakeMetadataFetcher`: trả về `TrackDraft(title: 'Bài demo <sourceId>', artist: 'Nghệ sĩ demo', artworkUrl: 'https://picsum.photos/seed/<sourceId>/300/300')`.
  - `Future<void> seedDemoData(AppDependencies deps)`: chỉ chạy khi `tracks` trống. Tạo 20 bài (7 YouTube, 7 SoundCloud, 6 Spotify). Tên có dấu tiếng Việt, trong đó có ít nhất "Mưa Tháng Sáu" và "Đêm Trăng". `durationMs` ngẫu nhiên với seed cố định. Ảnh dùng picsum theo seed. Tạo 3 playlist "Chill tối", "Tập gym", "Nhạc Việt", mỗi playlist 5–8 bài trộn nhiều nguồn.
  - `main.dart`: đọc `const bool.fromEnvironment('FAKE_SOURCES')` → `AppDependencies.create(...)` → `runApp(MultiMusicsApp(deps))`.

- [ ] **Step 1: Viết test thất bại**
  - `demo_seed_test`: DB trong bộ nhớ → `seedDemoData` → 20 bài, 3 playlist. Gọi lần 2 thì không đổi.
  - `app_smoke_test`: pump `MultiMusicsApp` với deps fake trên DB trong bộ nhớ → thấy chữ "Thư viện" và ít nhất 1 `TrackTile`. Bấm tab "Playlist" → thấy "Chill tối". Bấm vào "Chill tối" → thấy trang chi tiết có dòng "<n> bài".
- [ ] **Step 2: Chạy test, thấy FAIL.**
- [ ] **Step 3: Viết các file trên.**
- [ ] **Step 4: Chạy test, thấy PASS.** Run: `flutter analyze && flutter test --exclude-tags live`
- [ ] **Step 5: Kiểm tra bằng tay trên Windows.** Run: `flutter run -d windows --dart-define=FAKE_SOURCES=true`
  Expected: thấy 20 bài demo. Gõ `mua` vào ô lọc thì ra "Mưa Tháng Sáu". Kéo thả trong "Chill tối" giữ nguyên thứ tự sau khi khởi động lại app. Dán link YouTube thật vào sheet thì hiện preview "Bài demo …" (bản fake).
  Run: `flutter run -d windows` (dùng dữ liệu thật). Dán `https://youtu.be/dQw4w9WgXcQ` → preview đúng tên bài thật.
- [ ] **Step 6: Commit.** `git add -A && git commit -m "feat: wire app shell, router, DI and demo mode"`

---

### Task 14: Pipeline build IPA, GitHub repo và lần cài đầu tiên lên iPhone

**Files:**
- Create: `scripts/build_unsigned_ipa.sh`, `.github/workflows/release.yml`, `codemagic.yaml`
- Modify: `ios/Runner/Info.plist` (`CFBundleDisplayName` = `Multi Musics`), `README.md` (mục "Cài lên iPhone")

**Interfaces:**
- Consumes: app hoàn chỉnh từ Task 13.
- Produces: IPA `multi-musics-<tag>.ipa` đính kèm trong GitHub Release.

- [ ] **Step 1: Viết `scripts/build_unsigned_ipa.sh`** (đúng nội dung spec mục 11):

```bash
#!/usr/bin/env bash
set -euo pipefail
TAG="${1:?usage: build_unsigned_ipa.sh <tag>}"
VERSION="${TAG#v}"
BUILD_NUMBER="$(git rev-list --count HEAD)"
flutter pub get
dart run build_runner build -d
flutter test --exclude-tags live
flutter build ios --release --no-codesign --build-name="$VERSION" --build-number="$BUILD_NUMBER"
rm -rf build/ipa && mkdir -p build/ipa/Payload
cp -R build/ios/iphoneos/Runner.app build/ipa/Payload/
(cd build/ipa && zip -qr "multi-musics-$TAG.ipa" Payload)
echo "IPA: build/ipa/multi-musics-$TAG.ipa"
```
  Chạy `git update-index --chmod=+x scripts/build_unsigned_ipa.sh`. Kiểm tra cú pháp trên Windows bằng `bash -n scripts/build_unsigned_ipa.sh`, kết quả mong đợi là không in ra gì.

- [ ] **Step 2: Viết `.github/workflows/release.yml`.** Trigger `push: tags: ['v*']`. `permissions: contents: write`. Runner `macos-latest`. Các bước: `actions/checkout@v4` với `fetch-depth: 0` → `subosito/flutter-action@v2` (`flutter-version-file: pubspec.yaml`, `cache: true`) → `bash scripts/build_unsigned_ipa.sh "$GITHUB_REF_NAME"` → `softprops/action-gh-release@v2` với `files: build/ipa/*.ipa`.

- [ ] **Step 3: Viết `codemagic.yaml`.** Workflow `ios-unsigned`: `instance_type: mac_mini_m2`, `max_build_duration: 60`, `environment.flutter` là phiên bản đúng như trong `pubspec.yaml`, script `bash scripts/build_unsigned_ipa.sh "${CM_TAG:-v0.0.0-cm${BUILD_NUMBER}}"`, `artifacts: [build/ipa/*.ipa]`. Không cấu hình gửi email (repo public).

- [ ] **Step 4: Commit.** `git add -A && git commit -m "ci: add unsigned IPA release pipeline"`

- [ ] **Step 5: Tạo repo GitHub public và push.** ⚠️ Đây là thao tác ra bên ngoài. **Hỏi người dùng trước**, xác nhận tên repo và việc để public. Run: `gh repo create multi-musics --public --source . --push`
  Expected: workflow `ci.yml` trên tab Actions báo xanh.

- [ ] **Step 6: Phát hành bản đầu tiên.** Hỏi người dùng trước, rồi chạy `git tag v0.1.0 && git push origin v0.1.0`.
  Expected: workflow `release.yml` xanh. Release `v0.1.0` có file `multi-musics-v0.1.0.ipa`.

- [ ] **Step 7: Người dùng cài lên iPhone (thao tác thủ công, mình hướng dẫn từng bước).** Cài SideStore theo hướng dẫn chính thức tại docs.sidestore.io (cần PC Windows một lần để tạo pairing file, cộng app VPN mà SideStore yêu cầu). Sau đó trong SideStore: **+** → dán URL của IPA trong Release → cài.
  Expected: mở app Multi Musics trên iPhone, thấy tab Thư viện trống. Dán link YouTube → thêm được. Tạo playlist được. Mở SideStore thấy ngày hết hạn sau 7 ngày.

- [ ] **Step 8: Ghi kết quả vào README** (mục "Cài lên iPhone": các bước thực tế đã làm và lỗi gặp phải nếu có), rồi commit `docs: document iPhone install via SideStore`.
