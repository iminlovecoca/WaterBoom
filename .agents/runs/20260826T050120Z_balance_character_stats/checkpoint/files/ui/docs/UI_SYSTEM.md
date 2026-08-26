# BOOM ONLINE 1:1 UI DESIGN SYSTEM & COMPONENT LIBRARY

## 1. TỔNG QUAN HỆ THỐNG
Hệ thống UI được thiết kế bám sát 1:1 theo phong cách arcade retro kinh điển của **Boom Online / Crazy Arcade (Nexon)**, tối ưu cho Godot 4.x với độ sắc nét pixel-perfect, màu sắc Ocean Blue chuẩn mực, các panel 9-slice nổi khối 3D và các component có khả năng tái sử dụng cao trên toàn bộ game.

---

## 2. DESIGN TOKENS & PALETTE (ui/theme/palette.gd)

| Token Name | Hex Code | Ứng dụng |
|---|---|---|
| CHECKER_1 | #1887fb | Nền caro ô sáng |
| CHECKER_2 | #107bf0 | Nền caro ô tối |
| TOP_BANNER_NAVY | #00266d | Banner xanh navy đỉnh màn hình |
| LEFT_PANEL_BG | #008fd6 | Nền khung phòng chờ bên trái |
| RIGHT_PANEL_BG | #01458c | Nền khung thông tin bên phải |
| INSET_DARK_BG | #032e7c | Nền inset chìm (Chọn đội, Bản đồ, Chat) |
| CYAN_BORDER_BRIGHT | #00d2ff | Viền vát sáng cyan 3D |
| CYAN_BORDER_DARK | #0060a8 | Viền đổ bóng tối cyan |
| GOLD_BORDER | #ffd84a | Viền vàng slot được chọn / Trưởng phòng |
| SLOT_CARD_CYAN | #09bfff | Khung thẻ slot nhân vật (96x94) |
| SLOT_NAME_BG | #006cb2 | Thanh nẹp tên người chơi (96x20) |
| SLOT_STATUS_BG | #3792e1 | Thanh nẹp trạng thái Sẵn Sàng (96x22) |
| CHAR_SLOT_BG | #1469d4 | Nền ô chọn nhân vật chữ X (68x38) |
| BTN_GOLD_NORMAL | #ff9800 | Nút Bắt Đầu (Cam vàng nổi khối) |
| BTN_BLUE_NORMAL | #008be2 | Nút hành động xanh đại dương |
| TEXT_WHITE | #ffffff | Chữ chính với viền đen tương phản |
| TEXT_GREEN_READY | #42e0a2 | Trạng thái Sẵn Sàng / Đang Sống |
| TEXT_CYAN_VIBRANT | #55ffff | Tên nhân vật, chỉ số nổi bật |

---

## 3. THƯ VIỆN ASSET GIAO DIỆN (ui/assets_generated/)

### 3.1 Panels (Khung 9-Slice)
- panels/left_room_panel.png (64x64, margin 16px): Khung chính bên trái 8 slot.
- panels/right_section_panel.png (64x64, margin 16px): Khung chính bên phải cấu hình.
- panels/inset_dark_box.png (32x32, margin 10px): Khung chìm chọn đội & bản đồ.
- panels/chat_log_box.png (32x32, margin 8px): Khung hiển thị tin nhắn chat.
- panels/chat_input_box.png (24x24, margin 6px): Ô nhập liệu trò chuyện.

### 3.2 Buttons (Nút bấm)
- uttons/btn_gold_normal.png, _hover.png, _pressed.png: Nút Bắt Đầu chính (202x62).
- uttons/btn_blue_normal.png, _hover.png, _pressed.png: Nút hành động & chọn bản đồ.
- uttons/btn_cycle.png: Nút Đổi Màu Sắc (115x24).
- uttons/btn_auto_ready.png: Nút Tự Động Sẵn Sàng (48x52).

### 3.3 Slots & Plates (Thẻ slot & Thanh nẹp)
- slots/room_card_9slice.png: Thẻ nhân vật 96x94 có vát góc 3D.
- slots/slot_name_plate.png: Thanh nẹp tên 96x20 viền chìm.
- slots/slot_status_plate.png: Thanh nẹp trạng thái 96x22.
- slots/char_slot_x_normal.png: Ô chọn nhân vật 68x38 dập nổi chữ 'X'.
- slots/char_slot_x_selected.png: Ô chọn nhân vật viền vàng gold.
- slots/inv_slot.png: Ô vật phẩm túi đồ / cửa hàng 90x110.

### 3.4 Badges, Icons & Backgrounds
- adges/crown_gold.png: Vương miện Trưởng Phòng 20x16.
- icons/scrollbar_up.png, _down.png, _thumb.png, _track.png: Bộ cuộn chatbox.
- ackgrounds/checkered_bg.png: Nền caro xanh lặp vô tận (32x32).

---

## 4. BỘ COMPONENT TÁI SỬ DỤNG (ui/components/)

1. **BoomPanel (BoomPanel.tscn / BoomPanel.gd)**:
   - Khung 9-slice tự động co giãn (PRESET_FULL_RECT), hỗ trợ 5 variant phong cách.
2. **BoomButton (BoomButton.tscn / BoomButton.gd)**:
   - Nút bấm arcade xúc giác, tự render hiệu ứng hover/pressed, chữ đổ bóng viền tương phản.
3. **BoomRoomSlot (BoomRoomSlot.tscn / BoomRoomSlot.gd)**:
   - Thẻ slot người chơi 96x144 đầy đủ: Chibi AnimatedSprite2D, Vòng đội trán 2.5D, Cột cờ nước, Vương miện, Tên & Trạng thái.
4. **BoomSlot (BoomSlot.tscn / BoomSlot.gd)**:
   - Ô chọn nhân vật 68x38 chữ 'X', selfie icon, viền chọn vàng gold.
5. **BoomTab (BoomTab.tscn / BoomTab.gd)**:
   - Nẹp tab cyan chuyển đổi trạng thái active/inactive.
6. **BoomHeader (BoomHeader.tscn / BoomHeader.gd)**:
   - Tiêu đề phòng và mã số phòng #LOCAL.
7. **BoomStatusBox (BoomStatusBox.tscn / BoomStatusBox.gd)**:
   - Bảng hiển thị tên nhân vật và cột chỉ số bóng / dài / tốc độ LED.
8. **BoomMapCard (BoomMapCard.tscn / BoomMapCard.gd)**:
   - Khung xem trước bản đồ, hiển thị 3 dòng thông số (Người chơi, Cấp độ, Số sao) + Nút chọn bản đồ.
9. **BoomInventorySlot (BoomInventorySlot.tscn / BoomInventorySlot.gd)**:
   - Thẻ vật phẩm cho Cửa hàng & Túi đồ.
10. **BoomSidebarCard (BoomSidebarCard.tscn / BoomSidebarCard.gd)**:
    - Thẻ người chơi cho thanh HUD cạnh dọc trong trận đấu.

---

## 5. MÀN HÌNH PHÒNG CHỜ 1:1 (ui/screens/room_wait/)
- File Scene: 
es://ui/screens/room_wait/RoomWaitScreen.tscn
- Script: 
es://ui/screens/room_wait/RoomWaitScreen.gd
- Khớp 1:1 chuẩn xác với template mẫu (800x600):
  - Bên trái: Tab cyan + Tiêu đề + 8 Slot người chơi + Khung chat log + Chat input & nút Gửi.
  - Bên phải: Chỉ số nhân vật + 12 ô chọn nhân vật chữ X + Nút đổi màu + Chọn Đội (Đỏ/Xanh) + Khung bản đồ + Nút Bắt Đầu lớn & Nút Tự Động Sẵn Sàng.
  - Dưới đáy: Thanh điều hướng Thoát phòng, Cửa hàng, Túi đồ, Cài đặt.
