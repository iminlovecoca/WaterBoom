# Water-balloon catalog audit

## Tình trạng hiện tại

- File: `assets/water_balloons/water_balloon_catalog.json`.
- Metadata khai báo 63, thực tế 65 record.
- 65/65 thư mục có `icon.png`, resource frames và bốn idle PNG.
- Rarity: 11 common, 25 uncommon, 19 rare, 6 epic, 4 legendary.
- Không có ID string trùng.
- Schema đang là v1/v2 đơn ngữ, asset path dựa vào convention thư mục.

## Lỗi dữ liệu

| ID | Hiện trạng | Rủi ro | Xử lý đề xuất |
|---|---|---|---|
| `skin_061` | Jungle Fern, source (7,6) | trùng tọa độ với 063 | giữ ID, bỏ source coord khỏi runtime |
| `skin_062` | Watermelon, source (7,7) | concept trùng 063, giá 150k lệch band | giữ canonical Watermelon |
| `skin_063` | Watermelon / Dưa hấu, source (7,6) | ID khác nhưng cùng concept | giữ ID cho owner, redesign thành Melon Soda |
| `skin_064` | Dragon Ball / Ngọc Rồng, source (8,7) | ngoài grid và gợi IP | giữ ID, đổi art/name thành Seven-Star Comet |
| `skin_065` | Straw Hat Pirate, source (8,0) | ngoài grid và gợi IP | giữ ID, đổi thành Treasure Tide |

## Mismatch mặc định

- SQL schema cũ: `classic`.
- Registration/GameSession: `skin_039`.
- Registry fallback: `skin_001`.

Đề xuất an toàn: alias `classic -> skin_039` để không làm đổi đồ của account cũ; mọi ID không biết fallback thị giác sang `skin_001` nhưng phải log giá trị cũ. Chỉ update SQL sau khi backup và được duyệt.

## Schema catalog v3 đề xuất

```json
{
  "catalog_version": 3,
  "id": "skin_001",
  "display_name_vi": "Thủy Cầu Cổ Điển",
  "display_name_en": "Aqua Classic",
  "family": "aqua",
  "rarity": "common",
  "price": 0,
  "unlock_method": "starter",
  "icon_path": "res://assets/water_balloons/skins/skin_001/icon.png",
  "idle_frames": [".../idle_0.png", ".../idle_1.png", ".../idle_2.png", ".../idle_3.png"],
  "sprite_frames_path": "res://assets/water_balloons/skins/skin_001/skin_001_frames.tres",
  "vfx_profile": "water_default",
  "sfx_profile": "water_pop_default",
  "legacy_aliases": ["classic"]
}
```

Runtime không được đọc `source_row/source_col`; đó chỉ là provenance audit nếu còn giữ.

## Band economy đề xuất — chưa áp dụng

- Common: starter hoặc 50.000.
- Uncommon: 100.000.
- Rare: 200.000.
- Epic: 300.000.
- Legendary: 400.000.

Mọi giá hiện tại vẫn giữ nguyên trong checkpoint. Band chỉ dùng để audit và cần duyệt economy riêng.

