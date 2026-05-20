---
name: studio-editor-memory-workflow
description: Use when working on Studio Editor tasks, especially bugs around `Circulation`, room `stretch`, shared geometry updates, or recurring Studio debugging threads. Resolve the Studio repo from the current workspace, CODEX_STUDIO_REPO, or common local paths, then load the shared Studio memory note and working agreement before starting. Update the shared memory note after stable fixes, root causes, or reusable repro assets are discovered.
---

# Studio Editor Memory Workflow

This skill shortens Studio Editor bug threads by turning the shared repo notes into explicit starting context. It is designed to work on both Windows and macOS without hardcoded machine paths.

## Repository Resolution

Resolve the Studio repo in this order:

1. If the current workspace is the Studio UI repo, use it.
2. If `CODEX_STUDIO_REPO` is set, use that path.
3. Check common local paths:
   - Windows: `C:\Qbiq\ui`
   - macOS: `~/Code/ui`
   - macOS: `~/Qbiq/ui`
   - macOS: `~/Developer/ui`
4. If the repo still cannot be found, ask the user for the Studio repo path.

The repo must contain `.codex-working-agreement.md` or `.codex-studio-editor-memory.md`, or otherwise look like the Studio UI repository.

## Startup Workflow

1. Resolve the Studio repo path.
2. Read `<studio-repo>/.codex-working-agreement.md`.
3. Read `<studio-repo>/.codex-studio-editor-memory.md`.
4. Treat those files as the durable starting context for the thread.
5. Focus the task using only the new `Context delta` supplied by the user.

If `.codex-working-agreement.md` is missing, continue with the task and tell the user the agreement note was not found.

If `.codex-studio-editor-memory.md` is missing, recreate it in the repo root with stable section names:

```md
# Studio Editor Memory

## Stable Repros

## Known Root Causes

## Known Suspects / Architectural Constraints

## Resolved Issues
```

## Working Style

- Bias toward narrow fixes for Studio Editor bugs.
- Give extra attention to `Circulation`, room `stretch`, and neighboring-geometry recomputation.
- Preserve design ids, snapshot ids, and repro assets in the task context when they matter.
- If a broad geometry change looks necessary, pause and surface that explicitly before committing to it.
- Work with user changes already present in the repo; do not revert unrelated edits.
- Prefer focused validation that matches the touched behavior.

## Memory Maintenance

Update `<studio-repo>/.codex-studio-editor-memory.md` after a task only when the new information is reusable.

Good updates:

- a stable repro asset that future threads will likely need
- a confirmed root cause that belongs in `Known Root Causes`
- a useful suspect or architectural constraint that belongs in `Known Suspects / Architectural Constraints`
- a concise resolved-issue entry with the user-visible behavior change

Avoid:

- copying the whole thread into memory
- ticket-only chatter that will not help future tasks
- speculative conclusions presented as facts
- private local paths that will not work for other developers

## New-Thread Template

Use this shape when the user invokes the skill in a fresh Studio thread:

```md
Use $studio-editor-memory-workflow for this Studio Editor task.

Task: <ticket or goal>
Context delta: <design id / snapshot ids / repro path / what is new vs the shared memory>
Expected result: <what should change>
Scope: <minimal local fix only / helper refactor allowed / broader change acceptable>
Validation: <unit only / studio suite / live verification / prepare PR>
Branch notes: <optional>
```

## Notes

- The memory source is the repo note, not hidden cross-thread state.
- This skill is a shortcut for loading and maintaining that note.
- `CODEX_STUDIO_REPO` is the preferred cross-machine override for nonstandard repo locations.
