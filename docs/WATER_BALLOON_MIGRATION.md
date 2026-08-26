# Water-balloon migration plan

## Nguyên tắc không phá dữ liệu người chơi

1. `skin_001`…`skin_065` là immutable database IDs.
2. Không merge/xóa row ownership dù hai skin đang trùng hình hoặc tên.
3. Đổi display name/art bằng catalog version, không đổi primary key.
4. Backup database trước migration; migration chạy transaction và idempotent.
5. Server normalize alias; client chỉ render ID server trả về.

## Bảng chuyển đổi

| Legacy/current | Canonical v3 | Giữ ownership | Hành động |
|---|---|---:|---|
| `classic` | `skin_039` | có | thêm alias; sau duyệt mới normalize selected ID |
| `skin_001` Aqua Classic | `skin_001` Aqua Classic / Thủy Cầu Cổ Điển | có | giữ starter fallback |
| `skin_039` Pacific Deep | `skin_039` Pacific Deep / Thái Bình Dương Sâu | có | giữ default account hiện hành |
| `skin_061` Jungle Fern | cùng ID | có | gen asset gốc mới; bỏ coord trùng |
| `skin_062` Watermelon | cùng ID | có | canonical watermelon |
| `skin_063` Watermelon / Dưa hấu | `skin_063` Melon Soda / Soda Dưa Lưới | có | redesign khác 062, alias tên cũ |
| `skin_064` Dragon Ball | `skin_064` Seven-Star Comet / Sao Thất Tinh | có | thay motif gốc, bỏ liên hệ IP |
| `skin_065` Straw Hat Pirate | `skin_065` Treasure Tide / Thủy Triều Kho Báu | có | thay motif gốc, bỏ liên hệ IP |
| ID không tồn tại | render `skin_001` | giữ raw audit | không tự xóa dữ liệu |

## Trình tự migration sau khi duyệt

1. Thêm parser v3 có backward compatibility.
2. Thêm `legacy_aliases` và validator catalog; không update SQL.
3. Tạo asset mới trong staging, chạy alpha/size/contact-sheet QC.
4. Copy database backup có timestamp.
5. Transaction normalize `classic` và chèn ownership thiếu cho default.
6. Thêm server-side ownership validation cho equip/place/purchase.
7. Chạy account/network/catalog smoke trên database copy.
8. Chỉ sau visual + network approval mới retire asset cũ; không xóa trong cùng PR migration.

## Rollback

- Catalog giữ `catalog_version` và manifest checksum.
- Database backup là nguồn rollback.
- Asset mới dùng folder versioned; registry có thể quay về manifest cũ mà ID người chơi không đổi.

