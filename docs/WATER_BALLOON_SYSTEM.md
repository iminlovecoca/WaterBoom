# Water Balloon System

`PlayerController.place_water_balloon_request()` forwards the player's current cell and power. `WaterBalloonManager` validates `PLAYING`, alive/not bubbled, capacity, position ownership, floor validity, and cell occupancy before spawning at `GridManager.cell_to_world()`.

`WaterBalloon` advances four cyan frames and increases rotation/squash frequency until `pop()`. The manager removes occupancy and refunds capacity exactly once before propagating. Chain Water Burst uses a queue plus processed-ID set, preventing recursion and duplicate refunds.

Balance values live in `MatchConfig`: `water_balloon_duration`, base/max capacity, and water power.
