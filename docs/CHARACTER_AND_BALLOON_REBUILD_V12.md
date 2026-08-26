# CHARACTER V12 + WATER BALLOON CATALOG V3

Tài liệu này khóa phạm vi cho đợt xây lại **9 nhân vật** và **68 bóng nước hoạt động**. Mục tiêu là đạt cảm giác game arcade bóng nước chibi Hàn Quốc, đồng bộ với gameplay hiện tại, nhưng toàn bộ nhân vật, tên và họa tiết phải là thiết kế gốc của Boom Water Arcade.

## 1. Trạng thái trước khi xây lại

### Nhân vật

- Có đúng 9 ID đang được tài khoản, room và trận đấu sử dụng.
- Mỗi nhân vật đang có 64 PNG ở `assets/characters/<id>/v11/`, kích thước 112×112 RGBA.
- Bộ vật lý hiện tại gồm 4 hướng idle, 4 hướng walk, bubbled, escape, lose và win.
- `water_hit`, `die` và `rescued` có tên trong `SpriteFrames`, nhưng một số trạng thái đang tái sử dụng ảnh cũ thay vì có chuyển động riêng.
- Runtime đã biết phát `idle_*`, `walk_*`, `water_hit`, `bubble`, `rescued`, `die`, `win`, `lose`; vì vậy v12 có thể thay art mà không viết lại gameplay.

### Bóng nước

- JSON production hiện có 69 entry (68 active và alias ẩn `skin_063`).
- Có 69 bộ asset theo contract; 68 bộ active có icon 64×64 và idle 128×128.
- `skin_062` và `skin_063` đang là hai phiên bản dưa hấu gần trùng nhau.
- Một số tên/họa tiết cũ dựa quá sát thương hiệu hoặc tác phẩm bên ngoài; bản v3 sẽ đổi thành tên và thiết kế gốc.
- **Crystal Prism** là chuẩn hình cầu, kết cấu trong suốt và vị trí nút thắt đã được duyệt.

## 2. Art bible nhân vật v12

### Tỷ lệ cố định

- Canvas runtime: 112×112 RGBA, nền trong suốt.
- Điểm chân chuẩn: `(56, 103)`; sai số ngang tối đa 2 px, sai số dọc tối đa 1 px.
- Chiều cao nhìn thấy mục tiêu: 88–98 px; chiều rộng cơ thể mục tiêu: 62–78 px.
- Đầu lớn, tròn, nhưng không vượt khoảng 54–58% tổng chiều cao.
- Tay và chân là **một mẩu ngắn, bo tròn**, không lộ khuỷu tay/đầu gối dài.
- Hai chân vẫn phải tách được trong walk để người xem thấy bước chân thật, không co giãn nguyên ảnh.
- Ánh sáng từ trên-trái; viền màu đậm 2–3 px ở kích thước runtime; không dùng viền đen gắt.
- Không bake bóng đổ xuống đất vào frame; bóng đổ do Godot quản lý riêng.
- Không có chữ, tên người chơi, VFX rời hoặc vật thể nền trong sheet cơ thể.

### Tính nhất quán

- Một master identity được duyệt cho từng nhân vật trước khi tạo action.
- Khuôn mặt, màu da, tóc, trang phục, tỷ lệ đầu/thân và phụ kiện không được thay đổi giữa action.
- Mỗi action được tạo riêng, sau đó mới ghép thành atlas/tài nguyên Godot.
- Walk trái được phép lật có kiểm soát để tạo walk phải; các chi tiết bất đối xứng sẽ có lớp sửa riêng để không bị đảo sai.
- Bộ lọc import là nearest cho sprite runtime; master được giữ riêng ở độ phân giải cao để có thể xuất lại.

## 3. Danh sách 9 nhân vật giữ nguyên ID

| ID ổn định | Tên hiện tại | Vai trò silhouette |
|---|---|---|
| `boom_mascot` | Gấu Nâu | mascot tròn, khăn xanh, chuẩn tỷ lệ vàng của cả roster |
| `cloud_bunny` | Thỏ Trắng | tai thỏ cao nhưng thân vẫn cùng chiều cao cảm nhận |
| `cocoa_otter` | Thịt Mỡ | mũ rái cá nâu, dáng tròn và vui nhộn |
| `coral_diver` | Cá Nhỏ | mũ sinh vật biển hồng, bộ đồ lặn xanh ngọc |
| `lime_dino` | Khủng Long | mũ khủng long xanh, bụng sáng và gai nhỏ |
| `mint_sprout` | Bé Mầm | mũ lá xanh, silhouette gọn và nhẹ |
| `red_rider` | Nhanh Nhảu | mũ tai đỏ, khăn sáng, dáng nhanh nhưng không cao hơn roster |
| `star_skater` | Bé Sao | mũ sao tím, điểm nhấn vàng, dáng ma thuật |
| `sunny_mechanic` | Điệu Đà | mũ vàng, kính tròn, đồ thợ máy trắng-vàng |

ID, chỉ số gameplay và dữ liệu tài khoản không đổi trong đợt art này.

## 4. Hợp đồng animation v12

| Animation | Frame | Loop | Mục đích |
|---|---:|---|---|
| `idle_down` | 4 | có | thở, chớp mắt, tay cử động nhỏ |
| `idle_up` | 4 | có | thở, mũ/tai rung rất nhẹ |
| `idle_left` | 4 | có | cùng nhịp, giữ pivot chân |
| `idle_right` | 4 | có | bản phải đã sửa chi tiết bất đối xứng |
| `walk_down` | 8 | có | bước trái-phải rõ, nảy đầu tối đa 2 px |
| `walk_up` | 8 | có | chân xen kẽ, lưng/trang phục ổn định |
| `walk_left` | 8 | có | thân nghiêng nhẹ theo vận tốc |
| `walk_right` | 8 | có | đồng bộ walk trái |
| `rescue` | 4 | không | động tác chạm/phá bóng nước cứu đồng đội |
| `water_hit` | 4 | không | giật mình khi trúng luồng nước |
| `bubble` | 6 | có | ngồi co, khóc/cựa trong bóng; không vẽ lại vỏ bóng |
| `rescued` | 4 | không | đáp xuống và lấy lại thăng bằng |
| `die` | 6 | không | bóng nổ, choáng rồi biến mất theo runtime |
| `win` | 6 | có | ăn mừng rõ tay/chân và biểu cảm |
| `lose` | 6 | có | ngồi khóc/cúi đầu, khác `die` |

Tổng đầu ra: **84 frame/nhân vật, 756 frame cho 9 nhân vật**. Không thêm animation đặt bóng và nhặt vật phẩm; đặt bóng vẫn dùng idle + VFX, vật phẩm dùng phím Ctrl như gameplay hiện tại.

### Tốc độ phát đề xuất

- Idle: 5 FPS.
- Walk: 8–10 FPS, runtime có thể điều chỉnh theo tốc độ di chuyển.
- Bubble: 6 FPS.
- Rescue/water hit: 10–12 FPS.
- Die/win/lose: 7–9 FPS.

## 5. Hợp đồng 68 bóng nước

### Silhouette chuẩn Crystal Prism

- Master 256×256; runtime 128×128; icon 64×64.
- Neutral frame là hình cầu tròn; nút thắt nhỏ nằm chính giữa ở hướng 12 giờ và nối liền cổ bóng.
- Highlight lớn ở trên-trái, phản quang/màu phụ ở dưới-phải.
- Nước và họa tiết nằm bên trong màng bóng; không để glow hay họa tiết rời làm lộ đường cắt.
- Không khuôn mặt, không chữ, không logo/thương hiệu ngoài dự án.
- 4 frame idle chỉ biến dạng 2–3%, nút thắt đi theo tâm, không làm bóng méo thành hình bầu dục.
- Viền alpha sạch: không halo trắng/đen trên nền xanh đậm của game.

### Catalog v3

- Có đúng **68 skin hoạt động**.
- Giữ nguyên mọi ID đã phát cho tài khoản.
- `skin_063` (dưa hấu trùng) trở thành alias ẩn của `skin_062`; tài khoản sở hữu 063 vẫn được resolve sang bộ dưa hấu mới.
- `skin_064` và `skin_065` vẫn giữ ID nhưng đổi tên/họa tiết thành thiết kế gốc, không dùng tên hay biểu tượng của tác phẩm bên ngoài.
- `skin_036` là Crystal Prism đã duyệt và là baseline QC.
- Registry cần phân biệt `active`, `hidden_legacy` và `alias_to`; shop chỉ hiện 68 skin hoạt động.

### Phân bố cấp bậc mới

| Cấp | Số lượng | Giá mục tiêu |
|---|---:|---:|
| Common | 12 | 0–50.000 Cokecy |
| Uncommon | 16 | 80.000–120.000 Cokecy |
| Rare | 16 | 150.000–220.000 Cokecy |
| Epic | 12 | 260.000–340.000 Cokecy |
| Legendary | 6 | 380.000–500.000 Cokecy |
| Mythic | 2 | thành tựu/sự kiện, không mua trực tiếp |

Giá chỉ được áp dụng sau khi purchase/equip là server-authoritative và migration chạy trên bản sao database.

## 6. Quy trình tạo và kiểm duyệt

1. Tạo `boom_mascot` làm golden character, không ghi đè v11. **Đã hoàn tất ở `assets/characters/boom_mascot/v12_staging/`.**
2. Tạo bốn bóng thử thuộc bốn vật liệu khác nhau nhưng cùng cấu trúc Crystal Prism. **Đã hoàn tất ở staging và đã tích hợp production dưới `skin_066`–`skin_069`.**
3. Chroma-key, tách frame, căn chân, chuẩn hóa 112×112/128×128 và chạy QC tự động.
4. Xem contact sheet, GIF và preview trực tiếp trong Godot. **Đã có preview GPU và runner pass; ảnh lưu tại `tests/artifacts/character_v12_checkpoint.png`.**
5. Golden checkpoint đã được duyệt và ngân sách bulk đã được xác nhận. Tám master còn lại đã tạo vào staging; mỗi master
   khóa silhouette tay/chân một mẩu, bo tròn kiểu đồ chơi (Doraemon), khuôn mặt/tóc/màu da riêng theo roster. Runtime staging
   hiện đã chuẩn hóa đủ 15 action × 84 frame cho cả 9 nhân vật; `tests/CharacterV12CoverageSmoke.gd` báo 9/9 và manifest
   ghi rõ action nào là v12-authored, action nào là fallback chuẩn hóa từ v11. Đây là bước đảm bảo gameplay/UI luôn có clip
   đầy đủ, chưa thay thế v11 production. Star Skater có benchmark authored cho bốn hướng idle/walk cùng bubble/rescue.
6. Tạo `v12` cạnh `v11`, nối bằng `resources/characters/*_frames_v12.tres`; v11 không bị xóa và vẫn là fallback cho rollback/save migration.

Lớp preview tại `scripts/water_balloon/WaterBalloonCatalogV3Normalizer.gd` hiện chuẩn hóa catalog thành schema v3 trong bộ nhớ, kiểm tra 69 stable ID, 68 skin active, alias `skin_063 → skin_062` và Crystal Prism `skin_036`. `tests/WaterBalloonV12AssetCoverageSmoke.gd` kiểm tra 68 skin active đều có icon 64×64, 4 idle frame + pop burst 128×128. Bốn mẫu v12 đã được đưa từ staging vào production dưới `skin_066`–`skin_069`; 64 skin còn lại giữ nguyên art hiện hành. Purchase/equip vẫn đi qua flow hiện có, không tự động mở khóa cho tài khoản.

### QC bắt buộc

- Không frame rỗng, không dính nhân vật lân cận, không cắt tai/mũ/chân.
- Body-scale CV ≤ 0,08; độ lệch điểm chân chuẩn hóa ≤ 0,05 chiều cao canvas.
- Alpha fringe kiểm tra trên nền sáng, nền xanh đậm và nền map.
- Walk có thay đổi pose chân/tay thật; cấm chỉ scale, bob hoặc rung toàn ảnh.
- Chín nhân vật có chiều cao cảm nhận đồng đều trong map, room và inventory preview.
- 68 bóng đều tròn ở neutral frame; nút thắt và kích thước không nhảy giữa frame.
- Godot import không lỗi; character animation smoke, balloon registry smoke, shop/inventory/account migration đều pass.

## 7. Ước lượng lượt tạo ảnh và chi phí

Ước lượng dưới đây dùng giá Gemini 1K trong skill asset-gen là khoảng **0,07 USD/ảnh**.

### Checkpoint A — nên duyệt trước

- Golden character Gấu Nâu: 14 lượt (master, ba hướng idle + mirror sửa, ba hướng walk + mirror sửa, bảy trạng thái).
- Bốn bóng thử mới: 4 lượt.
- Tổng cơ sở: 18 lượt ≈ **1,26 USD**.
- Trần nếu mỗi lượt phải tạo lại đúng một lần: 36 lượt ≈ **2,52 USD**.

### Toàn bộ đợt sau khi checkpoint A đạt

- Chín nhân vật: khoảng 126 lượt ≈ 8,82 USD.
- 63 bóng mới ngoài Crystal Prism: khoảng 63 lượt ≈ 4,41 USD.
- Tổng cơ sở toàn đợt: khoảng **13,23 USD**.
- Dự phòng hợp lý 25% cho frame lỗi: khoảng **16,54 USD**.
- Trần cực đại một lần retry cho mọi ảnh: khoảng **26,46 USD**.

Checkpoint A đã được người dùng cho phép trong phạm vi trần 2,52 USD và đã tạo xong mẫu staging. Người dùng đã xác nhận trần
bulk tiếp theo 14,96 USD. Tám master mới hiện ở `assets/characters/<id>/v12_staging/master/` và đã qua chroma-key/QC
112×112. Không có asset production nào bị ghi đè; action sheet và 59 bóng còn lại vẫn đang làm theo lô, chỉ nối production
sau khi runner và migration pass.

## 8. Kỹ năng được dùng

- `gamestudio`: điều phối production, quality gates, save/network safety và kiểm chứng trong game.
- `asset-gen`: tuyến tạo art, chi phí và chuẩn asset game.
- `generate2dsprite`: chia action, chroma-key, tách/căn frame, contact sheet, GIF và QC sprite.
- `imagegen`: chỉ dùng ở bước tạo/chỉnh bitmap sau khi checkpoint chi phí được duyệt.

Các skill không liên quan đến sản xuất game/ảnh (email, spreadsheet, trading, browser...) không được gọi vì không tạo giá trị cho phạm vi này.
