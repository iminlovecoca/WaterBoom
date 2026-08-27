# Debug handoff

## Head accessory art checkpoint — 2026-08-27

Five head assets are now imported and registered: `head_sunglasses_red` (`face`), `head_cowboy_hat`, `head_conical_hat_vietnam`, `head_birthday_hat` and `head_crown_royal` (`hat`). They are transparent RGBA PNGs generated through the approved `generate2dsprite`/`asset-gen` route and cleaned locally with border-connected chroma removal so internal blue/cyan detail is not erased. Raw and intermediate images remain under `assets/cosmetics/head/generated_2026_08_27/` for reproducibility. The shared presentation layer keeps rings bobbing while hats and face items stay locked to their anchors.

The accessory registry now exposes 9 head items plus 6 live `KHUNG` frame definitions. PlayerCardPreview crops the selected frame into a rounded layer behind the portrait, so inventory and lobby use the same geometry. Verification after Godot reimport: `COSMETIC_PRESENTATION PASS visible=22 compatible_total=22`; `ROOM_SLOT_LAYER_RESULT: pass`; `CHARACTER_PRESENTATION_RESULT: 20 passed | 0 failed`; `PlayableSmoke` passed. RoomSlotVisualCapture intentionally skips framebuffer readback under Godot's headless/dummy renderer; use the existing GPU-backed capture for visual review.

The local `rembg_matting.py --preview` helper also now keeps the sampled matte color in single-image mode, removing the old `NameError` after successful output generation.

## Current balloon/stat checkpoint — 2026-08-26

The runtime registry currently exposes `skin_066`–`skin_101` (36 active skins). Ten new skins `skin_092`–`skin_101` are true-alpha packages from the accepted RGBA bundle, with 64×64 icons and four 128×128 idle frames; they pass `TransparentBalloonSkinsSmoke` 10/10 and contain no opaque magenta matte. Character balance smoke passes all 11 definitions with 2 starting balloons and shared caps 6 balloons / 6 power / 240 speed. The older 16-skin notes below are historical and superseded by this checkpoint.

## Resolved issue 1 — balloon economy authority (2026-08-27)

`GameSession.buy_balloon_skin()` no longer mutates an online client balance before unlock. The server-side `AccountDatabase._purchase_balloon_skin_for_user()` reads the catalog price, checks ownership and funds, then atomically updates `users` and `user_balloon_skins`. The authoritative balance/ownership snapshot is returned to the requester. `AccountDatabaseSmoke` covers success, persistence and exact deduction.

## Water-balloon runtime cleanup — 2026-08-25

The runtime registry is no longer allowed to fall back to `skin_001`/`skin_039`. It uses `skin_066` and exposes only catalog IDs `skin_066`–`skin_081`. The old folders remain recoverable on disk but are not shown or selected. All 16 active skins have transparent RGBA icons/idle frames; the low-alpha matte cleanup and alpha validation are recorded in `tests/artifacts/water_balloon_alpha_validation.json`.

The remaining visible magenta cast inside translucent blue balloons was corrected
without destructive background removal. `tools/DespillWaterBalloonMatte.py` applies
a narrow hue-only correction to the smooth upper glass of `skin_078`–`skin_081`,
leaving alpha, bounds and interior motifs unchanged. Evidence and per-file counts
are in `tests/artifacts/water_balloon_despill_report.json` and the 16-skin board
`tests/artifacts/water_balloon_alpha_qa.png`.
The before/after comparison is `tests/artifacts/water_balloon_despill_before_after.png`.

Stop rule: do not patch only the client. Fix is complete only when a hostile client cannot unlock/equip/place an unowned skin and network tests prove rejection.

## Resolved issue 2 — default skin identity

The runtime and new-account seed now use `skin_066` (`Aqua Classic Reforge`).
Profiles that still contain legacy IDs are normalized against the active
catalog (`skin_066`–`skin_081`) and always retain an owned valid selection after
reconnect. The old folders remain rollback-only and are not exposed by the
registry/shop.

## Known non-blocking issue — stale legacy TestRunner

`tests/TestRunner.gd` reports 22 failures against removed architecture (8 maps, 40 px tiles, old paths/API). Modern focused smokes pass. The old runner also does not reliably fail the process from its assertion count.

The old runner is retained only for historical comparison. It is not the release gate; the current 19 dedicated smoke scenes are the authoritative gate and all pass. Never treat the stale runner's exit code as current QA evidence.

## Fixed in checkpoint

Headless UI tests previously entered dedicated-server mode and could seize port 7777. `LoginScreen` now starts the server only with explicit `--server`.

Dedicated-server authentication previously had a disconnect race: `AccountDatabase.request_authenticate()` could call `rpc_id()` after ENet had removed the peer, producing `Attempt to call RPC with unknown peer ID`. `NetworkManager.start_host()` is now idempotent for the live same-port host, and AccountDatabase gates all server response RPCs through a live-peer check. The reachable localhost server passed `LocalAuthNetworkSmoke` after the patch was parsed and loaded.

Character runtime previously mixed a 14-action V12 resource contract with a 15-action staging contract. All nine CharacterDefinitions now load V13 resources with the same 15 actions/84 frames; `CharacterAnimationSmoke` and `CharacterV13ResourceConsistencySmoke` enforce this and the Godot importer reports no duplicate UID.

## Character V14 checkpoint

- Fixed/verified: Shadow Ninja and Aqua Pacifier now have their own processed 112×112 source sheets and runtime resources. They are no longer cut from a shared atlas at runtime, which prevents missing feet or side pixels in room cards and gameplay.
- Fixed/verified: `ActiveCharacterRoster` and `MatchManager` resolve the two new IDs; `AccountDatabase` accepts them during character normalization. Legacy character IDs still normalize to Boom Mascot.
- Fixed/verified: `CharacterPresentationContainmentSmoke` now checks every active character (4/4), including complete frame regions and room-card containment. `CharacterAnimationSmoke` is green at 26/26 after the active-roster gate was separated from rollback-only sheets.
- Intentional deferral: no new dedicated bubble/water-hit/death/win/lose art was commissioned in this pass. Those named clips use safe character-local idle frames, while `PlayerVisual`/`BubbleVisual` continues to supply the gameplay bubble shell/pop VFX. This avoids another crop regression until a dedicated status-art pass is approved.
- If a future status-sheet pass is started, preserve the same per-character source-sheet workflow, 112×112 cell, feet anchor and strict-QC thresholds; do not reuse a multi-character atlas.
- Proof-video note: Godot Movie Maker crashed in the headless dummy renderer while attempting a V14 showcase capture (`texture_2d_get` null). This is an engine/capture-path limitation; the normal headless scene tests and editor import remain green. Retry the video on a GPU-backed editor session rather than changing the character resources.

## Display-size normalization checkpoint — 2026-08-26

- Fixed the white bunny's smaller room/lobby appearance without touching source art: `CharacterPresentation` applies an x-only 1.18 correction to the shared 112×112 canvas. The vertical scale and feet baseline remain identical to Gấu Nâu, Shadow Ninja and Aqua Pacifier.
- Fixed the QA balloon preview path: changing skin/animation now reapplies the same alpha-footprint runtime normalization used by gameplay, lobby, shop and inventory.
- Applied the same contract to `PlayerVisual`, `PlayerCardPreview`, `BoomRoomSlot`, `BoomSlot`, `BootManager` room/character cards and `MatchHUD` sidebar avatars.
- Balloon skins use alpha-footprint normalization through `WaterBalloonSkinRegistry` for both gameplay (`get_runtime_scale`) and shop/inventory/gallery icons (`get_icon_scale`); this corrects inconsistent source margins without recropping or removing interior detail.
- Verification: `CHARACTER_PRESENTATION_RESULT: 20 passed | 0 failed`; `WATER_BALLOON_SCALE_RESULT: 54 passed | 0 failed`; Godot editor import exit 0.
