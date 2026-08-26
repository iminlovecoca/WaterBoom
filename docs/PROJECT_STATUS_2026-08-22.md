# BOOM WATER ARCADE — BÁO CÁO HIỆN TRẠNG DỰ ÁN

**Ngày chốt:** 22/08/2026  
**Cập nhật gần nhất:** 23/08/2026 — sửa local login, auth timeout và thêm network auth smoke test  
**Godot:** 4.7.1  
**Độ phân giải thiết kế:** 960 × 720, tỉ lệ 4:3  
**Mục đích:** Đây là bản tổng hợp theo **code, resource và test đang có trong project**, không phải bản nhắc lại lịch sử hội thoại.

## 1. Cách đọc trạng thái

- **Đã xác nhận:** Có code/resource và đã chạy smoke test tương ứng.
- **Đã triển khai, cần test thực tế:** Có luồng hoàn chỉnh trong code nhưng chưa xác nhận bằng hai máy ngoài Internet.
- **Một phần:** Có nền tảng dùng được nhưng còn nợ polish, bảo mật hoặc kiểm thử.
- **Asset cũ:** File vẫn còn trên ổ đĩa nhưng không còn nằm trong catalog/runtime chính.

## 2. Kết luận nhanh

Project hiện đã vượt mức prototype hình ảnh đơn thuần. Game có đăng ký/đăng nhập SQLite, lobby tương tác thật, 9 nhân vật có animation sheet riêng, 6 map chuẩn 16 × 16, 65 bóng nước, cosmetic mua/trang bị, gameplay cổ điển, boss 4 round, EXP/Cokecy, dedicated server ENet và bộ smoke test tương đối rộng.

Các phần đã ổn nhất:

- Gameplay đặt bóng, thoát khỏi ô bóng vừa đặt, vụ nổ bị chặn bởi hard/soft block.
- Map chuẩn 16 × 16 với số lượng block và vùng spawn được validator kiểm tra.
- Nhân vật dùng frame thật thay vì chỉ co giãn nguyên ảnh.
- Cosmetic có dữ liệu SQL, preview, lobby, danh sách trong trận và phụ kiện trên đầu trong game.
- Shop cosmetic đã mua bằng giao dịch nguyên tử, tránh trừ tiền mà không mở khóa.
- Bảng kết quả mới có hạng, kết quả, EXP, Cokecy và tự về phòng sau 3 giây.

Các phần chưa nên coi là hoàn tất phát hành:

- Chưa có bằng chứng kiểm thử end-to-end bằng hai máy qua Internet cho bản build hiện tại.
- Playit là dịch vụ bên ngoài và đang báo lỗi API nội bộ; dedicated server cũng phải được chạy riêng.
- Một số tài liệu cũ và asset legacy còn tồn tại, dễ gây hiểu nhầm nếu chỉ nhìn thư mục.
- Mua skin bóng nước vẫn cần được nâng lên cùng mức giao dịch server-authoritative như cosmetic.
- Cần thêm kiểm thử độ phân giải khác 960 × 720 và kiểm thử mất mạng/reconnect.

## 3. Kiến trúc và luồng màn hình

### 3.1 Luồng chính

1. `Login.tscn` — đăng nhập hoặc đăng ký tài khoản.
2. `Boot.tscn` — room lobby, chọn nhân vật, map, shop, túi đồ và cosmetic.
3. `Match.tscn` — trận cổ điển hoặc boss.
4. Kết quả — hiển thị 3 giây rồi tự quay về room.

### 3.2 Autoload chính

Project hiện khởi tạo các dịch vụ dùng chung: EventBus, CosmeticRegistry, AccountDatabase, SoundManager, ExitSequence, NetworkManager, RoomManager, GameSession, PlayerEquipmentService, SettingsStore và WaterBalloonSkinRegistry.

### 3.3 Tỉ lệ giao diện

- Viewport gốc: **960 × 720**.
- Stretch mode: `canvas_items`.
- Tỉ lệ chuẩn: **4:3**.
- Font theme chính: `ChakraPetch-SemiBold.ttf`, mặc định 17 px.
- Font bổ sung còn có Noto Sans Variable và Tiny5 Bold, nhưng Chakra Petch là font runtime chính.

### 3.4 Chọn endpoint đăng nhập

- Khi chạy game từ bản debug/Godot Editor: tự dùng `127.0.0.1:7777` để tránh hairpin qua Playit trên chính máy host.
- Khi chạy bản export/release: dùng `reminded-uncut.tun.ply.gg:38709`.
- Có thể ghi đè bằng user args `--connect-host=<host>` và `--connect-port=<port>`.
- Sau khi gửi RPC đăng nhập/đăng ký, client chờ tối đa 8 giây. Nếu server mất kết nối hoặc không trả lời, nút được mở lại và hiện lỗi thay vì kẹt vĩnh viễn ở “Đang xác thực…”.

## 4. Kích thước và layout chính xác

### 4.1 Màn hình đăng nhập

| Thành phần | Kích thước/vị trí thiết kế |
|---|---:|
| Background | Phủ toàn viewport 960 × 720 |
| Login panel | 450 × 335, căn giữa |
| Tiêu đề game | Khoảng y = 45–112, font 58 px |
| Subtitle | 20 px |
| Ô nhập | Cao tối thiểu 44 px |
| Nút đăng nhập/đăng ký | 115 × 46 |
| Nút quên mật khẩu | 100 × 46 |

Nhạc `assets/audio/music/login.mp3` chạy loop ở màn hình này.

### 4.2 Lobby 960 × 720

| Thành phần | Rect thiết kế |
|---|---:|
| Khu phòng/người chơi | x25, y70, 606 × 558 |
| Khu chọn nhân vật/map | x638, y70, 300 × 558 |
| Thanh Cokecy | x650, y18, 280 × 42 |
| Nút Bắt đầu | x653, y560, 275 × 60 |
| Shop | x52, y669, 132 × 37 |
| Túi đồ | x192, y669, 132 × 37 |
| Cài đặt | x846, y669, 37 × 37 |
| Tắt game | x891, y669, 37 × 37 |

Nhạc `assets/audio/music/lobby.mp3` chạy loop ở lobby.

### 4.3 Slot người chơi trong lobby

- 8 slot, bố cục **4 cột × 2 hàng**.
- Mỗi panel nhân vật: **126 × 104 px**.
- Thanh trạng thái “CHỦ PHÒNG/SẴN SÀNG” tách riêng bên dưới: **126 × 24 px**.
- Vùng background bên trong: **118 × 96 px**, inset 4 px, bo góc 10 px.
- Khung cosmetic bọc toàn bộ card: **126 × 104 px**, full-bleed tại (0,0), mask bo góc 13 px, không tràn sang slot khác.
- Nhân vật idle: vị trí thiết kế `(43, 48)`, scale 0.80.
- Khung được đưa ra sau nhân vật và bị mask theo góc bo tròn, không che mặt nhân vật hay tràn ra ngoài card.

### 4.4 Cờ trong slot

- Nhóm cờ: vị trí `(83, 43)`, kích thước vùng **39 × 46 px**.
- Cột cờ: 3 × 36 px.
- Đỉnh cột: 9 × 5 px.
- Chân cột: 11 × 4 px.
- Lá cờ runtime: **29 × 19 px**, đặt tại `(10, 8)` trong nhóm.
- Chân nhân vật và chân cột cờ cùng hàng y = 87.
- Cột cờ là geometry cố định bằng code; khi đổi cosmetic chỉ thay **lá cờ**.

### 4.5 Chọn nhân vật

- Hỗ trợ **15 ô/trang**, bố cục **5 × 3**.
- Mỗi ô: 52 × 52 px; selfie bên trong 46 × 46 px.
- Khoảng bước giữa các ô: 57 px.
- Có nút trang trước/sau; hệ thống không bị khóa ở 4 hoặc 9 nhân vật.
- Catalog hiện có 9 nhân vật, nên trang đầu còn 6 ô trống để mở rộng.

### 4.6 Popup chọn map

- Modal: **760 × 530 px**.
- Preview bên trái: 260 × 160; texture thật 252 × 152.
- Danh sách bên phải: 446 × 402.
- Mỗi dòng map là Button thật: 436 × 34.
- Nút xác nhận/hủy: 140 × 44.
- Đây là UI tương tác thật, không phải chữ chèn lên một ảnh lobby phẳng.

### 4.7 Shop và túi đồ

**Shop**

- Toàn màn 960 × 720; panel chính 936 × 690.
- Grid 4 cột.
- Card item 116 × 132.
- Khu preview rộng 235; ảnh preview 145 × 145.

**Túi đồ**

- Panel chính 936 × 690.
- Cột thông tin cá nhân 270 × 665.
- Player preview 235 × 160.
- Thanh EXP 245 × 13.
- Kho đồ 640 × 665, grid 4 cột.
- Card item 98 × 116.
- Preview trang bị 120 × 120.

## 5. Cosmetic: pixel asset và cách hiển thị

### 5.1 Background người chơi

Có 6 background logic: 1 mặc định và 5 mẫu mua được.

| Mẫu | Lobby asset | Match asset |
|---|---:|---:|
| Ocean Coral | 1024 × 1024 | 1536 × 480 |
| Blossom Day | 1024 × 1024 | 1536 × 480 |
| Neon Star | 1024 × 1024 | 1536 × 480 |
| Ember Dragon | 1024 × 1024 | 1536 × 480 |
| Angel Cloud | 1024 × 1024 | 1536 × 480 |
| Aqua mặc định | Không dùng texture | Màu nền do code vẽ |

Background vuông được crop/clip theo card; background ngang dùng cho danh sách trong trận. Không được kéo texture vuông thành dải ngang.

### 5.2 Khung người chơi

| Mẫu | Lobby asset | Match asset |
|---|---:|---:|
| Ocean Coral | 1024 × 1024 | 1600 × 500 |
| Blossom Day | 1024 × 1024 | 1600 × 500 |
| Neon Star | 1024 × 1024 | 1600 × 500 |
| Ember Dragon | 1024 × 1024 | 1600 × 500 |
| Angel Cloud | 1024 × 1024 | 1600 × 500 |
| Aqua mặc định | Không dùng texture | Viền panel do code vẽ |

Khung bọc toàn bộ card lobby (full-bleed 126 × 104), mask bo góc bằng shader `assets/shaders/rounded_clip.gdshader`, vẫn nằm sau nhân vật nên không phủ lên nhân vật. Shader chịu trách nhiệm mask theo kích thước và bán kính góc.

### 5.3 Lá cờ

- Ảnh nguồn đầy đủ: `flag_default_water.png` — **618 × 977 px**.
- Lá cờ đã tách dùng runtime: `flag_default_water_leaf.png` — **486 × 430 px**.
- Lá cờ mặc định là hình chữ nhật có biểu tượng bóng nước.
- Trong lobby lá được fit về 29 × 19; trong Match HUD khoảng 22 × 17; trong preview túi đồ khoảng 45 × 28.
- Cột cờ không thay đổi khi mua cờ khác.

### 5.4 Vòng/phụ kiện đầu

| Asset | Kích thước nguồn |
|---|---:|
| Angel ring | 1536 × 1024 |
| Fire ring | 1536 × 1024 |
| Flower wreath | 1536 × 1024 |
| Aqua halo | 1774 × 887 |

- Lobby fit cơ sở khoảng 56 × 40 rồi nhân scale của từng item.
- Trong world, tâm cơ sở `(0, -43)`; cạnh lớn nhất được fit về khoảng 58 px rồi nhân `world_scale`.
- Vòng có tween bay lên/xuống nhẹ; hiệu ứng xuất hiện trong lobby, Match HUD, túi đồ preview và trên đầu nhân vật trong trận.
- Fire ring và flower wreath có scale lớn hơn halo để bao quanh đầu rõ hơn.

### 5.5 Catalog và giá cosmetic

Tổng cộng **17 definition**:

- 4 phụ kiện đầu: Halo 450; Flower 550; Fire 720; Angel 800 Cokecy.
- 1 cờ mặc định: miễn phí.
- 6 khung: mặc định miễn phí; Ocean 650; Blossom 700; Neon 850; Ember 900; Angel 950.
- 6 background: mặc định miễn phí; Ocean 600; Blossom 650; Neon 800; Ember 850; Angel 900.

Cosmetic xuất hiện ở:

- Slot người chơi trong room.
- Banner/chọn nhân vật.
- Danh sách người chơi trong trận.
- Preview túi đồ.
- Phụ kiện đầu còn xuất hiện trực tiếp trên nhân vật ingame.

## 6. Nhân vật

### 6.1 Roster đang hoạt động

| ID | Tên | Boom đầu | Độ dài | Tốc độ |
|---|---|---:|---:|---:|
| boom_mascot | Gấu Nâu | 2 | 1 | 168 |
| cloud_bunny | Thỏ Trắng | 1 | 2 | 182 |
| cocoa_otter | Thịt Mỡ | 2 | 3 | 168 |
| coral_diver | Cá Nhỏ | 2 | 2 | 174 |
| lime_dino | Khủng Long | 3 | 1 | 160 |
| mint_sprout | Bé Mầm | 1 | 1 | 180 |
| red_rider | Nhanh Nhảu | 2 | 1 | 164 |
| star_skater | Bé Sao | 1 | 1 | 190 |
| sunny_mechanic | Điệu Đà | 2 | 2 | 154 |

### 6.2 Animation contract

- 9 nhân vật × 64 ảnh runtime = **576 frame assets**, mỗi ảnh **112 × 112 px**.
- Mỗi nhân vật có 14 animation:
  - `idle_down/up/left/right`: 4 frame riêng mỗi hướng.
  - `walk_down/up/left/right`: 8 frame mỗi hướng.
  - `water_hit`, `bubble`, `rescued`, `die`, `win`, `lose`.
- Không còn animation đặt boom riêng; nhân vật giữ directional idle khi đặt.
- Đã bỏ animation pickup riêng; pickup dùng VFX/gameplay feedback.
- Chân tay ngắn, thân chibi và kích thước frame đồng nhất giữa nhân vật.

### 6.3 Asset UI nhân vật

- Portrait chuẩn: 96 × 96.
- Card: 256 × 256.
- Banner: 512 × 128.
- Selfie: 256 × 256.
- Mỗi definition active tham chiếu riêng portrait, card, banner và selfie.

Một số file Ninja và biến thể kích thước lớn vẫn còn trong thư mục UI nhưng **Ninja không nằm trong roster active**. Đây là asset legacy cần dọn sau khi xác nhận không còn scene cũ tham chiếu.

## 7. Bóng nước và hiệu ứng nổ

### 7.1 Catalog bóng nước

- **65 skin** trong catalog JSON.
- Mỗi skin có `icon.png`, `idle_0..3` và resource SpriteFrames.
- Icon chuẩn: **64 × 64 px**.
- Frame/source idle chuẩn: **128 × 128 px**.
- Có bóng mặc định, dưa hấu, bóng tối, lấp lánh và nhiều biến thể hiếm.

Phân bố độ hiếm:

- Common: 11.
- Uncommon: 25.
- Rare: 19.
- Epic: 6.
- Legendary: 4.

### 7.2 Water stream VFX

- 16 mảnh topology, mỗi ảnh nguồn **80 × 80 px**.
- Gồm center, cross, horizontal, vertical, 4 đầu cuối, 4 góc và 4 nhánh T.
- Renderer chọn đúng mảnh theo hàng xóm, không chồng nhiều ảnh lên nhau để giả nối.
- Ở viewport chuẩn, mỗi mảnh được scale về đúng một ô 45 × 45, phủ trọn nền ô.
- Tâm vẫn xuất hiện khi chỉ nổ ngang hoặc chỉ nổ dọc.
- Nước dừng trước hard block; phá soft block rồi dừng; có chain reaction với bóng khác.

### 7.3 Va chạm bóng vừa đặt

Người đặt được phép đi xuyên ra khỏi ô bóng vừa đặt. Khi toàn thân đã rời ô đó, collision được khóa lại và không thể quay vào. Smoke test riêng đã xác nhận tình huống này PASS.

## 8. Map

### 8.1 Map active

Catalog runtime hiện có **6 map**:

1. Planning Plaza (`training_plaza`).
2. Pirate Harbor.
3. Toy Brick City (`lego_city`).
4. Aqua Park.
5. Snow Village.
6. Egypt Temple.

`Neon Arcade` và `Ice Labyrinth` còn preview cũ nhưng không nằm trong `MAP_IDS`; chúng là legacy, chưa phải map chọn được.

### 8.2 Chuẩn chung 16 × 16

Mỗi map thường có đúng:

- 256 ô tổng.
- 128 destructible block.
- 100 hard block, gồm perimeter 60 ô.
- 28 floor/spawn escape cell.
- 4 góc spawn dạng chữ L, mỗi góc 3 ô trống.
- 4 pocket cạnh cho team mode.
- Trung tâm 4 × 4 gồm 16 destructible, không có hard block, nên có thể mở đường thẳng qua giữa.

Spawn logic:

- Góc: `(1,1)`, `(14,14)`, `(14,1)`, `(1,14)`.
- Cạnh/team: `(7,1)`, `(8,14)`, `(1,7)`, `(14,8)`.
- Validator yêu cầu tối thiểu hai đường thoát tại mỗi spawn.

### 8.3 Pixel/runtime map

- Texture nguồn V2 của tile/map: **256 × 256 px**.
- Preview map: **368 × 207 px**, tỉ lệ gần 16:9.
- Ở 960 × 720, sidebar trận rộng cố định 204 px; arena còn 756 × 720.
- Tile runtime = `min(floor(756/16), floor(720/16))` = **45 px**.
- Board = **720 × 720 px**, căn giữa theo chiều ngang trong arena, x = 18.
- Không còn khung trang trí ngoài làm mất diện tích; hàng ngoài cùng là hard-block collision thực của map.
- Các giant center decoration cũ đã bị loại khỏi active regular maps; trung tâm dùng block thật để tăng chỗ phá và tránh footprint ẩn.

### 8.4 Nợ kỹ thuật map

- `MapLayoutBuilder` vẫn chứa một số array/hàm 15 × 15 cũ nhưng đường `build()` active đã chuyển toàn bộ map sang builder 16 × 16 mới.
- `docs/MAP_SYSTEM.md` cũ còn ghi 8 map 40 × 40 và preview 384 × 216; thông tin đó không đúng với runtime hiện tại.
- Cần dọn preview/tileset legacy sau khi chụp regression cuối cùng.

## 9. Gameplay và item

### 9.1 Item hiện có

| Item | Tác dụng |
|---|---|
| Water Balloon Up | Tăng số bóng có thể đặt |
| Water Power Up | Tăng độ dài nước |
| Speed Up | Tăng tốc độ đến giới hạn nhân vật |
| Bubble Pin | Bấm Ctrl khi bị nhốt để tự chọc bóng, rescue 0,75 giây |
| Shield | Bấm Ctrl khi bình thường để miễn sát thương 3 giây |

Chỉ có một ô held item cho Pin/Shield. Nếu ô đang bận, item mới không bị ăn mất: vật phẩm vẫn nằm trên map để nhặt sau.

### 9.2 Bubble

- Thời gian nhốt mặc định 5 giây.
- Đồng đội chạm vào có thể cứu.
- Đối thủ chạm vào làm nổ sớm và hạ người bị nhốt.
- Khi hết thời gian mà không được cứu, người chơi thua.

## 10. Chế độ boss

- 4 round, khóa map Pirate Harbor, không dùng bot người chơi.
- Round 1/2/3 có layout khác nhau và sinh lần lượt khoảng 4/5/6 lính mực.
- Lính mực có animation di chuyển bốn hướng; bị bóng nước nhốt và phải được chạm/pop mới chết.
- Round 4 có boss mực hải tặc khổng lồ, 36 HP.
- Phase 2 bắt đầu khi boss mất 60% máu; boss nhanh hơn và dùng spiral skill cooldown 5 giây.
- Kỹ năng cận chiến/cross burst có telegraph 1,5 giây.
- Nước bị vật cản chặn, nên người chơi có thể dùng cover.
- Round boss có 16 destructible được bố trí quanh bốn trụ; tài liệu cũ ghi “không có crate” đã lỗi thời.

## 11. Tài khoản, SQL, EXP và kinh tế

### 11.1 SQLite

Database nằm tại `user://boom_water_accounts.db`. Các bảng chính:

- `users`.
- `user_balloon_skins`.
- `user_cosmetics`.
- `user_equipment`.
- `schema_migrations`.

Hệ thống lưu username, nickname, password hash/salt, Cokecy, level, EXP, nhân vật, bóng nước, đồ đã mở khóa và đồ đang trang bị. Lỗi “đăng nhập tài khoản nào cũng thành coca” đã được sửa bằng ánh xạ user/peer riêng trên server.

### 11.2 EXP và kết quả trận

- Thắng: +120 Cokecy, +100 EXP.
- Hòa: +20 Cokecy, +50 EXP.
- Thua: +0 Cokecy, +25 EXP.
- Bảng kết quả có cột Hạng, Kết quả, Nhân vật, EXP, Cokecy.
- Có ảnh THẮNG/THUA, thanh EXP vuông vức, số định dạng digital và hiệu ứng tăng phần trăm.
- Không còn nút Chơi lại/Về phòng; tự đếm ngược và về room sau 3 giây.

### 11.3 Mua cosmetic mới

Luồng cosmetic hiện tại:

1. Shop gửi request mua lên server khi online.
2. Server xác định user từ peer đã đăng nhập.
3. SQLite chạy transaction `BEGIN`.
4. Trừ Cokecy và thêm unlock.
5. Chỉ `COMMIT` nếu cả hai bước thành công; nếu lỗi thì `ROLLBACK`.
6. Client nhận balance mới, refresh card và tự trang bị item vừa mua.

Đã test:

- Mua thành công.
- Không mua khi thiếu tiền.
- Không trừ tiền hai lần khi mua lại.
- Item mới như `head_flower_wreath` được mở khóa và trang bị.

Rủi ro còn lại: mua skin bóng nước cần được chuyển sang transaction server-authoritative tương tự cosmetic; hiện hai nhóm chưa đồng mức bảo vệ.

## 12. Đồng bộ online của cosmetic

### 12.1 Luồng đã có trong code

1. Client đăng nhập, server ánh xạ `peer_id → user_id`.
2. Khi vào/tạo phòng, client gửi equipment hiện tại.
3. Server không tin trực tiếp dữ liệu mua của client; nếu peer đã xác thực, server đọc equipment từ SQLite.
4. `RoomManager` broadcast equipment cho toàn phòng.
5. Lobby render flag, head accessory, frame và background của từng người.
6. Khi bắt đầu trận, server tạo snapshot bất biến cho từng player.
7. `MatchManager`, `PlayerController` và `MatchHUD` dùng snapshot đó.

**Kết luận:** người chơi online khác có thể thấy đồ bạn mua và đang trang bị. Điều kiện là:

- Cả hai client dùng cùng bản build chứa cùng cosmetic definition/asset.
- Client đăng nhập qua đúng dedicated server.
- Playit tunnel và UDP 7777 đang hoạt động.

Đây là xác nhận theo code và smoke test cục bộ; chưa được coi là chứng nhận end-to-end ngoài Internet cho đến khi chạy thử hai máy khác mạng.

## 13. Playit và dedicated server

### 13.1 Cấu hình hiện tại

- Godot dedicated server local: UDP **7777**.
- Client mặc định: `reminded-uncut.tun.ply.gg:38709`.
- Playit agent: 1.0.10.
- Agent service đang chạy, secret đã cấu hình, account verified, nạp được 1 tunnel.

### 13.2 Lỗi ngày 22/08/2026

Log Playit báo:

`Failed to load agent data: ApiError(Internal(ApiInternalError { trace_id: ... }))`

Đây là phản hồi lỗi nội bộ từ API/control-plane Playit, không phát sinh từ Godot. Trước đó log cũng có connection reset/timeout tới `api.playit.gg`. DNS và HTTPS tới domain vẫn truy cập được, nên lỗi có khả năng là sự cố phiên/API phía Playit hoặc phiên agent tạm thời, không phải sai port game.

Trong lần cập nhật 23/08, dedicated server đã được chạy lại và Windows xác nhận Godot đang lắng nghe UDP 7777. Playit hiện còn đúng một tunnel public trỏ về `127.0.0.1:7777`.

Quy trình kiểm tra an toàn:

1. Chạy `start_server.bat` và xác nhận UDP 7777 có listener.
2. Kiểm tra `playit status`; service phải `running`, secret `configured`.
3. Nếu API internal error còn lặp lại, chờ status Playit ổn định rồi restart service/agent một lần.
4. Không dùng `playit reset` trừ khi muốn claim lại agent, vì lệnh đó xóa secret hiện tại.
5. Test bằng một máy khác mạng tới host/port public, không chỉ test localhost.

Trang theo dõi chính thức: <https://status.playit.gg/>.

## 14. Âm thanh

| Ngữ cảnh | File runtime |
|---|---|
| Login loop | `assets/audio/music/login.mp3` |
| Lobby loop | `assets/audio/music/lobby.mp3` |
| Đặt bóng | `assets/audio/SFX/Cha_BombIgnite.ogg` |
| Nổ đơn | `assets/audio/SFX/Cha_BombExplode.ogg` |
| Nổ chuỗi | `assets/audio/SFX/Cha_BombExplodeMulti.ogg` |
| Thoát game | `assets/audio/ui/out.ogg` |

`assets/audio/ui/out.ogg` có hash trùng hoàn toàn với file `Ntc_GameEnd.ogg` người dùng cung cấp. ExitSequence phát hết âm thanh đồng thời phủ lớp tối dần rồi mới gọi quit.

## 15. Kết quả kiểm thử hiện tại

| Bộ test | Kết quả |
|---|---:|
| AccountDatabaseSmoke | 19 pass, 0 fail |
| MapLayoutSmoke | 90 pass, 0 fail |
| MapGameplayRegressionSmoke | 48 pass, 0 fail |
| CharacterAnimationSmoke | 22 pass, 0 fail |
| BossModeSmoke | 23 pass, 0 fail |
| ExitSequenceSmoke | 6 pass, 0 fail |
| PlayableSmoke | 17 pass, 0 fail |
| BalloonExitAndCollisionSmoke | PASS |
| LobbyV2Capture | Render thành công |
| LocalAuthNetworkSmoke | PASS — ENet local → server → SQLite → RPC client |

Tổng số assertion đếm được: **226 pass + 1 smoke PASS**, không có failure trong lần audit này.

Test đã xác nhận tốt logic nội bộ, nhưng chưa thay thế cho:

- Test hai client qua Internet.
- Test reconnect/mất mạng.
- Test nhiều độ phân giải và DPI.
- Soak test server 8 người.
- Kiểm thử mua hàng đồng thời của cùng một tài khoản.

## 16. Asset/tài liệu cũ cần dọn

- Preview Neon Arcade và Ice Labyrinth không thuộc catalog active.
- Ninja UI asset còn trên ổ đĩa nhưng không thuộc roster active.
- Một số source character kích thước lớn không phải runtime contract 112 × 112.
- `docs/MAP_SYSTEM.md` và vài tài liệu roadmap cũ không còn phản ánh đúng số map/kích thước.
- Một số hàm layout 15 × 15 cũ vẫn nằm trong builder nhưng không đi qua đường runtime active.

Không nên xóa ngay bằng tìm kiếm tên đơn giản. Cần chạy reference scan, tạo bản backup/commit rồi mới dọn để tránh xóa asset còn được scene cũ preload.

## 17. Đánh giá tiến độ theo hạng mục

| Hạng mục | Trạng thái | Nhận xét |
|---|---|---|
| Core arcade gameplay | Đã xác nhận | Đặt bóng, nước, block, bubble, item đã có test |
| Map 16 × 16 | Đã xác nhận | 6 map active, count/spawn đồng bộ |
| Character pipeline | Đã xác nhận | 9 nhân vật, 576 PNG runtime, 14 animation/người |
| Balloon/VFX | Đã xác nhận | 65 skin, topology water stream đầy đủ |
| Lobby tương tác | Đã xác nhận | Button thật, 8 slot, chọn char/map/shop/inventory |
| Cosmetic presentation | Đã xác nhận | Lobby/match/preview/world head accessory |
| Cosmetic SQL purchase | Đã xác nhận | Transaction và smoke test |
| EXP/result board | Đã xác nhận | Reward, progress, auto-return |
| Boss mode | Đã xác nhận bằng smoke test | Cần thêm playtest cân bằng |
| Dedicated server | Đã triển khai | Server ENet có script chạy riêng |
| Online cosmetic sync | Đã triển khai, cần test thực tế | Luồng server snapshot đầy đủ |
| Internet tunnel | Phụ thuộc bên ngoài | Playit đang có API internal error |
| Release readiness | Một phần | Còn cần multiplayer, resolution, security và soak QA |

## 18. Thứ tự ưu tiên tiếp theo

### P0 — chặn phát hành

1. Chạy lại dedicated server và test hai máy khác mạng qua Playit.
2. Xác nhận 2 client nhìn thấy cùng cờ, khung, background và vòng ở lobby lẫn match.
3. Chuyển mua balloon skin sang transaction server-authoritative.
4. Test reconnect, disconnect giữa trận và quay lại room.

### P1 — chất lượng

1. Test UI ở 1280 × 720, 1366 × 768, 1920 × 1080 và scale Windows 125%/150%.
2. Chụp regression từng map, từng góc spawn, từng cosmetic.
3. Cân bằng boss/nhân vật/item bằng playtest thật.
4. Dọn asset legacy và cập nhật các docs cũ trỏ về báo cáo này.

### P2 — mở rộng

1. Thêm map mới vào catalog sau khi đạt contract 16 × 16.
2. Thêm nhân vật bằng definition + 64 PNG runtime + bốn ảnh UI chuẩn.
3. Thêm flag/frame/background mới theo đúng cặp lobby/match asset.
4. Thêm admin/telemetry và log giao dịch phục vụ vận hành.

## 19. Các file nguồn quan trọng

- `project.godot` — viewport, autoload, main scene.
- `scripts/core/BootManager.gd` — lobby/layout/chọn nhân vật/map.
- `scripts/network/RoomManager.gd` — room và đồng bộ equipment.
- `scripts/network/NetworkManager.gd` — ENet host/client.
- `scripts/data/AccountDatabase.gd` — SQL, login, purchase, equipment.
- `scripts/cosmetics/CosmeticRegistry.gd` — catalog cosmetic.
- `scripts/cosmetics/PlayerEquipmentService.gd` — equip/save/broadcast.
- `scripts/ui/ShopView.gd` — shop và purchase flow.
- `scripts/ui/InventoryView.gd` — túi đồ và preview.
- `scripts/ui/MatchHUD.gd` — sidebar và result board.
- `scripts/maps/MapLayoutBuilder.gd` — layout map 16 × 16.
- `scripts/water_burst/` — topology hiệu ứng nước.
- `resources/characters/` — definition và SpriteFrames nhân vật.
- `tools/import_character_sheets.py` — cắt cell alpha, chuẩn hóa 112 × 112 và xuất runtime.
- `tools/rebuild_character_spriteframes.py` — tạo lại 14 clip SpriteFrames, gồm walk 8 frame.
- `resources/cosmetics/definitions/` — definition cosmetic.
- `assets/water_balloons/water_balloon_catalog.json` — 65 skin.
- `tests/` — smoke/regression scenes.

---

**Nguồn sự thật ưu tiên:** code/resource/test hiện tại → báo cáo này → tài liệu cũ. Nếu tài liệu cũ mâu thuẫn với runtime, dùng runtime và cập nhật tài liệu cũ sau.

## 20. Character sheet import — 24/08/2026

Đã cắt và chuẩn hóa 8 sheet người dùng cung cấp trong
`C:\Users\khang\Pictures\resources\Boom`:

- Gấu Nâu (`boom_mascot`) được đưa vào cùng pipeline từ sheet nguồn đã có, nên roster
  active hiện có đủ 9 nhân vật.

- Cắt alpha theo từng cell, loại phần ảnh rò từ cell kế bên và giữ nền trong suốt.
- Đồng bộ vào `assets/characters/<id>/v11/` với frame 112 × 112, cùng đường chân và tâm ngang.
- Mỗi nhân vật có đúng 64 PNG runtime: 4 idle × 4 hướng, 8 walk × 4 hướng,
  bubbled/escape/lose/win mỗi trạng thái 4 frame (tổng 14 clip logic).
- Cắt nguồn được lưu cạnh bộ ảnh người dùng tại
  `C:\Users\khang\Pictures\resources\Boom\Assets\images`.
- Manifest đầy đủ mapping nguồn → nhân vật → animation nằm ở
  `Assets/images/character_sheet_import_manifest.json`.
- Sheet Thỏ Trắng là ngoại lệ 7 cột × 8 hàng (56 frame nguồn); importer giữ nguyên
  56 crop thật và thêm frame chuyển cuối cho các animation cần 8 frame, không kéo
  ảnh của nhân vật kế bên vào frame.
- Script tái lập: `tools/import_character_sheets.py` và
  `tools/rebuild_character_spriteframes.py`.

QC bằng `generate2dsprite.py` đã chạy cho đủ 9 sheet active (8 sheet mới và
sheet Gấu Nâu) với `strict_qc`, không có
frame rỗng, không có frame bị clamp, body-scale CV ≤ 0.25 và anchor-y std ≤ 0.08.
