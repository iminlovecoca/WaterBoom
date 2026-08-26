# Map polish report — checkpoint 1

## Runtime contract hiện tại

Sáu map active: Training Plaza, Pirate Harbor, Lego City, Aqua Park, Snow Village, Egypt Temple.

Mỗi map chuẩn:

- 16×16 ô;
- 60 hard block ngoài;
- 40 hard block trong;
- 128 breakable;
- 28 floor;
- bốn spawn góc, mỗi spawn có đúng túi chữ L ba ô;
- bốn team spawn phụ đối xứng;
- tâm 4×4 là breakable để luôn có đường phá thẳng;
- không còn landmark khổng lồ che footprint gameplay.

`MapLayoutSmoke` đạt 90/90 và `MapGameplayRegressionSmoke` đạt 48/48.

## Điểm đã ổn

- Số block và escape route đồng nhất.
- Vụ nổ dừng ở boundary, hard block và breakable đúng logic.
- Item chỉ biến mất khi inventory nhận được.
- Asset runtime trỏ vào cây V2, không dùng frame cũ trong definition active.

## Điểm cần polish nhưng không đổi gameplay

1. Sáu map dùng cùng nhịp bố cục; cần biến thể đối xứng có kiểm soát thay vì chỉ đổi skin.
2. Decoration runtime tiêu chuẩn gần như trống; cần prop 1×1/2×2 đặt ngoài escape lane.
3. Cần visual contract chung: chân vật thể neo ở 75–82% chiều cao ô, collider nằm trong chân đế, bóng đổ cùng hướng.
4. Cần budget màu riêng từng map nhưng giữ độ tương phản floor/block/character tương đương Aqua Park.

## Quy tắc polish đề xuất

- Không đổi 16×16, tổng 128 breakable hoặc ba ô spawn.
- Tạo 3 layout seed cho mỗi map, cùng số block và cùng độ dài đường thoát.
- Decoration không được chiếm ô giả; footprint phải khớp collider và nav grid.
- Mỗi góc phải có mật độ thị giác tương đương, kiểm tra bằng quadrant count.
- Không đặt prop cao che tên/đầu nhân vật ở spawn hoặc lane một ô.
- Mọi biến thể phải vượt `MapValidator`, `MapLayoutSmoke`, `MapGameplayRegressionSmoke` và capture visual.

