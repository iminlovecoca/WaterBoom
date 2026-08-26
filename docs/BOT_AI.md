# Bot AI

`BotController` feeds movement intentions into the same `PlayerController.apply_movement_intent()` used by local input. It never teleports or bypasses placement validation.

## Difficulty System

Four difficulty levels (`GameConstants.BotDifficulty`): EASY, NORMAL, HARD, EXTREME.

Each level tunes a profile of parameters that scale bot intelligence across multiple dimensions:

| Parameter | EASY | NORMAL | HARD | EXTREME |
|---|---|---|---|---|
| Decision interval | 0.14s | 0.08s | 0.04s | 0.022s |
| Danger horizon | 2.0 | 3.5 | 5.0 | 6.5 |
| Escape BFS depth | 4 | 7 | 10 | 14 |
| Item safety margin | 4.0 | 3.0 | 2.0 | 1.5 |
| Attack range² | 9 (3 tiles) | 16 (4 tiles) | 25 (5 tiles) | 36 (6 tiles) |
| Chase range² | 16 (4 tiles) | 25 (5 tiles) | 49 (7 tiles) | 64 (8 tiles) |
| Strategic range² | 16 (4 tiles) | 36 (6 tiles) | 49 (7 tiles) | 64 (8 tiles) |
| Wander safety | 2.0 | 3.0 | 4.0 | 5.5 |
| Block search walkable | 2.0 | 2.5 | 2.5 | 3.0 |
| Prefers items first | yes | yes | no | no |
| Predict steps | 0 | 1 | 2 | 3 |
| Chain danger awareness | no | no | yes | yes |
| Enemy escape threshold | 3 | 2 | 2 | 1 |
| Pin reaction delay | 0.30s | 0.15s | 0.08s | 0.03s |

## Map → Difficulty Mapping

`MapCatalog.suggested_bot_difficulty()` maps map difficulty text to bot difficulty:
- "Dễ" → EASY
- "Trung bình" → NORMAL
- "Khó" → HARD

## Decision Chain (priority order)

1. **ESCAPE_DANGER** — flee if current cell is within danger horizon
2. **POP_TRAPPED_ENEMY** — rush to bubbled enemy to pop and kill
3. **SEEK_ITEM** (EASY/NORMAL priority) — collect nearby items
4. **ATTACK** — place balloon if adjacent to soft block or enemy nearby, AND safe escape exists
5. **STRATEGIC** — place balloon to trap enemies with limited escape routes
6. **SEEK_BLOCK** — path toward destructible blocks
7. **SEEK_ITEM** (HARD/EXTREME fallback) — collect items after combat priorities
8. **CHASE_ENEMY** — move toward nearest enemy
9. **WANDER** — random safe neighbor as fallback

## Escape-after-placement

`_find_escape_after_place()` performs a BFS from the bomb cell through the union of the simulated bomb's affected cells and existing danger map cells. The BFS depth scales with difficulty (4–14 tiles). If no safe cell is found, the bot does NOT place the bomb — preventing the classic "walk into own bomb" death.

## DangerMap

`DangerMap` projects every active water balloon through `WaterGridPropagation.calculate_water_burst()` and includes already-active water cells. `is_dangerous(cell, horizon)` returns true only if the cell's earliest detonation time is within the horizon.
