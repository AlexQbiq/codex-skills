# Studio Developer Guide

This repository is meant to make Codex useful for recurring Studio Editor work, especially when the same geometry domains appear across many tickets.

## Why This Exists

Studio Editor bugs often need context that lives outside a single ticket:

- known geometry constraints
- fragile areas in `Circulation`
- room `stretch` behavior
- shared wall and neighboring room recomputation
- design ids or snapshots that reproduce specific states

The `studio-editor-memory-workflow` skill makes Codex load that durable context before changing code.

## First-Time Setup

Install the skills from this repo, then point Codex at your Studio UI repo when it is not the current workspace.

macOS:

```bash
export CODEX_STUDIO_REPO="$HOME/Code/ui"
```

Windows PowerShell:

```powershell
$env:CODEX_STUDIO_REPO = "C:\Qbiq\ui"
```

For a persistent setup, put the environment variable in your shell profile.

## Required Studio Repo Notes

The Studio repo should keep these files at its root:

- `.codex-working-agreement.md`
- `.codex-studio-editor-memory.md`

The working agreement should capture team-level rules for Codex work in the repo.

The memory file should capture reusable debugging knowledge only. It is not a transcript and should not become noisy.

## Recommended Prompt

```text
Use $studio-editor-memory-workflow for this Studio Editor task.

Task: QBIQ-12345 Circulation handle breaks after stretch
Context delta: design id 123, snapshot abc, happens after dragging the right room edge inward
Expected result: circulation handles remain joined
Scope: minimal local fix only
Validation: focused unit tests plus live verification
```

## What To Add To Memory

Add durable facts:

- confirmed root causes
- stable repro ids or snapshots
- specific helper functions that are risky to change
- geometry invariants that future fixes must preserve
- concise resolved issue notes

Do not add:

- speculation
- one-off ticket chatter
- long pasted conversations
- local-only paths
- secrets or customer-private data

## PR Flow

After a fix is validated, use:

```text
Use $github-pr-workflow targeting staging.
```

For this `codex-skills` repository itself, target `main`:

```text
Use $github-pr-workflow targeting main.
```

## Team Practices

- Keep skill changes reviewed like normal code.
- Prefer portable paths and environment variables.
- Update the Studio memory file after stable learning, not after every ticket.
- Keep the PR helper scripts small enough that developers can inspect them quickly.
- Treat Codex as a collaborator with repo context, not as a replacement for code review.
