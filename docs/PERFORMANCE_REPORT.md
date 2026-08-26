# Performance baseline

## Môi trường đo

- Godot 4.7.1 stable, D3D12 Forward+.
- NVIDIA GeForce RTX 4060 Laptop GPU.
- Viewport logic 960×720.
- 30 frame warm-up, 180 frame lấy mẫu cho mỗi scene.
- Dữ liệu thô: `tests/artifacts/performance_baseline.json`.

## Kết quả

| Scene | Load | Trung bình | p95 | Max | FPS ước tính |
|---|---:|---:|---:|---:|---:|
| Login | 91,25 ms | 6,06 ms | 6,56 ms | 6,75 ms | 165,0 |
| Match — Training Plaza | 213,34 ms | 6,06 ms | 6,62 ms | 6,90 ms | 165,0 |

Đây là baseline desktop hiện tại, chưa phải benchmark máy thấp. p95 đang dưới ngân sách 16,67 ms của 60 FPS.

## Ngân sách đề xuất

- Desktop mục tiêu: p95 ≤ 16,67 ms, load match ≤ 500 ms sau warm cache.
- Không tạo texture/resource mới mỗi frame.
- Animation sprite không được cập nhật ngoài màn hình nếu không cần.
- Cache StyleBox/theme/resource; không dựng lại toàn bộ room slot mỗi tick.
- Network snapshot chỉ cập nhật node thay đổi, tránh rebuild danh sách.

## Việc cần đo sau khi được duyệt mở rộng

1. 8 người + nhiều bóng nổ đồng thời.
2. Shop/inventory 65 skin và paging.
3. Lobby có 8 idle character + cosmetic overlay.
4. Boss phase 2 + minion.
5. Máy iGPU/low-end và export release.

## Hình runtime trước/sau UI mẫu

Hai ảnh dùng cùng viewport logic và cùng renderer:

- `tests/artifacts/login_before_checkpoint1.png`
- `tests/artifacts/login_after_checkpoint1.png`

