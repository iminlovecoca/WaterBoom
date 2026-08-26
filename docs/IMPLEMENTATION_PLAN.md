# First Playable Delivery — Implementation Plan

## Audited baseline

- Godot 4.7 project, 1280×720, GDScript, Nearest texture filtering.
- Working grid conversion, realtime movement/corner assist, Water Balloon placement, four-direction water propagation, soft-block destruction, item upgrades, bubble timeout/rescue, HUD, ENet host/client foundation, and 41 deterministic tests.
- Integrated Water Balloon frames: `assets/water_balloon/water_balloon_0..3.png` (40×40).
- Integrated water segments: center, horizontal, vertical, four ends, and cross in `assets/water_stream/` (40×40).
- Missing from the playable definition: development-character fallback, solo bot/danger prediction, reliable winner path against a bot, complete menu/pause/settings flow, map catalog/validation, persistent active-water collision, and full documentation.

## Execution order

1. Preserve and extend the passing grid/Water Balloon systems; centralize balance in `MatchConfig`.
2. Add an original procedural `DevelopmentCharacter` behind `PlayerVisual` so gameplay does not depend on final character art.
3. Add `DangerMap`, `BotBrain`, and `BotController`; Solo spawns one player plus configurable bots using normal movement and placement APIs.
4. Add `GameSession`, map catalog/validator, Training Plaza plus four generated themes, and centered world coordinates.
5. Complete menu, settings persistence, pause, result, play-again, and main-menu transitions.
6. Keep water cells active for the configured visual lifetime and apply trapping throughout that interval.
7. Expand deterministic tests, run Godot editor validation, test scene, MatchArena smoke test, and scripted solo simulation.

## First-delivery exit criteria

F5 opens the menu; Solo starts a centered match with at least one bot; player and bot move/place/escape; Water Balloons pop into cell segments; blocks/items/upgrades/bubbles/death work; winner transitions to Result; Play Again and Main Menu work; no parse/resource/runtime error remains.
