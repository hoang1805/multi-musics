# Multi Musics

App iOS cá nhân (Flutter + BLoC) gom nhạc từ Spotify, YouTube và SoundCloud vào playlist chung.

- Spec: [docs/superpowers/specs/2026-10-04-multi-musics-design.md](docs/superpowers/specs/2026-10-04-multi-musics-design.md)
- Design system: [design-system/multi-musics/MASTER.md](design-system/multi-musics/MASTER.md)
- Kế hoạch: [docs/superpowers/plans/](docs/superpowers/plans/)

## Yêu cầu

- Flutter SDK — đúng phiên bản ghi ở `pubspec.yaml` (`environment.flutter`).
- Không cần Mac: build iOS chạy trên GitHub Actions / Codemagic.

## Lệnh thường dùng

```bash
flutter pub get
dart run build_runner build -d      # sinh code drift (*.g.dart) — chạy lại sau khi sửa bảng
flutter analyze
flutter test --exclude-tags live    # test thường
flutter test --tags live            # test gọi mạng thật (YouTube/SoundCloud)
```

Chế độ demo (dữ liệu mẫu, metadata giả): thêm `--dart-define=FAKE_SOURCES=true` khi build/chạy.
