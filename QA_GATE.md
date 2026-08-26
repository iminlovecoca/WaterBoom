# Boom local automation QA gate

Codex owns the final PASS/FAIL decision. Antigravity may implement changes, but its own success message is never acceptance evidence.

## Global safety gate

- The task JSON is valid, `scope` is narrow, `protected_paths` is explicit, and `max_iterations` is between 1 and 5.
- A pre-run checkpoint exists. In a Git checkout this includes status/diff metadata; without Git it includes a SHA-256 tree manifest and recoverable copies of scoped/protected files.
- No protected path changes. No file outside `scope` changes except declared `allowed_output_paths` used only for test artifacts.
- No commit, push, publishing, paid API/asset generation, secret creation, file deletion outside scope, or database/save migration.
- Gameplay, networking, account/save, economy and database paths are protected unless the task explicitly owns one of those contracts and the user approved it.

## Map gate (machine-checkable)

A map task must run `map_contract` plus the existing Godot regression scenes relevant to its claim.

- Dimensions and authored `tile_size` equal the task values.
- Breakable count equals the task value; hard/floor totals are internally consistent.
- Required center footprint has the requested size and allowed tile types.
- Every declared spawn is in bounds, walkable and has the requested connected escape-cell count.
- Border contract and four-way symmetry pass when requested.
- `MapLayoutSmoke.tscn` passes for construction/navigation/density contracts.
- `MapGameplayRegressionSmoke.tscn` passes for burst propagation, breakable collision and item-drop behavior.
- `BalloonExitAndCollisionSmoke.tscn` passes when bomb/water-balloon collision is in scope.
- Seam claims require `tools/agent_qa/validate_map_seams.py` plus a fresh runtime screenshot artifact. Screenshot existence alone is not proof of a seam-free asset.

## UI gate (machine-checkable)

A UI task must run `ui_layout_contract` or an owning project smoke scene at every declared viewport.

- Every required node and asset exists.
- Target bounds fall inside their declared min/max ranges.
- Controls remain within the viewport/safe area; no declared pair overlaps.
- Spacing/gaps are within the task range.
- Interactive targets meet the declared minimum size.
- Missing resource, parser error, layout overflow, focus-path failure or non-zero Godot exit is FAIL.
- A fresh GPU screenshot is required for reference-matching tasks. Pixel-perfect/aesthetic approval remains a supervisor visual review unless the task supplies a numeric image-comparison hook and threshold.

## Gameplay / networking / save gate

- Run the smallest owning smoke test plus the highest-risk adjacent contract.
- Any parser error, invalid resource, crash, timeout or non-zero exit is FAIL.
- Gameplay claims require a scene/runtime smoke, not only import success.
- Networking claims require a dedicated server/client test and rejection-path evidence; client-only success is insufficient.
- Save/account/database changes require explicit approval, a copy of the data, version/migration evidence and corrupt/missing-field tests. These paths are protected by default.

## Stop conditions

The orchestrator stops on the first applicable condition:

1. all required gates PASS;
2. fatal configuration, worker, safety or validator error;
3. the same normalized failure signature appears in two consecutive iterations;
4. `max_iterations` is reached (never more than 5).

The final report must contain status, stop reason, iterations, files changed, validator evidence, screenshots and unresolved issues/root cause.
