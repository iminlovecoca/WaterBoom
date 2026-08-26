# Build and Validation

Open `project.godot` with Godot 4.7.x stable and press F5. Windows 10/11 is the current target.

Headless validation used by this project:

```powershell
Godot_v4.7.1-stable_win64_console.exe --headless --path . --editor --quit
Godot_v4.7.1-stable_win64_console.exe --headless --path . --scene res://tests/TestScene.tscn --quit-after 10
Godot_v4.7.1-stable_win64_console.exe --headless --path . --scene res://tests/PlayableSmoke.tscn
```

The first scene verifies deterministic systems; the second runs a real Solo match through countdown, bot movement/placement, Water Balloon POP, bubble timeout, winner, and Result UI.
