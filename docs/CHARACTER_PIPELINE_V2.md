# CHARACTER PIPELINE V2 — 9 CHARACTER REMASTER

> Mục tiêu: remake toàn bộ 9 nhân vật hiện tại thành một roster đồng bộ, chibi đầu to/thân nhỏ theo các ảnh template đã cung cấp, giữ tương thích Godot và không phá gameplay.

## 0. RULES
- Đọc project trước khi sửa.
- Audit đủ 9 `CharacterDefinition`, `SpriteFrames`, `PlayerVisual`, selector, avatar/portrait, `CharacterStatusVFX`, `BubbleVisual`, tests và asset paths.
- Repository hiện tại là source of truth; không hardcode danh sách nhân vật cũ từ tài liệu.
- Không xóa asset V1 trước khi V2 runtime PASS.
- Không sửa gameplay, collision, bots, bomb, water, item, map hay networking để phục vụ art.
- Không tự thêm skill, vũ khí, lore, mechanic hoặc costume ngoài yêu cầu.
- Không placeholder/fake asset/fake completion.
- Minimal diff, backward-compatible khi có thể.

## 1. GIỮ PIPELINE HIỆN TẠI

`Sprite sheet -> SpriteFrames -> CharacterDefinition -> PlayerVisual`

Gameplay không được phụ thuộc trực tiếp vào từng file frame. Runtime art tiếp tục version dưới thư mục `runtime` của từng character và nối qua `CharacterDefinition`.

Không thay architecture chỉ để đổi art.

## 2. ROSTER

Target = **9 nhân vật đang xuất hiện trong selector hiện tại**.

Trước khi tạo asset, lập inventory thật từ repo:

| ID | Tên | Primary | Secondary | Accent | Identity | Resource |
|---|---|---|---|---|---|---|

Không đổi ID/path nếu không cần.

## 3. MASTER TEMPLATE

Dùng các nhân vật trong **ảnh reference 3/4/5** của task này làm master template.

Được clone:
- anatomy;
- silhouette;
- head/body ratio;
- tay/chân;
- camera;
- pose logic;
- sprite scale;
- selfie/avatar framing.

Mỗi nhân vật vẫn phải có identity riêng bằng:
- primary color;
- secondary color;
- accent nhỏ;
- hood/mũ/tai;
- pattern;
- phụ kiện nhỏ;
- chi tiết mascot.

Không biến roster thành 9 recolor giống hệt nhau.

### Proportion lock
- đầu chiếm khoảng 55–60% tổng chiều cao;
- torso rất ngắn, khoảng 0.45–0.55 chiều cao đầu;
- tay ngắn;
- chân ngắn;
- bàn tay/chân nhỏ và tròn;
- cổ gần như không thấy;
- compact silhouette;
- không body tỷ lệ anime/người thường.

### Render style
- cute arcade;
- clean;
- crisp;
- glossy 2D game render;
- edge rõ;
- cel/soft shading gọn;
- không painterly;
- không brush texture;
- không blur;
- không realism;
- không pixel-art thô.

Cả 9 phải cùng line weight, camera, lighting, eye style, shading, shadow và render sharpness.

## 4. COLOR RULE

Mỗi nhân vật có:
- **Primary:** màu nhận diện chính.
- **Secondary:** hỗ trợ, ít hơn primary.
- **Accent:** chỉ dùng ở kính, khăn, trim, buckle, icon, nút hoặc chi tiết nhỏ.

Không rainbow. Nhân vật phải nhận ra nhanh bằng silhouette + primary color.

## 5. SCALE / BASELINE

Pipeline hiện tại dùng character compact với visible alpha bounds khoảng 84 px và portrait cropped 96×96.

Trước khi export:
- đo contract thật trong repo;
- giữ cùng baseline;
- cùng ground contact;
- pivot ổn định;
- không frame jitter;
- mũ/tai không làm lệch body;
- không để một character cao/thấp bất thường.

Không đổi scale runtime nếu chưa test selector + lobby + gameplay.

## 6. ANIMATION CONTRACT

Giữ các clip compatibility hiện tại theo 4 hướng:
- idle
- walk
- place
- pickup
- hurt
- bubbled
- die
- win
- lose

Nếu remake toàn thân, các clip này cũng phải đồng style.

### Thêm clip mới bắt buộc: `escape`
Nếu runtime chưa có, thêm tối thiểu:
- `escape_down`
- `escape_up`
- `escape_left`
- `escape_right`

Thêm bằng thay đổi nhỏ, backward-compatible. Không thay `escape` bằng `win` hoặc `idle`.

## 7. DIRECTIONS

Gameplay animation phải hỗ trợ:
- down
- up
- left
- right

Không flip left/right nếu làm sai logo, tóc, mũ hoặc phụ kiện bất đối xứng. Chỉ reuse flip khi repo hiện tại hỗ trợ an toàn và đã verify.

## 8. ANIMATION DESIGN

### IDLE
Cơ thể gần như đứng yên.

Chỉ:
- blink;
- eye micro-movement;
- breathing cực nhẹ nếu thật sự cần;
- phụ kiện nhỏ rung rất ít.

Không bounce thân, lắc người hoặc nhún chân liên tục.

Target: 8–12 frame, loop tự nhiên.

### WALK
- 8–12 frame/hướng;
- tay chân cử động thật;
- bước ngắn;
- left/right foot alternating;
- foot contact rõ;
- head/body bob rất nhẹ;
- không trượt;
- giữ compact anatomy.

### BUBBLED
Khi bị bóng nước:
- nhân vật nằm hoàn toàn trong bubble;
- sợ/hoảng;
- khóc;
- mắt ướt;
- tay/chân co;
- có thể đập nhẹ vào bubble;
- loop rõ nhưng không quá loạn.

Nếu architecture hiện có `BubbleVisual`, giữ bubble shell/countdown tách khỏi body frames.

### ESCAPE
Khi được cứu hoặc dùng item:
- bubble burst;
- nhân vật thoát ra;
- **nhắm mắt cười khúc khích**;
- biểu cảm nhẹ nhõm;
- pose ngắn;
- rồi trở lại idle.

Target: 8–12 frame, one-shot.

### LOSE
- khóc;
- nước mắt;
- buồn;
- cúi đầu/lau mắt;
- không violent;
- không dùng die pose thay lose.

Target: 10–16 frame.

### WIN
- cười;
- ăn mừng;
- giơ tay/nhảy rất nhẹ;
- cute, compact;
- không cutscene dài.

Target: 10–16 frame.

### PLACE / PICKUP / HURT / DIE
Giữ để tương thích runtime, remake theo cùng style. Không thêm mechanic.

## 9. VFX

VFX tách body khi có thể.

### Bubble
- shell;
- highlight;
- wobble;
- countdown rim;
- burst;
- splash;
- droplets.

### Escape
- burst + splash;
- droplets;
- sparkle rất nhẹ.

### Win
- sparkle/sao/confetti nhẹ.

### Lose
- tear droplets.

### Walk
Nếu `CharacterStatusVFX` đã xử lý dust/streak thì reuse; không bake dust vào từng frame.

Không spam glow.

## 10. SPRITE SHEET CONTRACT

**Không xếp frame sát nhau.**

Mỗi frame:
- cell cố định;
- transparent padding rõ;
- không chạm frame kế bên;
- VFX không tràn cell;
- cùng canvas;
- cùng baseline;
- cùng pivot;
- không crop sát tóc/tai/tay/chân.

Mỗi animation nên nằm một row riêng. Metadata/frame-map lưu riêng nếu cần; không render label text vào production sheet nếu ảnh hưởng crop.

Agent phải đọc exact contract trước khi chọn:
- cell width/height;
- columns/rows;
- margin;
- spacing;
- FPS.

Không tự chọn 64/96/128 nếu repo đã có chuẩn khác.

## 11. SHEET OUTPUT

Ưu tiên tách:

### A — BODY SHEET
- idle
- walk
- place
- pickup
- hurt
- die
- win
- lose
- escape

### B — BUBBLED BODY
- bubbled crying loop 4 hướng

### C — SHARED VFX
- bubble shell/burst
- splash
- tears
- sparkle/result FX

VFX lớn không được làm thay đổi character body bounding box.

## 12. SELFIE / AVATAR

Remake avatar cho đủ 9 nhân vật theo template ảnh đã cung cấp.

Avatar:
- close-up;
- cảm giác selfie;
- đầu/mặt chiếm phần lớn;
- biểu cảm đáng yêu;
- direct hoặc 3/4 nhẹ;
- không phải full-body sprite phóng to.

Giữ asset separation hiện tại:
- `512×128` environment-only banner background;
- `256×256` transparent close-up selfie;
- `96×96` cropped portrait nếu room/player list còn dùng.

Xác minh kích thước thật trong repo trước export.

## 13. BACKGROUND RIÊNG

Mỗi character có background riêng nhưng cùng design system.

Dùng:
- primary + secondary;
- pattern/shape nhỏ theo theme;
- bubble/sparkle/environment motif nhẹ.

Background không tranh attention với mặt.

Không chỉ recolor cùng một background nếu có thể thêm motif nhận diện nhỏ.

## 14. SELECTOR

Giữ selector hiện tại:
- 3×3;
- 9 characters/page;
- selfie cutout trên button thật;
- selected = gold rim/glow;
- inactive = dim.

Không bake UI card vào selfie.

Cả 9 avatar phải:
- cùng scale;
- cùng crop;
- không mất tóc/tai;
- center ổn định.

## 15. CONSISTENCY SHEET

Trước integrate, tạo một lineup review sheet:
- 9 front idle poses;
- same scale;
- same baseline;
- transparent background;
- không text/UI.

Dùng nó để bắt:
- đầu nhỏ;
- body cao;
- tay/chân dài;
- shading lệch;
- saturation lệch;
- line weight lệch.

Lineup chỉ để review, không thay animation sheet.

## 16. IMPLEMENTATION ORDER

### Phase 1 — MASTER
Chọn mascot/template phù hợp nhất và hoàn thiện:
- anatomy;
- idle;
- walk 4 hướng;
- bubbled;
- escape;
- win;
- lose;
- compatibility clips;
- selfie;
- banner.

### Phase 2 — VALIDATE MASTER
Test:
- selector;
- lobby;
- player list portrait;
- movement;
- bubble;
- escape;
- win/lose;
- scale;
- baseline.

### Phase 3 — STYLE LOCK
Khóa:
- proportions;
- shading;
- shadow;
- frame cell;
- spacing;
- avatar crop;
- palette logic.

### Phase 4 — CLONE
Dùng master anatomy/template để remake 8 character còn lại. Không sáng tạo anatomy mới cho từng character.

## 17. QA

Phải chạy:
- `tools/SpriteSheetValidator.gd`
- `tests/CharacterAnimationPreview.tscn`
- `tests/CharacterAnimationSmoke.tscn`

Check:
- dimensions;
- alpha;
- border pixels;
- adjacent duplicates;
- baseline;
- slicing;
- FPS;
- pivot;
- runtime transitions;
- clipping;
- jitter;
- blur;
- scale.

Nếu thêm `escape`, bổ sung validation/smoke coverage.

## 18. CẤM
Không:
- đổi gameplay;
- đổi IDs tùy ý;
- xóa V1 sớm;
- 9 style khác nhau;
- body tỷ lệ người thường;
- painterly gameplay sprite;
- avatar = sprite đứng phóng to;
- bake card UI vào selfie;
- bake bubble shell vào body nếu pipeline đang tách;
- frame dính nhau;
- giả walk bằng bob/resize toàn thân;
- motion blur;
- báo DONE khi chưa runtime test.

## 19. REPORT MỖI CHARACTER

### CHARACTER
ID / Name / Primary / Secondary / Accent

### ASSETS
body sheet / bubbled sheet / selfie / banner / portrait / character-specific VFX

### ANIMATION
clip / direction / frames / FPS / loop hoặc one-shot

### CODE
files created / modified / reason

### QA
validator / preview / smoke

### REMAINING
chỉ phần thật sự chưa xong.

## 20. DEFINITION OF DONE

Một character chỉ DONE khi:
- đúng master anatomy;
- style đồng bộ;
- màu nhận diện rõ;
- đủ animation compatibility;
- bubbled khóc đúng;
- escape nhắm mắt cười đúng;
- lose khóc đúng;
- win ăn mừng đúng;
- selfie/avatar mới đúng;
- background riêng đúng;
- sheet spacing sạch;
- runtime import đúng;
- selector/lobby/gameplay đúng;
- QA PASS.

Roster chỉ DONE khi cả 9 đạt cùng chuẩn.
