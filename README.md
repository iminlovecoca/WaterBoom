# Boom Water Arcade

Godot 4.7.1 online water-balloon arcade game. Trạng thái này là **checkpoint UI/HUD Aqua Arcade v2**, chưa phải toàn bộ master prompt đã hoàn tất.

## Local Codex + Antigravity automation

Project có supervisor loop data-driven tại `tools/agent_orchestrator.py`: Codex audit/QA, Antigravity làm worker, tối đa 5 vòng, dừng sớm khi PASS/fatal hoặc cùng một failure lặp lại 2 lần. Rule `.cursor/rules/boom-auto-antigravity.mdc` tự route yêu cầu implementation từ Codex chat vào loop, nên không cần chạy PowerShell thủ công. Mỗi vòng lưu prompt, worker log, validator log, changed-file summary, QA JSON và screenshot dưới `.agents/`.

```powershell
# Chỉ kiểm tra cấu hình/checkpoint, không gọi worker hoặc validator
./agent-run.ps1 -Task .agents/tasks/fix_snow_village.json -DryRun

# Audit Godot read-only đang dùng
./agent-run.ps1 -Task .agents/tasks/audit_current_maps_readonly.json
```

AGY CLI hiện đã cài tại `%LOCALAPPDATA%\agy\bin\agy.exe` (version 1.1.20); orchestrator tự dò vị trí Windows chuẩn này. Xem `docs/ANTIGRAVITY_AUTOMATION.md` và `QA_GATE.md`. Sample Snow Village 104 breakables là future contract theo yêu cầu; production hiện tại vẫn là 128 và sample không tự chạy.

## Đã xây dựng

- Login, Lobby, Room, Shop, Inventory, Match, Result và vòng quay về room.
- SQLite account/register/login, Cokecy, EXP/level, ownership và cosmetic equipment.
- Classic solo/team, boss flow, bot và dedicated server/Playit path.
- Sáu map active 16×16 với contract 128 breakable và spawn chữ L.
- Roster gameplay hiện có 4 nhân vật đang hoạt động: Gấu Nâu (`boom_mascot`), Thỏ Trắng (`cloud_bunny`), Shadow Ninja (`shadow_ninja`) và Aqua Pacifier (`aqua_pacifier`). Hai nhân vật mới dùng bundle V14 được QC bằng `generate2dsprite`: cùng contract 15 nhóm hoạt ảnh, 84 frame/nhân vật, canvas 112×112, góc nhìn top-down và chân neo thống nhất. Asset chín nhân vật cũ còn lại không được discovery/instantiate; vẫn giữ làm rollback.
- Đã khóa hợp đồng hiển thị chung cho mọi surface (gameplay, room, lobby, inventory): portrait luôn lấy full idle frame V13/V14, canvas 112×112 và scale card/slot 0.72. Card không clip canvas; nền bo góc và khung trang trí là lớp riêng phía sau portrait để không cắt chân/hông/biên trái phải của bốn nhân vật active. Không còn crop v9–v11 trong Inventory.
- Bunny width correction is centralized in `scripts/ui/CharacterPresentation.gd`: `cloud_bunny` receives an x-only 1.18 content correction on gameplay, room/lobby cards, HUD sidebar and preview surfaces. Height, feet baseline and the 112×112 source canvas remain shared; no source frame is cropped or stretched vertically.
- 36 water-balloon skin record đang hiển thị trong runtime (`skin_066`–`skin_101`): 4 mẫu giữ lại + 12 mẫu v12/user + 10 mẫu Anime trước đó + 10 mẫu mới từ bundle RGBA đã duyệt (Boba Pearl, Citrus Splash, Moonlit Tide, Cloud Drift, Petal Jelly, Candy Orbit, Cherry Pop, Snow Globe, Prism Rainbow, Firefly Grove). Tất cả đều dùng canvas 128×128, icon 64×64 và alpha thật; không nạp nền hồng vào runtime.
- Cân bằng nhân vật đã khóa: cả 11 CharacterDefinition bắt đầu với đúng 2 bóng nước, sức mạnh 1 và tốc độ nền theo vai trò; giới hạn chung là 6 bóng, tầm nổ 6 và tốc độ 240 để không nhân vật nào vượt trần bất hợp lý.
- Runtime and UI balloon surfaces now use `WaterBalloonSkinRegistry.get_runtime_scale()` / `get_icon_scale()`: the non-transparent alpha footprint is normalized per texture while source art, transparent corners and internal glass detail remain untouched.
- Login mẫu đã chuyển sang responsive container, focus keyboard và đầy đủ button states.
- Login, Lobby, Room, Shop, Inventory và Match HUD hiện dùng chung Aqua Arcade v2: nền caro xanh, panel xanh sáng, inset navy, đường ghép cyan và CTA cam.
- Năm item gameplay đã dùng icon HD cùng chuẩn 96×96: kim châm, thêm bóng, khiên, giày tốc độ và bình tăng độ dài.
- Hệ thống phụ kiện đầu đã được bật lại xuyên suốt Shop, Inventory, Lobby/Room, Match HUD và gameplay: 7 món đang hiển thị (4 vòng profile `ring`, kính râm đỏ profile `face`, mũ cao bồi và nón lá Việt Nam profile `hat`), có tháo/trang bị; vòng vẫn bob nhẹ còn kính/nón khóa theo anchor để không trôi khỏi mặt/đầu. Khung thẻ tùy biến vẫn tắt ở lớp hiển thị, còn registry và dữ liệu cũ giữ nguyên để tương thích ngược.
- Ba asset phụ kiện mới được tạo bằng pipeline `generate2dsprite`/`asset-gen` sau khi đã xác nhận chi phí: nền màu phẳng chỉ dùng ở staging, sau đó chroma-key connected-component cleanup giữ nguyên pixel chi tiết và xuất RGBA trong suốt. Mỗi asset được crop theo alpha bbox với đệm 16 px, có `.import` Godot và được kiểm tra bốn góc alpha=0.
- Đồng bộ phụ kiện phòng đã được làm an toàn hơn: snapshot equipment gửi từ client chỉ được chuyển qua khi peer còn kết nối; host xử lý trực tiếp, client gửi tới peer 1 còn sống. Điều này ngăn RPC tới peer 1/peer cũ khi đang ở phòng offline hoặc vừa rời mạng.
- `NetworkManager.is_peer_connected(1)` hiện kiểm tra đúng trạng thái `client → server`, nên cập nhật trang bị từ client không bị bỏ qua khi server vẫn đang kết nối.
- Character V13/V14 resource/gameplay smoke: active roster 4/4 pass; presentation 18/18; V14 resource 36/36; animation 26/26; playable loop 17/17; Godot editor import exit 0. Shadow Ninja/Aqua Pacifier left/right/up idle is static and only the down-facing idle plays its authored blink frames. Dedicated kẹt-bóng-water art is intentionally deferred.
  Máy kiểm thử còn in cảnh báo DLL template debug tùy chọn của addon godot-sqlite, không liên quan đến runtime nhân vật.
- Room card frame layering đã sửa: frame nằm dưới portrait, nên thanh viền dưới không còn che chân hoặc các
  pose `water_hit`/`bubble`/`die`/`win`/`lose`.
- Dedicated-server RPC race đã được khóa: host cùng cổng được tái sử dụng thay vì đóng/mở lại, còn phản hồi xác thực,
  đăng ký, hồ sơ, shop và trang bị chỉ gửi tới peer vẫn tồn tại. Điều này loại bỏ lỗi `unknown peer ID` khi client vừa ngắt kết nối.
- Đã thêm lớp kiểm tra source/runtime: hai bundle V14 mới đều được `generate2dsprite` strict-QC ở 112×112, locomotion có alpha xuống vùng chân, không frame rỗng/edge-clamped; dynamic room-card containment xác nhận đủ chân và biên trái/phải cho cả 4 nhân vật active.
- Đã xử lý màu hồng bị dính vào lớp kính của các bóng trong suốt: `tools/DespillWaterBalloonMatte.py` chỉ chỉnh hue ở dải kính phía trên của `skin_078`–`skin_081`, không xóa pixel, không đổi alpha/hình học và không đụng vào các mẫu hồng/đỏ/tím chủ ý. Mười mẫu mới `skin_092`–`skin_101` được đóng gói từ PNG RGBA có sẵn, giữ nguyên chi tiết kính/nút thắt và vượt qua kiểm tra alpha/opaque-magenta.

## Còn lại của final polish

- Tiếp tục tinh chỉnh từng màn hình ở độ phân giải thấp sau khi Aqua Arcade v2 đã được triển khai xuyên suốt các màn hình chính.
- Đóng đường mua/trang bị bóng nước bằng server authority + transaction.
- Catalog runtime hiện có 36 ID ổn định (`skin_066`–`skin_101`), fallback duy nhất là `skin_066`; profile cũ tự migrate khỏi các ID không còn trong catalog.
- V13 là bundle nền của Gấu Nâu/Thỏ Trắng; V14 là bundle runtime mới của Shadow Ninja/Aqua Pacifier. V11/V12 được giữ nguyên chỉ để rollback. Các clip `bubble`, `water_hit`, `die`, `win`, `lose` của V14 hiện dùng frame nhân vật an toàn để không cắt hình; lớp bong bóng/VFX thật vẫn do `PlayerVisual`/`BubbleVisual` điều khiển và sẽ làm riêng sau.
- Thêm layout variants/trang trí map mà giữ nguyên collision/block budget.
- Benchmark 8-player/boss/low-end và capture video end-to-end 15–20 giây.
- Chạy một review được người dùng chọn: Bugbot hoặc Security Review.

## Asset table

| Nhóm | Vị trí | Trạng thái | Ghi chú |
|---|---|---|---|
| Character V13/V14 runtime | `assets/characters/boom_mascot/v13_staging/`, `assets/characters/cloud_bunny/v13_staging/` và `assets/characters/v14_rebuild/{shadow_ninja,aqua_pacifier}/` + `resources/characters/*_frames_v13/v14.tres` | active, 4/4 | 2 mascot V13 + 2 nhân vật mới V14; mỗi bundle 15 action/84 frame; runtime canvas 112×112; cùng top-down camera/feet anchor |
| Character rollback | `assets/characters/*/v12_staging/`, các V13 cũ ngoài roster | retained, inactive | Không được discovery/runtime load; giữ nguyên để rollback an toàn |
| Water balloons | `assets/water_balloons/skins/skin_066..skin_101/` + `assets/water_balloons/water_balloon_catalog.json` | 36 active asset contract pass | Mỗi skin có icon 64×64, idle 4 frame 128×128 và pop burst. `skin_066`–`skin_069` là 4 mẫu giữ lại; `skin_070`–`skin_081` là 12 mẫu kỳ trước; `skin_082`–`skin_091` là 10 mẫu Anime; `skin_092`–`skin_101` là 10 mẫu RGBA mới. Chuẩn hóa đồng nhất kích thước trên Lobby, Shop, Inventory và In-game. |
| Transparent balloon expansion | `assets/water_balloons/v14_new16_transparent_final/` + `tools/package_transparent_balloon_skins.py` + `tests/TransparentBalloonSkinsSmoke.tscn` | 10/10 integrated, no paid generation | Nguồn `single_asset-1..10.png` đã có alpha thật; đóng gói deterministic thành `skin_092`–`skin_101`, kiểm tra 60/60 file, không opaque magenta, giữ nguyên chi tiết trong bóng. |
| Crystal Prism sample | `assets/water_balloons/samples/crystal_prism/` | art baseline đã duyệt | 4 frame, master 256, runtime 128, icon 64, GIF; chưa nối catalog |
| v12 balloon samples | `assets/water_balloons/skins/skin_066..skin_069/` + `assets/water_balloons/v12_staging/samples/` | integrated, purchasable in Shop | Aqua Classic Reforge, Watermelon Fresh, Moonlit Abyss, Starlight Aurora; mỗi mẫu 4 frame/128 + icon 64; pop dùng baseline dùng chung hiện tại |
| User balloon samples | `assets/water_balloons/source_user_2026_08_25/`, `assets/water_balloons/skins/skin_070..skin_081/` | integrated, purchasable in Shop | 10 mẫu JPG của người dùng + Bubble Star + Cloud Pearl; mỗi nguồn 2×2 được tách thành 4 frame 128×128 + icon 64, đã kiểm tra alpha/viền trên nền xanh |
| Map V2 | `assets/maps/` | active | 6 map active, 16×16 |
| UI login | `assets/ui/login/` | active | màn hình mẫu checkpoint |
| Theme/font | `resources/ui/`, `scripts/ui/UITheme.gd`, `ui/theme/palette.gd` | Aqua Arcade v2 active | cùng font, panel, inset, button state và màu nhấn trên các surface chính |
| Gameplay item icons | `assets/items/item_*.png` | active, 5/5 contract pass | 96×96 RGBA; source người dùng giữ tại `assets/items/source_user_2026_08_24/` |
| Head accessory presentation | `scripts/cosmetics/AccessoryPresentation.gd`, `scripts/cosmetics/CosmeticRegistry.gd`, `scripts/player/PlayerVisual.gd`, `scripts/ui/PlayerCardPreview.gd`, `scripts/core/BootManager.gd`, `scripts/ui/MatchHUD.gd` | 7 assets active, custom frame retired | 4 vòng (`head_halo_aqua`, `head_fire_ring`, `head_flower_wreath`, `head_angel_ring`) + `head_sunglasses_red` (face) + `head_cowboy_hat`/`head_conical_hat_vietnam` (hat); card, room, match-list và world có geometry riêng, cùng sanitize equip/unequip |
| Head accessory art (2026-08-27) | `assets/cosmetics/head/{sunglasses_red,cowboy_hat,conical_hat_vietnam}.png`, `assets/cosmetics/head/generated_2026_08_27/` | transparent RGBA, imported | Asset pixel riêng từng món, nền staging được loại bỏ bằng connected-component chroma cleanup; raw/chroma provenance giữ trong thư mục generated |
| Audio | `assets/audio/` | active | login/lobby/exit/game SFX |
| Character V13/V14 evidence | `tests/artifacts/character_v13_*`, `assets/characters/v14_rebuild/*/walk_v2/` | verified | V13 mascot evidence + V14 strict-QC sheets; không tích hợp bubble sheet mới theo yêu cầu hiện tại |
| Character presentation containment | `scripts/ui/CharacterPresentation.gd`, `tests/CharacterPresentationContainmentSmoke.tscn`, `tests/RoomSlotLayerSmoke.tscn` | verified | 20/20 active checks + room-layer pass; 4/4 full 112×112 frame; bunny x-only correction; frame/rail ở dưới portrait, không cắt chân/biên trái phải |
| Balloon display normalization | `scripts/water_balloon/WaterBalloonSkinRegistry.gd`, `scripts/water_balloon/WaterBalloonAnimationQA.gd`, `tests/WaterBalloonDisplayScaleSmoke.tscn` | verified | 74/74 scale checks across `skin_066`–`skin_101`; runtime, icon and QA preview alpha footprints share a stable display target |
| Rejected balloon samples | `tests/artifacts/rejected_water_balloon_samples_checkpoint1/` | archived, `.gdignore` | 5 mẫu bị loại; có thể khôi phục, không được game import |

## Chạy

- Editor: mở `project.godot` bằng Godot 4.7.1.
- Client debug: chạy project, main scene là Login.
- Dedicated server: `start_server.bat` hoặc command có `--server`.

## Tài liệu checkpoint

- `docs/POLISH_BASELINE_AUDIT.md`
- `docs/UI_FLOW_AND_STATE_OWNERS.md`
- `docs/UI_DESIGN_SYSTEM.md`
- `docs/PERFORMANCE_REPORT.md`
- `docs/MAP_POLISH_REPORT.md`
- `docs/WATER_BALLOON_CATALOG_AUDIT.md`
- `docs/WATER_BALLOON_MIGRATION.md`
- `docs/WATER_BALLOON_SAMPLE_PROMPTS.md`
- `docs/CHARACTER_AND_BALLOON_REBUILD_V12.md`
- `scripts/water_balloon/WaterBalloonCatalogV3Normalizer.gd` + `tests/WaterBalloonCatalogV3ValidatorSmoke.gd`
- `scripts/characters/CharacterV12Coverage.gd` + `tests/CharacterV12CoverageSmoke.gd`
- `tests/WaterBalloonV12AssetCoverageSmoke.gd` + `tests/artifacts/water_balloon_v12_coverage.json`
- `tests/UserWaterBalloonSkinsSmoke.gd` + `tests/artifacts/user_water_balloon_skins.json`
- `tools/package_transparent_balloon_skins.py` + `tests/TransparentBalloonSkinsSmoke.tscn` + `tests/artifacts/transparent_balloon_skins.json`
- `tests/CharacterV12ResourceConsistencySmoke.gd` + `tests/artifacts/character_v12_resource_consistency.json`
- `tools/BuildCharacterV12Compat.ps1`
- `assets/characters/v13_rebuild_manifest.json`
- `tools/BuildCharacterV13Staging.py` + `tools/BuildCharacterV13Resources.py`
- `tests/CharacterV13ResourceConsistencySmoke.gd` + `tests/artifacts/character_v13_resource_consistency.json`
- `tests/CharacterV14ResourceSmoke.tscn` + `tests/CharacterV14ResourceSmoke.gd`
- `tests/CharacterV13CastPreview.tscn` + `tests/artifacts/character_v13_full_cast_showcase.mp4`
- `tests/RoomSlotVisualCapture.tscn` + `tests/artifacts/room_slot_visual_capture.png` (GPU visual gate cho room cards)
- `tools/DespillWaterBalloonMatte.py` + `tests/artifacts/water_balloon_despill_before_after.png` (QA màu kính bóng nước, không xóa chi tiết)
