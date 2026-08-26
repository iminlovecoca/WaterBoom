# Boom Water Arcade — Architecture

Godot 4.7, typed GDScript, 60 FPS target, 960×720 4:3 baseline. Gameplay is an authoritative `Vector2i` grid while players move continuously in world space.

## Runtime composition

```text
BootManager → GameSession → MatchManager
                           ├─ GridManager → ArenaMap
                           ├─ PlayerController → PlayerVisual → DevelopmentCharacter
                           ├─ BotController → BotBrain → DangerMap
                           ├─ WaterBalloonManager → WaterBalloon
                           │                       └─ WaterGridPropagation
                           │                          ├─ WaterStreamRenderer
                           │                          ├─ ArenaMap / ItemManager
                           │                          └─ WaterTrapSystem
                           ├─ MatchRules / RescueSystem
                           └─ MatchHUD / DebugOverlay / GridDebugRenderer
```

`GameSession` stores the selected play mode, map, bot count, and difficulty between scenes. `SettingsStore` persists non-secret display/audio preferences to `user://settings.cfg`.

Subsystems are composed rather than inherited. Gameplay does not depend on final character art or UI scenes. Optional audio is event-driven and missing clips do not stop simulation.

Online transport exists as an ENet foundation only; the menu labels Online as unavailable. Offline Solo and Local are the supported playable paths in this delivery.
