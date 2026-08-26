# Codex handoff

## Local supervisor automation checkpoint — 2026-08-26

- Added a bounded local Codex-supervisor/Antigravity-worker framework in `tools/agent_orchestrator.py`, with task schema/examples under `.agents/tasks/`, machine-readable Godot map/UI probes, Windows/Git Bash wrappers, safety checkpoints and iteration evidence.
- Current repository has no `.git` directory and `agy` is not installed/on PATH. The orchestrator does not initialize Git; it uses a SHA-256 manifest plus scoped/protected file copies. Real implementation runs require installing `agy` or setting `ANTIGRAVITY_CMD`.
- The requested Snow Village sample uses 104 breakables as a future contract, while the current production `MapLayoutSmoke` contract is 128. The sample is not automatically applied; `audit_current_maps_readonly.json` preserves and verifies the current 128 baseline.
- Gameplay/network/save/economy/database files remain protected by default. No gameplay, networking, save/account data or assets were changed for this tooling checkpoint.
- Verification: Python compile + all task JSON parse PASS; orchestrator dry-run PASS; PowerShell wrapper dry-run PASS; explicit rollback no-op PASS; Godot editor import exit 0; read-only supervisor run `20260825T183426Z_audit_current_maps_readonly` PASS with map contract 10/10, map layout 90/90 and map gameplay 48/48; UI contract probe 128/128; Snow Village seam validator 30/30. `agy` detection correctly reports not found.
- Automatic chat routing added in `.cursor/rules/boom-auto-antigravity.mdc`; orchestrator now autodetects the standard Windows AGY install path. Local AGY binary verified at `%LOCALAPPDATA%\agy\bin\agy.exe`, version 1.1.20. A real prompt was not sent during setup to avoid consuming Antigravity quota; next implementation request in a restarted Codex session is the first worker run.

## Current checkpoint

The approved Aqua Arcade v2 UI/HUD pass remains integrated. The active production roster is `boom_mascot` (Gấu Nâu), `cloud_bunny` (Thỏ Trắng), `shadow_ninja` and `aqua_pacifier`. All four use one locked 15-action/84-frame contract on 112×112 canvases with feet anchored at (56,103). The bunny's source silhouette is narrower, so its shared presentation layer applies an x-only 1.18 correction; no source crop or vertical stretch is used.

## Display normalization checkpoint — 2026-08-26

- Character size is centralized in `scripts/ui/CharacterPresentation.gd` and applied to gameplay, room cards, lobby selection, HUD sidebar and card/slot previews. Bunny width is corrected while height, feet baseline and full source canvas remain shared.
- Balloon size is centralized in `scripts/water_balloon/WaterBalloonSkinRegistry.gd`: runtime and UI icons normalize the non-transparent alpha footprint through `get_runtime_scale()` and `get_icon_scale()` without modifying source images.
- Verification recorded in this checkpoint: `CHARACTER_PRESENTATION_RESULT: 20 passed | 0 failed`; `WATER_BALLOON_SCALE_RESULT: 54 passed | 0 failed`; Godot editor import exit 0.

## Files changed

- `scenes/login/Login.tscn`: responsive login layout.
- `scripts/ui/LoginScreen.gd`: status/focus/busy UX and explicit `--server` routing.
- `scripts/ui/UITheme.gd`: disabled and keyboard focus button states.
- `resources/ui/game_theme.tres`, `ui/theme/palette.gd`, `scripts/ui/UITheme.gd`: Aqua Arcade v2 shared surfaces, fields, buttons and HUD tokens.
- `scripts/ui/Lobby.gd`, `scripts/ui/ShopView.gd`, `scripts/ui/InventoryView.gd`, `scripts/ui/MatchFrameUI.gd`: shared checkerboard and panel system across HUB/game surfaces.
- `scripts/cosmetics/CosmeticRegistry.gd`, `scripts/ui/PlayerCardPreview.gd`, `scripts/player/PlayerVisual.gd`, `scripts/ui/MatchHUD.gd`, `ui/components/BoomRoomSlot.gd`, `ui/screens/room_wait/RoomWaitScreen.gd`: retire head accessory/custom frame presentation without deleting compatibility data.
- `assets/items/item_*.png`: five supplied icons normalized to 96×96 RGBA; originals preserved in `assets/items/source_user_2026_08_24/`.
- `scripts/items/ItemEntity.gd`: 38 px world presentation for the new HD item icons.
- `tools/NormalizeItemIcons.py`, `tests/ItemIconContractSmoke.gd`, `tests/CosmeticPresentationSmoke.*`: reproducible import and regression contracts.
- `tests/LoginLayoutMatrixSmoke.*`: five-size UI layout gate.
- `tests/PerformanceBaseline.*`: renderer performance capture.
- `README.md` and checkpoint docs.
- `assets/characters/v13_rebuild_manifest.json`: locked V13 canvas, anchor, identity and 15-action contract.
- `assets/characters/*/v13_staging/`: generated source atlases, deterministic cleanup outputs and 9×84 production-ready runtime frames.
- `tools/BuildCharacterV13Staging.py`: deterministic extraction, magenta cleanup, alignment and QC pipeline (including Sunny Mechanic 4×8 walk compatibility).
- `tools/BuildCharacterV13Resources.py`: builds nine `*_frames_v13.tres` resources and switches CharacterDefinitions to V13.
- `resources/characters/*_frames_v13.tres`: active 15-action SpriteFrames resources.
- `tests/CharacterV13ResourceConsistencySmoke.gd`: production contract check and JSON artifact.
- `scripts/ui/CharacterPresentation.gd`, `tests/CharacterPresentationContainmentSmoke.*`: shared 112×112 full-frame presentation and card/slot containment gate; Inventory no longer falls back to cropped v9–v11 portraits.
- `scripts/player/PlayerVisual.gd`, `scripts/ui/PlayerCardPreview.gd`, `ui/components/BoomRoomSlot.gd`, `ui/components/BoomSlot.gd`: shared bunny x-only footprint correction on gameplay, room and player-card surfaces.
- `scripts/core/BootManager.gd`, `scripts/ui/MatchHUD.gd`: shared correction on lobby/room character cards, character selection, and in-game player sidebar portraits.
- `scripts/water_balloon/WaterBalloonSkinRegistry.gd`, `scripts/water_balloon/WaterBalloon.gd`, `scripts/ui/ShopView.gd`, `scripts/ui/InventoryView.gd`, `scripts/water_balloon/WaterBalloonGallery.gd`: alpha-footprint normalization for runtime and icon display sizes.
- `tests/WaterBalloonDisplayScaleSmoke.gd`, `tests/WaterBalloonDisplayScaleSmoke.tscn`: 54-check display-scale regression gate across all active skins.
- `ui/components/BoomRoomSlot.tscn`, `ui/components/BoomRoomSlot.gd`, `scripts/ui/PlayerCardPreview.gd`: static room/player cards no longer clip the authored canvas; portrait is z=3 while head/flag/VFX layers are z=4+, so lower feet and terminal poses remain visible.
- `scripts/core/BootManager.gd`: dynamic room-card frame is now a border layer behind the V13 portrait/VFX, so its bottom rail cannot crop feet or terminal poses.
- `scripts/network/NetworkManager.gd`: `start_host()` is idempotent for a live same-port server and exposes a peer-liveness check for safe server RPC replies.
- `scripts/data/AccountDatabase.gd`: authentication, registration, profile, inventory, cosmetic and balance responses now skip peers that disconnected during the request; stale duplicate-login mappings are removed without sending to an unknown ID.
- `scripts/characters/ActiveCharacterRoster.gd`: single source of truth for the four active character IDs and backward-compatible ID normalization.
- `scripts/core/GameSession.gd`, `scripts/data/AccountDatabase.gd`, `data/database/schema.sql`, `scripts/network/RoomManager.gd`, `scripts/match/MatchManager.gd`, `scenes/characters/Player.tscn`, `scripts/player/PlayerController.gd`: default/legacy character IDs normalize to Gấu Nâu; the four-character active roster is spawned or synchronized.
- `tests/ActiveCharacterRosterSmoke.*`: verifies exactly two definitions are discoverable and retired IDs normalize safely.
- `tests/RoomSlotLayerSmoke.*` and `tests/RoomSlotVisualCapture.*`: layer contract and GPU capture for the dynamic room-card path.
- `tests/CharacterV13CastPreview.*`: full-cast GPU preview using real `PlayerVisual`, bubble shell and status VFX.
- `tests/artifacts/character_v13_cast_idle.png`, `character_v13_cast_bubble.png`, `character_v13_full_cast_showcase.mp4`: visual evidence.
- `assets/water_balloons/samples/crystal_prism/`: accepted 4-frame art baseline and runtime exports.
- `assets/characters/boom_mascot/v12_staging/runtime_frames/`: 84 runtime frames across 15 animation contracts, 112×112 each.
- `assets/characters/*/v12_staging/master/processed/`: eight 112×112 master previews (Cloud Bunny, Cocoa Otter, Coral Diver, Lime Dino, Mint Sprout, Red Rider, Star Skater, Sunny Mechanic); each uses distinct face/hair/skin and short rounded Doraemon-like limbs.
- `assets/characters/*/v12_staging/runtime_frames/`: 9×84 normalized runtime frames across idle/walk/bubble/rescue/water-hit/die/win/lose contracts; every frame is 112×112 and non-empty.
- `assets/characters/v12_staging_manifest.json`: per-action source map (`v12-authored` vs `v11:… (normalized)`), canvas and contract counts.
- `resources/characters/*_frames_v12.tres`: runtime SpriteFrames resources wired to the v12 staging bundle; original `*_frames.tres` remains available for rollback.
- `assets/water_balloons/v12_staging/samples/`: four 4-frame v12 source samples with 128×128 game frames and 64×64 icons; Crystal Prism remains the locked structural reference.
- `assets/water_balloons/skins/skin_066/` … `skin_069/`: four v12 samples integrated into production catalog/runtime with stable IDs, shop metadata and generated SpriteFrames resources.
- `assets/water_balloons/source_user_2026_08_25/` + `assets/water_balloons/skins/skin_070/` … `skin_079/`: ten user-supplied 2×2 JPG balloon sheets archived, magenta-cleaned and packaged as four 128×128 idle frames, 64×64 icons and shared pop resources; shop/inventory/gameplay resolve these IDs through the existing registry.
- `tests/CharacterV12CheckpointPreview.tscn` + `tests/CharacterV12CheckpointRunner.gd`: isolated GPU preview and smoke runner.
- `tests/artifacts/character_v12_checkpoint.png` + `tests/artifacts/character_v12_checkpoint_qc.json`: visual capture and machine-readable QC evidence.
- `tests/artifacts/character_v12_coverage.json`: machine-readable 9/9 × 84/84 coverage evidence.
- `tests/CharacterV12ResourceConsistencySmoke.gd` + `tests/artifacts/character_v12_resource_consistency.json`: 9 resources share the same 14 runtime action names/counts.
- `tests/WaterBalloonV12AssetCoverageSmoke.gd` + `tests/artifacts/water_balloon_v12_coverage.json`: 78 active skins × 6 required PNG assets, dimension-checked.
- `tests/UserWaterBalloonSkinsSmoke.gd` + `tests/UserWaterBalloonSkinsSmoke.tscn` + `tests/artifacts/user_water_balloon_skins.json`: all ten new IDs resolve through the autoload registry with four idle frames and a 64px icon.
- `scripts/characters/CharacterV12Coverage.gd` + `tests/CharacterV12CoverageSmoke.gd`: read-only coverage gate.
- `tools/BuildCharacterV12Compat.ps1`: reproducible staging normalizer; never overwrites v11 or production resources.
- `tools/BuildCharacterV12Resources.ps1`: reproducible SpriteFrames resource generator for the 14 runtime clips.
- `scripts/water_balloon/WaterBalloonCatalogV3Normalizer.gd` + `tests/WaterBalloonCatalogV3ValidatorSmoke.gd`: non-mutating v2→v3 preview, 78-active/79-stable-ID gate; catalog now contains the v12 entries and ten user additions.
- `tools/IntegrateV12BalloonSamples.ps1`: reproducible staging-to-production integration for `skin_066`–`skin_069`; it preserves all existing IDs and uses the canonical shared pop burst until bespoke per-skin burst art is authored.
- `tests/WaterBalloonSampleGallery.*`: isolated Godot runtime preview; no catalog/economy mutation.
- `tests/artifacts/rejected_water_balloon_samples_checkpoint1/`: recoverable archive for the five rejected samples, excluded through `.gdignore`.
- `docs/CHARACTER_AND_BALLOON_REBUILD_V12.md`: locked 9-character animation contract, historical v12 QC/generation budget; current catalog is 78 active / 79 stable IDs.

## Verification snapshot

- Login matrix 40/0.
- Item icon contract 5/5 at 96×96.
- Cosmetic presentation: retired head/frame absent from visible catalog, legacy registry retained (7 visible / 17 compatible total).
- GPU captures exit 0: Login, Room/Lobby v2, Shop, Inventory and Match sidebar.
- 18.17-second 960×720/30 FPS review video: `tests/artifacts/aqua_arcade_ui_v2.mp4`; contact-sheet review: `tests/artifacts/aqua_arcade_ui_v2_review.png`.
- Account 19/0.
- Map layout 90/0.
- Map gameplay 48/0.
- Balloon collision 4/0.
- Character animation 24/0.
- Playable loop 17/0.
- Performance: login and training match p95 about 6.6 ms at 960×720 on RTX 4060.
- Character v12 checkpoint runner: `CHARACTER_V12_RUNNER PASS`, GPU renderer exit code 0; Gấu Nâu authored bundle has no empty/edge-clamped frames.
- Character v12 coverage: `CHARACTER_V12_COVERAGE PASS complete=9/9`; 756/756 frames present, 112×112, empty=0.
- Character V13 resource consistency: `PASS characters=2 actions=15 frames_per_character=84`; both active CharacterDefinitions load V13.
- Active character roster (historical V13 checkpoint): `ACTIVE_CHARACTER_ROSTER PASS active=boom_mascot,cloud_bunny`.
- Character presentation containment: `CHARACTER_PRESENTATION_RESULT: 20 passed | 0 failed`; all four active idle frames are 112×112 and fit room/player cards at the shared 0.72 UI scale, including the bunny's x-only correction.
- Balloon display normalization: `WATER_BALLOON_SCALE_RESULT: 54 passed | 0 failed`; all `skin_066`–`skin_091` runtime and icon scales are finite and normalized, including the tall cloud balloon.
- QA gallery preview now applies the same runtime normalization after skin/animation changes (`scripts/water_balloon/WaterBalloonAnimationQA.gd`), so debug previews do not reintroduce per-skin size drift.
- Room-slot layer smoke: `ROOM_SLOT_LAYER_RESULT: pass`; CardPanel clipping is disabled and decorative frame is behind portrait.
- V13 source/runtime lower-body audit: 756/756 PNGs present; all idle/walk frames have non-empty alpha through the feet band (bbox end.y ≥ 100); no source crop detected.
- Room-slot GPU capture: `tests/artifacts/room_slot_visual_capture.png`; all dynamic cards render complete lower bodies for the new characters without the cyan bottom rail covering them.
- V13 active bundle (mascot baseline): 2/2 × 15 actions × 84 frames, 112×112, no empty or edge-clamped runtime frame.
- V13 visual review: idle and bubble GPU captures show Gấu Nâu and Thỏ Trắng inside their cells with consistent feet anchoring and shared bubble/VFX composition.
- V13 showcase: 18.0-second 960×720/30 FPS video reviewed through a six-frame contact sheet; all four directions and terminal poses remain in frame.
- Playable loop after V13 switch: 17/17; selected character reaches live gameplay, bubble timeout and result flow.
- Godot editor import after V13 switch: exit 0; máy kiểm thử còn in cảnh báo DLL template debug tùy chọn của addon godot-sqlite, không liên quan đến runtime nhân vật.
- Catalog v3 preview smoke: `CATALOG_V3_SMOKE PASS active=78 ids=79`; existing legacy IDs, the four v12 IDs and ten user IDs resolve successfully.
- Balloon asset coverage: `BALLOON_V12_ASSET_COVERAGE PASS active=78 files_per_skin=6`; all active skins meet the runtime contract. The new skins use the shared canonical pop burst for now.
- User balloon registry smoke: `USER_BALLOON_SKINS PASS new=10 frames=4 icon=64`; every user sample is purchasable/equippable through the existing catalog path.
- Gấu Nâu/Thỏ Trắng roster check: active resource and presentation smoke passed; legacy source validation remains archived and is not part of runtime discovery.
- Dedicated network auth smoke: `LOCAL AUTH NETWORK SMOKE: PASS` against the reachable localhost server; the previous `unknown peer ID` race is guarded in the new code path.

## Hard stop / approvals required

Do not continue any of these until separately approved:

- any additional paid bulk generation beyond the completed V13 character pass;
- SQL ID normalization;
- physical deletion of old character assets (the user-facing roster removal is implemented; disk cleanup remains reversible until explicitly requested);
- economy-wide price migration;
- network architecture rewrite;
- another broad UI style replacement beyond the approved Aqua Arcade v2 system.
- Further paid character/balloon generation is paused. Dedicated V14 status/bubble art remains deferred; V11/V12 and older source bundles remain reversible fallbacks.

Review skill also requires user to choose exactly one: Bugbot or Security Review.

## Next safe sequence after approval

1. Playtest V13 in crowded 4v4 and boss scenes; make only per-character visual-scale/anchor corrections supported by capture evidence.
2. Treat Crystal Prism as the locked silhouette/structure/knot reference for every future balloon.
3. Apply the validated 78-active/79-stable-ID catalog migration on a database copy after approval; keep SQL IDs backward-compatible.
4. Make balloon purchase/equip server-authoritative and test on DB copy.
5. Continue low-resolution/device focus-navigation QA without changing the accepted Aqua Arcade v2 visual contract.

## Current character V14 checkpoint — 2026-08-25

- User-requested scope is now character-first. No new water-balloon skins or dedicated “kẹt trong bóng nước” sprite sheets are being integrated in this checkpoint; the existing `PlayerVisual`/`BubbleVisual` gameplay effect remains the source of truth.
- `assets/characters/v14_rebuild/shadow_ninja/` and `assets/characters/v14_rebuild/aqua_pacifier/` contain the accepted source sheets and strict-QC processed sheets. Both use a shared 112×112 cell, top-down camera, short one-piece limbs, and the same feet anchor.
- `tools/BuildCharacterV14Resources.py` deterministically assembles 15 named actions / 84 frames per character. Locomotion uses the authored idle/walk art; `rescue`, `water_hit`, `bubble`, `rescued`, `die`, `win`, and `lose` currently reuse that character’s safe idle frames so no body part is clipped. The actual bubble shell/VFX is still runtime-owned and intentionally deferred for a later art pass.
- `resources/characters/shadow_ninja.tres`, `aqua_pacifier.tres` and their `_frames_v14.tres` resources are wired into `ActiveCharacterRoster`, `MatchManager`, and account-character normalization. The active roster is now `boom_mascot`, `cloud_bunny`, `shadow_ninja`, `aqua_pacifier`; the older nine-character source bundles remain rollback-only.
- V14 idle correction (2026-08-26): Shadow Ninja and Aqua Pacifier no longer cycle walk frames while idle in the left/right/up directions. Those directions hold their correct standing pose; down-facing idle keeps the authored blink frames. `CharacterV14ResourceSmoke` includes a regression check that the three static directions do not reintroduce body motion.

## Current water-balloon transparency checkpoint — 2026-08-25

- Runtime catalog scope is now exactly 16 IDs: `skin_066`–`skin_081`. The four approved existing designs remain, the ten user-supplied designs remain, and `skin_080` Bubble Star plus `skin_081` Cloud Pearl were added. Old `skin_001`–`skin_065` folders are retained for rollback only and are not discoverable at runtime.
- Runtime defaults and network fallbacks now use `skin_066` (Aqua Classic Reforge). `GameSession` filters legacy database rows against the runtime registry and migrates invalid selected IDs to `skin_066`; new accounts seed `skin_066`.
- Every active skin is packaged as RGBA PNGs: one 64×64 icon, four 128×128 idle frames, and a shared pop burst. Magenta is never loaded by runtime; it exists only in raw/staging source sheets.
- `tools/CleanWaterBalloonMatte.py` removes only low-alpha magenta matte residue and intentionally preserves opaque internal glass colors. `tools/ValidateWaterBalloonAlpha.py` currently passes all 16 skins (96 PNGs) with transparent corners and no visible matte-like pixels; report: `tests/artifacts/water_balloon_alpha_validation.json`.
- `tests/ActiveCharacterRosterSmoke.tscn`: `ACTIVE_CHARACTER_ROSTER PASS active=boom_mascot,cloud_bunny,shadow_ninja,aqua_pacifier`.
- `tests/CharacterPresentationContainmentSmoke.tscn`: `CHARACTER_PRESENTATION_RESULT: 18 passed | 0 failed`; all active portraits preserve the complete 112×112 frame inside room/player cards.
- `tests/CharacterV14ResourceSmoke.tscn`: `CHARACTER_V14_RESOURCE_RESULT: 36 passed | 0 failed`; both new resources expose all 15 actions, expected frame counts and 112×112 textures, while left/right/up idle frames are verified static.
- `tests/CharacterAnimationSmoke.tscn`: `CHARACTER_ANIMATION_RESULT: 26 passed | 0 failed`; active-roster movement, idle, hit, bubble, rescue, death, win and lose runtime wiring remains intact. Dedicated “kẹt trong bóng nước” art is intentionally not part of this pass.
- Godot 4.7.1 headless scene run and editor import both exit 0 after the V14 resources are rebuilt.
