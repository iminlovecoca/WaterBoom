# Agent automation report: balance_character_stats

- Status: **FAIL**
- Stop reason: fatal validator or safety error
- Iterations: 1
- Run ID: `20260826T050120Z_balance_character_stats`
- Git checkpoint: Git metadata captured

## Files changed

- `addons/godot-sqlite/bin/~libgdsqlite.windows.template_debug.x86_64.dll`
- `addons/godot-sqlite/bin/~libgdsqlite.windows.template_debug.x86_64.dll~RFa260e8.TMP`

## Unresolved issues / root cause

- character_stats_smoke: exit 1
Godot Engine v4.7.1.stable.official.a13da4feb - https://godotengine.org


ERROR: Cannot open file 'res://tests/CharacterStatsBalanceSmoke.tscn'.
   at: load (scene/resources/resource_format_text.cpp:1442)
ERROR: Failed loading resource: res://tests/CharacterStatsBalanceSmoke.tscn.
   at: _load (core/io/resource_loader.cpp:317)
ERROR: Failed loading scene: res://tests/CharacterStatsBalanceSmoke.tscn.
   at: start (main/main.cpp:4763)
- safety: files outside scope changed: addons/godot-sqlite/bin/~libgdsqlite.windows.template_debug.x86_64.dll, addons/godot-sqlite/bin/~libgdsqlite.windows.template_debug.x86_64.dll~RFa260e8.TMP

## Screenshot evidence

- None collected

## Iteration evidence

- iteration 1: FAIL — `.agents/runs/20260826T050120Z_balance_character_stats/iteration_01/qa_result.json`
