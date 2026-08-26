# Six sample water-balloon prompts — approval pack

Đã chạy checkpoint mẫu. Asset-gen CLI không gọi được Gemini vì máy không có `GEMINI_API_KEY`, nên không phát sinh phí API từ CLI; sáu sheet được tạo bằng bộ tạo ảnh tích hợp rồi hậu xử lý local. Người dùng duyệt **Crystal Prism** vì đúng hình cầu, kết cấu và vị trí nút thắt; năm mẫu còn lại đã chuyển vào archive `.gdignore` và không thuộc asset active.

Crystal Prism hiện có `raw_sheet.png`, `master_256.png`, bốn frame `idle_*_128.png`, `icon_64.png`, `contact_sheet.png`, `idle_preview.gif` và metadata QC trong `assets/water_balloons/samples/crystal_prism/`. Đây là chuẩn khóa cho các lần tạo tiếp theo; chưa tích hợp catalog/shop/economy.

## Quy tắc chung khóa cứng

- Original Korean-chibi arcade water-balloon art direction; không sao chép logo, nhân vật, thương hiệu hoặc skin cụ thể từ reference.
- Quả bóng tròn, knot nhỏ ở đỉnh, cùng silhouette và tỷ lệ ở cả bốn cell.
- Ánh sáng trên-trái, outline sạch 3–5 px ở output 256 px, liquid refraction rõ, không mờ/cắt viền.
- Không mặt người, không chữ, không watermark, không prop ngoài bóng.
- Cell 1 neutral; cell 2 nén dọc 2%; cell 3 giãn ngang 2%; cell 4 highlight/bubble dịch nhẹ. Không xoay camera.
- Khoảng trống giữa cell rõ; không để art chạm biên sheet.

## 1. Common — Aqua Classic (`skin_001`)

```text
Create a 1024x1024 four-frame 2x2 sprite sheet, solid #FF00FF chroma background. One original round cyan water balloon per cell, small tied knot at top, transparent glassy water, simple internal waterline and three tiny bubbles, broad upper-left white highlight, deep aqua lower rim. Korean chibi arcade game asset, crisp high-definition sprite, no face, no text, no logo, no cast shadow outside silhouette. Four subtle idle states only: neutral, 2% vertical squash, 2% horizontal stretch, tiny highlight and bubble shift. Exact same scale, center and camera in all cells, generous cell padding.
```

## 2. Uncommon — Forest Guardian (`skin_002`)

```text
Create a 1024x1024 four-frame 2x2 sprite sheet, solid #FF00FF chroma background. One original emerald water balloon per cell, perfectly round liquid body, small knot, translucent green water, elegant leaf-vein caustic pattern and one tiny floating fern speck inside, upper-left highlight, dark teal-green lower rim. Cute Korean arcade styling, premium but readable at 64px, no face, no text, no logo. Four subtle idle states with identical framing: neutral, gentle squash, gentle stretch, internal fern and highlight drift. Clean closed alpha-ready silhouette, no glow crossing cell boundaries.
```

## 3. Rare — Watermelon Wave (`skin_062`)

```text
Create a 1024x1024 four-frame 2x2 sprite sheet, solid #FF00FF chroma background. One original round watermelon-inspired water balloon per cell: translucent green rind shell, juicy coral-red inner liquid visible through refraction, a few small dark seeds suspended inside, small green knot, glossy upper-left highlight, coherent liquid volume. Cute Korean chibi arcade asset, no face, no text, no brand. Four restrained idle frames, fixed center and size: neutral, 2% squash, 2% stretch, seed and highlight drift. Preserve a clean circular silhouette and crisp rim at game scale.
```

## 4. Rare — Crystal Prism (`skin_036`)

```text
Create a 1024x1024 four-frame 2x2 sprite sheet, solid #FF00FF chroma background. One original spherical crystal-water balloon per cell with a tiny knot, pale cyan liquid, three soft faceted refractions contained inside the round body, subtle rainbow dispersion along the lower-right interior, bright upper-left highlight. Premium Korean chibi arcade game sprite, clean and cute rather than realistic, no face, text, logo or detached sparkles. Four subtle idle frames with identical silhouette placement: neutral, squash, stretch, internal prism shimmer shift.
```

## 5. Epic — Abyss Bloom (`skin_052` target family)

```text
Create a 1024x1024 four-frame 2x2 sprite sheet, solid #FF00FF chroma background. One original round deep-ocean water balloon per cell, small knot, midnight indigo translucent water, a contained bioluminescent cyan-violet bloom pattern curling inside the liquid, soft upper-left highlight and luminous inner rim. Cute mysterious Korean arcade asset, readable silhouette, no monster face, no text, no logo, no smoke. Four subtle idle frames only: neutral, squash, stretch, inner bloom pulse; keep all glow inside a crisp closed outer contour.
```

## 6. Legendary — Celestial Tide (`skin_058` target family)

```text
Create a 1024x1024 four-frame 2x2 sprite sheet, solid #FF00FF chroma background. One original perfectly round celestial water balloon per cell with a small knot, layered sapphire and turquoise liquid bands, tiny original seven-point star particles suspended inside, a thin gold-cyan inner halo and strong upper-left highlight. Legendary Korean chibi arcade game asset with rich but uncluttered detail, no recognizable franchise symbol, no text, no logo, no face. Four controlled idle frames: neutral, squash, stretch, slow inner tide and star drift. Fixed center, fixed camera, crisp silhouette and padding.
```

## Output sau postprocess

Mỗi sample sẽ có:

- `raw_sheet.png`;
- `master_256.png`;
- `idle_0.png`…`idle_3.png` ở 128 px;
- `icon_64.png`;
- `contact_sheet.png`;
- `idle_preview.gif`;
- báo cáo QC alpha, bbox, center drift và frame size.

## Dự toán generation

- Khuyến nghị: Gemini image, 1K, 0,07 USD/call.
- Sáu sample, lần đầu: **0,42 USD**.
- Trần nếu mỗi sample retry đúng một lần: **0,84 USD**.
- Chroma cleanup/cắt frame/QC local: không có phí generation.
- Phương án rẻ Grok là 0,12 USD cho sáu call nhưng độ ổn định sheet có thể thấp hơn; không phải lựa chọn mặc định.
