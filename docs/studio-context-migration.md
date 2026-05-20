# Studio Context Migration

The `studio-editor-memory-workflow` skill is the loader and maintenance workflow. The valuable Studio debugging context lives in the Studio UI repository notes:

- `.codex-working-agreement.md`
- `.codex-studio-editor-memory.md`

This split is intentional:

- the skill can be shared and installed from this public repository
- the live memory can stay with the private Studio source tree
- each developer can use a different local Studio path

## What Was Migrated Here

This repository includes portable starter templates under `templates/studio/`.

They preserve the reusable structure and general Studio debugging heuristics:

- investigation workflow
- architecture map
- stretch data flow
- symptom-to-file triage table
- fragile patterns
- root-cause categories
- context delta checklist
- starter prompt
- memory maintenance rules

## What Should Stay In The Studio Repo

Keep private or highly specific project data in the Studio UI repository:

- real design ids
- snapshot ids
- Jira-only details
- customer-specific repro notes
- internal implementation history that should not be public
- exact resolved issue log when it names private tickets

## Install Templates Into A Studio Repo

From this repository:

```bash
cp templates/studio/.codex-working-agreement.md "$CODEX_STUDIO_REPO/.codex-working-agreement.md"
cp templates/studio/.codex-studio-editor-memory.md "$CODEX_STUDIO_REPO/.codex-studio-editor-memory.md"
```

PowerShell:

```powershell
Copy-Item .\templates\studio\.codex-working-agreement.md "$env:CODEX_STUDIO_REPO\.codex-working-agreement.md"
Copy-Item .\templates\studio\.codex-studio-editor-memory.md "$env:CODEX_STUDIO_REPO\.codex-studio-editor-memory.md"
```

If the Studio repo already has these files, merge manually rather than overwriting them.

## Mac Setup

On macOS, set `CODEX_STUDIO_REPO` to the local Studio UI checkout:

```bash
export CODEX_STUDIO_REPO="$HOME/Code/ui"
```

Then ask Codex:

```text
Use $studio-editor-memory-workflow for this Studio Editor task.
```

Codex should resolve the Studio repo and load the two repo notes before starting.
