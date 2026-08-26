# Build Godot game from a description

- Keep durable project status in `README.md`: what is built, what is left, and an asset table.
- Generate visual assets with `$asset-gen`. Confirm the spend with the user before the first paid generation.
- Read `godot.md` for engine guidance: stack, project layout, how to run, and how to capture.

## Delivery

Judge progress from the running game, never from a clean build: verify the structural things yourself (it loads, no errors, assets present) and let what you see drive the next iteration.

Decide from how the task is framed how to work. A task that invites collaboration — open-ended, exploratory, phrased as a direction rather than a spec — gets the live game early: checkpoint at decisions of taste, scope, or cost, and build freely in between. A task handed over as a finished brief to execute gets reasonable calls and steady progress, no blocking. Either way the result is proven, not claimed — if the user hasn't seen it running, finish with a 15–20s video of the game in action, and watch it back before you call the work done.

## Local supervisor / worker automation

- A project rule in `.cursor/rules/boom-auto-antigravity.mdc` makes this routing automatic for implementation requests made in Codex chat; the user should not need to run PowerShell manually.
- Codex is the supervisor: audit scope, protect gameplay/network/save contracts, define machine-checkable acceptance criteria, run QA, and make the final PASS/FAIL decision.
- Delegate routine, bounded implementation work to Antigravity through `tools/agent_orchestrator.py`. Codex must still review the changed-file boundary, validator evidence, screenshots, and unresolved issues.
- Do not delegate product decisions, destructive cleanup, publishing, commits/pushes, secrets, paid generation, save migrations, economy authority, or network architecture changes without explicit user approval.
- Every delegated task must use a JSON task under `.agents/tasks/`, declare narrow `scope`, `protected_paths`, `acceptance_criteria`, and `max_iterations` (hard limit: 5), and follow `QA_GATE.md`.
- Stop on PASS, fatal worker/validator error, two consecutive identical QA failure signatures, or the iteration limit. Never create an infinite retry loop.
- The worker must not commit, push, delete outside scope, or edit protected paths. If it does, the supervisor stops and reports the safety violation.
- This project currently has no Git metadata. The orchestrator therefore records a SHA-256 manifest and copies scoped/protected files into the run checkpoint. If Git is added later, it also records status and diff evidence automatically; it never initializes Git itself.
