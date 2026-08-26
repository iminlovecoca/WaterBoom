# Boom Water UI design system — Aqua Arcade v2

## Nguồn sự thật

- `resources/ui/game_theme.tres`: font, button, field, progress và panel mặc định toàn game.
- `scripts/ui/UITheme.gd`: màu, surface, radius, shadow, button states và factory style canonical.
- `ui/theme/palette.gd`, `ui/theme/typography.gd`: compatibility layer cho component cũ; không thêm token mới tại đây.
- `scripts/ui/LiftButton.gd`: motion hover/pressed dùng chung.

Login, Lobby, Room, Shop, Inventory và Match HUD hiện đã cùng đọc bộ quy tắc này. Compatibility layer chỉ còn để component cũ không bị gãy trong lúc tiếp tục chuyển đổi.

## Token baseline

| Token | Giá trị | Dùng cho |
|---|---:|---|
| Font | Chakra Petch SemiBold | toàn game, số và chữ dễ đọc |
| Body | 17 px | label/input mặc định |
| Panel main | `#087FC8` | panel chính sáng, gần giao diện Crazy Arcade mẫu |
| Panel modal | `#0866B9` | modal/login/result |
| Inset | `#042E66` | input, chat và slot sâu |
| Cyan border | `#42D7FF` | đường ghép và viền tương tác |
| Primary | `#FF9800` | CTA chính |
| Secondary | `#0099F7` | CTA phụ |
| Danger | `#E63946` | thoát/xóa |
| Focus | `#FFF08A` | bàn phím/gamepad focus |
| Ready | `#61F59A` | online/sẵn sàng |
| Pending | `#FFD45C` | đang xử lý |
| Error | `#FF7C8B` | lỗi |

## Hình học

- Grid spacing cơ sở: 4 px; khoảng thường dùng 8/12/16/24/32.
- Radius: slot 6–8, input 10, button 12, panel 16, modal 18.
- Button tối thiểu 100×44; CTA chính nên 115×46 trở lên.
- Panel dùng viền 2–3 px, đáy 4–6 px để tạo bevel; shadow không vượt layout clip.
- Mọi màn hình có outer safe-area tối thiểu 18–24 px.

## Trạng thái bắt buộc

Mỗi button phải có `normal`, `hover`, `pressed`, `focus`, `disabled` khác nhau. Hover nâng nhẹ, pressed hạ xuống và giảm bevel; focus có viền vàng, không phụ thuộc hover.

Input/modal phải có:

- trạng thái focus rõ;
- trạng thái busy khóa input và CTA;
- feedback ready/pending/success/error;
- focus neighbor đầy đủ cho keyboard/gamepad;
- hit target không nhỏ hơn 44 px.

## Layout responsive

- Thiết kế logic ở 960×720.
- Dùng container + anchor; tuyệt đối không đặt control chính bằng `position` cố định.
- Kiểm tra tối thiểu: 760×570, 960×720, 1280×720, 1280×960, 1440×1080.
- Background dùng cover; nội dung dùng safe-area và không stretch theo texture.

## Quy tắc liên kết màn hình

- Backdrop HUB dùng `ui/assets_generated/backgrounds/checkered_bg.png` và cùng tint xanh; không tạo màu nền riêng cho Shop/Inventory/Lobby.
- Panel sáng chứa thông tin cấp cao; panel navy chỉ dùng cho nội dung, preview, input, chat và slot trống.
- CTA quyết định dùng cam; nút điều hướng dùng cyan/xanh; danger dùng đỏ.
- Viền 2–3 px, đáy bevel dày hơn viền cạnh; shadow phải nằm trong safe-area.
- Không dùng một ảnh giao diện lớn để giả nút. Mọi nút là `Button` thật với normal/hover/pressed/focus/disabled.

## Trạng thái triển khai

Login là baseline responsive và qua ma trận 40/40. Lobby/Room dùng cùng checker, light-panel/navy-well/cyan-seam/orange-CTA. Shop và Inventory dùng panel factory chung thay vì palette riêng. Match HUD dùng navy compact để ưu tiên diện tích map và bỏ phần trình bày vòng/khung nhân vật.

## Item icon contract

- Runtime canvas: 96×96 RGBA, nội dung nằm trong vùng tối đa 84×84.
- World pickup: fit vào 38 px và lọc tuyến tính có mipmap để icon HD không bị răng cưa.
- Mapping: `BUBBLE_PIN` → kim châm, `WATER_BALLOON_UP` → thêm bóng, `SHIELD` → khiên, `SPEED_UP` → giày, `WATER_POWER_UP` → bình tăng độ dài.
- Source gốc không bị ghi đè; nằm ở `assets/items/source_user_2026_08_24/`.

## Cosmetic presentation contract

`head_accessory` và `player_frame` bị retire khỏi UI/runtime presentation. Definition, quyền sở hữu và giá trị đã lưu vẫn tồn tại để tài khoản cũ không lỗi. `flag` và `player_background` vẫn được mua, trang bị và đồng bộ online bình thường.
