# Design System Master File — Multi Musics

> **LOGIC:** Khi build một màn hình, kiểm tra `design-system/multi-musics/pages/[tên-màn-hình].md` trước.
> Nếu file đó tồn tại, quy tắc trong đó **ghi đè** file Master này. Nếu không, theo đúng Master.

**Nền tảng:** Flutter, chỉ iOS (iPhone XS Max, iOS 18) — có chạy desktop Windows với dữ liệu giả để dev UI.
**Nguồn gốc:** Sinh bởi `ui-ux-pro-max` (query "music streaming player dark immersive", Motion 4/10, Density 5/10), sau đó chỉnh tay theo quyết định trong spec `docs/superpowers/specs/2026-10-04-multi-musics-design.md`. Các chỗ lệch khỏi gợi ý của tool được ghi rõ lý do.

---

## Phong cách

**Dark Mode (OLED)** — chỉ dark theme (không có light theme).
- Nền gần đen, chữ tương phản cao, ít phát sáng trắng.
- Màn hình Now Playing: nền gradient lấy từ màu ảnh bìa (`ColorScheme.fromImageProvider`), phủ một lớp tối để chữ vẫn đạt tương phản ≥ 4.5:1.

## Màu (định nghĩa trong `ThemeData` / `ThemeExtension`, không hard-code trong widget)

| Token | Hex | Dùng cho |
|---|---|---|
| `background` | `#0B0B16` | Nền scaffold |
| `surface` / `card` | `#1B1B30` | Card, sheet, mini player |
| `muted` | `#27273B` | Ô input, skeleton, divider đậm |
| `border` | `#312E81` | Viền mảnh khi cần |
| `onBackground` | `#F8FAFC` | Chữ chính |
| `mutedForeground` | `#94A3B8` | Chữ phụ (nghệ sĩ, thời lượng) |
| `accent` | `#818CF8` | Nút chính, thanh tua, trạng thái active |
| `onAccent` | `#0B0B16` | Chữ/icon trên nền accent |
| `destructive` | `#EF4444` | Xóa, lỗi |
| `sourceSpotify` | `#1DB954` | Badge nguồn |
| `sourceYouTube` | `#FF0033` | Badge nguồn |
| `sourceSoundCloud` | `#FF5500` | Badge nguồn |

**Lệch khỏi gợi ý tool:** tool đề xuất accent `#22C55E` (xanh lá) — đổi sang indigo `#818CF8` vì xanh lá trùng màu thương hiệu Spotify, gây nhầm giữa "màu app" và "nguồn Spotify". Background đổi `#0F0F23` → `#0B0B16` (tối hơn cho OLED).

Tương phản đã kiểm: `accent` trên `background` ≈ 6.5:1; `mutedForeground` trên `card` ≈ 6.6:1; `onAccent` trên `accent` ≈ 6.5:1.

Badge nguồn **luôn gồm logo** (simple_icons), không truyền tải thông tin chỉ bằng màu.

## Typography

- **Font:** Be Vietnam Pro (bundle trong `assets/fonts/`, weights 400/500/600/700). Không dùng `google_fonts` runtime fetch.
- **Lệch khỏi gợi ý tool:** tool đề xuất Righteous + Poppins — không hỗ trợ đầy đủ ký tự tiếng Việt (ạ, ế, ữ…), mà tên bài hát Việt là nội dung chính.
- Thang chữ qua `TextTheme`: `displaySmall` 28/700 (tiêu đề màn hình), `titleLarge` 22/600 (tên bài ở Now Playing), `titleMedium` 16/600 (tên bài trong list), `bodyMedium` 14/400, `labelSmall` 12/500 (badge, thời lượng). Không có chữ nội dung < 12.
- Hỗ trợ Dynamic Type: không khóa `textScaler`; layout phải chịu được cỡ chữ lớn nhất (ellipsis cho tên bài, không overflow).

## Spacing (Density 5/10)

`xs 4` · `sm 8` · `md 16` · `lg 24` · `xl 32` · `2xl 48`. Padding ngang màn hình: 16. Bo góc: card 12, ảnh bìa trong list 8, sheet 20 (góc trên).

## Icon

- `lucide_icons_flutter` cho toàn bộ icon UI; `simple_icons` cho logo Spotify/YouTube/SoundCloud.
- Không dùng emoji làm icon. Icon-only button phải có `Semantics(label: ...)` / `tooltip`.

## Motion (Motion 4/10)

- Thời lượng 150–300ms; exit nhanh hơn enter. Mở Now Playing: slide-up + fade ~300ms; đóng ~200ms.
- List xuất hiện lần đầu: stagger nhẹ (fade + dịch 8–16px, mỗi item ~40ms, tối đa ~8 item đầu).
- `MediaQuery.disableAnimations` (Reduce Motion của iOS) = true → bỏ stagger/slide, chỉ đổi trạng thái ngay.

## Tương tác

- Vùng chạm tối thiểu **44×44pt** (icon nhỏ hơn thì mở rộng hit area).
- Tôn trọng **safe area** (notch + home indicator của XS Max) cho app bar, mini player, tab bar.
- **Haptic:** `HapticFeedback.lightImpact` khi play/pause, thêm bài thành công; `selectionClick` khi kéo thả sắp xếp.
- Loading: skeleton cho list/metadata; ảnh qua `cached_network_image` với placeholder cố định kích thước (không nhảy layout).
- Mọi list có **empty state** có hướng dẫn hành động tiếp theo.
- List động dùng `ValueKey(id)` cho từng item (bắt buộc với list kéo thả).
- Theme lấy qua `Theme.of(context)` / extension; không `TextStyle(fontSize: …)` hay `Color(0xFF…)` rải rác trong widget.

## Anti-patterns (KHÔNG dùng)

- ❌ Emoji làm icon
- ❌ Chỉ dùng màu để phân biệt nguồn
- ❌ Chữ phụ tương phản < 4.5:1
- ❌ Đổi trạng thái tức thì 0ms (trừ khi Reduce Motion bật)
- ❌ UI nằm dưới notch / home indicator
- ❌ Layout bố cục rối; player UX kém (nút nhỏ, không có feedback)

## Pre-Delivery Checklist (mỗi màn hình)

- [ ] Không emoji làm icon; icon cùng bộ Lucide
- [ ] Touch target ≥ 44×44pt
- [ ] Safe area đúng ở trên và dưới
- [ ] Tương phản chữ ≥ 4.5:1 (kể cả trên gradient Now Playing)
- [ ] Reduce Motion: không còn animation không thiết yếu
- [ ] Dynamic Type cỡ lớn nhất: không overflow
- [ ] Có loading / empty / error state
- [ ] Icon-only button có semantics label
