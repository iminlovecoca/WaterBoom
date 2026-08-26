# Local Codex supervisor + Antigravity worker

`tools/agent_orchestrator.py` is a bounded, local implementation/QA loop. Codex supplies or reviews a JSON task, the adapter calls Antigravity, validators decide PASS/FAIL, and a correction prompt is generated for the next attempt. The hard cap is five attempts; two identical consecutive failure signatures stop early.

## Quick start (Windows)

After `.cursor/rules/boom-auto-antigravity.mdc` is loaded by Codex, ordinary implementation requests in this project are routed automatically: Codex creates a task JSON, invokes the supervisor, and reports the final QA result. The commands below remain useful for a first setup check, an explicit read-only run, or debugging the local environment.

```powershell
# Configuration/evidence test only; no worker and no validators
./agent-run.ps1 -Task .agents/tasks/fix_snow_village.json -DryRun

# Real read-only Godot audit; Antigravity is not called
./agent-run.ps1 -Task .agents/tasks/audit_current_maps_readonly.json

# Real implementation loop
./agent-run.ps1 -Task .agents/tasks/fix_snow_village.json
```

Direct Python works in PowerShell or Git Bash:

```bash
python tools/agent_orchestrator.py --task .agents/tasks/match_login_reference.json
```

Every run writes prompts, worker stdout/stderr, validator logs, cumulative/iteration file diffs, QA JSON, screenshots and the final report under `.agents/runs/<run-id>/`. A copy of the final report is placed in `.agents/reports/`.

## Antigravity configuration

The default adapter looks for `agy` and invokes `agy -p <prompt>`. If the executable is elsewhere:

```powershell
$env:ANTIGRAVITY_CMD = 'C:\path\to\agy.exe'
```

For a different CLI argument shape, supply a JSON string array. Supported placeholders are `{prompt}`, `{prompt_file}`, `{project}` and `{run_dir}`.

```powershell
$env:ANTIGRAVITY_ARGS_JSON = '["run","--prompt-file","{prompt_file}","--project","{project}"]'
```

If `agy -p` reports that it needs a TTY, `auto` mode tries `winpty` on Windows or `script` on POSIX. Native Windows Python does not ship a ConPTY API, so PTY fallback requires `winpty` on PATH. If the CLI still cannot run non-interactively, set the task worker mode to `shared_file`: requests appear in `.agents/inbox/<run-id>/iteration_NN.request.json`; an external Antigravity watcher/operator must apply the prompt and write the named response JSON. Shared-file mode is bounded by `shared_file_timeout_seconds` and never waits forever.

When neither `agy` nor `ANTIGRAVITY_CMD` resolves, the run stops as a fatal configuration error and writes an inbox request explaining the missing executable. The framework also checks the standard Windows install location `%LOCALAPPDATA%\agy\bin\agy.exe`, so a restarted Codex session normally needs no manual environment variable.

For Godot discovery, the adapter checks `GODOT_CMD`, PATH, this project's known Godot 4.7.1 Downloads location, and common executable names:

```powershell
$env:GODOT_CMD = 'C:\path\to\Godot_v4.7.1-stable_win64_console.exe'
```

## Task contract

Create a JSON file using `.agents/tasks/task.schema.json`. The mandatory fields are `task`, `scope`, `protected_paths`, `acceptance_criteria`, `validators`, and `max_iterations`. Keep scope narrow. `allowed_output_paths` is only for validator artifacts such as `tests/artifacts/**`.

Built-in validators:

- `godot_import`: headless editor/import/parser check;
- `godot_scene`: run an existing smoke/capture scene and parse exit/log/regex;
- `map_contract`: inspect a `MapCatalog` map using task values;
- `ui_layout_contract`: load a scene at declared viewports and check assets, bounds, minimum sizes, overflow and spacing/overlap relations;
- `command`: run an argument array without a shell;
- `file_exists`: require exact project files.

The Snow Village sample intentionally contains the requested future value of 104 breakables. Current production code and `MapLayoutSmoke` use 128. Do not run that implementation task until 104 is confirmed as a product-direction change; the read-only sample captures today's 128-block baseline.

## Safety and rollback

Before any worker call, the orchestrator records Git status/diff metadata when the project is a Git worktree. This project currently is not one, so it records a SHA-256 manifest and copies all existing files covered by task scope/protected patterns into the run checkpoint. It never initializes Git, commits or pushes.

The supervisor stops if a protected or outside-scope file changes. Explicit rollback restores only paths covered by that checkpoint and removes newly created files in that same boundary:

```powershell
python tools/agent_orchestrator.py --rollback <run-id>
```

Rollback intentionally leaves unrelated/outside-checkpoint changes untouched. Review `rollback_result.json` afterward.
