#!/usr/bin/env python3
"""Bounded local Codex-supervisor / Antigravity-worker loop for Boom.

The script intentionally uses only the Python standard library. Antigravity is
an optional external executable; Godot and validators are discovered at runtime.
Every run is evidence-first and capped at five implementation attempts.
"""

from __future__ import annotations

import argparse
import datetime as dt
import fnmatch
import hashlib
import json
import os
import re
import shlex
import shutil
import subprocess
import sys
import time
from dataclasses import dataclass
from pathlib import Path, PurePosixPath
from typing import Any, Iterable


HARD_MAX_ITERATIONS = 5
VOLATILE_PREFIXES = (
    ".git/",
    ".godot/",
    ".agents/inbox/",
    ".agents/reports/",
    ".agents/screenshots/",
    ".agents/runs/",
)
DEFAULT_PROTECTED = (
    "scripts/network/**",
    "scripts/data/**",
    "data/database/**",
    "scripts/core/GameSession.gd",
    "server_config.json",
    "export_presets.cfg",
)


class OrchestratorError(RuntimeError):
    """Fatal configuration or execution error."""


@dataclass
class CommandResult:
    argv: list[str]
    exit_code: int | None
    stdout: str
    stderr: str
    duration_seconds: float
    timed_out: bool = False
    launch_error: str = ""

    @property
    def ok(self) -> bool:
        return self.exit_code == 0 and not self.timed_out and not self.launch_error

    def as_dict(self) -> dict[str, Any]:
        return {
            "argv": self.argv,
            "exit_code": self.exit_code,
            "stdout": self.stdout,
            "stderr": self.stderr,
            "duration_seconds": round(self.duration_seconds, 3),
            "timed_out": self.timed_out,
            "launch_error": self.launch_error,
            "ok": self.ok,
        }


def utc_stamp() -> str:
    return dt.datetime.now(dt.timezone.utc).strftime("%Y%m%dT%H%M%SZ")


def write_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def write_text(path: Path, value: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(value, encoding="utf-8")


def normalize_rel(path: str | Path) -> str:
    value = str(path).replace("\\", "/")
    while value.startswith("./"):
        value = value[2:]
    return value.strip("/")


def normalize_pattern(pattern: str) -> str:
    value = normalize_rel(pattern)
    if value in {"", ".", "**", "**/*"}:
        raise OrchestratorError("Broad project-root scope is not allowed; declare narrow paths.")
    if value.startswith("../") or "/../" in value or Path(value).is_absolute():
        raise OrchestratorError(f"Path pattern escapes the project: {pattern}")
    return value


def path_matches(relative: str, patterns: Iterable[str]) -> bool:
    rel = normalize_rel(relative)
    for original in patterns:
        pattern = normalize_rel(original)
        prefix = pattern.rstrip("/*")
        if rel == pattern or (prefix and rel.startswith(prefix + "/")):
            return True
        if fnmatch.fnmatchcase(rel, pattern) or PurePosixPath(rel).match(pattern):
            return True
    return False


def is_volatile(relative: str) -> bool:
    rel = normalize_rel(relative) + ("/" if not relative.endswith("/") else "")
    return any(rel.startswith(prefix) for prefix in VOLATILE_PREFIXES)


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def build_manifest(project_root: Path, previous: dict[str, dict[str, Any]] | None = None) -> dict[str, dict[str, Any]]:
    manifest: dict[str, dict[str, Any]] = {}
    for path in project_root.rglob("*"):
        if not path.is_file() or path.is_symlink():
            continue
        relative = normalize_rel(path.relative_to(project_root))
        if is_volatile(relative):
            continue
        try:
            stat = path.stat()
            prior = previous.get(relative) if previous else None
            digest = (
                prior.get("sha256")
                if prior
                and prior.get("size") == stat.st_size
                and prior.get("mtime_ns") == stat.st_mtime_ns
                and prior.get("sha256")
                else sha256_file(path)
            )
            manifest[relative] = {
                "size": stat.st_size,
                "mtime_ns": stat.st_mtime_ns,
                "sha256": digest,
            }
        except (OSError, PermissionError) as exc:
            manifest[relative] = {"error": str(exc)}
    return manifest


def diff_manifests(before: dict[str, Any], after: dict[str, Any]) -> dict[str, list[str]]:
    before_keys = set(before)
    after_keys = set(after)
    return {
        "added": sorted(after_keys - before_keys),
        "deleted": sorted(before_keys - after_keys),
        "modified": sorted(key for key in before_keys & after_keys if before[key] != after[key]),
    }


def flattened_changes(diff: dict[str, list[str]]) -> list[str]:
    return sorted(set(diff["added"] + diff["deleted"] + diff["modified"]))


def run_command(argv: list[str], cwd: Path, timeout_seconds: int, env: dict[str, str] | None = None) -> CommandResult:
    started = time.monotonic()
    try:
        completed = subprocess.run(
            argv,
            cwd=str(cwd),
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=timeout_seconds,
            env=env,
            shell=False,
        )
        return CommandResult(argv, completed.returncode, completed.stdout, completed.stderr, time.monotonic() - started)
    except subprocess.TimeoutExpired as exc:
        stdout = exc.stdout.decode("utf-8", "replace") if isinstance(exc.stdout, bytes) else (exc.stdout or "")
        stderr = exc.stderr.decode("utf-8", "replace") if isinstance(exc.stderr, bytes) else (exc.stderr or "")
        return CommandResult(argv, None, stdout, stderr, time.monotonic() - started, timed_out=True)
    except OSError as exc:
        return CommandResult(argv, None, "", "", time.monotonic() - started, launch_error=str(exc))


def parse_command(value: str) -> list[str]:
    parts = shlex.split(value, posix=os.name != "nt")
    return [part[1:-1] if len(part) >= 2 and part[0] == part[-1] == '"' else part for part in parts]


def resolve_executable(candidate: str) -> str | None:
    expanded = os.path.expandvars(os.path.expanduser(candidate))
    path = Path(expanded)
    if path.is_file():
        return str(path.resolve())
    return shutil.which(expanded)


def discover_godot() -> list[str] | None:
    configured = os.environ.get("GODOT_CMD", "").strip()
    if configured:
        argv = parse_command(configured)
        if argv and resolve_executable(argv[0]):
            argv[0] = resolve_executable(argv[0]) or argv[0]
            return argv
        return None
    names = ("godot", "godot4", "Godot_v4.7.1-stable_win64_console.exe", "Godot_v4.7.1-stable_win64.exe")
    for name in names:
        found = shutil.which(name)
        if found:
            return [found]
    home = Path.home()
    candidates = (
        home / "Downloads" / "Godot_v4.7.1-stable_win64.exe" / "Godot_v4.7.1-stable_win64_console.exe",
        home / "Downloads" / "Godot_v4.7.1-stable_win64.exe",
        Path("C:/Godot/Godot_v4.7.1-stable_win64.exe"),
    )
    for path in candidates:
        if path.is_file():
            return [str(path.resolve())]
    for path in (home / "Downloads").glob("Godot*_console.exe"):
        return [str(path.resolve())]
    for path in (home / "Downloads").glob("Godot*.exe"):
        return [str(path.resolve())]
    return None


def discover_antigravity() -> list[str] | None:
    configured = os.environ.get("ANTIGRAVITY_CMD", "").strip()
    argv = parse_command(configured) if configured else ["agy"]
    if not argv:
        return None
    executable = resolve_executable(argv[0])
    if not executable and not configured:
        known_paths = (
            Path(os.environ.get("LOCALAPPDATA", "")) / "agy" / "bin" / "agy.exe",
            Path("C:/Program Files/Google/antigravity-cli/agy.exe"),
        )
        for known_path in known_paths:
            if known_path.is_file():
                executable = str(known_path.resolve())
                break
    if not executable:
        return None
    argv[0] = executable
    return argv


def load_task(task_path: Path) -> dict[str, Any]:
    try:
        task = json.loads(task_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise OrchestratorError(f"Cannot read task JSON: {exc}") from exc
    required = ("version", "id", "task", "scope", "protected_paths", "acceptance_criteria", "validators", "max_iterations")
    missing = [key for key in required if key not in task]
    if missing:
        raise OrchestratorError("Task is missing required fields: " + ", ".join(missing))
    if task["version"] != 1:
        raise OrchestratorError("Only task schema version 1 is supported.")
    if not re.fullmatch(r"[a-z0-9][a-z0-9_-]{2,63}", str(task["id"])):
        raise OrchestratorError("Task id must use 3-64 lowercase letters, numbers, '_' or '-'.")
    if task.get("mode", "implementation") not in {"implementation", "read_only"}:
        raise OrchestratorError("mode must be implementation or read_only.")
    if not isinstance(task["scope"], list) or not task["scope"]:
        raise OrchestratorError("scope must contain at least one narrow path.")
    task["scope"] = [normalize_pattern(value) for value in task["scope"]]
    task["protected_paths"] = [normalize_pattern(value) for value in task["protected_paths"]]
    task["allowed_output_paths"] = [normalize_pattern(value) for value in task.get("allowed_output_paths", [])]
    task["max_iterations"] = int(task["max_iterations"])
    if not 1 <= task["max_iterations"] <= HARD_MAX_ITERATIONS:
        raise OrchestratorError("max_iterations must be between 1 and 5.")
    if not task["acceptance_criteria"] or not task["validators"]:
        raise OrchestratorError("At least one acceptance criterion and validator are required.")
    validator_ids = [str(item.get("id", "")) for item in task["validators"]]
    if len(validator_ids) != len(set(validator_ids)) or any(not item for item in validator_ids):
        raise OrchestratorError("Validator ids must be non-empty and unique.")
    return task


def git_metadata(project_root: Path) -> dict[str, Any]:
    probe = run_command(["git", "rev-parse", "--show-toplevel"], project_root, 10)
    if not probe.ok:
        return {"available": False, "reason": "not a Git worktree; manifest checkpoint is active"}
    status = run_command(["git", "status", "--short", "--branch"], project_root, 20)
    diff = run_command(["git", "diff", "--stat"], project_root, 30)
    staged = run_command(["git", "diff", "--cached", "--stat"], project_root, 30)
    return {
        "available": True,
        "root": probe.stdout.strip(),
        "status": status.stdout,
        "diff_stat": diff.stdout,
        "staged_diff_stat": staged.stdout,
    }


def copy_checkpoint_files(project_root: Path, manifest: dict[str, Any], patterns: list[str], checkpoint_dir: Path) -> list[str]:
    copied: list[str] = []
    for relative in manifest:
        if not path_matches(relative, patterns):
            continue
        source = project_root / Path(relative)
        target = checkpoint_dir / "files" / Path(relative)
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
        copied.append(relative)
    return copied


def create_checkpoint(project_root: Path, run_dir: Path, task: dict[str, Any], manifest: dict[str, Any]) -> dict[str, Any]:
    patterns = sorted(set(task["scope"] + task["protected_paths"] + list(DEFAULT_PROTECTED)))
    checkpoint_dir = run_dir / "checkpoint"
    copied = copy_checkpoint_files(project_root, manifest, patterns, checkpoint_dir)
    metadata = {
        "created_at": utc_stamp(),
        "project_root": str(project_root),
        "patterns": patterns,
        "copied_files": copied,
        "git": git_metadata(project_root),
        "manifest_file": "manifest.json",
    }
    write_json(checkpoint_dir / "manifest.json", manifest)
    write_json(checkpoint_dir / "metadata.json", metadata)
    return metadata


def restore_checkpoint(project_root: Path, run_dir: Path) -> dict[str, Any]:
    checkpoint_dir = run_dir / "checkpoint"
    metadata_path = checkpoint_dir / "metadata.json"
    manifest_path = checkpoint_dir / "manifest.json"
    if not metadata_path.is_file() or not manifest_path.is_file():
        raise OrchestratorError(f"Run has no usable checkpoint: {run_dir.name}")
    metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
    baseline = json.loads(manifest_path.read_text(encoding="utf-8"))
    patterns = metadata["patterns"]
    current = build_manifest(project_root)
    changed = flattened_changes(diff_manifests(baseline, current))
    targets = [item for item in changed if path_matches(item, patterns)]
    restored: list[str] = []
    removed_new: list[str] = []
    for relative in targets:
        destination = (project_root / relative).resolve()
        if project_root.resolve() not in destination.parents:
            raise OrchestratorError(f"Rollback target escaped project: {relative}")
        backup = checkpoint_dir / "files" / relative
        if backup.is_file():
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(backup, destination)
            restored.append(relative)
        elif relative not in baseline and destination.is_file():
            destination.unlink()
            removed_new.append(relative)
    result = {"run_id": run_dir.name, "restored": restored, "removed_new": removed_new, "untouched_outside_checkpoint": sorted(set(changed) - set(targets))}
    write_json(run_dir / "rollback_result.json", result)
    return result


def render_prompt(task: dict[str, Any], iteration: int, previous_qa: dict[str, Any] | None, project_root: Path) -> str:
    criteria = "\n".join(f"- [{item.get('id')}] {item.get('description')}" for item in task["acceptance_criteria"])
    correction = ""
    if previous_qa:
        issues = previous_qa.get("unresolved_issues", [])
        correction = "\nThis is a correction pass. Fix only these machine-reported failures:\n" + "\n".join(f"- {issue}" for issue in issues)
    return f"""You are Antigravity, the bounded implementation worker for the Boom Godot project.

Iteration: {iteration}/{task['max_iterations']}
Project: {project_root}
Task: {task['task']}

Allowed scope (edit/create only here):
{chr(10).join('- ' + item for item in task['scope'])}

Protected paths (never edit/delete):
{chr(10).join('- ' + item for item in task['protected_paths'] + list(DEFAULT_PROTECTED))}

Acceptance criteria:
{criteria}
{correction}

Rules:
- Audit owning files before editing and preserve existing Godot architecture.
- Do not change gameplay, networking, save/account/database/economy behavior unless explicitly inside task scope.
- Do not delete outside scope. Do not commit, push, publish, install paid services, or create secrets.
- Make the smallest correction that can satisfy the listed gates.
- You may run focused checks, but Codex will independently run every validator and decide PASS/FAIL.
- At completion, summarize files changed and any known limitation. Never claim PASS without evidence.
"""


def worker_argv(prompt: str, prompt_file: Path, project_root: Path, run_dir: Path) -> list[str] | None:
    base = discover_antigravity()
    if base is None:
        return None
    configured_args = os.environ.get("ANTIGRAVITY_ARGS_JSON", "").strip()
    if configured_args:
        try:
            suffix = json.loads(configured_args)
        except json.JSONDecodeError as exc:
            raise OrchestratorError(f"ANTIGRAVITY_ARGS_JSON is invalid JSON: {exc}") from exc
        if not isinstance(suffix, list) or not all(isinstance(item, str) for item in suffix):
            raise OrchestratorError("ANTIGRAVITY_ARGS_JSON must be a JSON array of strings.")
    else:
        suffix = ["-p", "{prompt}"]
    replacements = {
        "{prompt}": prompt,
        "{prompt_file}": str(prompt_file),
        "{project}": str(project_root),
        "{run_dir}": str(run_dir),
    }
    argv = base + suffix
    return [replace_tokens(value, replacements) for value in argv]


def replace_tokens(value: str, replacements: dict[str, str]) -> str:
    result = value
    for key, replacement in replacements.items():
        result = result.replace(key, replacement)
    return result


def tty_failure(result: CommandResult) -> bool:
    combined = (result.stdout + "\n" + result.stderr).lower()
    return any(marker in combined for marker in ("not a tty", "requires a tty", "interactive terminal", "raw mode", "stdin is not a terminal"))


def pty_wrapped(argv: list[str]) -> list[str] | None:
    if os.name == "nt":
        winpty = shutil.which("winpty")
        return [winpty] + argv if winpty else None
    script = shutil.which("script")
    return [script, "-q", "/dev/null", "-c", shlex.join(argv)] if script else None


def shared_file_worker(task: dict[str, Any], prompt: str, run_id: str, iteration: int, project_root: Path) -> dict[str, Any]:
    inbox = project_root / ".agents" / "inbox" / run_id
    request_path = inbox / f"iteration_{iteration:02d}.request.json"
    response_path = inbox / f"iteration_{iteration:02d}.response.json"
    request = {
        "run_id": run_id,
        "iteration": iteration,
        "project_root": str(project_root),
        "prompt": prompt,
        "response_path": str(response_path),
        "instructions": "Run this prompt in Antigravity against project_root, then write response JSON with {ok, summary, files_changed}.",
    }
    write_json(request_path, request)
    timeout = int(task.get("worker", {}).get("shared_file_timeout_seconds", 120))
    started = time.monotonic()
    while time.monotonic() - started < timeout:
        if response_path.is_file():
            try:
                response = json.loads(response_path.read_text(encoding="utf-8"))
            except json.JSONDecodeError as exc:
                return {"ok": False, "mode": "shared_file", "fatal": True, "message": f"Invalid shared-file response: {exc}", "request": str(request_path)}
            return {"ok": bool(response.get("ok", False)), "mode": "shared_file", "fatal": not bool(response.get("ok", False)), "response": response, "request": str(request_path)}
        time.sleep(1.0)
    return {
        "ok": False,
        "mode": "shared_file",
        "fatal": True,
        "message": f"Timed out after {timeout}s waiting for {response_path}. Shared-file mode requires an external Antigravity watcher/operator.",
        "request": str(request_path),
    }


def invoke_worker(task: dict[str, Any], prompt: str, prompt_file: Path, run_dir: Path, iteration: int, project_root: Path) -> dict[str, Any]:
    mode = task.get("worker", {}).get("mode", "auto")
    timeout = int(task.get("worker", {}).get("timeout_seconds", 1800))
    if mode == "shared_file":
        return shared_file_worker(task, prompt, run_dir.name, iteration, project_root)
    argv = worker_argv(prompt, prompt_file, project_root, run_dir)
    if argv is None:
        inbox = project_root / ".agents" / "inbox" / run_dir.name
        write_json(inbox / f"iteration_{iteration:02d}.request.json", {"project_root": str(project_root), "prompt": prompt, "reason": "Antigravity executable not found"})
        return {
            "ok": False,
            "fatal": True,
            "mode": mode,
            "message": "Antigravity executable not found. Install `agy` or set ANTIGRAVITY_CMD to its executable/command. Optional argument template: ANTIGRAVITY_ARGS_JSON='[\"-p\",\"{prompt}\"]'.",
        }
    selected = argv
    if mode == "pty":
        wrapped = pty_wrapped(argv)
        if wrapped is None:
            return {"ok": False, "fatal": True, "mode": "pty", "message": "PTY mode requested but neither winpty (Windows) nor script (POSIX) is available."}
        selected = wrapped
    result = run_command(selected, project_root, timeout)
    attempts = [{"mode": "pty" if mode == "pty" else "subprocess", **result.as_dict()}]
    if mode == "auto" and not result.ok and tty_failure(result):
        wrapped = pty_wrapped(argv)
        if wrapped is not None:
            pty_result = run_command(wrapped, project_root, timeout)
            attempts.append({"mode": "pty", **pty_result.as_dict()})
            result = pty_result
    if result.ok:
        return {"ok": True, "fatal": False, "mode": attempts[-1]["mode"], "attempts": attempts}
    if mode == "auto" and tty_failure(result):
        shared = shared_file_worker(task, prompt, run_dir.name, iteration, project_root)
        shared["attempts"] = attempts
        return shared
    return {"ok": False, "fatal": True, "mode": attempts[-1]["mode"], "attempts": attempts, "message": "Antigravity command failed or timed out."}


def resolve_validator_command(command: list[str], project_root: Path, task_path: Path, run_dir: Path) -> list[str]:
    replacements = {
        "{python}": sys.executable,
        "{project}": str(project_root),
        "{task_file}": str(task_path),
        "{run_dir}": str(run_dir),
    }
    return [replace_tokens(str(value), replacements) for value in command]


def validator_message(result: CommandResult, validator_id: str) -> str:
    if result.timed_out:
        return f"{validator_id}: timed out"
    if result.launch_error:
        return f"{validator_id}: launch error: {result.launch_error}"
    combined = (result.stdout + "\n" + result.stderr).strip()
    tail = "\n".join(combined.splitlines()[-12:])
    return f"{validator_id}: exit {result.exit_code}" + (f"\n{tail}" if tail else "")


def run_validator(validator: dict[str, Any], project_root: Path, task_path: Path, run_dir: Path, godot: list[str] | None) -> dict[str, Any]:
    validator_id = str(validator["id"])
    validator_type = str(validator["type"])
    required = bool(validator.get("required", True))
    timeout = int(validator.get("timeout_seconds", 300))
    if validator_type == "file_exists":
        paths = [normalize_rel(item) for item in validator.get("paths", [])]
        missing = [item for item in paths if not (project_root / item).is_file()]
        return {"id": validator_id, "type": validator_type, "required": required, "ok": not missing, "missing": missing, "message": "all files exist" if not missing else "missing: " + ", ".join(missing)}
    if validator_type == "command":
        command = validator.get("command")
        if not isinstance(command, list) or not command:
            return {"id": validator_id, "type": validator_type, "required": required, "ok": False, "fatal": True, "message": "command validator requires a non-empty command array"}
        argv = resolve_validator_command(command, project_root, task_path, run_dir)
    else:
        if godot is None:
            return {"id": validator_id, "type": validator_type, "required": required, "ok": False, "fatal": True, "message": "Godot not found. Set GODOT_CMD to the Godot 4 executable."}
        if validator_type == "godot_import":
            argv = godot + ["--headless", "--editor", "--path", str(project_root), "--quit"]
        elif validator_type == "godot_scene":
            scene = str(validator.get("scene", ""))
            if not scene:
                return {"id": validator_id, "type": validator_type, "required": required, "ok": False, "fatal": True, "message": "godot_scene requires scene"}
            argv = godot + ([] if validator.get("renderer") == "gpu" else ["--headless"]) + ["--path", str(project_root), scene]
        elif validator_type == "map_contract":
            argv = godot + ["--headless", "--path", str(project_root), "--quit-after", "600", "res://tools/agent_qa/MapContractProbe.tscn", "--", f"--agent-task={task_path}"]
        elif validator_type == "ui_layout_contract":
            argv = godot + ["--headless", "--path", str(project_root), "--quit-after", "600", "res://tools/agent_qa/UIContractProbe.tscn", "--", f"--agent-task={task_path}"]
        else:
            return {"id": validator_id, "type": validator_type, "required": required, "ok": False, "fatal": True, "message": f"unsupported validator type: {validator_type}"}
    result = run_command(argv, project_root, timeout)
    combined = result.stdout + "\n" + result.stderr
    ok = result.ok
    success_regex = validator.get("success_regex")
    if success_regex:
        ok = ok and re.search(str(success_regex), combined, flags=re.MULTILINE) is not None
    fail_regex = validator.get("fail_on_log_regex")
    if fail_regex and re.search(str(fail_regex), combined, flags=re.MULTILINE | re.IGNORECASE):
        ok = False
    parsed_report: dict[str, Any] | None = None
    for line in combined.splitlines():
        if line.startswith("AGENT_QA_JSON:"):
            try:
                parsed_report = json.loads(line.split(":", 1)[1])
            except json.JSONDecodeError:
                pass
    value = {
        "id": validator_id,
        "type": validator_type,
        "required": required,
        "ok": ok,
        "message": "PASS" if ok else validator_message(result, validator_id),
        "command": result.as_dict(),
    }
    if result.timed_out or result.launch_error:
        value["fatal"] = True
    if parsed_report is not None:
        value["qa_report"] = parsed_report
    return value


def run_validators(task: dict[str, Any], project_root: Path, task_path: Path, run_dir: Path, iteration_dir: Path) -> list[dict[str, Any]]:
    godot = discover_godot()
    results: list[dict[str, Any]] = []
    for validator in task["validators"]:
        result = run_validator(validator, project_root, task_path, run_dir, godot)
        results.append(result)
        command = result.get("command")
        if command:
            log = f"COMMAND: {json.dumps(command['argv'], ensure_ascii=False)}\nEXIT: {command['exit_code']}\nDURATION: {command['duration_seconds']}s\n\nSTDOUT\n{command['stdout']}\n\nSTDERR\n{command['stderr']}"
            write_text(iteration_dir / "logs" / f"validator_{result['id']}.log", log)
        if result.get("fatal"):
            break
    return results


def collect_screenshots(task: dict[str, Any], project_root: Path, run_id: str, iteration: int) -> tuple[list[dict[str, Any]], list[str]]:
    collected: list[dict[str, Any]] = []
    failures: list[str] = []
    target_root = project_root / ".agents" / "screenshots" / run_id / f"iteration_{iteration:02d}"
    for spec in task.get("screenshots", []):
        pattern = normalize_rel(spec["source"])
        matches = [path for path in project_root.glob(pattern) if path.is_file()]
        required = bool(spec.get("required", True))
        if not matches and required:
            failures.append(f"screenshot:{pattern}: required artifact missing")
            continue
        for source in matches:
            relative = normalize_rel(source.relative_to(project_root))
            destination = target_root / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, destination)
            collected.append({"label": spec.get("label", source.name), "source": relative, "copy": normalize_rel(destination.relative_to(project_root)), "sha256": sha256_file(destination)})
    return collected, failures


def safety_result(task: dict[str, Any], changes: dict[str, list[str]]) -> dict[str, Any]:
    all_changes = flattened_changes(changes)
    protected_patterns = task["protected_paths"] + list(DEFAULT_PROTECTED)
    protected = [item for item in all_changes if path_matches(item, protected_patterns)]
    allowed_patterns = task["scope"] + task.get("allowed_output_paths", [])
    outside = [item for item in all_changes if not path_matches(item, allowed_patterns)]
    if task.get("mode", "implementation") == "read_only":
        outside = [item for item in all_changes if not path_matches(item, task.get("allowed_output_paths", []))]
        protected = [item for item in all_changes if path_matches(item, protected_patterns)]
    return {"ok": not protected and not outside, "protected_changes": protected, "outside_scope_changes": outside, "all_changes": all_changes}


def qa_result(task: dict[str, Any], validator_results: list[dict[str, Any]], safety: dict[str, Any], screenshot_failures: list[str]) -> dict[str, Any]:
    issues: list[str] = []
    fatal = False
    for result in validator_results:
        if result.get("required", True) and not result.get("ok", False):
            report = result.get("qa_report", {})
            report_failures = report.get("failures", []) if isinstance(report, dict) else []
            if report_failures:
                issues.extend(f"{result['id']}:{item}" for item in report_failures)
            else:
                issues.append(result.get("message", f"{result['id']} failed"))
        fatal = fatal or bool(result.get("fatal", False))
    issues.extend(screenshot_failures)
    if safety["protected_changes"]:
        issues.append("safety: protected paths changed: " + ", ".join(safety["protected_changes"]))
        fatal = True
    if safety["outside_scope_changes"]:
        issues.append("safety: files outside scope changed: " + ", ".join(safety["outside_scope_changes"]))
        fatal = True
    signature_source = "\n".join(sorted(re.sub(r"\b\d+(?:\.\d+)?\b", "#", issue) for issue in issues))
    signature = hashlib.sha256(signature_source.encode("utf-8")).hexdigest() if issues else "PASS"
    return {"status": "PASS" if not issues else "FAIL", "fatal": fatal, "failure_signature": signature, "unresolved_issues": issues, "validators": validator_results, "safety": safety}


def final_markdown(report: dict[str, Any]) -> str:
    changed = report.get("files_changed", [])
    issues = report.get("unresolved_issues", [])
    shots = report.get("screenshots", [])
    return f"""# Agent automation report: {report['task_id']}

- Status: **{report['status']}**
- Stop reason: {report['stop_reason']}
- Iterations: {report['iterations']}
- Run ID: `{report['run_id']}`
- Git checkpoint: {report['checkpoint']['git'].get('reason', 'Git metadata captured')}

## Files changed

{chr(10).join('- `' + item + '`' for item in changed) if changed else '- None'}

## Unresolved issues / root cause

{chr(10).join('- ' + item for item in issues) if issues else '- None'}

## Screenshot evidence

{chr(10).join('- `' + item['copy'] + '` (' + item['sha256'][:12] + ')' for item in shots) if shots else '- None collected'}

## Iteration evidence

{chr(10).join('- iteration ' + str(item['iteration']) + ': ' + item['status'] + ' — `.agents/runs/' + report['run_id'] + '/iteration_' + str(item['iteration']).zfill(2) + '/qa_result.json`' for item in report.get('iteration_results', [])) if report.get('iteration_results') else '- No implementation iteration executed'}
"""


def execute(task_path: Path, project_root: Path, dry_run: bool, max_override: int | None) -> int:
    task = load_task(task_path)
    if max_override is not None:
        if not 1 <= max_override <= HARD_MAX_ITERATIONS:
            raise OrchestratorError("--max-iterations must be between 1 and 5.")
        task["max_iterations"] = min(task["max_iterations"], max_override)
    run_id = f"{utc_stamp()}_{task['id']}"
    run_dir = project_root / ".agents" / "runs" / run_id
    run_dir.mkdir(parents=True, exist_ok=False)
    task_copy = run_dir / "task.json"
    write_json(task_copy, task)
    baseline = build_manifest(project_root)
    latest_manifest = baseline
    checkpoint = create_checkpoint(project_root, run_dir, task, baseline)
    environment = {
        "python": sys.executable,
        "godot": discover_godot(),
        "antigravity": discover_antigravity(),
        "ANTIGRAVITY_CMD_configured": bool(os.environ.get("ANTIGRAVITY_CMD")),
        "GODOT_CMD_configured": bool(os.environ.get("GODOT_CMD")),
    }
    write_json(run_dir / "environment.json", environment)

    iteration_results: list[dict[str, Any]] = []
    screenshots: list[dict[str, Any]] = []
    previous_qa: dict[str, Any] | None = None
    previous_signature: str | None = None
    status = "DRY_RUN" if dry_run else "FAIL"
    stop_reason = "dry-run completed; no worker or validator command executed" if dry_run else "not started"

    if dry_run:
        prompt = render_prompt(task, 1, None, project_root)
        write_text(run_dir / "iteration_01" / "prompt.txt", prompt)
    else:
        attempts = 1 if task.get("mode", "implementation") == "read_only" else task["max_iterations"]
        for iteration in range(1, attempts + 1):
            iteration_dir = run_dir / f"iteration_{iteration:02d}"
            iteration_dir.mkdir(parents=True, exist_ok=True)
            before_iteration = build_manifest(project_root, latest_manifest)
            prompt = render_prompt(task, iteration, previous_qa, project_root)
            write_text(iteration_dir / "prompt.txt", prompt)
            if task.get("mode", "implementation") == "implementation":
                worker = invoke_worker(task, prompt, iteration_dir / "prompt.txt", run_dir, iteration, project_root)
                write_json(iteration_dir / "worker_result.json", worker)
                attempts_log = worker.get("attempts", [])
                for index, attempt in enumerate(attempts_log, start=1):
                    write_text(iteration_dir / "logs" / f"worker_attempt_{index}.log", f"COMMAND: {json.dumps(attempt.get('argv', []), ensure_ascii=False)}\nEXIT: {attempt.get('exit_code')}\n\nSTDOUT\n{attempt.get('stdout', '')}\n\nSTDERR\n{attempt.get('stderr', '')}")
                if not worker.get("ok", False):
                    after_worker = build_manifest(project_root, before_iteration)
                    latest_manifest = after_worker
                    changes = diff_manifests(before_iteration, after_worker)
                    write_json(iteration_dir / "diff_summary.json", changes)
                    issue = worker.get("message", "Antigravity worker failed")
                    current_qa = {"status": "FAIL", "fatal": True, "failure_signature": hashlib.sha256(issue.encode()).hexdigest(), "unresolved_issues": [issue], "validators": [], "safety": safety_result(task, diff_manifests(baseline, after_worker))}
                    write_json(iteration_dir / "qa_result.json", current_qa)
                    iteration_results.append({"iteration": iteration, "status": "FAIL", "failure_signature": current_qa["failure_signature"]})
                    previous_qa = current_qa
                    stop_reason = "fatal Antigravity worker error"
                    break
            validator_results = run_validators(task, project_root, task_copy, run_dir, iteration_dir)
            collected, screenshot_failures = collect_screenshots(task, project_root, run_id, iteration)
            screenshots.extend(collected)
            after_iteration = build_manifest(project_root, before_iteration)
            latest_manifest = after_iteration
            iteration_diff = diff_manifests(before_iteration, after_iteration)
            cumulative_diff = diff_manifests(baseline, after_iteration)
            write_json(iteration_dir / "diff_summary.json", {"iteration": iteration_diff, "cumulative": cumulative_diff, "git": git_metadata(project_root)})
            safety = safety_result(task, cumulative_diff)
            current_qa = qa_result(task, validator_results, safety, screenshot_failures)
            write_json(iteration_dir / "qa_result.json", current_qa)
            iteration_results.append({"iteration": iteration, "status": current_qa["status"], "failure_signature": current_qa["failure_signature"]})
            if current_qa["status"] == "PASS":
                status = "PASS"
                stop_reason = "all required validators and safety gates passed"
                previous_qa = current_qa
                break
            if current_qa["fatal"]:
                stop_reason = "fatal validator or safety error"
                previous_qa = current_qa
                break
            if previous_signature == current_qa["failure_signature"]:
                stop_reason = "identical normalized failure repeated twice consecutively"
                previous_qa = current_qa
                break
            previous_signature = current_qa["failure_signature"]
            previous_qa = current_qa
            stop_reason = "maximum iterations reached" if iteration == attempts else "QA failed; correction prompt scheduled"

    final_manifest = build_manifest(project_root, latest_manifest)
    changed = flattened_changes(diff_manifests(baseline, final_manifest))
    unresolved = previous_qa.get("unresolved_issues", []) if previous_qa else []
    report = {
        "status": status,
        "stop_reason": stop_reason,
        "task_id": task["id"],
        "run_id": run_id,
        "iterations": len(iteration_results),
        "files_changed": changed,
        "unresolved_issues": unresolved,
        "screenshots": screenshots,
        "checkpoint": checkpoint,
        "iteration_results": iteration_results,
        "finished_at": utc_stamp(),
    }
    write_json(run_dir / "final_report.json", report)
    markdown = final_markdown(report)
    write_text(run_dir / "final_report.md", markdown)
    write_json(project_root / ".agents" / "reports" / f"{run_id}.json", report)
    write_text(project_root / ".agents" / "reports" / f"{run_id}.md", markdown)
    print(markdown)
    return 0 if status in {"PASS", "DRY_RUN"} else 1


def main() -> int:
    project_root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description="Run the bounded Boom Codex/Antigravity supervisor loop.")
    parser.add_argument("--task", type=Path, help="Task JSON path (relative paths resolve from project root).")
    parser.add_argument("--dry-run", action="store_true", help="Validate/configure/checkpoint only; do not call worker or validators.")
    parser.add_argument("--max-iterations", type=int, help="Lower the task iteration cap (hard maximum remains 5).")
    parser.add_argument("--rollback", metavar="RUN_ID", help="Explicitly restore files covered by a prior run checkpoint.")
    args = parser.parse_args()
    try:
        if args.rollback:
            run_dir = project_root / ".agents" / "runs" / normalize_rel(args.rollback)
            if run_dir.parent.resolve() != (project_root / ".agents" / "runs").resolve() or not run_dir.is_dir():
                raise OrchestratorError("Rollback RUN_ID is invalid or does not exist.")
            result = restore_checkpoint(project_root, run_dir)
            print(json.dumps(result, ensure_ascii=False, indent=2))
            return 0
        if args.task is None:
            parser.error("--task is required unless --rollback is used")
        task_path = args.task if args.task.is_absolute() else project_root / args.task
        return execute(task_path.resolve(), project_root, args.dry_run, args.max_iterations)
    except OrchestratorError as exc:
        print(f"FATAL: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
